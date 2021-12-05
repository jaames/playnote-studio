import 'CoreLibs/math'
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/nineslice'
import 'CoreLibs/ui'
import 'CoreLibs/crank'
import 'CoreLibs/timer'
import 'CoreLibs/frameTimer'
import 'CoreLibs/animation'

import './services/config'
import './services/locales'
import './services/noteFs'
import './services/transitions'
import './services/screens'
import './services/dialog'
import './utils/utils'
import './utils/stringUtils'
import './utils/gfxUtils'
import './utils/fsUtils'

import './components/Button'
import './components/Select'
import './components/FolderSelect'
import './components/Clock'
import './components/Timeline'

import './screens/Screenbase'
import './screens/Home'
import './screens/NoteList'
import './screens/Player'
import './screens/Settings'
import './screens/Credits'

playdate.display.setRefreshRate(30)

config:init()
locales:init()
noteFs:init()

screenManager:register('home',     HomeScreen())
screenManager:register('notelist', NoteListScreen())
screenManager:register('player',   PlayerScreen())
screenManager:register('settings', SettingsScreen())
screenManager:register('credits',  CreditsScreen())

screenManager:setScreen('home', screenManager.BOOTUP)

function playdate.update()
  screenManager:update()
  dialogManager:update()
  utils:doDeferredDraws()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
end