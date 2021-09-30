import 'CoreLibs/timer'

import './screenManager'
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
  playdate.timer:updateTimers()
end