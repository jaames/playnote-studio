-- import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/frameTimer'

local gfx <const> = playdate.graphics

local ppm = PpmParser.new("./ppm/fdd.ppm")

local numFrames = ppm:getNumFrames()

print(ppm, numFrames)

local layer = gfx.image.new(256, 192)

gfx.setBackgroundColor(gfx.kColorWhite)
gfx.clear()

-- ppm:decodeFrameToBitmap(1, layer)

-- layer:draw(10, 10)

-- playdate.stop()

local i = 1;

function playdate.update()

  if i <= numFrames then
    ppm:decodeFrameToBitmap(i, layer)
    gfx.clear()
    layer:draw(72, 24)
    i = i + 1
  else
    i = 1
  end

  -- if playdate.buttonIsPressed(playdate.kButtonA) then i = 1 end
end