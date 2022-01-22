gfxUtils = {}

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

-- scrolling grid pattern at different offsets
local GRID_PATTERNS <const> = {
  { 0x55, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF },
  { 0xFF, 0x55, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F },
  { 0x7F, 0xFF, 0x55, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF },
  { 0xFF, 0x7F, 0xFF, 0x55, 0xFF, 0x7F, 0xFF, 0x7F },
  { 0x7F, 0xFF, 0x7F, 0xFF, 0x55, 0xFF, 0x7F, 0xFF },
  { 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x55, 0xFF, 0x7F },
  { 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x55, 0xFF },
  { 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x55 },
}

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
  -- clamp because this can apparently end up as 9 in certain cases? how the fuck does that happen?
  local pattern = utils:clamp((math.floor(offset % 8) + 1), 1, 8)
  gfx.setPattern(GRID_PATTERNS[pattern])
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