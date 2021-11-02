import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'
import 'CoreLibs/timer'
-- import 'CoreLibs/frameTimer'

import './ScreenBase'
import '../screenManager.lua'
import '../dialogManager.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)
  self.selectedButton = 'view'
  self.inputHandlers = {
    upButtonDown = function ()
      if self.selectedButton == 'view' then
        self.selectedButton = 'settings'
      end
    end,
    downButtonDown = function ()
      if self.selectedButton == 'settings' then
        self.selectedButton = 'view'
      end
    end,
    AButtonDown = function()
      if self.selectedButton == 'view' then
        screenManager:setScreen('notelist')
      elseif self.selectedButton == 'settings' then
        screenManager:setScreen('settings')
      end
    end
  }
end

function HomeScreen:beforeEnter()
  HomeScreen.super.beforeEnter(self)
  -- load graphics
  self.clockFont = gfx.font.new('./fonts/ugomemo_numbers_8px')
  self.logoGfx = gfx.image.new('./img/logo')
  self.clockGfx = gfx.image.new('./img/clock')
  self.settingsButtonGfx = gfx.image.new('./img/settings')
  self.viewButttonGfx = gfx.image.new('./img/view')
  -- blink timer
  local blink = gfx.animation.blinker.new()
  blink.loop = true
  blink.cycles = 6
  blink.onDuration = 1000
  blink.offDuration = 1000
  blink:start()
  self.clockBlinkTimer = blink
end

function HomeScreen:afterLeave()
  HomeScreen.super.afterLeave(self)
  self.clockFont = nil
  self.logoGfx = nil
  self.clockGfx = nil
  self.settingsButtonGfx = nil
  self.viewButttonGfx = nil
  if self.clockBlinkTimer then
    self.clockBlinkTimer:remove()
    self.clockBlinkTimer = nil
  end
end

function HomeScreen:transitionEnter(t, id)
  -- initial entrance
  if id == nil then
    self:update()
    gfxUtils:drawWhiteFade(t)
  -- inter-page transition
  elseif t >= 0.5 then
    self:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end

function HomeScreen:update()
  gfx.setDrawOffset(0, 0)
  -- draw background
  gfxUtils:drawBgGrid()
  -- draw main logo
  self.logoGfx:draw(52, 52)
  -- clock
  self.clockBlinkTimer:update()
  local sep = self.clockBlinkTimer.on and ":" or " "
  local time = playdate.getTime()
  local dateString = string.format("%02d/%02d/%04d", time.day, time.month, time.year)
  local timeString = string.format("%02d%s%02d", time.hour, sep, time.minute)
  gfx.setFont(self.clockFont)
  gfx.setFontTracking(2)
  gfx.fillRect(8, 8, 160, 24)
  gfx.drawText(dateString, 16, 15)
  self.clockGfx:draw(104, 13)
  gfx.drawText(timeString, 120, 15)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  gfx.drawRect(8 - 1, 8 - 1, 160, 24)
  -- settings icon/button
  self.settingsButtonGfx:draw(PLAYDATE_W - 112, 12)
  gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
  gfx.drawText('Settings', PLAYDATE_W - 88, 10)
  -- "View Flipnotes" button
  gfxUtils:drawButtonWithTextAndIcon(
    'View Flipnotes',
    self.viewButttonGfx,
    PLAYDATE_W / 2 - 98, PLAYDATE_H - 50,
    196, 30, 
    self.selectedButton == 'view'
  )
  -- self.view:draw(PLAYDATE_W / 2 - 100, PLAYDATE_H - 50)
end