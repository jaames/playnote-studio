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
local logo <const> = gfx.image.new('./img/logo')
local clock <const> = gfx.image.new('./img/clock')
local clockFont <const> = gfx.font.new('./fonts/ugomemo_numbers_8px')

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)
  local blink = gfx.animation.blinker.new()
  blink.loop = true
  blink.cycles = 6
  blink.onDuration = 1000
  blink.offDuration = 1000
  blink:start()
  
  self.scrollY = 0
  self.clockBlink = blink
  self.inputHandlers = {
    BButtonUp = function()
      if dialogManager.isVisible then
        dialogManager:hide()
      else
        dialogManager:show('*Generic Error*\n\nAh geeze something went really wrong here honestly')
      end
      
    end,
    AButtonUp = function()
      screenManager:setScreen('notelist')
    end,
    cranked = function(change, acceleratedChange)
      self.scrollY = utils:clampScroll(self.scrollY + change, 0, 240)
    end,
  }
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

function HomeScreen:transitionLeave(t)
  if t < 0.5 then
    self:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
end

function HomeScreen:beforeEnter()
  HomeScreen.super.beforeEnter(self)
  self.scrollY = 0
end

function HomeScreen:update()

  gfx.setDrawOffset(0, self.scrollY)
  -- draw background
  gfxUtils:drawBgGrid()
  -- draw main logo
  logo:draw(52, 52)
  -- clock
  self.clockBlink:update()
  local sep = self.clockBlink.on and ":" or " "
  local time = playdate.getTime()
  local dateString = string.format("%02d/%02d/%04d", time.day, time.month, time.year)
  local timeString = string.format("%02d%s%02d", time.hour, sep, time.minute)
  gfx.setFont(clockFont)
  gfx.setFontTracking(2)
  gfx.fillRect(8, 8, 160, 24)
  gfx.drawText(dateString, 16, 15)
  clock:draw(104, 13)
  gfx.drawText(timeString, 120, 15)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  gfx.drawRect(8 - 1, 8 - 1, 160, 24)
  -- button

  -- gfx.drawTextAligned('Press (A) to view Flipnotes', PLAYDATE_W / 2, PLAYDATE_H - 40, kTextAlignment.center)
end