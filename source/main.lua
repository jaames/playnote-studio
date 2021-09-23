-- import 'CoreLibs/sprites'
-- import 'CoreLibs/graphics'
import 'CoreLibs/frameTimer'

import './PpmParser'

local gfx <const> = playdate.graphics

gfx.setBackgroundColor(gfx.kColorWhite)
gfx.clear()

local ppm = PpmParser("ppm/samplememo_04.ppm")

local i = 1

function playdate.update()

  if i <= ppm.frame_count then
    ppm:drawFrame(i, 10, 10)
    i = i + 1
  end

  if playdate.buttonIsPressed(playdate.kButtonA) then i = 1 end
end