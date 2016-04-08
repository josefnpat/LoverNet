local server = {}

function server.start()
  server_data = {}
  server_data.lovernet = lovernetlib.new({type=lovernetlib.mode.server})
  require("define")(server_data.lovernet)
end

function server.stop()
  server_data.lovernet:disconnect()
  server_data = nil
end

function server.draw()
  love.graphics.setColor(255,255,255)
  love.graphics.print(
    "Server hosting on: " ..
      server_data.lovernet:getIp()..":"..server_data.lovernet:getPort())
end

function server.update(dt)
  server_data.lovernet:update(dt)
end

return server
