import 'CoreLibs/timer'

import './screenManager'
import './dialogManager'
import './noteManager'
import './gfxUtils'

import './screens/Home'
import './screens/Credits'
import './screens/Player'
import './screens/NoteList'

playdate.display.setRefreshRate(30)

screenManager:registerScreen('home', HomeScreen())
screenManager:registerScreen('credits', CreditsScreen())
screenManager:registerScreen('player', PlayerScreen())
screenManager:registerScreen('notelist', NoteListScreen())

screenManager:setScreen('home')

function playdate.update()
  screenManager:update()
  dialogManager:update()
  playdate.timer:updateTimers()
end