HomeScreen = {}
class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)
  self.focus = FocusController(self)
end

function HomeScreen:setupSprites()
  local viewButton = Button(PLAYDATE_W / 2, PLAYDATE_H - 52, 196, 40, locales:getText('HOME_VIEW'))
  viewButton.autoWidth = true
  viewButton:setIcon('./gfx/icon_view')
  viewButton:setAnchor('center', 'top')
  viewButton:onClick(function ()
    screens:push('notelist', screens.kTransitionFade)
  end)
  self.viewButton = viewButton

  local settingsButton = Button(PLAYDATE_W - 8, 4, 128, 32, locales:getText('HOME_SETTINGS'))
  settingsButton.autoWidth = true
  settingsButton:setIcon('./gfx/icon_settings')
  settingsButton:setAnchor('right', 'top')
  settingsButton:onClick(function ()
    screens:push('settings', screens.kTransitionFade)
  end)
  self.settingsButton = settingsButton

  local clock = Clock(8, 8, 152, 24)

  local homeLogo = HomeLogo(52, 54)

  self.focus:setFocus(viewButton)
  
  return {viewButton, settingsButton, clock, homeLogo}
end

function HomeScreen:drawBg(x, y, w, h)
  grid:draw(x, y, w, h)
end