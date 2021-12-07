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
  gfxUtils:drawBgGridWithOffset(yOffset)
  -- reset scroll position
  gfx.setDrawOffset(xOffset, yOffset)
end

-- draw a full-screen grid background, with a given offset
function gfxUtils:drawBgGridWithOffset(offset)
  gfx.setPattern(GRID_PATTERNS[math.floor(offset) % 8])
  gfx.fillRect(0, 0, PLAYDATE_W, PLAYDATE_H)
  -- white outline around the screen
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(0, 0, PLAYDATE_W, PLAYDATE_H)
end

function gfxUtils:drawWhiteFade(white)
  -- draw offset is used to scroll the page, so we wanna ignore this
  local xOffset, yOffset = gfx.getDrawOffset()
  gfx.setColor(gfx.kColorWhite)
  gfx.setDitherPattern(white, gfx.image.kDitherTypeBayer8x8)
  gfx.fillRect(-xOffset, -yOffset, PLAYDATE_W, PLAYDATE_H)
end

function gfxUtils:drawBlackFade(black)
  -- draw offset is used to scroll the page, so we wanna ignore this
  local xOffset, yOffset = gfx.getDrawOffset()
  gfx.setColor(gfx.kColorBlack)
  gfx.setDitherPattern(black, gfx.image.kDitherTypeBayer8x8)
  gfx.fillRect(-xOffset, -yOffset, PLAYDATE_W, PLAYDATE_H)
end