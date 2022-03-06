local NOTE_X <const> = 72
local NOTE_Y <const> = 16
local NOTE_W <const> = 256
local NOTE_H <const> = 192

local DELAY_PAGE_FIRST <const> = 350
local DELAY_PAGE_REPEAT <const> = 100
local DELAY_PLAY_UI <const> = 200

local fast_intersection <const> = playdate.geometry.rect.fast_intersection

local kTransitionDirAdvance <const> = 1
local kTransitionDirRetreat <const> = -1

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
  -- frame transition components
  self.isFrameTransitionActive = false
  self.frameTransitionBottomSlide = Image(NOTE_X, NOTE_Y, NOTE_W, NOTE_H)
  self.frameTransitionTopSlide = Image(NOTE_X, NOTE_Y, NOTE_W, NOTE_H)
  self.frameTransitionTopSlide:setZIndex(self.frameTransitionBottomSlide:getZIndex() + 10)
  -- input stuff
  local pageNextStart, pageNextEnd, rmvTimer1 = utils:createRepeater(DELAY_PAGE_FIRST, DELAY_PAGE_REPEAT, function (isRepeat)
    if self.isPlaying then return end
    self:jumpToNextFrame(not isRepeat)
  end)
  local pagePrevStart, pagePrevEnd, rmvTimer2 = utils:createRepeater(DELAY_PAGE_FIRST, DELAY_PAGE_REPEAT, function (isRepeat)
    if self.isPlaying then return end
    self:jumpToPrevFrame(not isRepeat)
  end)

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
  self.removeTimers = function ()
    rmvTimer1()
    rmvTimer2()
  end
end

function PlayerScreen:setupSprites()
  local counter = Counter(PLAYDATE_W - 4, PLAYDATE_H - 4)
  counter:setAnchor('right', 'bottom')
  self.counter = counter

  local timeline = Timeline(PLAYDATE_W / 2, PLAYDATE_H - 6, 166)
  timeline:setAnchor('center', 'bottom')
  self.timeline = timeline

  return { timeline, counter }
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

function PlayerScreen:beforeLeave()
  PlayerScreen.super.beforeLeave(self)
  self:pause()
  self.removeTimers()
end

function PlayerScreen:afterLeave()
  PlayerScreen.super.afterLeave(self)
  sounds:releaseSfxGroup('player')
  self:unloadPpm()
end

function PlayerScreen:loadPpm()
  -- print(noteFs.currentNote)
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
  self.counter:setTotal(self.numFrames)
  self.counter:setValue(self.currentFrame)
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
  if i ~= self.currentFrame then
    ppm:setCurrentFrame(math.floor(i))
    self.currentFrame = ppm.currentFrame
    self.timeline:setProgress(ppm.progress)
    self.counter:setValue(self.currentFrame)
    spritelib.redrawBackground()
  end
end

function PlayerScreen:jumpToPrevFrame(animate)
  local currFrame = self.currentFrame
  if animate then
    local prevFrame = currFrame == 1 and self.numFrames or currFrame - 1
    sounds:playSfx('pagePrev')
    self:doFrameTransition(kTransitionDirRetreat, prevFrame, function ()
      self:setCurrentFrame(prevFrame)
    end)
  else
    sounds:playSfx('pagePrevFast')
    self:setCurrentFrame(currFrame - 1)
  end
end

function PlayerScreen:jumpToNextFrame(animate)
  local currFrame = self.currentFrame
  if animate then
    local nextFrame = currFrame == self.numFrames and 1 or currFrame + 1
    sounds:playSfx('pageNext')
    self:doFrameTransition(kTransitionDirAdvance, nextFrame, function ()
      self:setCurrentFrame(nextFrame)
    end)
  else
    sounds:playSfx('pageNextFast')
    self:setCurrentFrame(currFrame + 1)
  end
end

function PlayerScreen:doFrameTransition(direction, toFrame, callbackFn)
  if self.isFrameTransitionActive then return end
  self.isFrameTransitionActive = true
  -- shorthands
  local ppm = self.ppm
  local topSlide = self.frameTransitionTopSlide
  local bottomSlide = self.frameTransitionBottomSlide

  local currFrame = self.currentFrame
  local initPos, endPos, easing
  if direction == kTransitionDirAdvance then
    initPos = 0
    endPos = -NOTE_W
    easing = playdate.easingFunctions.inQuad
    ppm:drawFrameToBitmap(currFrame, topSlide.image)
    ppm:drawFrameToBitmap(toFrame, bottomSlide.image)
  elseif direction == kTransitionDirRetreat then
    initPos = -NOTE_W
    endPos = 0
    easing = playdate.easingFunctions.outQuad
    ppm:drawFrameToBitmap(currFrame, bottomSlide.image)
    ppm:drawFrameToBitmap(toFrame, topSlide.image)
  end
  -- draw frames to bitmaps
  self:addSprite(topSlide)
  self:addSprite(bottomSlide)
  topSlide:offsetByX(initPos)

  local transitionTimer = playdate.timer.new(200, initPos, endPos, easing)
  transitionTimer.updateCallback = function (t)
    topSlide:offsetByX(t.value)
  end
  transitionTimer.timerEndedCallback = function (t)
    topSlide:offsetByX(t.value)
    callbackFn()
    utils:nextTick(function ()
      self:removeSprite(topSlide)
      self:removeSprite(bottomSlide)
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
    self:setControlsVisible(false)
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
    self:setControlsVisible(true)
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

function PlayerScreen:setControlsVisible(visible)
  local transitionTimer
  if visible then
    transitionTimer = playdate.timer.new(DELAY_PLAY_UI, 1, 0, playdate.easingFunctions.outBack)
  else
    transitionTimer = playdate.timer.new(DELAY_PLAY_UI, 0, 1, playdate.easingFunctions.inBack)
  end

  transitionTimer.updateCallback = function (t)
    self:setControlsPos(t.value)
  end
  transitionTimer.timerEndedCallback = function (t)
    self:setControlsPos(t.value)
  end
end

function PlayerScreen:setControlsPos(pos)
  self.counter:offsetByY(pos * 50)
  self.timeline:offsetByY(pos * 40)
end

function PlayerScreen:drawBg(x, y, w, h)
  grid:draw(x, y, w, h)
  -- draw frame here only if the transition is active
  if not self.isFrameTransitionActive then
    -- only draw frame if clip rect overlaps it
    local _, _, iw, ih = fast_intersection(NOTE_X, NOTE_Y, NOTE_W, NOTE_H, x, y, w, h)
    if iw > 0 and ih > 0 then
      self.ppm:draw(NOTE_X, NOTE_Y)
    end
  -- still at least draw frame border if transtion is active
  else
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(NOTE_X - 1, NOTE_Y - 1, NOTE_W + 2, NOTE_H + 2)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(NOTE_X, NOTE_Y, NOTE_W, NOTE_H)
  end
end

function PlayerScreen:update()
  -- playdate.drawFPS(8, 16)
  if not self.isPlaying then
    local frameChange = playdate.getCrankTicks(24)
    self:setCurrentFrame(self.currentFrame + frameChange)
  end
  if self.isPlaying then
    self:setCurrentFrame(self.currentFrame + 1)
  end
end