local SVRconnections = {}
local SVRrunning = false
local SVRdebug = false
local SVRidleTimeout = 60
local SVRonAccept, SVRonData

local function SVRcreateConnection(Id, Address)
   local meta = {
      id = Id,
      ip = Address,
      ts = os.time(),
      tp = "socket_connection"
   }
   local connection = {
      id = Id,
      ip = Address
   }
   setmetatable(connection, meta)
   return connection
end

local function SVRsocketConnection(Connection)
   if type(Connection) ~= "table" then
      return false
   end
   local meta = getmetatable(Connection)
   if not meta then
      return false
   end
   if meta.tp ~= "socket_connection" then
      return false
   end
   return true
end

local function SVRtouchConnection(Connection)
   if not SVRsocketConnection(Connection) then
      erorr("input is not a socket connection")
   end
   getmetatable(Connection).ts = os.time()
end

local function SVRpurgeIdleConnections()
   local now = os.time()
   for id, connection in pairs(SVRconnections) do
      if now - getmetatable(connection).ts > SVRidleTimeout then
         if SVRdebug then
            iguana.logDebug("Closing idle connection " .. tostring(Id) .. " from " .. Address)
         end
         socket.close_a(id)
      end
   end
end

socket.onAccept = function(Address, Id)
   if SVRdebug then
      iguana.logInfo("Established new connection " .. tostring(Id) .. " from " .. Address)
   end
   if SVRconnections[Id] then
      error("New connection has the same Id as an existing connection")
   end
   SVRconnections[Id] = SVRcreateConnection(Id, Address)
   if not SVRonAccept then
      error("Accept callback is not set")
   end
   SVRonAccept(SVRconnections[Id])
   SVRpurgeIdleConnections()
end

socket.onData = function(Data, Id)
   if SVRdebug then
      iguana.logDebug("Received data from connection " .. tostring(Id) .. "\n")
   end
   if not SVRconnections[Id] then
      error("Connection not found")
   end
   SVRtouchConnection(SVRconnections[Id])
   SVRonData(SVRconnections[Id], Data)
   SVRpurgeIdleConnections()
end

socket.onWrite = function(Id)
   if SVRdebug then
      iguana.logDebug("Connection " .. tostring(Id) .. " is ready to receive more data")
   end
   SVRtouchConnection(SVRconnections[Id])
	-- TODO: callback for streaming data
   SVRpurgeIdleConnections()
end

socket.onClose = function(Data, Id)
   local log_message = "Connection " .. tostring(Id) .. " closed"
   if #Data > 0 then
      log_message = log_message .. " with non-empty buffer: " .. Data:sub(1, 1024)
   end
   if SVRdebug then
      iguana.logInfo(log_message)
   end
   SVRconnections[Id] = nil
   SVRpurgeIdleConnections()
end

socket.onError = function(Data, Id)
   if SVRdebug then
      iguana.logError("Connection " .. tostring(Id) .. " encountered error: " .. Data)
   end
   -- TODO: callback
   SVRpurgeIdleConnections()
end


local function SVRstartServer(Config)
   if SVRrunning then
      error("Server already running")
   end
   socket.listen_a(Config)
   SVRrunning = true
end

local function SVRstopServer()
   if not SVRrunning then
      return
   end
   -- close all connections and stop listening
   -- wipe callbacks?
   SVRrunning = false
end

local function SVRsendResponse(Connection, Data)
   if not SVRsocketConnection(Connection) then
      erorr("input is not a socket connection")
   end
   socket.send_a(Data, getmetatable(Connection).id)
end

local function SVRcloseConnection(Connection)
   if not SVRsocketConnection(Connection) then
      erorr("input is not a socket connection")
   end
   socket.close_a(getmetatable(Connection).id)
end

local function SVRsetDebugMode(State)
   if type(State) ~= "boolean" then
      error("must be a bool")
   end
   SVRdebug = State
end

local function SVRsetIdleTimeout(Seconds)
   if type(Seconds) ~= "number" then
      error("must be an integer")
   end
   SVRidleTimeout = Seconds
end

local function SVRsetAcceptCallback(Callback)
   if type(Callback) ~= "function" then
      error("must be a function")
   end
   SVRonAccept = Callback
end

local function SVRsetDataCallabck(Callback)
   if type(Callback) ~= "function" then
      error("must be a function")
   end
   SVRonData = Callback
end

return {
   start       = SVRstartServer,
   stop        = SVRstopServer,
   respond     = SVRsendResponse,
   close       = SVRcloseConnection,
   setDebug    = SVRsetDebugMode,
   setTimeout  = SVRsetIdleTimeout,
   setOnAccept = SVRsetAcceptCallback,
   setOnData   = SVRsetDataCallabck
}