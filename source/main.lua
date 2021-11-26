import 'CoreLibs/timer'
-- import 'CoreLibs/frameTimer'

import './services/screens'
import './services/dialog'
import './services/noteFs'
import './gfxUtils'

import './screens/Home'
import './screens/NoteList'
import './screens/Player'
import './screens/Settings'
import './screens/Credits'

playdate.display.setRefreshRate(30)

screenManager:registerScreen('home',     HomeScreen())
screenManager:registerScreen('notelist', NoteListScreen())
screenManager:registerScreen('player',   PlayerScreen())
screenManager:registerScreen('settings', SettingsScreen())
screenManager:registerScreen('credits',  CreditsScreen())

screenManager:setScreen('home', screenManager.BOOTUP)

function playdate.update()
  screenManager:update()
  dialogManager:update()
  utils:doDeferredDraws()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
end