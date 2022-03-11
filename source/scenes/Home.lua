HomeScreen = {}
class('HomeScreen').extends(ScreenBase)

function HomeScreen:init()
  HomeScreen.super.init(self)
  self.focus = FocusController(self)
end

function HomeScreen:setupSprites()
  local viewButton = Button(PLAYDATE_W / 2, PLAYDATE_H - 60, 196, 44, '%HOME_VIEW%')
  viewButton.autoWidth = true
  viewButton:setIcon('./gfx/icon_view')
  viewButton:setAnchor('center', 'top')
  viewButton:onClick(function ()
    sceneManager:push('notelist', sceneManager.kTransitionFade)
  end)
  self.viewButton = viewButton

  local settingsButton = Button(PLAYDATE_W - 8, 4, 128, 36, '%HOME_SETTINGS%')
  settingsButton.autoWidth = true
  settingsButton:setIcon('./gfx/icon_settings')
  settingsButton:setAnchor('right', 'top')
  settingsButton:onClick(function ()
    sceneManager:push('settings', sceneManager.kTransitionFade)
  end)
  self.settingsButton = settingsButton

  local clock = Clock(8, 10, 152, 28)

  local homeLogo = HomeLogo(52, 54)

  self.focus:setFocus(viewButton)

  return {viewButton, settingsButton, clock, homeLogo}
end

function HomeScreen:afterEnter()
  -- check if the C extention has been loaded
  -- imo it's fine for this message to not be localised, you should only come across it in the simulator
  if PpmParser == nil then
    local errMsg = [[
 Native extension error

Playnote Studio probably hasn't been compiled for this platform, sorry!

If you want to try compiling it yourself, the source code can be found at
github.com/jaames/playnote-studio]]
    dialog:error(errMsg, 100)
  end
end

function HomeScreen:drawBg(x, y, w, h)
  grid:draw(x, y, w, h)
end

return HomeScreen