FocusTest = {}
class('FocusTest').extends(ScreenBase)

function FocusTest:init()
  FocusTest.super.init(self)

  self.inputHandlers = {}
  self.focus = FocusController(self)
  self.scroll = ScrollController(self)
  self.scroll:setHeight(600)
  -- self.focus:debugModeEnabled(true)
end

function FocusTest:setupSprites()
  local button1 = Button(PLAYDATE_W / 2, PLAYDATE_H - 70, 196, 34, locales:getText('HOME_VIEW'))
  button1:setAnchor('center', 'top')
  button1:onClick(function() print('view flipnotes') end)
  self.focus:setFocus(button1)
  return {
    button1,
    Button(8, 6, 128, 26, locales:getText('HOME_SETTINGS')),
    Button(PLAYDATE_W - 200, 100, 128, 26, locales:getText('HOME_SETTINGS')),
    Button(PLAYDATE_W - 200, 100, 128, 26, locales:getText('HOME_SETTINGS')),
    Button(100, 220, 50, 50, 'low'),
  }
end

function FocusTest:drawBg(x, y, w, h)
  grid:draw(x, y, w, h)
end