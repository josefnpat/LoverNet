require "board_size"

function love.conf(t)
  t.version = "0.10.1"
  t.window.title = "LoverNet Demo"
  t.window.width = 16*(board_size+2)
  t.window.height = 16*(board_size+2)
end
