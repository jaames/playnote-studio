import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'
import 'CoreLibs/timer'

import './ScreenBase'

import '../components/Button.lua'
import '../components/Clock.lua'

import '../services/screens.lua'
import '../services/dialog.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local gfx <const> = playdate.graphics

local logoGfx <const> = gfx.image.new('./img/logo')
local viewButtonGfx <const> = gfx.image.new('./img/view')
local settingsButtonGfx <const> = gfx.image.new('./img/settings')

HomeScreen = {}
class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)

  self.viewButton = Button(PLAYDATE_W / 2 - 98, PLAYDATE_H - 52, 196, 34)
  self.viewButton:setText('View Flipnotes')
  self.viewButton:setIcon(viewButtonGfx)
  self.viewButton.isSelected = true

  self.settingsButton = Button(PLAYDATE_W - 120, 8, 112, 24)
  self.settingsButton:setText('Settings')
  self.settingsButton:setIcon(settingsButtonGfx)

  self.clock = Clock(8, 8, 160, 24)

  self.inputHandlers = {
    upButtonDown = function ()
      if self.viewButton.isSelected then
        self.viewButton.isSelected = false
        self.settingsButton.isSelected = true
      end
    end,
    downButtonDown = function ()
      if self.settingsButton.isSelected then
        self.settingsButton.isSelected = false
        self.viewButton.isSelected = true
      end
    end,
    AButtonDown = function()
      if self.viewButton.isSelected then
        screenManager:setScreen('notelist')
      elseif self.settingsButton.isSelected then
        screenManager:setScreen('settings')
      end
    end
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

function HomeScreen:update()
  gfx.setDrawOffset(0, 0)
  -- draw background
  gfxUtils:drawBgGrid()
  -- main logo
  logoGfx:draw(52, 52)
  -- clock
  self.clock:draw()
  -- buttons
  self.settingsButton:draw()
  self.viewButton:draw()
end