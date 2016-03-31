lovernetlib = require("lovernet")


function love.load()
  lovernet = lovernetlib.new({type=lovernetlib.status.server})
  require("define")(lovernet)
end

function love.update(dt)
  lovernet:update(dt)
end
