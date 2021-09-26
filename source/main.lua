-- import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/object'

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240

local font <const> = gfx.font.new('./fonts/Asheville-Sans-14-Bold')

local layer = gfx.image.new(256, 192)
local ppm = PpmParser.new("./ppm/samplememo_02.ppm")
local numFrames = ppm:getNumFrames()
-- local fps = ppm:getFps()
local fps = 12
local duration = numFrames / fps

-- print (fps, duration)

local isPlaying = false
local frameIndex = -1
local lastFrameIndex = -1

local playbackTimer = playdate.timer.new(duration * 1000, 1, numFrames)

playbackTimer.repeats = true

playbackTimer.updateCallback = function()
	frameIndex = math.floor(playbackTimer.value)
end

playbackTimer:pause()

function playdate.AButtonDown()
  if (isPlaying) then 
    playbackTimer:pause()
    isPlaying = false
  else
    playbackTimer:start()
    isPlaying = true
  end
end

function drawFrame(frameIndex)
  -- draw grid background
  gfx.setPattern({ 0xFF, 0xEF, 0xFF, 0xAA, 0xFF, 0xEF, 0xFF, 0xEF })
  gfx.fillRect(0, 0, PLAYDATE_W, PLAYDATE_H)
  gfx.setColor(0)
  -- draw counter
  local counterText = string.format("%03d/%03d", math.floor(frameIndex), numFrames);
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(PLAYDATE_W - 84, PLAYDATE_H - 26, 80, 22, 4)
  font:drawText(counterText, PLAYDATE_W - 80, PLAYDATE_H - 22)
  -- draw border
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(72 - 1, 16 - 1, 256 + 2, 192 + 2)
  -- draw ppm frame
  ppm:decodeFrameToBitmap(frameIndex, layer)
  layer:draw(72, 16)
end

drawFrame(1)

function playdate.update()
  if not (lastFrameIndex == frameIndex) then
    drawFrame(frameIndex)
  end
  if isPlaying then
    playdate.timer.updateTimers()
  end
end