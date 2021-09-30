import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'

import './ScreenBase'
import '../screenManager.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local gfx <const> = playdate.graphics

local creditsFont <const> =gfx.font.newFamily({
  [gfx.font.kVariantBold]   = './fonts/Asheville-Sans-14-Bold',
  [gfx.font.kVariantNormal] = './fonts/Asheville-Sans-14-Bold',
  [gfx.font.kVariantItalic] = './fonts/Asheville-Sans-14-Light'
})
local creditsText <const> = utils:readTextFile('./credits.txt')
local _, creditsHeight = gfx.getTextSize(creditsText, creditsFont)

local SCROLL_START <const> = 200
local SCROLL_HEIGHT <const> = creditsHeight
local SCROLL_AUTO_STEP <const> = -1

class('CreditsScreen').extends(ScreenBase)

function CreditsScreen:init()
  CreditsScreen.super.init(self)
  -- don't scroll to begin with
  self.autoScroll = false
  self.scrollY = SCROLL_START

  self.inputHandlers = {
    BButtonUp = function()
      screenManager:setScreen('home')
    end,
    cranked = function(change, acceleratedChange)
      self.autoScroll = false
      self.scrollY = utils:clampScroll(self.scrollY + change, SCROLL_START, SCROLL_HEIGHT)
    end,
  }
end

function CreditsScreen:afterEnter()
  CreditsScreen.super.afterEnter(self)
  -- begin scrolling
  self.autoScroll = true
end

function CreditsScreen:transitionEnter(t)
  if t >= 0.5 then
    self:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end

function CreditsScreen:transitionLeave(t)
  if (t < 0.5) then
    self:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
end

function CreditsScreen:update()
  gfx.setDrawOffset(0, self.scrollY)
  -- draw background
  -- gfxUtils:drawBgGrid()
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()
  -- draw text
  gfx.setFont(creditsFont)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  local rect = playdate.geometry.rect.new(10, 0, 400 - 20, creditsHeight)
  gfx.drawTextInRect(creditsText, rect, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
  -- auto scroll
  if self.autoScroll then
    self.scrollY = utils:clampScroll(self.scrollY + SCROLL_AUTO_STEP, SCROLL_START, SCROLL_HEIGHT)
  end
end