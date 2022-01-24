local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local logoGfx <const> = gfx.image.new('./gfx/gfx_logo_credits')

CreditsScreen = {}
class('CreditsScreen').extends(ScreenBase)

function CreditsScreen:init()
  CreditsScreen.super.init(self)
  self.creditsTexture = nil

  self.scroll = ScrollController(self)
  self.scroll:setStart(200)
end

function CreditsScreen:getArtistCredits()
  local text = ''
  local credits = noteFs:getArtistCredits()
  for _, artist in pairs(credits) do
    text = text .. stringUtils:escape(artist.name) .. '\n'
    for _, link in pairs(artist.links) do
      text = text .. '_' .. stringUtils:escape(link) .. '_\n'
    end
    text = text .. '\n'
  end
  return text
end

function CreditsScreen:getCreditsText()
  local text = fsUtils:readText('./data/credits.txt')
  local artistCredits = self:getArtistCredits()
  -- replace placeholders in credits text
  text = locales:replaceKeysInText(text)
  text = stringUtils:replaceVars(text, {
    version = playdate.metadata.version,
    artistCredits = artistCredits
  })
  return text
end

function CreditsScreen:beforeEnter()
  CreditsScreen.super.beforeEnter(self)
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = MAIN_FONT,
    [gfx.font.kVariantBold] = gfx.font.new('./fonts/Asheville-Rounded-24-px'),
    [gfx.font.kVariantItalic] = gfx.getSystemFont(gfx.font.kVariantNormal)
  })
  local text = self:getCreditsText()
  local _, height = gfx.getTextSize(text)
  local cache = gfx.image.new(PLAYDATE_W, height, gfx.kColorClear)
  local rect = playdate.geometry.rect.new(10, 0, PLAYDATE_W - 20, height)
  gfx.pushContext(cache)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(text, rect, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
  gfx.popContext()
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = MAIN_FONT,
    [gfx.font.kVariantBold] = MAIN_FONT,
    [gfx.font.kVariantItalic] = MAIN_FONT
  })
  text = nil
  self.scroll.autoScroll = false
  self.scroll:resetOffset()
  self.scroll:setHeight(height)
  self.creditsTexture = cache
end

function CreditsScreen:afterEnter()
  CreditsScreen.super.afterEnter(self)
  -- begin scrolling after enter transition
  self.scroll.autoScroll = true
end

function CreditsScreen:afterLeave()
  CreditsScreen.super.afterLeave(self)
  self.creditsTexture = nil
end

-- function CreditsScreen:update()
--   gfx.setDrawOffset(0, self.scroll.offset)
--   gfx.setBackgroundColor(gfx.kColorBlack)
--   gfx.clear()
--   logoGfx:drawCentered(200, -30)
--   self.creditsTexture:draw(0, 0)
--   -- auto scroll
--   self.scroll:update()
-- end