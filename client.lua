local client = {}

function client.start(args)

  client_data = {}

  client_data.name = args.name or "Lover"..math.random(1000,9999)
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
  client_data.lovernet:pushData("version")

  -- Send your name once
  client_data.lovernet:pushData("whoami",{name=client_data.name})

end

function client.stop()
  client_data.lovernet:disconnect()
  client_data = nil
end

function client.update(dt)

  local cx,cy = love.mouse.getPosition()
  -- If the current position has changed
  if cx ~= client_data.lx or cy ~= client_data.ly then
    -- clear the offset data from the keyboard
    client_data.ox,client_data.oy = 0,0
    -- use the corrent mouse coords
    client_data.lx,client_data.ly = cx,cy
    -- Only send the latest mouse position
    client_data.lovernet:clearData('pos')
    client_data.lovernet:pushData('pos',{x=cx,y=cy})
  end

  -- Check keyboard inputs for offset data
  if love.keyboard.isDown("right") then client_data.ox = client_data.ox + 1 end
  if love.keyboard.isDown("left") then client_data.ox = client_data.ox - 1 end
  if love.keyboard.isDown("down") then client_data.oy = client_data.oy + 1 end
  if love.keyboard.isDown("up") then client_data.oy = client_data.oy - 1 end

  -- Send keyboard offsets if it's being used
  if client_data.ox ~= 0 or client_data.oy ~= 0 then
    client_data.lovernet:clearData('pos')
    client_data.lovernet:pushData('pos',{x=cx+client_data.ox,y=cy+client_data.oy})
  end

  -- If we have not requested a player list
  if not client_data.lovernet:hasData('p') then
    -- Request a player list
    client_data.lovernet:pushData('p')
  end

  -- Request updates to the board with the latest board index
  client_data.lovernet:clearData('b')
  client_data.lovernet:pushData('b',client_data.board_index)

  if client_data.lovernet:getCache('b') then
    for _,v in pairs(client_data.lovernet:getCache('b')) do
      client_data.board_index = math.max(client_data.board_index,v.u+1)
      client_data.board[v.x] = client_data.board[v.x] or {}
      client_data.board[v.x][v.y] = {r=v.r,g=v.g,b=v.b}
    end
    client_data.lovernet:clearCache('b')
  end

  -- cache the users so we can perform a tween
  for i,v in pairs(client_data.lovernet:getCache('p')) do
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

  local x,y = math.floor(mx/pixel_size),math.floor(my/pixel_size)

  -- As shown in define.lua, the draw operation can handle erronious data, but
  -- We're going to try to avoid sending bad data anyway.
  if x > 0 and x <= board_size and y > 0 and y <= board_size then

    if button == 1 then

      if client_data.board[x] and client_data.board[x][y] then -- it is empty
        if client_data.board[x][y].r == 0 and client_data.board[x][y].g == 0 and client_data.board[x][y].b == 0 then -- it is black
          -- draw white
          client_data.lovernet:pushData('draw',{x=x,y=y,r=255,g=255,b=255})
        else -- it's not black
          -- draw black
          client_data.lovernet:pushData('draw',{x=x,y=y,r=0,g=0,b=0})
        end
      else
        -- draw white
        client_data.lovernet:pushData('draw',{x=x,y=y,r=255,g=255,b=255})
      end

    elseif button == 2 then

      -- Simple hack to show how multiple pushData's can be run in one update
      local cat = love.image.newImageData('cat.png')
      for cx = 1,cat:getWidth() do
        for cy = 1,cat:getHeight() do
          local cr,cg,cb,ca = cat:getPixel(cx-1,cy-1)
          -- Get the target location of the pixel
          local tx,ty = cx+x-1,cy+y-1
          -- Only send data if it's alpha is 255 and it's on the board
          if ca == 255 and tx <= board_size and ty <= board_size and tx > 0 and ty > 0 then
            client_data.lovernet:pushData('draw',{x=tx,y=ty,r=cr,g=cg,b=cb})
          end
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

  elseif client_data.lovernet:getCache('version') ~= true then

    love.graphics.printf(
      client_data.lovernet:getCache('version'),
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
        love.graphics.rectangle(mode,x*pixel_size+0.5,y*pixel_size+0.5,pixel_size,pixel_size)
      end
    end

    love.graphics.setColor(127,0,0) -- dark red
    -- iterate over the literal data for players
    for i,v in pairs(client_data.lovernet:getCache('p')) do
      love.graphics.print(v.name,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,7)
    end

    love.graphics.setColor(255,0,0) -- red
    -- iterate over the tweened data for players
    for i,v in pairs(client_data.users) do
      love.graphics.print(i,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,6)
    end

    -- show the current cursor position
    love.graphics.circle("line",
      love.mouse.getX()+client_data.ox,
      love.mouse.getY()+client_data.oy,
      8
    )

  end

end

return client
