-- Indexes in the board are being accesed first height, second width, like [y][x]
-- if seen in screen coordinates or the more common (for programmers) [i][j], this
-- is because the cache misses are reduced by accessing adjacent locations more
-- often. (Ask your PC memory techie friends :^)

local WHITE_COLOR = {r=255,g=255,b=255}

-- This is a queue that will hold the changes needed to make the actual board look
-- like the next step in the game of life. It will hold 5 values meaning:
--     { Y position, X position, Red value, Green value, Blue value }
local changesQueue = {[0] = 0}
for i = 1, 64*64 do
  changesQueue[i] = {}
end

function changesQueue:toggle(y, x, r, g, b, drawIndex)
  drawIndex = drawIndex or 0

  self[0] = self[0] and self[0]+1 or 1
  self[ self[0] ].y = y  -- This is not a typo
  self[ self[0] ].x = x  -- This is not a typo
  self[ self[0] ].r = r
  self[ self[0] ].g = g
  self[ self[0] ].b = b
  self[ self[0] ].u = drawIndex
end

function changesQueue:clear()
  changesQueue[0] = 0
end

-- This are some transient variables that will speed up things (maybe)
local tmp,tmp2,tmp3

local checkAlive = function( board, y, x, liveColor, drawIndex )
  if type(board[y]) == 'table' and type(board[y][x]) == 'table' then
    tmp3 = board[y][x]
  else
    return false
  end

  if tmp3.r == liveColor.r and tmp3.g == liveColor.g and tmp3.b == liveColor.b then
    return true
  end

  return false
end

local aliveNeighbours = function( board, y, x, liveColor )

  -- Accumulator for the alive neighbours of a cell
  tmp2 = 0

  if checkAlive( board, y-1, x-1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y-1, x  , liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y-1, x+1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y  , x-1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y  , x+1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y+1, x-1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y+1, x  , liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, y+1, x+1, liveColor ) then tmp2 = tmp2 + 1 end

  return tmp2
end

local gameOfLife = function( board, width, height, liveColor, drawIndex )
  if not board then  return  end

  if not width then width = 64 end
  if not height then height = 64 end
  if not liveColor then liveColor = WHITE_COLOR end

  changesQueue:clear()

  for y = 1, height do
    for x = 1, width do
      tmp = aliveNeighbours( board, y, x, liveColor )

      if checkAlive(board, y, x, liveColor) then
        if tmp < 2 or tmp > 3 then
          changesQueue:toggle( y, x, 0, 0, 0, drawIndex )
        end
      else
        if tmp == 3 then
          changesQueue:toggle( y, x, liveColor.r, liveColor.g, liveColor.b, drawIndex )
        end
      end

    end
  end

  tmp = changesQueue[0]

  for i = 1, changesQueue[0] do
    if not board[changesQueue[i].y] then
      board[changesQueue[i].y] = {}
    end
    if not board[changesQueue[i].y][changesQueue[i].x] then
      board[changesQueue[i].y][changesQueue[i].x] = {}
    end

    board[changesQueue[i].y][changesQueue[i].x].r = changesQueue[i].r
    board[changesQueue[i].y][changesQueue[i].x].g = changesQueue[i].g
    board[changesQueue[i].y][changesQueue[i].x].b = changesQueue[i].b
    board[changesQueue[i].y][changesQueue[i].x].u = changesQueue[i].u
  end
  changesQueue:clear()

  return tmp
end

return gameOfLife
