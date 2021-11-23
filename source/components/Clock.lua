import 'CoreLibs/object'
import 'CoreLibs/graphics'

local gfx <const> = playdate.graphics
local font <const> = gfx.font.new('./fonts/ugomemo_numbers_8px')
local clockGfx <const> = gfx.image.new('./img/clock')

Clock = {}
class('Clock').extends()

function Clock:init(x, y, w, h)
  Clock.super.init(self)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.blinkOn = false
  self.dateString = ''
  self.timeString = ''
  self.lastTickTime = playdate.getCurrentTimeMilliseconds() - 1000
  self:tick()
end

function Clock:tick()
  local currTime = playdate.getCurrentTimeMilliseconds()
  if (currTime - self.lastTickTime > 1000) then
    local sep = self.blinkOn and ":" or " "
    local time = playdate.getTime()
    self.lastTickTime = currTime
    self.blinkOn = not self.blinkOn
    self.dateString = string.format("%02d/%02d/%04d", time.day, time.month, time.year)
    self.timeString = string.format("%02d%s%02d", time.hour, sep, time.minute)
  end
end

function Clock:draw()
  local x = self.x
  local y = self.y
  local w = self.w
  local h = self.h
  self:tick()
  gfx.setFont(font)
  gfx.setFontTracking(2)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(x, y, w, h)
  gfx.drawText(self.dateString, x + 8, y + 7)
  clockGfx:draw(x + 96, y + 5)
  gfx.drawText(self.timeString, x + 112, y + 7)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  gfx.drawRect(x - 1, y - 1, w, h)
end
