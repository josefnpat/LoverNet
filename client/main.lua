math.randomseed(os.time())

lovernetlib = require("lovernet")

function love.load()

  name = "Guest"..math.random(1,9999)
  lx,ly = 0,0
  users = {}

  -- Connects to localhost by default
  lovernet = lovernetlib.new()

  -- Just in case google ever hosts a server:
  -- lovernet = lovernetlib.new{ip="8.8.8.8"}

  -- Configure the lovernet instances the same way the server does
  require("define")(lovernet)

  -- Send your name once
  lovernet:dataAdd("whoami",{name=name})

end

function love.update(dt)

  local cx,cy = love.mouse.getPosition()
  -- If the current position has changed
  if cx ~= lx or cy ~= ly then
    lx,ly = cx,cy
    -- Only send the latest mouse position
    lovernet:dataClear('pos')
    lovernet:dataAdd('pos',{x=cx,y=cy})
  end

  -- Request a player list
  lovernet:dataClear('p')
  lovernet:dataAdd('p')

  -- Request the board
  lovernet:dataClear('board')
  lovernet:dataAdd('board')

  -- cache the users so we can perform a tween
  for i,v in pairs(lovernet:getData('p')) do
    -- initialize users if not set
    if users[v.name] == nil then
      users[v.name] = {x=v.x,y=v.y}
    end
    -- update target position
    users[v.name].tx = v.x
    users[v.name].ty = v.y
  end

  -- Simple tween
  for i,v in pairs(users) do
    v.x = (v.tx + v.x)/2
    v.y = (v.ty + v.y)/2
  end

  -- update the lovernet object
  lovernet:update(dt)
end

function love.mousepressed(x,y)
  lovernet:dataAdd('toggle',{x=math.floor(x/32),y=math.floor(y/32)})
end

function love.draw()

  if not lovernet:isConnectedToServer() then

    love.graphics.printf(
      "Connecting to "..lovernet._ip..":"..lovernet._port,
      0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")

  else

    love.graphics.setColor(127,127,127) -- gray
    -- iterate over the literal data for players
    for i,v in pairs(lovernet:getData('p')) do
      love.graphics.print(v.name,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,8)
    end

    love.graphics.setColor(255,255,255) -- white
    -- iterate over the tweened data for players
    for i,v in pairs(users) do
      love.graphics.print(i,
        v.x+10,
        v.y-love.graphics.getFont():getHeight()/2)
      love.graphics.circle("line",v.x,v.y,8)
    end

  end

  local board = lovernet:getData('board')
  for x = 1,16 do
    for y = 1,16 do
      local mode = "line"
      if board[x] and board[x][y] then
        mode = "fill"
      end
      love.graphics.rectangle(mode,x*32,y*32,32,32)
    end
  end

end

function love.quit()
  lovernet:disconnect()
  print('bye!')
end
