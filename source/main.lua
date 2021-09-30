import 'CoreLibs/timer'

import './screenManager'
import './dialogManager'
import './gfxUtils'

import './screens/Home'
import './screens/Credits'
import './screens/Player'

screenManager:registerScreen('home', HomeScreen())
screenManager:registerScreen('credits', CreditsScreen())
screenManager:registerScreen('player', PlayerScreen())

screenManager:setScreen('home')

function playdate.update()
  screenManager:update()
  dialogManager:update()
  playdate.timer:updateTimers()
end