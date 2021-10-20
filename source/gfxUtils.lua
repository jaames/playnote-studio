import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/nineslice'

gfxUtils = {}

local gfx <const> = playdate.graphics

local buttonImg_default <const> = gfx.nineSlice.new('./img/button_default', 6, 6, 4, 4)
local buttonImg_heavy <const> = gfx.nineSlice.new('./img/button_heavy', 6, 6, 4, 4)
local buttonFont <const> = gfx.font.new('./fonts/Asheville-Sans-14-Bold')

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

-- scrolling grid pattern at different offsets
local GRID_PATTERNS <const> = table.create(8, 0)
GRID_PATTERNS[0] = { 0x55, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF }
GRID_PATTERNS[1] = { 0xFF, 0x55, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F }
GRID_PATTERNS[2] = { 0x7F, 0xFF, 0x55, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF }
GRID_PATTERNS[3] = { 0xFF, 0x7F, 0xFF, 0x55, 0xFF, 0x7F, 0xFF, 0x7F }
GRID_PATTERNS[4] = { 0x7F, 0xFF, 0x7F, 0xFF, 0x55, 0xFF, 0x7F, 0xFF }
GRID_PATTERNS[5] = { 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x55, 0xFF, 0x7F }
GRID_PATTERNS[6] = { 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x55, 0xFF }
GRID_PATTERNS[7] = { 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x55 }

-- draw a full-screen grid background, taking page Y scroll into account
function gfxUtils:drawBgGrid()
  -- draw offset is used to scroll the page
  local xOffset, yOffset = gfx.getDrawOffset()
  -- full-screen grid
  gfx.setDrawOffset(0, 0)
  gfx.setPattern(GRID_PATTERNS[yOffset % 8])
  gfx.fillRect(0, 0, PLAYDATE_W, PLAYDATE_H)
  -- white outline around the screen
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(0, 0, PLAYDATE_W, PLAYDATE_H)
  -- reset scroll position
  gfx.setDrawOffset(xOffset, yOffset)
end

function gfxUtils:drawWhiteFade(white)
  -- draw offset is used to scroll the page
  local xOffset, yOffset = gfx.getDrawOffset()
  gfx.setColor(gfx.kColorWhite)
  gfx.setDitherPattern(white, gfx.image.kDitherTypeBayer8x8)
  gfx.fillRect(-xOffset, -yOffset, PLAYDATE_W, PLAYDATE_H)
end

function gfxUtils:drawButton(x, y, w, h, isHeavy)
  isHeavy = isHeavy or false
  if isHeavy then
    buttonImg_heavy:drawInRect(x, y, w, h)
  else
    buttonImg_default:drawInRect(x, y, w, h)
  end
end

function gfxUtils:drawButtonWithText(text, x, y, w, h, isHeavy)
  local _, textH = gfx.getTextSize(text)
  local textY = y + (h / 2 - textH)
  gfxUtils:drawButton(x, y, w, h, isHeavy)
  gfx.setFontTracking(2)
  -- gfx.drawTextInRect(text, x + 1, textY + 2, w, h, nil, nil, kTextAlignment.center, buttonFont)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(text, x, textY, w, h, nil, nil, kTextAlignment.center, buttonFont)
  gfx.setImageDrawMode(0)
end