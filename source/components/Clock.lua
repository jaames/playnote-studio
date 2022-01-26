local font <const> = gfx.font.new('./fonts/UgoNumber_8')
local clockGfx <const> = gfx.image.new('./gfx/icon_clock')

Clock = {}
class('Clock').extends(playdate.graphics.sprite)

function Clock:init(x, y, w, h)
  self:moveTo(x, y)
  self:setSize(w, h)
  self:setCenter(0, 0)
  self:setZIndex(100)
  self.blinkOn = false
  self.dateString = ''
  self.timeString = ''
  self:tick()
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
  playdate.timer.performAfterDelay(1000, self.tick, self)
end

function Clock:draw()
  local w = self.width
  local h = self.height
  gfx.setClipRect(-2, -2, w + 4, h + 4)
  gfx.setFontTracking(1)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, w, h)
  font:drawText(self.dateString, 8, 7)
  clockGfx:draw(90, 5)
  font:drawText(self.timeString, 106, 7)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  gfx.drawRect(-1, -1, w, h)
end
