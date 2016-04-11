--------------------------------------------------------------------------------
-- The author of this wishes to remain anonymous, but wants to contribute to the
-- project regardless. While the code has been reviewed to ensure it is not
-- malicious, I am not at liberty to say that LoverNet will support or maintain
-- this functionality of the demo.
--------------------------------------------------------------------------------

local WHITE_COLOR = {r=255,g=255,b=255}

-- This is a queue that will hold the changes needed to make the actual board look
-- like the next step in the game of life. It will hold 5 values meaning:
--     { Y position, X position, Red value, Green value, Blue value }
local changesQueue = {[0] = 0}
for i = 1, 64*64 do
  changesQueue[i] = {}
end

function changesQueue:toggle(x, y, r, g, b, drawIndex)
  drawIndex = drawIndex or 0

  self[0] = self[0] and self[0]+1 or 1
  self[ self[0] ].y = y
  self[ self[0] ].x = x
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

local checkAlive = function( board, x, y, liveColor, drawIndex )
  if type(board[x]) == 'table' and type(board[x][y]) == 'table' then
    tmp3 = board[x][y]
  else
    return false
  end

  if tmp3.r == liveColor.r and tmp3.g == liveColor.g and tmp3.b == liveColor.b then
    return true
  end

  return false
end

local aliveNeighbours = function( board, x, y, liveColor )

  -- Accumulator for the alive neighbours of a cell
  tmp2 = 0

  if checkAlive( board, x-1, y-1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x-1, y  , liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x-1, y+1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x  , y-1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x  , y+1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x+1, y-1, liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x+1, y  , liveColor ) then tmp2 = tmp2 + 1 end
  if checkAlive( board, x+1, y+1, liveColor ) then tmp2 = tmp2 + 1 end

  return tmp2
end

local gameOfLife = function( board, width, height, liveColor, drawIndex )
  if not board then  return  end

  if not width then width = 64 end
  if not height then height = 64 end
  if not liveColor then liveColor = WHITE_COLOR end

  changesQueue:clear()

  for x = 1, height do
    for y = 1, width do
      tmp = aliveNeighbours( board, x, y, liveColor )

      if checkAlive(board, x, y, liveColor) then
        if tmp < 2 or tmp > 3 then
          changesQueue:toggle( x, y, 0, 0, 0, drawIndex )
        end
      else
        if tmp == 3 then
          changesQueue:toggle( x, y, liveColor.r, liveColor.g, liveColor.b, drawIndex )
        end
      end

    end
  end

  tmp = changesQueue[0]

  for i = 1, changesQueue[0] do
    if not board[changesQueue[i].x] then
      board[changesQueue[i].x] = {}
    end
    if not board[changesQueue[i].x][changesQueue[i].y] then
      board[changesQueue[i].x][changesQueue[i].y] = {}
    end

    board[changesQueue[i].x][changesQueue[i].y].r = changesQueue[i].r
    board[changesQueue[i].x][changesQueue[i].y].g = changesQueue[i].g
    board[changesQueue[i].x][changesQueue[i].y].b = changesQueue[i].b
    board[changesQueue[i].x][changesQueue[i].y].u = changesQueue[i].u
  end
  changesQueue:clear()

  return tmp
end

return gameOfLife
