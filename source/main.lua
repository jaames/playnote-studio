-- import 'CoreLibs/sprites'
-- import 'CoreLibs/graphics'
import 'CoreLibs/frameTimer'

local gfx <const> = playdate.graphics

gfx.setBackgroundColor(gfx.kColorWhite)
gfx.clear()

local str = playdate.testFunction("world")

print(str)

playdate.stop()

function playdate.update()

  -- if i <= ppm.frameCount then
  --   ppm:drawFrame(i, 32, 24)
  --   i = i + 1
  -- else
  --   i = 1
  -- end

  -- if playdate.buttonIsPressed(playdate.kButtonA) then i = 1 end
end