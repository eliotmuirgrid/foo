require "LLPS.LLPSserver"

-- CUSTOMIZE this ACK generation if it doesn't meet your requirements 
function GenerateAck(Message)
   -- M is the inbound message 
   local M = hl7.parse{vmd="ack.vmd", data=Message}
   -- A is the outbound ACKnowledgement message
   local A = hl7.message{vmd="ack.vmd", name="ACK"}
   A.MSH[3][1] = M.MSH[5][1]
   A.MSH[4][1] = M.MSH[6][1]
   A.MSH[5][1] = M.MSH[3][1]
   A.MSH[6][1] = M.MSH[4][1]
   A.MSH[7]    = M.MSH[7]
   A.MSH[8]    = M.MSH[8]
   A.MSH[9][1] = "ACK"
   A.MSH[10]   = "A"..M.MSH[10]
   A.MSH[11]   = M.MSH[11]
   A.MSH[12]   = M.MSH[12]
   A.MSA[1]    = "AA"
   A.MSA[2]    = M.MSH[10] 
   local Ack = A:S()
   return Ack
end

-- The main function is called when a message is received by the server
-- An ACKnowledgement message must be returned when it exits
function main(Message)
   queue.push{data=Message}
   local Ack = GenerateAck(Message)
   return Ack
end

--This function starts the LLP server.
LLPstart()