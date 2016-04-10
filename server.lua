local server = {}

function server.start()
  server_data = {}
  server_data.lovernet = lovernetlib.new({type=lovernetlib.mode.server})
  if server_data.lovernet then
    require("define")(server_data.lovernet)
  else
    server_data = nil
  end
end

function server.stop()
  server_data.lovernet:disconnect()
  server_data = nil
end

function server.draw()
  love.graphics.setColor(255,255,255,63)
  love.graphics.print(
    "Server hosting on: " ..
      server_data.lovernet:getIp()..":"..server_data.lovernet:getPort())
end

function server.update(dt)
  server_data.lovernet:update(dt)

  if confetti then

    confetti_dt = confetti_dt or 0
    confetti_t = confetti_t or 1/32
    confetti_colors = confetti_colors or {
      {226,68,59},--red
      {255,205,106}, -- yellow
      {16,199,203}, -- blue
    }

    confetti_dt = confetti_dt + dt
    if confetti_dt > confetti_t then
      confetti_dt = 0
      local storage = server_data.lovernet:getStorage()
      local x,y = math.random(1,board_size),math.random(1,board_size)
      storage.board = storage.board or {}
      storage.board[x] = storage.board[x] or {}
      local color = confetti_colors[math.random(#confetti_colors)]
      storage.board[x][y] = {
        r = color[1],
        g = color[2],
        b = color[3],
        u = storage.draw_index or 0
      }
      storage.draw_index = ( storage.draw_index or 0 ) + 1
    end

  end

  if conway then
    if not gameOfLife then gameOfLife = require 'conway' end
    conway_dt = conway_dt or 0
    conway_t = conway_t or 1/2

    conway_dt = conway_dt + dt
    if conway_dt > conway_t then
      conway_dt = 0

      local storage = server_data.lovernet:getStorage()
      storage.board = storage.board or {}
      gameOfLife( storage.board, board_size, board_size, {r=255,g=255,b=255}, storage.draw_index or 0 )
      storage.draw_index = ( storage.draw_index or 0 ) + 1
    end
  end


end

return server
