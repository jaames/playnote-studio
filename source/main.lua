import 'CoreLibs/math'
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/nineslice'
import 'CoreLibs/crank'
import 'CoreLibs/timer'
import 'CoreLibs/frameTimer'
import 'CoreLibs/animation'

import './globals'

import './services/config'
import './services/locales'
import './services/noteFs'
import './services/sounds'
import './services/screens'
import './services/dialog'

import './utils/utils'
import './utils/stringUtils'
import './utils/fsUtils'

import './ui/grid'
import './ui/overlayBg'

import './controllers/ScrollController'
import './controllers/FocusController'

import './components/AutoLayout'
import './components/Button'
import './components/Select'
import './components/FolderSelect'
import './components/Clock'
import './components/HomeLogo'
import './components/Timeline'
import './components/DitherSwatch'
import './components/ScrollBar'
import './components/KeyValList'

import './screens/Screenbase'
import './screens/Home'
import './screens/NoteList'
import './screens/Details'
import './screens/Player'
import './screens/Settings'
import './screens/Dithering'
import './screens/Credits'

debug = nil -- disallow debugging

MAIN_FONT = playdate.graphics.font.new('./fonts/WhalesharkSans')
playdate.graphics.setFont(MAIN_FONT)
playdate.display.setRefreshRate(30)

sounds:prepareSfxGroup('common', {
  'navigationForward',
  'navigationBackward',
  'navigationNotAllowed',
  'selectionChange',
  'selectionNotAllowed',
})

config:init()
locales:init()
noteFs:init()
dialog:init()

screens:register('home',      HomeScreen())
screens:register('notelist',  NoteListScreen())
screens:register('details',   DetailsScreen())
screens:register('player',    PlayerScreen())
screens:register('settings',  SettingsScreen())
screens:register('dithering', DitheringScreen())
screens:register('credits',   CreditsScreen())

screens:push('home', screens.kTransitionStartup, screens.kTransitionFade)

function playdate.update()
  screens:update()
  playdate.graphics.sprite.update()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
end

-- import 'CoreLibs/qrcode'
-- playdate.graphics.generateQRCode('https://playnote.studio/filehelp', 120, function (qr)
--   playdate.simulator.writeToFile(qr, '~/qr.png')
--   print('qr generated')
-- end)