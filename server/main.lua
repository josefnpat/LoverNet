lovernetlib = require("lovernet")


function love.load()
  lovernet = lovernetlib.new({type=lovernetlib.mode.server})
  require("define")(lovernet)
end

function love.update(dt)
  lovernet:update(dt)
end
