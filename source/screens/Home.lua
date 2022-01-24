HomeScreen = {}
class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)

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
        screens:push('notelist', screens.kTransitionFade)
      elseif self.settingsButton.isSelected then
        self.settingsButton:click()
        screens:push('settings', screens.kTransitionFade)
      end
    end,
  }
end

function HomeScreen:setupComponents()
  local viewButton = Button(PLAYDATE_W / 2, PLAYDATE_H - 52, 196, 34, locales:getText('HOME_VIEW'))
  viewButton.autoWidth = true
  viewButton:setIcon('./gfx/icon_view')
  viewButton:setAnchor('center', 'top')
  viewButton:select()
  self.viewButton = viewButton

  local settingsButton = Button(PLAYDATE_W - 8, 6, 128, 26, locales:getText('HOME_SETTINGS'))
  settingsButton.autoWidth = true
  settingsButton:setIcon('./gfx/icon_settings')
  settingsButton:setAnchor('right', 'top')
  self.settingsButton = settingsButton

  local clock = Clock(8, 8, 152, 24)

  local homeLogo = HomeLogo(52, 54)
  
  return {viewButton, settingsButton, clock, homeLogo}
end

function HomeScreen:drawBg(x, y, w, h)
  grid:draw(x, y, w, h)
end