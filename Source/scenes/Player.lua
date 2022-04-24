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
local transitionCurve = motionPath:newCurve(0, 0, -150, -40, -300, 0)

PlayerScreen = {}
class('PlayerScreen').extends(ScreenBase)

function PlayerScreen:init()
  PlayerScreen.super.init(self)
  -- ppm playback state stuff
  self.ppm = nil
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
    if self.ppm.isPlaying then return end
    self:jumpToNextFrame(not isRepeat)
  end)
  local pagePrevStart, pagePrevEnd, rmvTimer2 = utils:createRepeater(DELAY_PAGE_FIRST, DELAY_PAGE_REPEAT, function (isRepeat)
    if self.ppm.isPlaying then return end
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
    sceneManager:push('details', sceneManager.kTransitionFade, nil, currNote)
  end)

  local ditherItem = menu:addMenuItem(locales:getText('PLAY_MENU_DITHERING'), function()
    local ditherSettings = noteFs:getNoteDitherSettings(currNote)
    local function updateDither(newSettings)
      noteFs:updateNoteDitherSettings(currNote, newSettings)
    end
    sceneManager:push('dithering', sceneManager.kTransitionFade, nil, ditherSettings, updateDither)
  end)

  return {detailsItem, ditherItem}
end

function PlayerScreen:beforeEnter()
  sounds:prepareSfxGroup('player', {
    'pageNext',
    'pagePrev',
    'pageNextFast',
    'pagePrevFast',
    'pause',
    'playMove',
    'crankA',
    'crankB',
  })
  playdate.getCrankTicks(24) -- prevent crank going nuts if it's been moved since this screen was last active
  self:unloadPpm()
  self:loadPpm()
end

function PlayerScreen:beforeLeave()
  if self.ppm then
    self:pause()
    self.removeTimers()
  end
end

function PlayerScreen:afterLeave()
  sounds:releaseSfxGroup('player')
  self:unloadPpm()
end

function PlayerScreen:loadPpm()
  local ppm = PpmPlayer.new(NOTE_X, NOTE_Y)
  local openedSuccessfully = ppm:open(noteFs.currentNote)

  if openedSuccessfully then
    self.ppm = ppm
    local this = self
    local ditherSetttings = noteFs:getNoteDitherSettings(noteFs.currentNote)
    for layer = 1,2 do
      for colour = 1,3 do
        ppm:setLayerDither(layer, colour, ditherSetttings[layer][colour])
      end
    end
    self:refreshControls()
    ppm:setStoppedCallback(utils:newCallbackFn(function (a, b)
      this:pause()
    end))
  else
    local err = stringUtils:escape(ppm:getError())
    -- display parser error then push back to previous screen
    dialog:sequence({
      {type = dialog.kTypeAlert, delay = 100, message = err, callback = function ()
        sceneManager:pop()
      end}
    })
  end
end

function PlayerScreen:unloadPpm()
  if self.ppm then
    self:pause()
    self.ppm = nil
  end
end

function PlayerScreen:setCurrentFrame(i)
  local ppm = self.ppm
  if i ~= self.ppm.currentFrame then
    ppm:setCurrentFrame(math.floor(i))
    self:refreshControls()
    spritelib.redrawBackground()
  end
end

function PlayerScreen:jumpToPrevFrame(animate)
  local currFrame = self.ppm.currentFrame
  if animate then
    local prevFrame = currFrame == 1 and self.ppm.numFrames or currFrame - 1
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
  local currFrame = self.ppm.currentFrame
  if animate then
    local nextFrame = currFrame == self.ppm.numFrames and 1 or currFrame + 1
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

  local currFrame = self.ppm.currentFrame
  local from, to, easing
  if direction == kTransitionDirAdvance then
    from = 0
    to = 1
    easing = playdate.easingFunctions.inQuad
    ppm:drawFrameToBitmap(currFrame, topSlide.image)
    ppm:drawFrameToBitmap(toFrame, bottomSlide.image)
  elseif direction == kTransitionDirRetreat then
    from = 1
    to = 0
    easing = playdate.easingFunctions.outQuad
    ppm:drawFrameToBitmap(currFrame, bottomSlide.image)
    ppm:drawFrameToBitmap(toFrame, topSlide.image)
  end
  -- draw frames to bitmaps
  self:addSprite(topSlide)
  self:addSprite(bottomSlide)

  local x, y = transitionCurve(from)
  topSlide:offsetBy(x, y)

  local timer = playdate.timer.new(250, from, to, easing)
  timer.updateCallback = function (t)
    local x, y = transitionCurve(t.value)
    topSlide:offsetBy(x, y)
  end
  timer.timerEndedCallback = function (t)
    local x, y = transitionCurve(t.value)
    topSlide:offsetBy(x, y)
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
  if not self.ppm.isPlaying then
    sounds:playSfx('playMove')
    self.ppm:play()
    self:setControlsVisible(false)
    playdate.setAutoLockDisabled(true)
    playdate.display.setRefreshRate(REFRESH_RATE_INSTANT)
  end
end

function PlayerScreen:pause()
  if self.isPlayTransitionActive then return end
  if self.ppm.isPlaying then
    self:refreshControls()
    sounds:playSfx('pause')
    self.ppm:pause()
    self:setControlsVisible(true)
    playdate.setAutoLockDisabled(false)
    playdate.display.setRefreshRate(REFRESH_RATE_GLOBAL)
    playdate.getCrankTicks(24)
  end
end

function PlayerScreen:togglePlay()
  if self.ppm.isPlaying then
    self:pause()
  else
    self:play()
  end
end

function PlayerScreen:refreshControls()
  local ppm = self.ppm
  self.counter:setTotal(ppm.numFrames)
  self.counter:setValue(ppm.currentFrame)
  self.timeline:setProgress(ppm.progress)
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
  if self.ppm and not self.isFrameTransitionActive then
    -- only draw frame if clip rect overlaps it
    local _, _, iw, ih = fast_intersection(NOTE_X - 4, NOTE_Y - 4, NOTE_W + 8, NOTE_H + 8, x, y, w, h)
    if iw > 0 and ih > 0 then
      self.ppm:draw()
    end
  -- still at least draw frame border if transtion is active
  else
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(NOTE_X - 2, NOTE_Y - 2, NOTE_W + 4, NOTE_H + 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(NOTE_X - 1, NOTE_Y - 1, NOTE_W + 2, NOTE_H + 2)
  end
end

function PlayerScreen:update()
  if self.ppm then
    if not self.ppm.isPlaying then
      local frameChange = playdate.getCrankTicks(24)
      if frameChange ~= 0 then
        self:setCurrentFrame(self.ppm.currentFrame + frameChange)
        if frameChange < 0 then
          sounds:playSfxWithCooldown('crankA', 60)
        else
          sounds:playSfxWithCooldown('crankB', 60)
        end
      end
    else
      self.ppm:update()
    end
  end
end

function PlayerScreen:updateTransitionIn(t, fromScreen)
  self.counter:offsetByX(playdate.easingFunctions.outQuad(t, 100, -100, 1))
  self.timeline:offsetByY(playdate.easingFunctions.outQuad(t, 60, -60, 1))
end

function PlayerScreen:updateTransitionOut(t, toScreen)
  self.counter:offsetByX(playdate.easingFunctions.inQuad(t, 0, 100, 1))
  self.timeline:offsetByY(playdate.easingFunctions.inQuad(t, 0, 60, 1))
end

return PlayerScreen