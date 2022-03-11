import 'CoreLibs/math'
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/nineslice'
import 'CoreLibs/crank'
import 'CoreLibs/timer'
import 'CoreLibs/frameTimer'
import 'CoreLibs/animation'

import './utils/utils'
import './utils/stringUtils'
import './utils/fsUtils'

import './globals'

import './config'
import './locales'
import './noteFs'
import './sounds'
import './sceneManager'

import './ui/grid'
import './ui/overlay'
import './ui/dialog'
import './ui/pdbug'

import './controllers/ScrollController'
import './controllers/FocusController'

import './components/ComponentBase'
import './components/AutoLayout'
import './components/Image'
import './components/Button'
import './components/Select'
import './components/Clock'
import './components/HomeLogo'
import './components/FolderSelect'
import './components/Counter'
import './components/NoNoteDialog'
import './components/Thumbnail'
import './components/Timeline'
import './components/DitherSwatch'
import './components/ScrollBar'
import './components/KeyValList'
import './components/TextView'

import './scenes/Screenbase'

MAIN_FONT = playdate.graphics.font.new('./fonts/WhalesharkSans')
playdate.graphics.setFont(MAIN_FONT)
playdate.display.setRefreshRate(50)
-- playdate.display.setRefreshRate(30)

debug = nil -- disallow debugging
-- pdbug:setEnabled(true)

config:init()
locales:init()
noteFs:init()
dialog:init()

sceneManager:register({
  home = (import './scenes/Home'),
  notelist = (import './scenes/NoteList'),
  details = (import './scenes/Details'),
  player = (import './scenes/Player'),
  settings = (import './scenes/Settings'),
  dithering = (import './scenes/Dithering'),
  credits = (import './scenes/Credits'),
})

sceneManager:push('home', sceneManager.kTransitionStartup, sceneManager.kTransitionFade)

function playdate.update()
  sceneManager:update()
  playdate.graphics.sprite.update()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
  gfx.animation.blinker.updateAll()
  -- playdate.drawFPS(8, PLAYDATE_H - 20)
end

-- import 'CoreLibs/qrcode'
-- playdate.graphics.generateQRCode('https://playnote.studio/filehelp', 120, function (qr)
--   playdate.simulator.writeToFile(qr, '~/qr.png')
--   print('qr generated')
-- end)