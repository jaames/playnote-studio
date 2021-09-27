import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/object'

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

local ppm = PpmParser.new("./ppm/samplememo_04.ppm")

local magic = ppm:getMagic()

print('ppm magic passed to lua:', magic)

local layer = gfx.image.new(256, 192)

local i = 1

playdate.display.setRefreshRate(50)

function playdate.update()
  -- draw grid background
  gfx.setPattern({ 0xFF, 0xEF, 0xFF, 0xAA, 0xFF, 0xEF, 0xFF, 0xEF })
  gfx.fillRect(0, 0, PLAYDATE_W, PLAYDATE_H)
  gfx.setColor(0)
  -- draw counter
  -- local counterText = string.format("%03d/%03d", math.floor(i), 75);
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(PLAYDATE_W - 84, PLAYDATE_H - 26, 80, 22, 4)
  -- draw border
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(72 - 1, 16 - 1, 256 + 2, 192 + 2)
  ppm:decodeFrameToBitmap(i, layer)
  layer:draw(72, 16)
  playdate.drawFPS(0, 0)
  i = i + 1
  if i == 70 then
    i = 1
  end
end