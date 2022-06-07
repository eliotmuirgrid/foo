local SVRserver = require "server"

-- Change to use LLP prefixes and change into parameters for the parsing function
local MESSAGE_PREFIX = "\11"
local MESSAGE_SUFFIX = "\28\13"

local function LLPonAccept(Connection)
end

local function LLPonData(Connection, Data)
   -- append data to buffer
	if not Connection.buffer then
      Connection.buffer = Data
   else
      Connection.buffer = Connection.buffer .. Data
   end
   -- extract LLP messages - TODO - shift into LLP library
   for message in Connection.buffer:gmatch(MESSAGE_PREFIX .. "(.-)" .. MESSAGE_SUFFIX) do
      local ack = main(message)
      SVRserver.respond(Connection, MESSAGE_PREFIX .. ack .. MESSAGE_SUFFIX)
   end
   -- END OF LLP library
   
   -- truncate buffer
   local _,trim_position = Connection.buffer:find(".*" .. MESSAGE_SUFFIX)
   if trim_position then
      Connection.buffer = Connection.buffer:sub(trim_position + 1)
   end
end

-- start server in run mode only
local LIVE = not iguana.isTest()
if LIVE then
   SVRserver.setOnAccept(LLPonAccept)
   SVRserver.setOnData(LLPonData)
   SVRserver.start({port = component.fields().Port})
end