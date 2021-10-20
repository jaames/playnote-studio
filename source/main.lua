import 'CoreLibs/timer'
-- import 'CoreLibs/frameTimer'

import './screenManager'
import './dialogManager'
import './noteManager'
import './gfxUtils'

import './screens/Home'
import './screens/Credits'
import './screens/Player'
import './screens/NoteList'

playdate.display.setRefreshRate(30)

screenManager:registerScreen('home',     HomeScreen())
screenManager:registerScreen('notelist', NoteListScreen())
screenManager:registerScreen('player',   PlayerScreen())
screenManager:registerScreen('credits',  CreditsScreen())

screenManager:setScreen('home')

function playdate.update()
  screenManager:update()
  dialogManager:update()
  playdate.timer:updateTimers()
  -- playdate.frameTimer.updateTimers()
end