import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'

import './ScreenBase'
import '../screenManager.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local gfx <const> = playdate.graphics
local boldFont <const> = gfx.getSystemFont(gfx.font.kVariantBold)
local normalFont <const> = gfx.getSystemFont(gfx.font.kVariantNormal)

local SCROLL_START <const> = 200
local SCROLL_AUTO_STEP <const> = -2

class('CreditsScreen').extends(ScreenBase)

function CreditsScreen:init()
  CreditsScreen.super.init(self)
  -- don't scroll to begin with
  self.autoScroll = false
  self.inputHandlers = {
    BButtonDown = function()
      screenManager:setScreen('settings')
    end,
    cranked = function(change, acceleratedChange)
      self.autoScroll = false
      self.scrollY = utils:clampScroll(self.scrollY + change, SCROLL_START, self.creditsHeight)
    end,
  }
end

function CreditsScreen:beforeEnter()
  CreditsScreen.super.beforeEnter(self)
  gfx.setFont(boldFont, gfx.font.kVariantBold)
  gfx.setFont(boldFont, gfx.font.kVariantNormal)
  gfx.setFont(normalFont, gfx.font.kVariantItalic)
  self.scrollY = SCROLL_START
  self.creditsText = utils:readTextFile('./credits.txt')
  local _, creditsHeight = gfx.getTextSize(self.creditsText)
  self.creditsHeight = creditsHeight
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
  gfx.setFont(boldFont, gfx.font.kVariantBold)
  gfx.setFont(boldFont, gfx.font.kVariantNormal)
  gfx.setFont(normalFont, gfx.font.kVariantItalic)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  local rect = playdate.geometry.rect.new(10, 0, 400 - 20, self.creditsHeight)
  gfx.drawTextInRect(self.creditsText, rect, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
  -- auto scroll
  if self.autoScroll then
    self.scrollY = utils:clampScroll(self.scrollY + SCROLL_AUTO_STEP, SCROLL_START, self.creditsHeight)
  end
end