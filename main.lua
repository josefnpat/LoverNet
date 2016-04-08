math.randomseed(os.time())

lovernetlib = require("lovernet")

server = require "server"
client = require "client"

function love.load()

  if headless then server.start() return end

  options = {
    {
      name = function() return server_data and "Shutdown Server" or "Host Server" end,
      action = function()
        if server_data then
          server.stop()
        else
          server.start()
        end
      end,
    },
    {
      name = function() return "Connect to localhost" end,
      action = function()
        client.start()
      end,
    },
    {
      name = function() return "Connect to demo server" end,
      action = function()
        client.start{ip="50.116.63.25"}
      end,
    },
    {
      name = function() return "Quit" end,
      action = love.event.quit,
    },
  }
  current_option = 1
end

function love.draw()

  if not client_data then
    love.graphics.setColor(255,255,255)
    local offset = (love.graphics.getHeight() - #options*24)/2
    love.graphics.printf("LoverNet Demo",0,offset-24,love.graphics.getWidth(),"center")
    for i,v in pairs(options) do
      local name = i == current_option and ">>> " .. v.name() .. " <<<" or v.name()
      love.graphics.printf(name,0,i*24+offset,love.graphics.getWidth(),"center")
    end
  end

  if server_data then server.draw() end
  if client_data then client.draw() end

end

function love.keypressed(key)

  if not client_data then

    if key == "up" then
      current_option = current_option - 1
      if current_option < 1 then
        current_option = #options
      end
    elseif key == "down" then
      current_option = current_option + 1
      if current_option > #options then
        current_option = 1
      end
    elseif key == "return" then
      options[current_option].action()
    end

  end

  if key == "escape" then
    if client_data then
      client.stop()
    elseif server_data then
      server.stop()
    else
      love.event.quit()
    end
  end

end

function love.mousepressed(x,y,button)
  if client_data then client.mousepressed(x,y,button) end
end

function love.update(dt)
  if client_data then client.update(dt) end
  if server_data then server.update(dt) end
end

function love.quit()
  if client_data then client.stop() end
  if server_data then server.stop() end
  print('bye!')
end
