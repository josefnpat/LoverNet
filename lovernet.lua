--[[
TODO:
* add ldoc
* clean up api
* follow kikito guidelines on lua modules
--]]

local lovernet = {}

lovernet.status = {
  client = "Client",
  server = "Server",
}

function lovernet:log(...)
  local args = { ... }
  args[1] = os.time().." ["..args[1].."]"
  assert(self) -- this may use configs from .new later
  print(unpack(args))
end

function lovernet:encode(input)
  return self._serdes.dumps(input)
end

function lovernet:decode(input)
  return self._serdes.loads(input)
end

function lovernet.new(init)

  init = init or {}
  local self = {}
  self._ip = init.ip or "localhost"
  self._port = init.port or 19870

  if self._type == lovernet.status.client then
    self.getIp = lovernet.getIp
    self.getPort = lovernet.getPort
  end

  self.log = lovernet.log

  self._dt = 0

  self._type = init.type or lovernet.status.client
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

  self.encode = lovernet.encode
  self.decode = lovernet.decode

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

  self:log("init","Setting up "..self._type.." on port "..self._port)
  if self._type == lovernet.status.client then
    self._host = self._enet.host_create()
    self._host:connect(self._ip .. ':' .. self._port)
    self._cache = {}
  else --if self._type == lovernet.status.server then
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
  local raw = self:encode(self._data)
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

--TODO: easy ip conflict -- use hash and sync with client
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
  local names = {"Benn","Seppi","Phil","Sam","Jerry","Ann","Joe","Fran","Jen"}
  user.name = names[math.random(#names)]
  self._users[self:_getUserIndex(peer)] = user
end

function lovernet:_validateEventReceive(event)

  local success,data = pcall(function() return self:decode(event.data) end)
  if success then
    local ret = {}
    if type(data) == "table" then
      for _,op in pairs(data) do
        if type(op) == "table" then
          if op.f then
            if self._ops[op.f] then

              local vsuccess,errmsg
              if self._type == lovernet.status.client then
                vsuccess,errmsg = self._ops[op.f].validate_client(self,event.peer,op.d,self._storage)
              else --if self._type == lovernet.status.server then
                vsuccess,errmsg = self._ops[op.f].validate_server(self,event.peer,op.d,self._storage)
              end

              if vsuccess then

                if self._type == lovernet.status.client then
                  local opret = self._ops[op.f].process_client(self,event.peer,op.d,self._storage)
                  if opret then
                    self._cache[op.f] = opret
                  end
                else --if self._type == lovernet.status.server then
                  local opret = self._ops[op.f].process_server(self,event.peer,op.d,self._storage)
                  if opret then
                    table.insert(ret,{f=op.f,d=opret})
                  end
                end

              else
                print("Op did not validate, ErrMsg:",errmsg)
              end


            else
              print("Op.f not in ops table:",op.f)
            end
          else
            print("Op data object expect to have `f` index, got ",type(op.f))
          end
        else
          print("Op data object expected to be a table, got:",type(op))
        end
      end
    end

    if #ret > 0 then
      event.peer:send(self:encode(ret))
    end

  end -- if success

end

function lovernet:update(dt)

  --TODO Add ping
  --TODO test disconnecting for client/server

  self._dt = self._dt + dt

  if self._host then

    if self._type == lovernet.status.server or self._dt > self:getClientTransmitRate() then
      for _,peer in pairs(self._peers) do
        if self:_hasPayload() then
          self._dt = 0
          local payload = self:_renderPayload()
          --print("payload",tostring(peer),payload)
          peer:send( payload )
        end
      end
    end

    local event = self._host:service(1)

    if event then

      if self._type == lovernet.status.client then

        if event then
          if event.type == "connect" then
            self._connectedToServer = true
            table.insert(self._peers,event.peer)
          elseif event.type == "disconnect" then
            self._peers = {}
          elseif event.type == "receive" then
            self:_validateEventReceive(event)
          else
            print('unexpected event type',event.type)
          end
        end

      else --if self._type == lovernet.status.server then

        if event.type == "connect" then
          self:_initUser(event.peer)
          local user = self:_getUser(event.peer)
          table.insert(self._peers,event.peer)
          self:log("event","Connect: " .. tostring(event.peer))
        elseif event.type == "disconnect" then
          local user = self:_getUser(event.peer)
          self:log("event","Disconnect: " .. user.name)
          self:_removeUser(event.peer)
          for i,v in pairs(self._peers) do
            if v == event.peer then
              table.remove(self._peers,i)
            end
          end
        elseif event.type == "receive" then
          self:_validateEventReceive(event)
        else
          print('unexpected event type')
        end

      end

    end -- if event

  end -- if self._host

end

function lovernet:disconnect()
  for i,v in pairs(self._peers) do
    v:disconnect()
  end
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
  if self._type == lovernet.status.client then
    return self._cache[name] or self._ops[name].default_client(self)
  else --if self._type == lovernet.status.server then
    return self._cache[name] or self._ops[name].default_server(self)
  end
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
