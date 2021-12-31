local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local gfx <const> = playdate.graphics

local logo <const> = gfx.animation.loop.new(1000 / 4, gfx.imagetable.new('./gfx/gfx_logo_anim'))

local viewButtonGfx <const> = gfx.image.new('./gfx/icon_view')
local settingsButtonGfx <const> = gfx.image.new('./gfx/icon_settings')

HomeScreen = {}
class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)

  self.viewButton = Button(PLAYDATE_W / 2 - 98, PLAYDATE_H - 52, 196, 34)
  self.viewButton:setIcon(viewButtonGfx)
  self.viewButton:select()

  self.settingsButton = Button(PLAYDATE_W - 136, 6, 128, 26)
  self.settingsButton:setIcon(settingsButtonGfx)

  self.clock = Clock(8, 8, 152, 24)

  self.inputHandlers = {
    upButtonDown = function ()
      if self.viewButton.isSelected then
        self.viewButton:deselect()
        self.settingsButton:select()
      end
    end,
    downButtonDown = function ()
      if self.settingsButton.isSelected then
        self.settingsButton:deselect()
        self.viewButton:select()
      end
    end,
    AButtonDown = function()
      if self.viewButton.isSelected then
        self.viewButton:click()
        screens:push('notelist', transitions.kTransitionStartup)
      elseif self.settingsButton.isSelected then
        self.settingsButton:click()
        screens:push('settings', transitions.kTransitionStartup)
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