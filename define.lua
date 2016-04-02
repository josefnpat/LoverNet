return function(l)

  -- Add a way to name users
  l:addOp('whoami')
  -- Validate the name argument
  l:addValidateOnServer('whoami',function(self,peer,arg,storage)
    if type(arg.name) == "string" and arg.name ~= "" then
      return true
    end
    return false
  end)
  -- Store the user's name in the user data
  l:addProcessOnServer('whoami',function(self,peer,arg,storage)
    local user = self:_getUser(peer)
    user.name = arg.name
  end)

  -- Add a way to send the current user's position
  l:addOp('pos')
  -- Validate the x and y arguments
  l:addValidateOnServer('pos',function(self,peer,arg,storage)
    return type(arg.x) == "number" and type(arg.y) == "number"
  end)
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

  -- Add a way to draw stuff haha
  l:addOp('board')
  l:addProcessOnServer('board',function(self,peer,arg,storage)
    return storage.board or {}
  end)
  l:addDefaultOnClient('board',function(self,peer,arg,storage)
    return {}
  end)

  l:addOp('toggle')
  l:addValidateOnServer('toggle',function(self,peer,arg,storage)
    if type(arg) ~= "table" then return false,"root expecting table" end

    if type(arg.x) ~= "number" then return false,"arg.x expecting number" end
    if math.floor(arg.x) ~= arg.x then return false,"arg.x expecting int" end
    if arg.x < 1 or arg.x > 32 then
      return false,"arg.x expecting 1-32"
    end

    if type(arg.y) ~= "number" then return false,"arg.y expecting number" end
    if math.floor(arg.y) ~= arg.y then return false,"arg.y expecting int" end
    if arg.y < 1 or arg.y > 32 then
      return false,"arg.y expecting 1-32"
    end

    if type(arg.r) ~= "number" then return false,"arg.r expecting number" end
    if math.floor(arg.r) ~= arg.r then return false,"arg.r expecting int" end
    if arg.r < 0 or arg.r > 255 then
      return false,"arg.r expecting 0-255"
    end

    if type(arg.g) ~= "number" then return false,"arg.g expecting number" end
    if math.floor(arg.g) ~= arg.g then return false,"arg.g expecting int" end
    if arg.g < 0 or arg.g > 255 then
      return false,"arg.g expecting 0-255"
    end

    if type(arg.b) ~= "number" then return false,"arg.b expecting number" end
    if math.floor(arg.b) ~= arg.b then return false,"arg.b expecting int" end
    if arg.b < 0 or arg.b > 255 then
      return false,"arg.b expecting 0-255"
    end

    return true
  end)
  l:addProcessOnServer('toggle',function(self,peer,arg,storage)
    storage.board = storage.board or {}
    storage.board[arg.x] = storage.board[arg.x] or {}
    storage.board[arg.x][arg.y] = {r=arg.r,g=arg.g,b=arg.b}
  end)

end
