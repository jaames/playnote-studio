local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local gfx <const> = playdate.graphics
local counterFont <const> = gfx.font.new('./fonts/WhalesharkCounter')

local NOTE_X <const> = 72
local NOTE_Y <const> = 16
local NOTE_W <const> = 256
local NOTE_H <const> = 192

local DELAY_PAGE_FIRST <const> = 500
local DELAY_PAGE_REPEAT <const> = 100
local DELAY_PLAY_UI <const> = 200

PlayerScreen = {}
class('PlayerScreen').extends(ScreenBase)

function PlayerScreen:init()
  PlayerScreen.super.init(self)
  -- ppm playback state stuff
  self.ppm = nil
  self.currentFrame = 1
  self.numFrames = 1
  self.loop = true
  self.isPlaying = false
  self.animTimer = nil -- TODO
  -- player ui transition stuff
  self.isPlayTransitionActive = false
  self.isUiVisible = true
  self.playTransitionVal = 0
  -- frame transition stuff
  self.isFrameTransitionActive = false
  self.frameTransitionStaticBitmap = gfx.image.new(NOTE_W, NOTE_H)
  self.frameTransitionBitmap = gfx.image.new(NOTE_W, NOTE_H)
  self.frameTransitionPos = nil
  -- input stuff
  local pageNextStart, pageNextEnd, removePageNextTimer = utils:createRepeater(DELAY_PAGE_FIRST, DELAY_PAGE_REPEAT, function (isRepeat)
    if self.isPlaying then
      return
    end
    self.removePagePrevTimer()
    if isRepeat then
      self:jumpToNextFrame()
    else
      self:jumpToNextFrameWithTransition()
    end
  end)
  local pagePrevStart, pagePrevEnd, removePagePrevTimer = utils:createRepeater(DELAY_PAGE_FIRST, DELAY_PAGE_REPEAT, function (isRepeat)
    if self.isPlaying then
      return
    end
    self.removePageNextTimer()
    if isRepeat then
      self:jumpToPrevFrame()
    else
      self:jumpToPrevFrameWithTransition()
    end
  end)
  self.removePageNextTimer = removePageNextTimer
  self.removePagePrevTimer = removePagePrevTimer
  self.inputHandlers = {
    leftButtonDown = pagePrevStart,
    leftButtonUp = pagePrevEnd,
    rightButtonDown = pageNextStart,
    rightButtonUp = pageNextEnd,
    downButtonDown = function()
      self:togglePlay()
    end,
    AButtonDown = function()
      self:togglePlay()
    end
  }
  -- ui components
  self.timeline = Timeline((PLAYDATE_W / 2) - 82, PLAYDATE_H - 26, 164, 20)
end

function PlayerScreen:setupMenuItems(menu)
  local currNote = noteFs.currentNote
  local detailsItem = menu:addMenuItem(locales:getText('PLAY_MENU_DETAILS'), function()
    screens:push('details', screens.kTransitionFade, nil, currNote)
  end)
  local ditherItem = menu:addMenuItem(locales:getText('PLAY_MENU_DITHERING'), function()
    local ditherSettings = noteFs:getNoteDitherSettings(currNote)
    local function updateDither(newSettings)
      noteFs:updateNoteDitherSettings(currNote, newSettings)
    end
    screens:push('dithering', screens.kTransitionFade, nil, ditherSettings, updateDither)
  end)
  return {detailsItem, ditherItem}
end

function PlayerScreen:beforeEnter()
  PlayerScreen.super.beforeEnter(self)
  sounds:prepareSfxGroup('player', {
    'pageNext',
    'pagePrev',
    'pageNextFast',
    'pagePrevFast',
    'pause',
    'playMove'
  })
  playdate.getCrankTicks(24) -- prevent crank going nuts if it's been moved since this screen was last active
  self:unloadPpm()
  self:loadPpm()
end

function PlayerScreen:afterEnter()
  PlayerScreen.super.afterEnter(self)
  gfxUtils:drawBgGrid()
  self:update()
end

function PlayerScreen:beforeLeave()
  PlayerScreen.super.beforeLeave(self)
  self:pause()
  self.removePageNextTimer()
  self.removePagePrevTimer()
end

function PlayerScreen:afterLeave()
  PlayerScreen.super.afterLeave(self)
  sounds:releaseSfxGroup('player')
  self:unloadPpm()
end

function PlayerScreen:loadPpm()
  local ppm = PpmParser.new(noteFs.currentNote)
  local ditherSetttings = noteFs:getNoteDitherSettings(noteFs.currentNote)
  for layer = 1,2 do
    for colour = 1,3 do
      ppm:setLayerDither(layer, colour, ditherSetttings[layer][colour])
    end
  end
  self.currentFrame = 1
  self.numFrames = ppm.numFrames
  self.loop = ppm.loop
  self.ppm = ppm
  local animTimer = playdate.timer.new(ppm.duration * 1000, 0, self.numFrames)
  animTimer.repeats = self.loop
  animTimer.discardOnCompletion = false
  animTimer:pause()
  animTimer.updateCallback = function ()
    print('anim timer update v: ', math.floor(animTimer.value) + 1, self.currentFrame)
  end
  animTimer.timerEndedCallback = function ()
    print('anim timer end: ', math.floor(animTimer.value) + 1, self.currentFrame)
  end
  self.animTimer = animTimer
end

function PlayerScreen:unloadPpm()
  self:pause()
  self.ppm = nil
  if self.animTimer then
    self.animTimer:remove()
    self.animTimer = nil
  end
end

function PlayerScreen:setCurrentFrame(i)
  local ppm = self.ppm
  ppm:setCurrentFrame(math.floor(i))
  self.currentFrame = ppm.currentFrame
  self.timeline.progress = ppm.progress
end

function PlayerScreen:jumpToPrevFrame()
  sounds:playSfx('pagePrevFast')
  self:setCurrentFrame(self.currentFrame - 1)
end

function PlayerScreen:jumpToPrevFrameWithTransition()
  if self.isFrameTransitionActive then return end
  local initPos = NOTE_X
  local endPos = -NOTE_W
  local currFrame = self.currentFrame
  local nextFrame = currFrame == 1 and self.numFrames or currFrame - 1

  self.frameTransitionPos = initPos
  self.ppm:drawFrameToBitmap(nextFrame, self.frameTransitionStaticBitmap)
  self.ppm:drawFrameToBitmap(currFrame, self.frameTransitionBitmap)
 
  utils:nextTick(function ()
    sounds:playSfx('pagePrev')
    self.isFrameTransitionActive = true
  end)

  local transitionTimer = playdate.timer.new(250, initPos, endPos, playdate.easingFunctions.inCubic)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self.frameTransitionPos = timer.value
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    self.frameTransitionPos = endPos
    self:setCurrentFrame(nextFrame)
    utils:nextTick(function ()
      self.isFrameTransitionActive = false
    end)
  end
end

function PlayerScreen:jumpToNextFrame()
  sounds:playSfx('pageNextFast')
  self:setCurrentFrame(self.currentFrame + 1)
end

function PlayerScreen:jumpToNextFrameWithTransition()
  if self.isFrameTransitionActive then return end
  local initPos = PLAYDATE_W + NOTE_W
  local endPos = NOTE_X
  local currFrame = self.currentFrame
  local nextFrame = currFrame == self.numFrames and 1 or currFrame + 1

  self.frameTransitionPos = initPos
  self.ppm:drawFrameToBitmap(currFrame, self.frameTransitionStaticBitmap)
  self.ppm:drawFrameToBitmap(nextFrame, self.frameTransitionBitmap)
 
  utils:nextTick(function ()
    sounds:playSfx('pageNext')
    self.isFrameTransitionActive = true
  end)

  local transitionTimer = playdate.timer.new(250, initPos, endPos, playdate.easingFunctions.outCubic)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self.frameTransitionPos = timer.value
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    self.frameTransitionPos = endPos
    self:setCurrentFrame(nextFrame)
    utils:nextTick(function ()
      self.isFrameTransitionActive = false
    end)
  end
end

function PlayerScreen:play()
  if self.isPlayTransitionActive then return end
  if not self.isPlaying then
    sounds:playSfx('playMove')
    -- workaround for timer bug https://devforum.play.date/t/playdate-timer-value-increases-between-calling-pause-and-start/2096
	  self.animTimer._lastTime = nil
    self.animTimer:start()
    -- TODO: reenable
    self.ppm:playAudio()
    self.isPlaying = true
    self:transitionUiControls(false)
    playdate.setAutoLockDisabled(true)
    playdate.display.setRefreshRate(self.ppm.fps)
  end
end

function PlayerScreen:pause()
  if self.isPlayTransitionActive then return end
  if self.isPlaying then
    if self.keyTimer then
      self.keyTimer:remove()
      self.keyTimer = nil
    end
    sounds:playSfx('pause')
    -- TODO: reenable
    self.ppm:stopAudio()
    self.animTimer:pause()
    self.isPlaying = false
    self:transitionUiControls(true)
    playdate.setAutoLockDisabled(false)
    playdate.display.setRefreshRate(30)
    playdate.getCrankTicks(24)
  end
end

function PlayerScreen:togglePlay()
  if self.isPlaying then
    self:pause()
  else
    self:play()
  end
end

function PlayerScreen:transitionUiControls(show)
  local transitionTimer
  if show then
    transitionTimer = playdate.timer.new(DELAY_PLAY_UI, 1, 0, playdate.easingFunctions.outBack)
  else
    transitionTimer = playdate.timer.new(DELAY_PLAY_UI, 0, 1, playdate.easingFunctions.inBack)
  end
  self.isUiVisible = true
  self.isPlayTransitionActive = true
  self.playTransitionVal = show and 1 or 0
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self.playTransitionVal = timer.value
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    self.playTransitionVal = show and 0 or 1
    utils:nextTick(function ()
      self.isUiVisible = show
      self.isPlayTransitionActive = false
    end)
  end
end

function PlayerScreen:update()
  -- playdate.drawFPS(8, 16)
  if (not self.isPlaying) then
    local frameChange = playdate.getCrankTicks(24)
    self:setCurrentFrame(self.currentFrame + frameChange)
  end
  -- this effectively clears the screen
  -- which is only needed if the ui is moving, everything else is static, so it's faster to not always draw the grid
  if self.isPlayTransitionActive or self.isFrameTransitionActive then
    gfxUtils.drawBgGrid()
  end
  -- 
  if self.isFrameTransitionActive then
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(NOTE_X - 2, NOTE_Y - 2, NOTE_W + 4, NOTE_H + 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(NOTE_X - 1, NOTE_Y - 1, NOTE_W + 2, NOTE_H + 2)
    self.frameTransitionStaticBitmap:draw(NOTE_X, NOTE_Y)
    self.frameTransitionBitmap:draw(self.frameTransitionPos, 16)
  -- draw the current frame
  -- TODO: only if the frame has changed?
  else
    self.ppm:draw(NOTE_X, NOTE_Y)
  end
  -- draw player UI
  if self.isUiVisible then
    -- using transition offset
    gfx.setDrawOffset(0, self.playTransitionVal * 48)
    -- TODO: make component
    -- frame counter
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(PLAYDATE_W - 104, PLAYDATE_H - 26, 100, 22, 4)
    -- frame counter text
    counterFont:drawTextAligned(self.currentFrame, PLAYDATE_W - 78, PLAYDATE_H - 24, kTextAlignment.center)
    counterFont:drawTextAligned('/', PLAYDATE_W - 54, PLAYDATE_H - 24, kTextAlignment.center)
    counterFont:drawTextAligned(self.numFrames, PLAYDATE_W - 30, PLAYDATE_H - 24, kTextAlignment.center)
    -- dpad hint (TODO: redraw so it feels less distracting?)
    -- gfx.setDrawOffset(0, self.playTransitionValue * 64)
    -- dpadGfx[self.dpadState]:draw(6, PLAYDATE_H - 60)
    -- frame timeline
    gfx.setDrawOffset(0, self.playTransitionVal * 32)
    self.timeline:draw()
    -- reset offset
    gfx.setDrawOffset(0, 0)
  end
  -- TODO: proper frame timing
  if self.isPlaying then
    self:setCurrentFrame(self.currentFrame + 1)
  end
end