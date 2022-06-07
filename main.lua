component.fields().Port = 8888 -- TODO DELETE ME WHEN WE FIX CUSTOM fields.
require "validate"
require "llp_server"
require "LLP.LLPparse"

-- The main function is called when a message is received by the server,
-- and an ACK message must be returned when it exits
function main(Message)
   -- log the message
   iguana.logMessage(Message)
   -- return ACK
   return LLPgenerateAck(Message)
end