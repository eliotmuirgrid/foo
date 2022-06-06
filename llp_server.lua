local server = require "server"

local MESSAGE_PREFIX = "\11"
local MESSAGE_SUFFIX = "\28\13"

local function on_accept(Connection)
end

local function on_data(Connection, Data)
   -- append data to buffer
	if not Connection.buffer then
      Connection.buffer = Data
   else
      Connection.buffer = Connection.buffer .. Data
   end
   -- extract LLP messages
   for message in Connection.buffer:gmatch(MESSAGE_PREFIX .. "(.-)" .. MESSAGE_SUFFIX) do
      local ack = main(message)
      server.respond(Connection, MESSAGE_PREFIX .. ack .. MESSAGE_SUFFIX)
   end
   -- truncate buffer
   local _,trim_position = Connection.buffer:find(".*" .. MESSAGE_SUFFIX)
   if trim_position then
      Connection.buffer = Connection.buffer:sub(trim_position + 1)
   end
end

-- start server in run mode only
local LIVE = not iguana.isTest()
if LIVE then
   server.setOnAccept(on_accept)
   server.setOnData(on_data)
   server.start({port = component.fields().Port})
end