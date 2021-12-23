local gfx <const> = playdate.graphics
local SCROLL_START <const> = 200
local SCROLL_AUTO_STEP <const> = -1

local logoGfx <const> = gfx.image.new('./gfx/gfx_logo_credits')

CreditsScreen = {}
class('CreditsScreen').extends(ScreenBase)

function CreditsScreen:init()
  CreditsScreen.super.init(self)
  -- don't scroll to begin with
  self.autoScroll = false
  self.scrollY = 0
  self.creditsTexture = nil
  self.inputHandlers = {
    cranked = function(change, acceleratedChange)
      self.autoScroll = false
      self.scrollY = utils:clampScroll(self.scrollY + change, SCROLL_START, self.creditsHeight)
    end,
  }
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
    VERSION = playdate.metadata.version,
    ARTIST_CREDITS = artistCredits
  })
  return text
end

function CreditsScreen:beforeEnter()
  CreditsScreen.super.beforeEnter(self)
  self.scrollY = SCROLL_START
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = MAIN_FONT,
    [gfx.font.kVariantBold] = gfx.font.new('./fonts/Asheville-Rounded-24-px'),
    [gfx.font.kVariantItalic] = gfx.getSystemFont(gfx.font.kVariantNormal)
  })
  local text = self:getCreditsText()
  local _, height = gfx.getTextSize(text)
  local cache = gfx.image.new(400, height, gfx.kColorClear)
  local rect = playdate.geometry.rect.new(10, 0, 400 - 20, height)
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
  self.creditsHeight = height
  self.creditsTexture = cache
end

function CreditsScreen:afterEnter()
  CreditsScreen.super.afterEnter(self)
  -- begin scrolling after enter transition
  self.autoScroll = true
end

function CreditsScreen:afterLeave()
  CreditsScreen.super.afterLeave(self)
  self.creditsTexture = nil
end

function CreditsScreen:update()
  gfx.setDrawOffset(0, self.scrollY)
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()
  logoGfx:drawCentered(200, -30)
  self.creditsTexture:draw(0, 0)
  -- auto scroll
  if self.autoScroll then
    self.scrollY = utils:clampScroll(self.scrollY + SCROLL_AUTO_STEP, SCROLL_START, self.creditsHeight)
  end
end