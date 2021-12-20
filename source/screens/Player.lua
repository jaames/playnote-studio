local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local gfx <const> = playdate.graphics
local counterFont <const> = gfx.font.new('./fonts/WhalesharkCounter')

local DPAD_DEFAULT <const> = 1
local DPAD_DOWN <const> = 2
local DPAD_LEFT <const> = 3
local DPAD_RIGHT <const> = 4
local dpadGfx <const> = {
  [DPAD_DEFAULT] = gfx.image.new('./gfx/gfx_player_dpadhint_default'),
  [DPAD_LEFT] = gfx.image.new('./gfx/gfx_player_dpadhint_leftpressed'),
  [DPAD_RIGHT] = gfx.image.new('./gfx/gfx_player_dpadhint_rightpressed'),
  [DPAD_DOWN] = gfx.image.new('./gfx/gfx_player_dpadhint_downpressed')
}

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
  self.dpadState = DPAD_DEFAULT
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
        self.dpadState = DPAD_LEFT
      end)
    end,
    leftButtonUp = function()
      if self.keyTimer then
        self.keyTimer:remove()
        self.keyTimer = nil
      end
      self.dpadState = DPAD_DEFAULT
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
        self.dpadState = DPAD_RIGHT
      end)
    end,
    rightButtonUp = function()
      if self.keyTimer then
        self.keyTimer:remove()
        self.keyTimer = nil
      end
      self.dpadState = DPAD_DEFAULT
    end,
    downButtonDown = function()
      self:togglePlay()
      self.dpadState = DPAD_DOWN
    end,
    downButtonUp = function()
      self:togglePlay()
      self.dpadState = DPAD_DEFAULT
    end,
    AButtonDown = function()
      self:togglePlay()
    end
  }
  self.timeline = Timeline((PLAYDATE_W / 2) - 82, PLAYDATE_H - 26, 164, 20)
end

function PlayerScreen:beforeEnter()
  PlayerScreen.super.beforeEnter(self)
  self.dpadState = DPAD_DEFAULT
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
  local ppm = PpmParser.new(noteFs.currentNote)
  for layer = 1,2 do
    for colour = 1,3 do
      ppm:setLayerDither(layer, colour, config.dithering[layer][colour])
    end
  end
  self.numFrames = ppm.numFrames
  self.loop = ppm.loop
  self.ppm = ppm
  self.currentFrame = 1
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
    self.ppm:playAudio()
    self.isPlaying = true
    self:transitionUiControls(false)
    playdate.setAutoLockDisabled(true)
    -- playdate.display.setRefreshRate(self.ppm.fps)
  end
end

function PlayerScreen:pause()
  if self.isPlayTransitionActive then return end
  if self.isPlaying then
    if self.keyTimer then
      self.keyTimer:remove()
      self.keyTimer = nil
    end
    self.ppm:stopAudio()
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
  -- playdate.drawFPS(8, 16)
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
    counterFont:drawTextAligned(self.currentFrame, PLAYDATE_W - 78, PLAYDATE_H - 24, kTextAlignment.center)
    counterFont:drawTextAligned('/', PLAYDATE_W - 54, PLAYDATE_H - 24, kTextAlignment.center)
    counterFont:drawTextAligned(self.numFrames, PLAYDATE_W - 30, PLAYDATE_H - 24, kTextAlignment.center)
    -- dpad hint
    gfx.setDrawOffset(0, self.playTransitionValue * 64)
    dpadGfx[self.dpadState]:draw(6, PLAYDATE_H - 60)
    -- frame timeline
    gfx.setDrawOffset(0, self.playTransitionValue * 32)
    self.timeline:draw()
    -- reset offset
    gfx.setDrawOffset(0, 0)
  end
  -- TODO: proper frame tming
  if self.isPlaying then
    self:setCurrentFrame(self.currentFrame + 1)
  end
end