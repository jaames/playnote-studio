local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local gfx <const> = playdate.graphics

local logo <const> = gfx.animation.loop.new(1000 / 4, gfx.imagetable.new('./img/logo_anim'))

local viewButtonGfx <const> = gfx.image.new('./img/view')
local settingsButtonGfx <const> = gfx.image.new('./img/settings')

HomeScreen = {}
class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)

  self.viewButton = Button(PLAYDATE_W / 2 - 98, PLAYDATE_H - 52, 196, 34)
  self.viewButton:setIcon(viewButtonGfx)
  self.viewButton.isSelected = true

  self.settingsButton = Button(PLAYDATE_W - 140, 8, 132, 24)
  self.settingsButton:setIcon(settingsButtonGfx)

  self.clock = Clock(8, 8, 152, 24)

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
        screens:push('notelist', transitions.CROSSFADE)
      elseif self.settingsButton.isSelected then
        screens:push('settings', transitions.CROSSFADE)
      end
    end,
  }
end

function HomeScreen:beforeEnter()
  HomeScreen.super.beforeEnter(self)
  self.viewButton:setText(locales:getText('HOME_VIEW'))
  self.settingsButton:setText(locales:getText('HOME_SETTINGS'))
end

function HomeScreen:update()
  -- draw background
  gfxUtils:drawBgGrid()
  -- main logo
  logo:draw(52, 52)
  -- clock
  self.clock:draw()
  -- buttons
  self.settingsButton:draw()
  self.viewButton:draw()
end