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

end
