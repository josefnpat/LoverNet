--- LoverNet is an enet networking wrapper module for LÖVE.
-- @module LoverNet
-- @author Josef N Patoprsty <seppi@josefnpat.com>
-- @copyright 2016
-- @license <a href="http://www.opensource.org/licenses/zlib-license.php">zlib/libpng</a>

local lovernet = {
  _VERSION     = "v%%VERSION%%",
  _DESCRIPTION = "An enet networking wrapper module for LÖVE.",
  _URL         = "https://github.com/josefnpat/lovernet",
  _LICENSE     = "zlib/libpng",
  _AUTHOR      = "Josef N Patoprsty <seppi@josefnpat.com>",
}

lovernet.mode = {
  client = "Client",
  server = "Server",
}

--- Instansiate a new instance of LoverNet.
-- @param init Parameters are passed in by a table.
-- param type The object type (lovernet.mode.client or lovernet.mode.server) Defaults to lovernet.mode.client
-- param ip The IP address in which the object should connect to. Defaults to "localhost"
-- param port The port in which the object should connect to. Defaults to 19870.
-- param enet The enet global module. Defaults the the one in namespace.
-- param serdes The Serializer/Deserializer module. Defaults to bitser.
-- param transmitRate The transmission rate that the object should update with. Defaults to 1/16.
-- param log The function used for logging. Defaults to lovernet.log.
-- return new LoverNet object or nil,error
function lovernet.new(init)

  init = init or {}
  local self = {}

  self.log = init.log or lovernet.log
  assert(type(self.log)=="function")

  self._dt = 0

  self._type = init.type or lovernet.mode.client
  assert(type(self._type)=="string")

  self._ip = init.ip or "localhost"
  assert(type(self._ip)=="string")
  self._port = init.port or 19870
  assert(type(self._port)=="number" or type(self._port=="string"))
  self.getIp = lovernet.getIp
  self.getPort = lovernet.getPort

  self._ops = {}

  self._data = {}

  if self._type == lovernet.mode.client then
    self.pushData = lovernet.pushData
    self.sendData = lovernet.sendData
    self.hasData = lovernet.hasData
    self.clearData = lovernet.clearData

    self.getCache = lovernet.getCache
    self.clearCache = lovernet.clearCache
  else -- if self._type == lovernet.mode.server then
    self.getStorage = lovernet.getStorage
    self.setStorage = lovernet.setStorage
  end

  self._storage = {}

  self._users = {}
  self._peers = {}

  self._enet = init.enet or require "enet"
  assert(self._enet)

  self._serdes = init.serdes or require "bitser"
  assert(self._serdes)

  self.hasOp = lovernet.hasOp
  self.addOp = lovernet.addOp
  self.addValidateOnClient = lovernet.addValidateOnClient
  self.addValidateOnServer = lovernet.addValidateOnServer
  self.addProcessOnClient = lovernet.addProcessOnClient
  self.addProcessOnServer = lovernet.addProcessOnServer
  self.addDefaultOnClient = lovernet.addDefaultOnClient

  self.update = lovernet.update
  self.disconnect = lovernet.disconnect

  self._encode = lovernet._encode
  self._decode = lovernet._decode

  self._connectedToServer = false
  self.isConnectedToServer = lovernet.isConnectedToServer

  self._transmitRate = init.transmitRate or 1/16
  assert(type(self._transmitRate)=="number")
  self.getClientTransmitRate = lovernet.getClientTransmitRate
  self.setClientTransmitRate = lovernet.setClientTransmitRate

  self._validateEventReceive = lovernet._validateEventReceive
  self._hasPayload = lovernet._hasPayload

  self._getUserIndex = lovernet._getUserIndex
  self.getUser = lovernet.getUser
  self.getUsers = lovernet.getUsers
  self._removeUser = lovernet._removeUser
  self._initUser = lovernet._initUser

  self._validateRecursive = lovernet._validateRecursive

  self:log("start","Starting "..self._type.." on port "..self._port)
  if self._type == lovernet.mode.client then
    self._host = self._enet.host_create()
    self._host:connect(self._ip .. ':' .. self._port)
    self._cache = {}
  else --if self._type == lovernet.mode.server then
    local enet_error
    self._host,enet_error = self._enet.host_create("*:"..self._port)
    if enet_error then
      self:log("error",enet_error)
      return nil,enet_error
    end
  end

  return self
end

--- Returns the IP address.
-- @return string
function lovernet:getIp()
  return self._ip
end

--- Returns the port.
-- @return string/number
function lovernet:getPort()
  return self._port
end

--- Determine if the client is connected to the server
-- @return boolean
function lovernet:isConnectedToServer()
  return self._connectedToServer
end

--- Determine if the object has a defined operation
-- @return boolean
function lovernet:hasOp(name)
  return self._ops[name] ~= nil
end

--- Add a new defined operation
-- @param name string
function lovernet:addOp(name)
  assert(not self:hasOp(name))
  self._ops[name] = {
    validate_server = function() return true end,
    validate_client = function() return true end,
    process_client = function(self,peer,arg,storage) return arg end,
    process_server = function(self,peer,arg,storage) return arg end,
    default_client = function() end,
  }
end

--- Add a validator when the client gets data
-- @param name string
-- @param input mixed
function lovernet:addValidateOnClient(name,input)
  assert(self:hasOp(name))
  self._ops[name].validate_client = input
end

--- Add a validator when the server gets data
-- @param name string
-- @param input mixed
function lovernet:addValidateOnServer(name,input)
  assert(self:hasOp(name))
  self._ops[name].validate_server = input
end

--- Add a processor when the client gets valid data
-- @param name string
-- @param input mixed
function lovernet:addProcessOnClient(name,input)
  assert(self:hasOp(name))
  self._ops[name].process_client = input
end

--- Add a processor when the server gets valid data
-- @param name string
-- @param input mixed
function lovernet:addProcessOnServer(name,input)
  assert(self:hasOp(name))
  self._ops[name].process_server = input
end

--- Add a default processor when the client doesn't have data yet
-- @param name string
-- @param input mixed
function lovernet:addDefaultOnClient(name,input)
  assert(self:hasOp(name))
  self._ops[name].default_client = input
end

--- Gets the user from the peer object
-- @param peer object
-- @return user object
function lovernet:getUser(peer)
  return self._users[self:_getUserIndex(peer)]
end

--- Gets all user objects
-- @return table of user objects
function lovernet:getUsers()
  return self._users
end

--- Update function required to enforce communication between client/server
-- @param dt float
function lovernet:update(dt)

  self._dt = self._dt + dt

  if self._host then

    if self._type == lovernet.mode.server or self._dt > self:getClientTransmitRate() then
      for _,peer in pairs(self._peers) do
        if self:_hasPayload() then
          self._dt = 0
          --TODO: Add time info to allow for delays (e.g. only refresh this every second)
          local payload = self:_encode(self._data)
          self._data = {}
          peer:send( payload )
        end
      end
    end

    local event = self._host:service(1)

    if event then

      if self._type == lovernet.mode.client then

        if event then
          if event.type == "connect" then
            self._connectedToServer = true
            table.insert(self._peers,event.peer)
          elseif event.type == "disconnect" then
            self._peers = {}
          elseif event.type == "receive" then
            self:_validateEventReceive(event)
          else
            self:log('error','unexpected event type',event.type)
          end
        end

      else --if self._type == lovernet.mode.server then

        if event.type == "connect" then
          self:_initUser(event.peer)
          local user = self:getUser(event.peer)
          table.insert(self._peers,event.peer)
          self:log("event","Connect: " .. tostring(event.peer).." ["..tostring(user.name).."]")
        elseif event.type == "disconnect" then
          local user = self:getUser(event.peer)
          self:log("event","Disconnect: " .. tostring(event.peer).." ["..tostring(user.name).."]")
          self:_removeUser(event.peer)
          for i,v in pairs(self._peers) do
            if v == event.peer then
              table.remove(self._peers,i)
            end
          end
        elseif event.type == "receive" then
          self:_validateEventReceive(event)
        else
          self:log('error','unexpected event type')
        end

      end

    end -- if event

  end -- if self._host

end

--- Disconnect the client(s) from the server.
function lovernet:disconnect()
  for i,v in pairs(self._peers) do
    v:disconnect()
  end
  self:log("stop","Stopping "..self._type.." on port "..self._port)
end

--- Get the rate at which LoveNet will update the client.
-- @return float
function lovernet:getClientTransmitRate()
  return self._transmitRate
end

--- Set the rate at which LoveNet will update the client.
-- @param rate float time in seconds
function lovernet:setClientTransmitRate(rate)
  assert( type(rate) == "number" )
  self._transmitRate = rate
end

--- Get the current cache value for a named resource. Only available in client mode.
-- @param name string
-- @return data object
function lovernet:getCache(name)
  assert(self._ops[name])
  return self._cache[name] or self._ops[name].default_client(self)
end

--- Clears the current cache value for a named resource in case you are using streamed data. Only available in client mode.
-- @param name string
function lovernet:clearCache(name)
  assert(self._ops[name])
  self._cache[name] = nil
end

--- Queues a new outgoing data request. Only available in client mode.
-- @param name string
-- @param args data
function lovernet:pushData(name,args)
  assert(self._ops[name])
  table.insert(self._data,{f=name,d=args})
end

--- Overwrites all new outgoing data requests. Only available in client mode.
-- @param name string
-- @param args data
function lovernet:sendData(name,args)
  assert(self._ops[name])
  self:clearData(name)
  table.insert(self._data,{f=name,d=args})
end

--- Checks if there are any outgoing data requests. Only available in client mode.
-- @param name string
function lovernet:hasData(name)
  assert(self._ops[name])
  for i,v in pairs(self._data) do
    if v.f == name then
      return true
    end
  end
  return false
end

--- Clears any queued outgoing data requests. Only available in client mode.
-- @param name string
function lovernet:clearData(name)
  assert(self._ops[name])
  for i,v in pairs(self._data) do
    if v.f == name then
      table.remove(self._data,i)
    end
  end
end

--- Returns the storage object that is contained by the server. Only available in server mode.
-- @return storage data
function lovernet:getStorage()
  return self._storage
end

--- Set the storage object for the server. Only available in server mode.
-- @param storage data
function lovernet:setStorage(storage)
  self._storage = storage
end

--- Send a message to the LoverNet logging system.
-- @param ... This function handles data much like lua's print does, but it should be called with the syntax lovernetobject:log(...)
function lovernet:log(...)
  local args = { ... }
  args[1] = os.time().." ["..self._type..":"..args[1].."]"
  assert(self) -- this may use configs from .new later
  print(unpack(args))
end

--- Internal function that encodes data for transmission.
-- @param input Data to be encoded.
-- @return encoded data
function lovernet:_encode(input)
  return self._serdes.dumps(input)
end

--- Internal function that decodes data for transmission.
-- @param input Data to be decoded.
-- @return decoded data
function lovernet:_decode(input)
  return self._serdes.loads(input)
end

--- Internal function to determine if there is data to transmit.
-- @return boolean
function lovernet:_hasPayload()
  for i,v in pairs(self._data) do
    return true
  end
  return false
end

--- Internal function to create a index for a peer.
-- @param peer object
-- @return string
function lovernet:_getUserIndex(peer)
  return tostring(peer)
end

--- Internal function to initialize a user
-- @param peer object
function lovernet:_initUser(peer)
  local user = {}
  user.name = "InvalidName"..math.random(1000,9999)
  self._users[self:_getUserIndex(peer)] = user
end

--- Internal function to remove a user
-- @param peer object
function lovernet:_removeUser(peer)
  self._users[self:_getUserIndex(peer)] = nil
end

--- Internal function to validate the addValidateOn[Client|Server] data recursively.
-- @param config mixed
-- @param data mixed
-- @return boolean, error string
function lovernet:_validateRecursive(config,data)
  if type(config) == "table" then
    if type(data) == "table" then
      for i,v in pairs(config) do
        local success,errmsg = self._validateRecursive(self,v,data[i])
        if not success then
          return false,errmsg
        end
      end
    else
      return false,"expecting `table`, got `"..type(data).."`["..tostring(data).."]"
    end
    return true
  elseif type(config) == "function" then
    local success,errmsg = config(data)
    return success,errmsg
  elseif config == type(data) then
    return true
  else
    return false,"expecting `"..config.."`, got `"..type(data).."`["..tostring(data).."]"
  end
end

--- Internal function to validate and store data on the receive event
-- @param event object
function lovernet:_validateEventReceive(event)

  local success,data = pcall(function() return self:_decode(event.data) end)
  if success then
    local ret = {}
    if type(data) == "table" then
      for _,op in pairs(data) do
        if type(op) == "table" then
          if op.f then
            if self._ops[op.f] then

              local vsuccess,errmsg
              if self._type == lovernet.mode.client then
                if type(self._ops[op.f].validate_client) == "function" then
                  vsuccess,errmsg = self._ops[op.f].validate_client(self,event.peer,op.d,self._storage)
                else
                  vsuccess,errmsg = self._validateRecursive(self,self._ops[op.f].validate_client,op.d)
                end
              else --if self._type == lovernet.mode.server then
                if type(self._ops[op.f].validate_server) == "function" then
                  vsuccess,errmsg = self._ops[op.f].validate_server(self,event.peer,op.d,self._storage)
                else
                  vsuccess,errmsg = self._validateRecursive(self,self._ops[op.f].validate_server,op.d)
                end
              end

              if vsuccess then

                if self._type == lovernet.mode.client then
                  local opret = self._ops[op.f].process_client(self,event.peer,op.d,self._storage)
                  if opret then
                    self._cache[op.f] = opret
                  end
                else --if self._type == lovernet.mode.server then
                  local opret = self._ops[op.f].process_server(self,event.peer,op.d,self._storage)
                  if opret then
                    table.insert(ret,{f=op.f,d=opret})
                  end
                end

              else
                self:log("error","Op `"..op.f.."` did not validate, ErrMsg:",errmsg)
              end

            else
              self:log("error","Op.f `"..op.f.."` not in ops table:",op.f)
            end
          else
            self:log("error","Op data object expect to have `f` index, got ",type(op.f))
          end
        else
          self:log("error","Op data object expected to be a table, got:",type(op))
        end
      end
    end

    if #ret > 0 then
      event.peer:send(self:_encode(ret))
    end

  end -- if success

end

setmetatable(lovernet,{__call = function(_,init) return lovernet.new(init) end})

return lovernet
