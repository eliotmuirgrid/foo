local LLP_MESSAGE_PREFIX = "\11"
local LLP_MESSAGE_SUFFIX = "\28\13"

local LLPconnections = {}
local LLP_DEBUG = false
local LLP_TIMEOUT = 60

local function LLPpurgeIdleConnections()
   local now = os.time()
   for id, connection in pairs(LLPconnections) do
      if now - connection.ts > LLP_TIMEOUT then
         if LLP_DEBUG then
            iguana.logDebug("Closing idle connection " .. tostring(Id) .. " from " .. Address)
         end
         socket.close_a{connection=id}
      end
   end
end

local function LLPcreateConnection(Id, Address)
   local connection = {
      id = Id,
      ip = Address,
      ts = os.time(),
      tp = "socket_connection"
   }
   return connection
end

socket.onAccept = function(Address, Id)
   iguana.logInfo("New connection " .. tostring(Id) .. " received from " .. Address)
   if LLPconnections[Id] then
      error("New connection has the same Id as an existing connection")
   end
   LLPconnections[Id] = LLPcreateConnection(Id, Address)
   LLPpurgeIdleConnections()
end

socket.onData = function(Data, Id)
   if LLP_DEBUG then
      iguana.logDebug("Received data from connection " .. tostring(Id) .. "\n")
   end
   if not LLPconnections[Id] then
      error("Connection not found")
   end
   LLPonData(LLPconnections[Id], Data)
   LLPconnections[Id].ts = os.time()
   LLPpurgeIdleConnections()
end

socket.onWrite = function(Id)
   if LLP_DEBUG then
      iguana.logDebug("Connection " .. tostring(Id) .. " is ready to receive more data")
   end
   -- TODO: callback for streaming data -- could we deal with fragmented large ACKs?
   LLPconnections[Id].ts = os.time()
   LLPpurgeIdleConnections()
end

-- TODO - we don't an error callback
socket.onClose = function(Data, Id)
   local log_message = "Connection " .. tostring(Id) .. " closed"
   if #Data > 0 then
      log_message = log_message .. " with non-empty buffer: " .. Data:sub(1, 1024)
   end
   if LLP_DEBUG then
      iguana.logInfo(log_message)
   end
   LLPconnections[Id] = nil
   LLPpurgeIdleConnections()
end

-- TODO - we don't get an event for this.
socket.onError = function(Data, Id)
   iguana.logError("Connection " .. tostring(Id) .. " encountered error: " .. Data)
   -- TODO: callback
   LLPpurgeIdleConnections()
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
      socket.send_a{data=LLPserialize(ack), connection=Connection}
   end
end

-- parse LLP messages in buffer into Messages
function LLPparse(Buffer, Prefix, Suffix)
   if not Prefix then Prefix = LLP_MESSAGE_PREFIX end
   if not Suffix then Suffix = LLP_MESSAGE_SUFFIX end
   local prefix_size = #Prefix
   local suffix_size = #Suffix
   -- extract messages
   local consumed = 0
   local messages = {}
   for message in Buffer:gmatch(Prefix .. "(.-)" .. Suffix) do
      consumed = consumed + prefix_size + #message + suffix_size
      table.insert(messages, message)
   end
   Buffer:sub(consumed)
   return messages, consumed
end

-- add message prefix and suffix for LLP transport
function LLPserialize(Message, Prefix, Suffix)
   if not Prefix then Prefix = LLP_MESSAGE_PREFIX end
   if not Suffix then Suffix = LLP_MESSAGE_SUFFIX end
   return Prefix .. Message .. Suffix
end

-- Generates a standard HL7 ACK - if you need to make something custom
-- copy paste this and make your own ACK routine.
function LLPgenerateAck(Message)
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
      [2]  = fields[2] or '',
      [3]  = fields[5] or '',
      [4]  = fields[6] or '',
      [5]  = fields[3] or '',
      [6]  = fields[4] or '',
      [7]  = "",
      [8]  = "",
      [9]  = "ACK",
      [10] = 'A' .. (fields[10] or ''),
      [11] = fields[11] or '',
      [12] = fields[12] or '',
      [13] = ""
   }
   -- generate ACK segment
   local ack2 = {
      [1] = "MSA",
      [2] = "AA",
      [3] = fields[10] or '',
      [4] = ""
   }
   trace(ack, ack2, delimiter)
   return table.concat(ack, delimiter) .. '\r' .. table.concat(ack2, delimiter)
end