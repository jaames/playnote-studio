import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/object'

import './ScreenBase'
import '../screenManager.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

local ppm = PpmParser.new("./ppm/samplememo_04.ppm")
local numFrames = ppm.numFrames

local layer = gfx.image.new(256, 192)
local i = 1

function decodeFrame(i)
  ppm:decodeFrameToBitmap(i, layer)
end

class('PlayerScreen').extends(ScreenBase)

function PlayerScreen:init()
  PlayerScreen.super.init(self)
  decodeFrame(1)
  self.isPlaying = false
  self.inputHandlers = {
    leftButtonDown = function()
      -- frame left
    end,
    rightButtonDown = function()
      -- frame rright
    end,
    downButtonDown = function()
      -- play
    end,
    BButtonUp = function()
      screenManager:setScreen('home')
    end,
    cranked = function(change, acceleratedChange)
      -- seek frame
    end,
  }
end

function PlayerScreen:transitionEnter(t, id)
  -- initial entrance
  if id == nil then
    gfxUtils:drawBgGrid()
    self:update()
    gfxUtils:drawWhiteFade(t)
  -- inter-page transition
  elseif t >= 0.5 then
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

function PlayerScreen:afterEnter()
  PlayerScreen.super.afterEnter(self)
  gfxUtils:drawBgGrid()
  self:update()
end

function PlayerScreen:update()
  gfx.setDrawOffset(0, 0)
  layer:draw(72, 16)
  -- local counterText = string.format("%03d/%03d", math.floor(i), 75);
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(PLAYDATE_W - 84, PLAYDATE_H - 26, 80, 22, 4)

  gfx.fillRoundRect((PLAYDATE_W / 2) - 80, PLAYDATE_H - 26, 160, 16, 4)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(2)
  -- gfx.fillRoundRect(barleft, PLAYDATE_H - 20, 144, 3, 1)

  -- local step = 144 / numFrames
  -- local x = step * i

  -- gfx.setColor(gfx.kColorWhite)
  -- gfx.fillRoundRect(barleft + x, PLAYDATE_H - 22, 3, 7, 4)
  -- gfx.setColor(gfx.kColorBlack)
  -- gfx.drawRoundRect(barleft + x, PLAYDATE_H - 22, 3, 7, 4)
end