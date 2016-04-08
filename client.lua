local client = {}

function client.start(args)

  client_data = {}

  client_data.name = "Guest"..math.random(1,9999)
  client_data.lx,client_data.ly = 0,0
  client_data.users = {}
  client_data.board = {}
  client_data.board_index = 0

  -- Connects to localhost by default
  client_data.lovernet = lovernetlib.new(args)

  -- Just in case google ever hosts a server:
  -- client_data.lovernet = lovernetlib.new{ip="8.8.8.8"}

  -- Configure the lovernet instances the same way the server does
  require("define")(client_data.lovernet)

  -- Get version information
  client_data.lovernet:dataAdd("version")

  -- Send your name once
  client_data.lovernet:dataAdd("whoami",{name=client_data.name})

end

function client.stop()
  client_data.lovernet:disconnect()
  client_data = nil
end

function client.update(dt)

  local cx,cy = love.mouse.getPosition()
  -- If the current position has changed
  if cx ~= client_data.lx or cy ~= client_data.ly then
    client_data.lx,client_data.ly = cx,cy
    -- Only send the latest mouse position
    client_data.lovernet:dataClear('pos')
    client_data.lovernet:dataAdd('pos',{x=cx,y=cy})
  end

  -- Request a player list
  client_data.lovernet:dataClear('p')
  client_data.lovernet:dataAdd('p')

  -- Request updates to the board
  client_data.lovernet:dataClear('b')
  client_data.lovernet:dataAdd('b',client_data.board_index)

  if client_data.lovernet:getData('b') then
    for _,v in pairs(client_data.lovernet:getData('b')) do
      client_data.board_index = math.max(client_data.board_index,v.u+1)
      client_data.board[v.x] = client_data.board[v.x] or {}
      client_data.board[v.x][v.y] = {r=v.r,g=v.g,b=v.b}
    end
    client_data.lovernet:clearData('b')
  end

  -- cache the users so we can perform a tween
  for i,v in pairs(client_data.lovernet:getData('p')) do
    -- initialize users if not set
    if client_data.users[v.name] == nil then
      client_data.users[v.name] = {x=v.x,y=v.y,t=os.time()}
    end
    -- update target position
    client_data.users[v.name].tx = v.x
    client_data.users[v.name].ty = v.y
  end

  -- Simple tween & cleanup
  for i,v in pairs(client_data.users) do
    v.x = (v.tx + v.x)/2
    v.y = (v.ty + v.y)/2
    if v.t < os.time()-2 then
      client_data.users[i] = nil
    end
  end

  -- update the lovernet object
  client_data.lovernet:update(dt)
end

function client.mousepressed(mx,my,button)

  -- For anyone who is hacking at this, take note that while the client only
  -- works in black and white, the server accepts RGB - so fee free to go crazy.

  -- We don't handle crazy values
  -- This is an example of how the server can handle bad data.
  local x,y = math.floor(mx/16),math.floor(my/16)

  if button == 1 then

    if client_data.board[x] and client_data.board[x][y] then -- it is empty
      if client_data.board[x][y].r == 0 and client_data.board[x][y].g == 0 and client_data.board[x][y].b == 0 then -- it is black
        -- draw white
        client_data.lovernet:dataAdd('draw',{x=x,y=y,r=255,g=255,b=255})
      else -- it's not black
        -- draw black
        client_data.lovernet:dataAdd('draw',{x=x,y=y,r=0,g=0,b=0})
      end
    else
      -- draw white
      client_data.lovernet:dataAdd('draw',{x=x,y=y,r=255,g=255,b=255})
    end

  elseif button == 2 then

    -- Simple hack to show how multiple dataAdd's can be run in one update
    local cat = love.image.newImageData('cat.png')
    for cx = 1,cat:getWidth() do
      for cy = 1,cat:getHeight() do
        local cr,cg,cb,ca = cat:getPixel(cx-1,cy-1)
        -- Get the target location of the pixel
        local tx,ty = cx+x-1,cy+y-1
        -- Only send data if it's alpha is 255 and it's on the board
        if ca == 255 and tx <= board_size and ty <= board_size and tx > 0 and ty > 0 then
          client_data.lovernet:dataAdd('draw',{x=tx,y=ty,r=cr,g=cg,b=cb})
        end
      end
    end

  end

end

function client.draw()

  if not client_data.lovernet:isConnectedToServer() then

    love.graphics.printf(
      "Connecting to "..client_data.lovernet:getIp()..":"..client_data.lovernet:getPort(),
      0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")

  elseif client_data.lovernet:getData('version') ~= true then

    love.graphics.printf(
      client_data.lovernet:getData('version'),
      0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")

  else

    love.graphics.setColor(255,255,255,63)

    love.graphics.printf("board index:"..tostring(client_data.board_index),
      0,0,love.graphics.getWidth(),"center")

    love.graphics.setColor(255,255,255) -- white

    for x = 1,board_size do
      for y = 1,board_size do
        local mode
        if client_data.board[x] and client_data.board[x][y] then
          mode = "fill"
          love.graphics.setColor(client_data.board[x][y].r,client_data.board[x][y].g,client_data.board[x][y].b)
        else
          mode = "line"
          love.graphics.setColor(255,255,255,63)
        end
        love.graphics.rectangle(mode,x*16,y*16,16,16)
      end
    end

    love.graphics.setColor(127,0,0) -- dark red
    -- iterate over the literal data for players
    for i,v in pairs(client_data.lovernet:getData('p')) do
      love.graphics.print(v.name,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,8)
    end

    love.graphics.setColor(255,0,0) -- red
    -- iterate over the tweened data for players
    for i,v in pairs(client_data.users) do
      love.graphics.print(i,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,8)
    end

  end

end

return client
