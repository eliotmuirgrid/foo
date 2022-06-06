require "validate"
require "llp_server"

local function generate_ack(Message)
   trace(Message)
   if Message:sub(1,3) ~= "MSH" then
      error("invalid HL7 message")
   end
   local delimiter = Message:sub(4,4)
   local header = Message:split("\r")[1]
   local fields = header:split(delimiter)
   -- generate ACK header
   local ack = {
      [1]  = "MSH",
      [2]  = fields[2],
      [3]  = fields[5],
      [4]  = fields[6],
      [5]  = fields[3],
      [6]  = fields[4],
      [7]  = "",
      [8]  = "",
      [9]  = "ACK",
      [10] = 'A' .. fields[10],
      [11] = fields[11],
      [12] = fields[12],
      [13] = ""
   }
   -- generate ACK segment
   local ack2 = {
      [1] = "MSA",
      [2] = "AA",
      [3] = fields[10],
      [4] = ""
   }
   return table.concat(ack, delimiter) .. '\r' .. table.concat(ack2, delimiter)
end

-- The main function is called when a message is received by the server,
-- and an ACK message must be returned when it exits
function main(Message)
   -- log the message
   iguana.logMessage(Message)
   -- return ACK
   return generate_ack(Message)
end

