import 'CoreLibs/math'
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/nineslice'
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
import './components/DitherSwatch'
import './components/Scrollbar'

import './screens/Screenbase'
import './screens/Home'
import './screens/NoteList'
import './screens/Player'
import './screens/Settings'
import './screens/Dithering'
import './screens/Credits'

debug = nil -- disallow debugging

MAIN_FONT = playdate.graphics.font.new('./fonts/WhalesharkSans')
playdate.graphics.setFont(MAIN_FONT)
playdate.display.setRefreshRate(30)

config:init()
locales:init()
noteFs:init()
dialog:init()

screens:register('home',      HomeScreen())
screens:register('notelist',  NoteListScreen())
screens:register('player',    PlayerScreen())
screens:register('settings',  SettingsScreen())
screens:register('dithering', DitheringScreen())
screens:register('credits',   CreditsScreen())

screens:push('home', transitions.BOOTUP, transitions.CROSSFADE)

function playdate.update()
  screens:update()
  dialog:update()
  utils:doDeferredDraws()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
end