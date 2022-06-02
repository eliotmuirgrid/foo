local Connections = {}
local Running = false
local Debug = false
local IdleTimeout = 60
local OnAccept, OnData

local function create_connection(Id, Address)
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

local function socket_connection(Connection)
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

local function touch_connection(Connection)
   if not socket_connection(Connection) then
      erorr("input is not a socket connection")
   end
   getmetatable(Connection).ts = os.time()
end

local function purge_idle_connections()
   local now = os.time()
   for id, connection in pairs(Connections) do
      if now - getmetatable(connection).ts > IdleTimeout then
         if Debug then
            iguana.logDebug("Closing idle connection " .. tostring(Id) .. " from " .. Address)
         end
         socket.close_a(id)
      end
   end
end

socket.onAccept = function(Address, Id)
   if Debug then
      iguana.logInfo("Established new connection " .. tostring(Id) .. " from " .. Address)
   end
   if Connections[Id] then
      error("New connection has the same Id as an existing connection")
   end
   Connections[Id] = create_connection(Id, Address)
   if not OnAccept then
      error("Accept callback is not set")
   end
   OnAccept(Connections[Id])
   purge_idle_connections()
end

socket.onData = function(Data, Id)
   if Debug then
      iguana.logDebug("Received data from connection " .. tostring(Id) .. "\n")
   end
   if not Connections[Id] then
      error("Connection not found")
   end
   touch_connection(Connections[Id])
   OnData(Connections[Id], Data)
   purge_idle_connections()
end

socket.onWrite = function(Id)
   if Debug then
      iguana.logDebug("Connection " .. tostring(Id) .. " is ready to receive more data")
   end
   touch_connection(Connections[Id])
	-- TODO: callback for streaming data
   purge_idle_connections()
end

socket.onClose = function(Data, Id)
   local log_message = "Connection " .. tostring(Id) .. " closed"
   if #Data > 0 then
      log_message = log_message .. " with non-empty buffer: " .. Data:sub(1, 1024)
   end
   if Debug then
      iguana.logInfo(log_message)
   end
   Connections[Id] = nil
   purge_idle_connections()
end

socket.onError = function(Data, Id)
   if Debug then
      iguana.logError("Connection " .. tostring(Id) .. " encountered error: " .. Data)
   end
   -- TODO: callback
   purge_idle_connections()
end


local function start_server(Config)
   if Running then
      error("Server already running")
   end
   socket.listen_a(Config)
   Running = true
end

local function stop_server()
   if not Running then
      return
   end
   -- close all connections and stop listening
   -- wipe callbacks?
   Running = false
end

local function send_response(Connection, Data)
   if not socket_connection(Connection) then
      erorr("input is not a socket connection")
   end
   socket.send_a(Data, getmetatable(Connection).id)
end

local function close_connection(Connection)
   if not socket_connection(Connection) then
      erorr("input is not a socket connection")
   end
   socket.close_a(getmetatable(Connection).id)
end

local function set_debug_mode(State)
   if type(State) ~= "boolean" then
      error("must be a bool")
   end
   Debug = State
end

local function set_idle_timeout(Seconds)
   if type(Seconds) ~= "number" then
      error("must be an integer")
   end
   IdleTimeout = Seconds
end

local function set_accept_callback(Callback)
   if type(Callback) ~= "function" then
      error("must be a function")
   end
   OnAccept = Callback
end

local function set_Data_callabck(Callback)
   if type(Callback) ~= "function" then
      error("must be a function")
   end
   OnData = Callback
end

return {
   start       = start_server,
   stop        = stop_server,
   respond     = send_response,
   close       = close_connection,
   setDebug    = set_debug_mode,
   setTimeout  = set_idle_timeout,
   setOnAccept = set_accept_callback,
   setOnData   = set_Data_callabck,
   create_connection = create_connection
}