Clock = {}
class('Clock').extends(ComponentBase)

function Clock:init(x, y, w, h)
  Clock.super.init(self, x-1, y-1, w, h)
  self.blinkOn = false
  self.dateString = ''
  self.timeString = ''
  self.isRunning = true
  self.font = nil
  self.clockGfx = nil
  self:setOpaque(true)
end

function Clock:tick()
  local currTime = playdate.getCurrentTimeMilliseconds()
  local time = playdate.getTime()
  local dateFormat = locales:getText('CLOCK_DATE_FORMAT')
  local timeFormat = self.blinkOn and '${HOUR}:${MINUTE}' or '${HOUR} ${MINUTE}'
  local dateStr, timeStr = stringUtils:formatTimeMultiple(time, dateFormat, timeFormat)
  self.lastTickTime = currTime
  self.blinkOn = not self.blinkOn
  self.dateString = dateStr
  self.timeString = timeStr
  self:markDirty()
  if self.isRunning then
    playdate.timer.performAfterDelay(1000, self.tick, self)
  end
end

function Clock:addedToScreen()
  self.isRunning = true
  self.font = gfx.font.new('./fonts/UgoNumber_8')
  self.clockGfx = gfx.image.new('./gfx/icon_clock')
  self:tick()
end

function Clock:removedFromScreen()
  self.isRunning = false
  self.font = nil
  self.clockGfx = nil
end

function Clock:draw()
  local w = self.width
  local h = self.height
  gfx.setFontTracking(1)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, w, h)
  self.font:drawText(self.dateString, 10, 10)
  self.clockGfx:draw(92, 7)
  self.font:drawText(self.timeString, 108, 10)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  gfx.drawRect(1, 1, w-1, h-1)
end
