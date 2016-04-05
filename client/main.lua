math.randomseed(os.time())

lovernetlib = require("lovernet")

local game = {}

function love.load()

  game.name = "Guest"..math.random(1,9999)
  game.lx,game.ly = 0,0
  game.users = {}
  game.board = {}

  -- Connects to localhost by default
  lovernet = lovernetlib.new()

  -- Just in case google ever hosts a server:
  -- lovernet = lovernetlib.new{ip="8.8.8.8"}

  -- Configure the lovernet instances the same way the server does
  require("define")(lovernet)

  -- Get version information
  lovernet:dataAdd("version")

  -- Send your name once
  lovernet:dataAdd("whoami",{name=game.name})

end

function love.update(dt)

  local cx,cy = love.mouse.getPosition()
  -- If the current position has changed
  if cx ~= game.lx or cy ~= game.ly then
    game.lx,game.ly = cx,cy
    -- Only send the latest mouse position
    lovernet:dataClear('pos')
    lovernet:dataAdd('pos',{x=cx,y=cy})
  end

  -- Request a player list
  lovernet:dataClear('p')
  lovernet:dataAdd('p')

  -- Request updates to the board
  lovernet:dataClear('b')
  lovernet:dataAdd('b',board_index or 0)

  if lovernet:getData('b') then
    for _,v in pairs(lovernet:getData('b')) do
      board_index = math.max(board_index or 0,v.u+1)
      game.board[v.x] = game.board[v.x] or {}
      game.board[v.x][v.y] = {r=v.r,g=v.g,b=v.b}
    end
    lovernet:clearData('b')
  end

  -- cache the users so we can perform a tween
  for i,v in pairs(lovernet:getData('p')) do
    -- initialize users if not set
    if game.users[v.name] == nil then
      game.users[v.name] = {x=v.x,y=v.y,t=os.time()}
    end
    -- update target position
    game.users[v.name].tx = v.x
    game.users[v.name].ty = v.y
  end

  -- Simple tween & cleanup
  for i,v in pairs(game.users) do
    v.x = (v.tx + v.x)/2
    v.y = (v.ty + v.y)/2
    if v.t < os.time()-2 then
      game.users[i] = nil
    end
  end

  -- update the lovernet object
  lovernet:update(dt)
end

function love.mousepressed(mx,my)

  -- For anyone who is hacking at this, take node that while the client only
  -- works in black and white, the server accepts RGB - so fee free to go crazy.

  -- We don't handle crazy values
  -- This is an example of how the server can handle bad data.
  local x,y = math.floor(mx/16),math.floor(my/16)

  if game.board[x] and game.board[x][y] then -- it is empty
    if game.board[x][y].r == 0 and game.board[x][y].g == 0 and game.board[x][y].b == 0 then -- it is black
      -- draw white
      lovernet:dataAdd('draw',{x=x,y=y,r=255,g=255,b=255})
    else -- it's not black
      -- draw black
      lovernet:dataAdd('draw',{x=x,y=y,r=0,g=0,b=0})
    end
  else
    -- draw white
    lovernet:dataAdd('draw',{x=x,y=y,r=255,g=255,b=255})
  end

end

function love.draw()

  if not lovernet:isConnectedToServer() then

    love.graphics.printf(
      "Connecting to "..lovernet:getIp()..":"..lovernet:getPort(),
      0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")

  elseif lovernet:getData('version') ~= true then

    love.graphics.printf(
      lovernet:getData('version'),
      0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")

  else

    love.graphics.setColor(255,255,255,63)

    love.graphics.printf("board index:"..tostring(board_index),
      0,0,love.graphics.getWidth(),"center")

    love.graphics.setColor(255,255,255) -- white

    for x = 1,board_size do
      for y = 1,board_size do
        local mode
        if game.board[x] and game.board[x][y] then
          mode = "fill"
          love.graphics.setColor(game.board[x][y].r,game.board[x][y].g,game.board[x][y].b)
        else
          mode = "line"
          love.graphics.setColor(255,255,255,63)
        end
        love.graphics.rectangle(mode,x*16,y*16,16,16)
      end
    end

    love.graphics.setColor(127,0,0) -- dark red
    -- iterate over the literal data for players
    for i,v in pairs(lovernet:getData('p')) do
      love.graphics.print(v.name,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,8)
    end

    love.graphics.setColor(255,0,0) -- red
    -- iterate over the tweened data for players
    for i,v in pairs(game.users) do
      love.graphics.print(i,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,8)
    end

  end

end

function love.quit()
  lovernet:disconnect()
  print('bye!')
end
