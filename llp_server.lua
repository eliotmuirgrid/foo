require "LLP.LLPparse"
local SVRserver = require "server"


local function LLPonAccept(Connection)
end

local function LLPonData(Connection, Data)
   -- append data to buffer
	if not Connection.buffer then
      Connection.buffer = Data
   else
      Connection.buffer = Connection.buffer .. Data
   end
   -- extract LLP messages
   local messages, amount = LLPparse(Connection.buffer)
   -- truncate buffer
   if amount > 0 then
      Connection.buffer = Connection.buffer:sub(amount + 1)
   end
   -- process messages in main and send response
   for _,message in ipairs(messages) do
      local ack = main(message)
      SVRserver.respond(Connection, LLPserialize(ack))
   end
end

-- start server in run mode only
local LIVE = not iguana.isTest()
if LIVE then
   SVRserver.setOnAccept(LLPonAccept)
   SVRserver.setOnData(LLPonData)
   SVRserver.start({port = component.fields().Port})
end