local gfx <const> = playdate.graphics
local tinyFont <const> = gfx.getSystemFont(gfx.font.kVariantNormal)
local normalFont <const> = gfx.font.new('./fonts/WhalesharkSans')
local boldFont <const> = gfx.font.new('./fonts/Asheville-Rounded-24-px')

local SCROLL_START <const> = 200
local SCROLL_AUTO_STEP <const> = -1

CreditsScreen = {}
class('CreditsScreen').extends(ScreenBase)

function CreditsScreen:init()
  CreditsScreen.super.init(self)
  -- don't scroll to begin with
  self.autoScroll = false
  self.scrollY = 0
  self.creditsTexture = nil
  self.inputHandlers = {
    BButtonDown = function()
      screenManager:setScreen('settings', screenManager.CROSSFADE)
    end,
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
    for _, link in ipairs(artist.links) do
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
    [gfx.font.kVariantNormal] = normalFont,
    [gfx.font.kVariantBold] = boldFont,
    [gfx.font.kVariantItalic] = tinyFont
  })
  local text = self:getCreditsText()
  local _, height = gfx.getTextSize(text)
  local cache = gfx.image.new(400, height, gfx.kColorBlack)
  local rect = playdate.geometry.rect.new(10, 0, 400 - 20, height)
  gfx.pushContext(cache)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(text, rect, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
  gfx.popContext()
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
  -- draw background
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()
  self.creditsTexture:draw(0, 0)
  -- auto scroll
  if self.autoScroll then
    self.scrollY = utils:clampScroll(self.scrollY + SCROLL_AUTO_STEP, SCROLL_START, self.creditsHeight)
  end
end