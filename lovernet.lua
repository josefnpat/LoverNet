local lovernet = {}

lovernet.mode = {
  client = "Client",
  server = "Server",
}

function lovernet:log(...)
  local args = { ... }
  args[1] = os.time().." ["..self._type..":"..args[1].."]"
  assert(self) -- this may use configs from .new later
  print(unpack(args))
end

function lovernet:_encode(input)
  return self._serdes.dumps(input)
end

function lovernet:_decode(input)
  return self._serdes.loads(input)
end

function lovernet.new(init)

  init = init or {}
  local self = {}

  self.log = lovernet.log

  self._dt = 0

  self._type = init.type or lovernet.mode.client

  self._ip = init.ip or "localhost"
  self._port = init.port or 19870
  self.getIp = lovernet.getIp
  self.getPort = lovernet.getPort

  self._ops = {}

  self._data = {}
  self.dataAdd = lovernet.dataAdd
  self.dataPending = lovernet.dataPending
  self.dataClear = lovernet.dataClear

  self._storage = {}
  self.getStorage = lovernet.getStorage

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
  self.addDefaultOnServer = lovernet.addDefaultOnServer
  self.update = lovernet.update
  self.disconnect = lovernet.disconnect
  self.getData = lovernet.getData
  self.clearData = lovernet.clearData

  self._encode = lovernet._encode
  self._decode = lovernet._decode

  self._connectedToServer = false
  self.isConnectedToServer = lovernet.isConnectedToServer

  self._transmitRate = 1/24
  self.getClientTransmitRate = lovernet.getClientTransmitRate
  self.setClientTransmitRate = lovernet.setClientTransmitRate

  self._validateEventReceive = lovernet._validateEventReceive
  self._renderPayload = lovernet._renderPayload
  self._hasPayload = lovernet._hasPayload

  self._getUserIndex = lovernet._getUserIndex
  self._getUser = lovernet._getUser
  self._getUsers = lovernet._getUsers
  self._removeUser = lovernet._removeUser
  self._initUser = lovernet._initUser

  self._validateRecursive = lovernet._validateRecursive

  self:log("start","Starting "..self._type.." on port "..self._port)
  if self._type == lovernet.mode.client then
    self._host = self._enet.host_create()
    self._host:connect(self._ip .. ':' .. self._port)
    self._cache = {}
  else --if self._type == lovernet.mode.server then
    self._host = self._enet.host_create("*:"..self._port)
  end

  return self
end

function lovernet:getIp()
  return self._ip
end

function lovernet:getPort()
  return self._port
end

function lovernet:_renderPayload()
  --TODO: Add time info to allow for delays (e.g. only refresh this every second)
  local raw = self:_encode(self._data)
  self._data = {}
  return raw
end

function lovernet:_hasPayload()
  for i,v in pairs(self._data) do
    return true
  end
  return false
end

function lovernet:isConnectedToServer()
  return self._connectedToServer
end

function lovernet:hasOp(name)
  return self._ops[name] ~= nil
end

function lovernet:addOp(name)
  assert(not self:hasOp(name))
  self._ops[name] = {
    validate_server = function() return true end,
    validate_client = function() return true end,
    process_client = function(self,peer,arg,storage) return arg end,
    process_server = function(self,peer,arg,storage) return arg end,
    default_server = function() end,
    default_client = function() end,
  }
end

function lovernet:addValidateOnClient(name,input)
  assert(self:hasOp(name))
  self._ops[name].validate_client = input
end

function lovernet:addValidateOnServer(name,input)
  assert(self:hasOp(name))
  self._ops[name].validate_server = input
end

function lovernet:addProcessOnClient(name,input)
  assert(self:hasOp(name))
  self._ops[name].process_client = input
end

function lovernet:addProcessOnServer(name,input)
  assert(self:hasOp(name))
  self._ops[name].process_server = input
end

function lovernet:addDefaultOnClient(name,input)
  assert(self:hasOp(name))
  self._ops[name].default_client = input
end

function lovernet:addDefaultOnServer(name,input)
  assert(self:hasOp(name))
  self._ops[name].default_server = input
end

function lovernet:_getUserIndex(peer)
  return tostring(peer)
end

function lovernet:_getUser(peer)
  return self._users[self:_getUserIndex(peer)]
end

function lovernet:_getUsers()
  return self._users
end

function lovernet:_removeUser(peer)
  self._users[self:_getUserIndex(peer)] = nil
end

function lovernet:_initUser(peer)
  local user = {}
  user.name = "InvalidName"..math.random(1000,9999)
  self._users[self:_getUserIndex(peer)] = user
end

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

function lovernet:update(dt)

  self._dt = self._dt + dt

  if self._host then

    if self._type == lovernet.mode.server or self._dt > self:getClientTransmitRate() then
      for _,peer in pairs(self._peers) do
        if self:_hasPayload() then
          self._dt = 0
          local payload = self:_renderPayload()
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
          local user = self:_getUser(event.peer)
          table.insert(self._peers,event.peer)
          self:log("event","Connect: " .. tostring(event.peer).." ["..tostring(user.name).."]")
        elseif event.type == "disconnect" then
          local user = self:_getUser(event.peer)
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

function lovernet:disconnect()
  for i,v in pairs(self._peers) do
    v:disconnect()
  end
  self:log("stop","Stopping "..self._type.." on port "..self._port)
end

function lovernet:getClientTransmitRate()
  return self._transmitRate
end

function lovernet:setClientTransmitRate(rate)
  assert( type(rate) == "number" )
  self._transmitRate = rate
end

function lovernet:getData(name)
  assert(self._ops[name])
  if self._type == lovernet.mode.client then
    return self._cache[name] or self._ops[name].default_client(self)
  else --if self._type == lovernet.mode.server then
    return self._cache[name] or self._ops[name].default_server(self)
  end
end

function lovernet:clearData(name)
  assert(self._ops[name])
  self._cache[name] = nil
end

-- add a request to the queue
function lovernet:dataAdd(name,args)
  table.insert(self._data,{f=name,d=args})
end

-- is a request there?
function lovernet:dataPending(name)
  for i,v in pairs(self._data) do
    if v.f == name then
      return true
    end
  end
  return false
end

-- clear the requests
function lovernet:dataClear(name)
  for i,v in pairs(self._data) do
    if v.f == name then
      table.remove(self._data,i)
    end
  end
end

function lovernet:getStorage()
  return self._storage
end

return lovernet
