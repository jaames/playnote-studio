import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/nineslice'

gfxUtils = {}

local gfx <const> = playdate.graphics

-- local buttonImg_default <const> = gfx.nineSlice.new('./img/button_default', 6, 6, 4, 4)
-- local buttonImg_heavy <const> = gfx.nineSlice.new('./img/button_heavy', 6, 6, 4, 4)
local buttonFont <const> = gfx.getSystemFont(gfx.font.kVariantBold)

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
  -- draw offset is used to scroll the page, so we wanna ignore this
  local xOffset, yOffset = gfx.getDrawOffset()
  gfx.setColor(gfx.kColorWhite)
  gfx.setDitherPattern(white, gfx.image.kDitherTypeBayer8x8)
  gfx.fillRect(-xOffset, -yOffset, PLAYDATE_W, PLAYDATE_H)
end

function gfxUtils:drawButton(x, y, w, h, isSelected)
  gfx.setColor(gfx.kColorBlack)
  if isSelected then
    gfx.fillRoundRect(x - 3, y - 3, w + 6, h + 6, 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRoundRect(x - 1, y - 1, w + 2, h + 2, 3)
  else
    gfx.fillRoundRect(x, y, w, h, 3)
  end
end

function gfxUtils:drawButtonWithText(text, x, y, w, h, isSelected)
  gfx.setFont(buttonFont)
  gfx.setFontTracking(2)
  local _, textH = gfx.getTextSize(text)
  local textY = y + (h / 2) - (textH / 2)
  gfxUtils:drawButton(x, y, w, h, isSelected)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(text, x, textY + 1, w, h, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
end

function gfxUtils:drawButtonWithTextAndIcon(text, icon, x, y, w, h, isSelected)
  gfx.setFont(buttonFont)
  gfx.setFontTracking(2)
  local textW, textH = gfx.getTextSize(text)
  local iconW, _ = icon:getSize()
  local totalW = iconW + 8 + textW -- 8 px gap between icon and text
  local iconX = x + (w / 2) - (totalW / 2)
  local textY = y + (h / 2) - (textH / 2)
  local textX = iconX + iconW + 8
  gfxUtils:drawButton(x, y, w, h, isSelected)
  icon:drawAnchored(iconX, y + (h / 2), 0, 0.5)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(text, textX, textY + 1, w, h, nil, nil, kTextAlignment.left)
  gfx.setImageDrawMode(0)
end