import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'

import './ScreenBase'
import '../services/screens.lua'
import '../services/noteFs.lua'
import '../gfxUtils.lua'
import '../utils.lua'

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
  self.inputHandlers = {
    BButtonDown = function()
      screenManager:setScreen('settings', screenManager.CROSSFADE)
    end,
    cranked = function(change, acceleratedChange)
      self.autoScroll = false
      self.scrollY = utils:clampScroll(self.scrollY + change, SCROLL_START, self.creditsRect.h)
    end,
  }
end

function CreditsScreen:getArtistCredits()
  local text = ''
  local credits = noteFs:getArtistCredits()
  for _, artist in pairs(credits) do
    text = text .. utils:escapeText(artist.name) .. '\n'
    for _, link in ipairs(artist.links) do
      text = text .. '_' .. utils:escapeText(link) .. '_\n'
    end
    text = text .. '\n'
  end
  return text
end

function CreditsScreen:getCreditsText()
  local text = utils:readTextFile('./data/credits.txt')
  local artistCredits = self:getArtistCredits()
  text = string.gsub(text, '$ARTIST_CREDITS', artistCredits)
  text = string.gsub(text, '$VERSION', playdate.metadata.version)
  return text
end

function CreditsScreen:beforeEnter()
  CreditsScreen.super.beforeEnter(self)
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = normalFont,
    [gfx.font.kVariantBold] = boldFont,
    [gfx.font.kVariantItalic] = tinyFont
  })
  self.creditsText = self:getCreditsText()
  self.scrollY = SCROLL_START
  local _, creditsHeight = gfx.getTextSize(self.creditsText)
  self.creditsRect = playdate.geometry.rect.new(10, 0, 400 - 20, creditsHeight)
end

function CreditsScreen:afterEnter()
  CreditsScreen.super.afterEnter(self)
  -- begin scrolling
  self.autoScroll = true
end

function CreditsScreen:afterLeave()
  CreditsScreen.super.afterLeave(self)
  self.creditsText = nil
end

function CreditsScreen:update()
  gfx.setDrawOffset(0, self.scrollY)
  -- draw background
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()
  -- draw text
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = normalFont,
    [gfx.font.kVariantBold] = boldFont,
    [gfx.font.kVariantItalic] = tinyFont
  })
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(self.creditsText, self.creditsRect, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
  -- auto scroll
  if self.autoScroll then
    self.scrollY = utils:clampScroll(self.scrollY + SCROLL_AUTO_STEP, SCROLL_START, self.creditsRect.h)
  end
end