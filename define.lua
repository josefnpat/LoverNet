return function(l)

  -- Add a way to name users
  l:addOp('whoami')
  -- Validate the name argument
  l:addValidateOnServer('whoami',{name="string"})
  -- Store the user's name in the user data
  l:addProcessOnServer('whoami',function(self,peer,arg,storage)
    local user = self:_getUser(peer)
    user.name = arg.name
  end)

  -- Add a way to send the current user's position
  l:addOp('pos')
  -- Validate the x and y arguments as numbers
  l:addValidateOnServer('pos',{x="number",y="number"})
  -- Store the position of the user in the user data
  l:addProcessOnServer('pos',function(self,peer,arg,storage)
    local user = self:_getUser(peer)
    user.x = arg.x
    user.y = arg.y
  end)

  -- Add a way to inform all clients where all players are
  l:addOp('p')
  -- Create a table containing the name, x and y of each user
  l:addProcessOnServer('p',function(self,peer,arg,storage)
    local info = {}
    for i,v in pairs(self:_getUsers()) do
      table.insert(info,{name=v.name,x=v.x,y=v.y})
    end
    -- Return it to the requester
    return info
  end)
  -- Validate that the data is indeed a table containing users with name,x and y
  l:addValidateOnClient('p',function(self,peer,arg,storage)
    if type(arg) ~= "table" then return false,"root expecting table" end
    for i,v in pairs(arg) do
      if type(v.name) ~= "string" then return false,"v.name expecting string" end
      if type(v.x) ~= "number" then return false,"v.x expecting number" end
      if type(v.y) ~= "number" then return false,"v.y expecting number" end
    end
    return true
  end)
  -- Provide an empty table by default when a client requests the players
  l:addDefaultOnClient('p',function(self,peer,arg,storage)
    return {}
  end)

  -- Get board updates
  l:addOp('b')
  l:addValidateOnServer('b',"number")
  l:addProcessOnServer('b',function(self,peer,arg,storage)
    local ret = {}
    for x,row in pairs(storage.board or {}) do
      for y,val in pairs(row) do
        if val.u >= arg then
          table.insert(ret,{x=x,y=y,u=val.u,r=val.r,g=val.g,b=val.b})
        end
      end
    end
    return ret
  end)

  l:addOp('draw')

  local check_dim = function(data)
    if type(data) ~= "number" then return false,"data expecting number" end
    if math.floor(data) ~= data then return false,"data expecting int" end
    if data < 1 or data > board_size then
      return false,"data expecting 1-"..board_size
    end
    return true
  end

  local check_color_part = function(data)
    if type(data) ~= "number" then return false,"data expecting number" end
    if math.floor(data) ~= data then return false,"data expecting int" end
    if data < 0 or data > 255 then
      return false,"data expecting 0-255"
    end
    return true
  end

  l:addValidateOnServer('draw',{
    x=check_dim,y=check_dim,
    r=check_color_part,g=check_color_part,b=check_color_part,
  })

  l:addProcessOnServer('draw',function(self,peer,arg,storage)
    storage.board = storage.board or {}
    storage.board[arg.x] = storage.board[arg.x] or {}
    storage.board[arg.x][arg.y] = {
      r=arg.r,
      g=arg.g,
      b=arg.b,
      u=storage.draw_index or 0,
    }
    storage.draw_index = ( storage.draw_index or 0 ) + 1
  end)

end
