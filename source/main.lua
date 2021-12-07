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
import './services/screens'
import './services/transitions'
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

screens:register('home',     HomeScreen())
screens:register('notelist', NoteListScreen())
screens:register('player',   PlayerScreen())
screens:register('settings', SettingsScreen())
screens:register('credits',  CreditsScreen())

screens:setScreen('home', transitions.BOOTUP)

function playdate.update()
  screens:update()
  dialog:update()
  utils:doDeferredDraws()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
end