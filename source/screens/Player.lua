import 'CoreLibs/graphics'
import 'CoreLibs/object'
import 'CoreLibs/timer'
import 'CoreLibs/crank'

import './ScreenBase'
import '../screenManager.lua'
import '../noteManager.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

class('PlayerScreen').extends(ScreenBase)

function PlayerScreen:init()
  PlayerScreen.super.init(self)

  self.ppm = nil
  self.loop = true
  self.isPlaying = false
  self.currentFrame = 1

  self.prevFrameCrankAngle = 0
  self.currentCrankAngle = 0

  local animTimer = nil
  local keyTimer = nil
  
  self.inputHandlers = {
    leftButtonDown = function()
      if self.isPlaying then return end
      local function timerCallback()
        self:setCurrentFrame(self.currentFrame - 1)
      end
      keyTimer = playdate.timer.keyRepeatTimerWithDelay(500, 100, timerCallback)
    end,
    leftButtonUp = function()
      keyTimer:remove()
    end,
    rightButtonDown = function()
      if self.isPlaying then return end
      local function timerCallback()
        self:setCurrentFrame(self.currentFrame + 1)
      end
      keyTimer = playdate.timer.keyRepeatTimerWithDelay(500, 100, timerCallback)
    end,
    rightButtonUp = function()
      keyTimer:remove()
    end,
    downButtonDown = function()
      self:togglePlay()
    end,
    AButtonDown = function()
      self:togglePlay()
    end,
    BButtonDown = function()
      screenManager:setScreen('notelist')
    end
  }
end

function PlayerScreen:transitionEnter(t)
  if t >= 0.5 then
    gfxUtils:drawBgGrid()
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
end

function PlayerScreen:loadPpm()
  self.ppm = PpmParser.new(noteManager.currentNote)
  self.numFrames = self.ppm.numFrames
  self.currentFrame = 1
  self.loop = true -- TODO: take from ppm
  local animTimer = playdate.timer.new(1000, 1, 32)
  animTimer.repeats = true
  animTimer.discardOnCompletion = false
  self.animTimer = animTimer
end

function PlayerScreen:setCurrentFrame(i)
  if self.loop then  
    if i > self.numFrames then
      self.currentFrame = 1
    elseif i < 1 then
      self.currentFrame = self.numFrames
    else
      self.currentFrame = i
    end
  else
    self.currentFrame = math.max(1, math.min(i, self.numFrames))
  end
end

function PlayerScreen:play()
  if not self.isPlaying then
    self.isPlaying = true
    playdate.display.setRefreshRate(self.ppm.fps)
  end
end

function PlayerScreen:pause()
  if self.isPlaying then
    self.isPlaying = false
    playdate.display.setRefreshRate(30)
  end
end

function PlayerScreen:togglePlay()
  if self.isPlaying then
    self:pause()
  else
    self:play()
  end
end

function PlayerScreen:update()
  
  -- playdate.drawFPS(0, 240 -16)

  local frameChange = playdate.getCrankTicks(24)
  if (not self.isPlaying) then
    self:setCurrentFrame(self.currentFrame + frameChange)
  end

  gfx.setColor(gfx.kColorBlack)
  gfx.drawRect(72 - 2, 16 - 2, 256 + 4, 192 + 4)
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(72 - 1, 16 - 1, 256 + 2, 192 + 2)

  self.ppm:drawFrame(self.currentFrame, false)
  
  -- local counterText = string.format("%03d/%03d", math.floor(i), 75);
  -- gfx.setColor(gfx.kColorWhite)
  -- gfx.fillRoundRect(PLAYDATE_W - 84, PLAYDATE_H - 26, 80, 22, 4)

  -- gfx.fillRoundRect((PLAYDATE_W / 2) - 80, PLAYDATE_H - 26, 160, 16, 4)

  -- TODO: proper frame tming
  if self.isPlaying then
    self:setCurrentFrame(self.currentFrame + 1)
  end
end