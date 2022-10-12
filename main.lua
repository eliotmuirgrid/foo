require "LLPS.LLPSserver"

-- The main function is called when a message is received by the server,
-- and an ACK message must be returned when it exits
function main(Message)
   start()
   -- Queue the message
   queue.push{data=Message}
   -- return ACK
   return LLPgenerateAck(Message)
end

function start()
   local Config = component.fields()
   socket.listen_a{port=Config.Port}
end

start()