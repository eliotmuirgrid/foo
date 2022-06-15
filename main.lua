require "validate"
require "LLP.LLPparse"
require "LLP.LLPserver"

-- The main function is called when a message is received by the server,
-- and an ACK message must be returned when it exits
function main(Message)
   -- Queue the message
   queue.push{data=Message}
   -- return ACK
   return LLPgenerateAck(Message)
end