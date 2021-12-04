local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local gfx <const> = playdate.graphics
local counterFont <const> = gfx.font.new('./fonts/WhalesharkCounter')

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
  self.playTransitionDir = 1
  self.isPlayTransitionActive = false
  self.isPlayUiActive = true
  self.playTransitionTimer = nil
  self.playTransitionValue = 0
  -- input stuff
  self.keyTimer = nil
  self.inputHandlers = {
    leftButtonDown = function()
      if self.isPlaying then
        return
      end
      if self.keyTimer then
        self.keyTimer:remove()
        self.keyTimer = nil
      end
      self.keyTimer = playdate.timer.keyRepeatTimerWithDelay(500, 100, function ()
        self:setCurrentFrame(self.currentFrame - 1)
      end)
    end,
    leftButtonUp = function()
      if self.keyTimer then
        self.keyTimer:remove()
        self.keyTimer = nil
      end
    end,
    rightButtonDown = function()
      if self.isPlaying then
        return
      end
      if self.keyTimer then
        self.keyTimer:remove()
        self.keyTimer = nil
      end
      self.keyTimer = playdate.timer.keyRepeatTimerWithDelay(500, 100, function ()
        self:setCurrentFrame(self.currentFrame + 1)
      end)
    end,
    rightButtonUp = function()
      if self.keyTimer then
        self.keyTimer:remove()
        self.keyTimer = nil
      end
    end,
    downButtonDown = function()
      self:togglePlay()
    end,
    AButtonDown = function()
      self:togglePlay()
    end,
    BButtonDown = function()
      screenManager:setScreen('notelist', screenManager.CROSSFADE)
    end
  }
  self.timeline = Timeline((PLAYDATE_W / 2) - 82, PLAYDATE_H - 26, 164, 20)
end

function PlayerScreen:transitionEnter(t)
  if t >= 0.5 then
    gfxUtils:drawBgGrid()
    self.currentFrame = 1
    self:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end

function PlayerScreen:transitionLeave(t)
  if t < 0.5 then
    gfxUtils:drawBgGrid()
    self:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
end

function PlayerScreen:beforeEnter()
  PlayerScreen.super.beforeEnter(self)
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
end

function PlayerScreen:afterLeave()
  PlayerScreen.super.afterLeave(self)
  self:unloadPpm()
end

function PlayerScreen:loadPpm()
  self.ppm = PpmParser.new(noteFs.currentNote)
  self.numFrames = self.ppm.numFrames
  self.currentFrame = 1
  self.loop = true -- TODO: take from ppm
  local animTimer = playdate.timer.new(1000, 1, 32)
  animTimer.repeats = true
  animTimer.discardOnCompletion = false
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
  i = math.floor(i)
  -- if playback can loop, allow the playback to wrap around
  if self.loop then  
    if i > self.numFrames then
      self.currentFrame = 1
    elseif i < 1 then
      self.currentFrame = self.numFrames
    else
      self.currentFrame = i
    end
  -- else clamp
  else
    self.currentFrame = math.max(1, math.min(i, self.numFrames))
  end
  self.timeline.progress = (self.currentFrame - 1) / (self.numFrames - 1)
end

function PlayerScreen:play()
  if self.isPlayTransitionActive then return end
  if not self.isPlaying then
    self.isPlaying = true
    self:transitionUiControls(false)
    playdate.display.setRefreshRate(self.ppm.fps)
    -- playdate.display.setRefreshRate(50)
  end
end

function PlayerScreen:pause()
  if self.isPlayTransitionActive then return end
  if self.isPlaying then
    if self.keyTimer then
      self.keyTimer:remove()
      self.keyTimer = nil
    end
    self.isPlaying = false
    self:transitionUiControls(true)
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
    transitionTimer = playdate.timer.new(200, 1, 0, playdate.easingFunctions.outBack)
  else
    transitionTimer = playdate.timer.new(200, 0, 1, playdate.easingFunctions.inBack)
  end
  self.isPlayUiActive = true
  self.isPlayTransitionActive = true
  self.playTransitionTimer = transitionTimer
  self.playTransitionValue = show and 1 or 0
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self.playTransitionValue = timer.value
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    self.playTransitionValue = show and 0 or 1
    utils:nextTick(function ()
      self.isPlayUiActive = show
      self.isPlayTransitionActive = false
    end)
  end
end

function PlayerScreen:update()
  playdate.drawFPS(0, 240 -16)
  if (not self.isPlaying) then
    local frameChange = playdate.getCrankTicks(24)
    self:setCurrentFrame(self.currentFrame + frameChange)
  end
  -- this effectively clears the screen
  -- which is only needed if the ui is moving, everything else is static, so it's faster too not draw the grid
  if self.isPlayTransitionActive then
    gfxUtils.drawBgGrid()
  end
  -- draw border around the frame
  gfx.setColor(gfx.kColorBlack)
  gfx.drawRect(72 - 2, 16 - 2, 256 + 4, 192 + 4)
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(72 - 1, 16 - 1, 256 + 2, 192 + 2)
  -- draw the frame itself
  self.ppm:drawFrame(self.currentFrame, false)
  -- draw player UIx
  if self.isPlayUiActive then
    -- using transition offset
    gfx.setDrawOffset(0, self.playTransitionValue * 48)
    -- frame counter
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(PLAYDATE_W - 104, PLAYDATE_H - 26, 100, 22, 4)
    -- frame counter text
    gfx.setFont(counterFont)
    gfx.drawTextAligned(self.currentFrame, PLAYDATE_W - 78, PLAYDATE_H - 24, kTextAlignment.center)
    gfx.drawTextAligned('/', PLAYDATE_W - 54, PLAYDATE_H - 24, kTextAlignment.center)
    gfx.drawTextAligned(self.numFrames, PLAYDATE_W - 30, PLAYDATE_H - 24, kTextAlignment.center)
    -- using transition offset
    gfx.setDrawOffset(0, self.playTransitionValue * 32)
    -- frame timeline
    self.timeline:draw()
    -- reset offset
    gfx.setDrawOffset(0, 0)
  end
  -- TODO: proper frame tming
  if self.isPlaying then
    self:setCurrentFrame(self.currentFrame + 1)
  end
end