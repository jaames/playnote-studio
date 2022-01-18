local PLAYDATE_H <const> = 240

ScrollController = {}
class('ScrollController').extends()

function ScrollController:init()
  self.start = 0
  self.offset = 0
  self.height = 0
  self.range = 0
  self.progress = 0

  self.autoScroll = false
  self.autoScrollStep = -1

  self.scrollAnimationActive = false

  self.updateCallback = function(scroll) end
end

function ScrollController:setStart(s)
  self.start = s
  self:setOffset(s)
end

function ScrollController:setHeight(h)
  self.height = h
  self.range = h - PLAYDATE_H
end

function ScrollController:setOffset(o)
  local oldOffset = self.offset
  self.offset = self:clampOffset(o)
  self.progress = -self.offset / self.range
  if not (self.offset == oldOffset) then
    self.updateCallback(self)
  end
end

function ScrollController:animateToOffset(offset, duration, easing)
  self.scrollAnimationActive = true
  local endOffset = self:clampOffset(offset)
  local timer = playdate.timer.new(duration, self.offset, endOffset, easing)
  timer.updateCallback = function ()
    self:setOffset(timer.value)
  end
  timer.timerEndedCallback = function ()
    self:setOffset(endOffset)
    self.scrollAnimationActive = false
  end
end

function ScrollController:resetOffset()
  self:setOffset(self.start)
end

function ScrollController:extendInputHandlers(handlers)
  handlers.cranked = function(c, ac)
    self:crankHandler(c, ac)
  end
  return handlers
end

function ScrollController:crankHandler(change, acceleratedChange)
  self:setOffset(self.offset + change)
  self.autoScroll = false
end

function ScrollController:update()
  if self.autoScroll then
    self:setOffset(self.offset + self.autoScrollStep)
  end
end

function ScrollController:clampOffset(pos)
  if pos <= -self.range then
    return -self.range
  elseif pos >= self.start then
    return self.start
  end
  return pos
end