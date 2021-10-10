import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/object'

import './ScreenBase'
import '../screenManager.lua'
import '../noteManager.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local gfx <const> = playdate.graphics
local pageFont <const> = gfx.font.new('./fonts/ugomemo_numbers_8px')

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local TRANSITION_DUR <const> = 250

class('NoteListScreen').extends(ScreenBase)

function NoteListScreen:init()
  NoteListScreen.super.init(self)

  noteManager:initFs()

  self.currPage = 1
  self.currFilepaths = table.create(noteManager.notesPerPage, 0)
  self.currThumbBitmaps = table.create(noteManager.notesPerPage, 0)

  self.hasPrevPage = false
  self.prevThumbBitmaps = table.create(noteManager.notesPerPage, 0)

  self.transitionDir = 1
  self.isTransitionActive = false
  self.transitionTimer = nil
  self.xOffset = 0

  self.selectedRow = 0
  self.selectedCol = 0
  
  self.inputHandlers = {
    leftButtonDown = function()
      self.selectedCol -= 1
      if self.selectedCol < 0 then
        self:setCurrentPage(self.currPage - 1)
      end
    end,
    rightButtonDown = function()
      self.selectedCol += 1
      if self.selectedCol > 3 then
        self:setCurrentPage(self.currPage + 1)
      end
    end,
    upButtonDown = function()
      self.selectedRow -= 1
    end,
    downButtonDown = function()
      self.selectedRow += 1
    end,
    BButtonUp = function()
      screenManager:setScreen('home')
    end,
    AButtonUp = function()
      -- TODO: select note, then go to player screen
      local i = self.selectedRow * 4 + self.selectedCol + 1
      local path = self.currFilepaths[i]
      noteManager:setCurrentNote(path)
      screenManager:setScreen('player')
    end,
  }
end

function NoteListScreen:beforeEnter()
  NoteListScreen.super.beforeEnter(self)
  self:setCurrentPage(self.currPage)
end

function NoteListScreen:afterLeave()
  self.hasPrevPage = false -- prevent initial transition when returning to this page
end

function NoteListScreen:transitionEnter(t)
  if t >= 0.5 then
    self:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end

function NoteListScreen:transitionLeave(t)
  if (t < 0.5) then
    self:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
end

function NoteListScreen:setCurrentPage(pageIndex)
  if self.isTransitionActive then return end
  if pageIndex < 1 then return end
  if pageIndex > noteManager.numPages then return end
  
  local page = noteManager:getPage(pageIndex)
  -- cleanup all old bitmaps
  for i = 1, #self.prevThumbBitmaps, 1 do
    self.prevThumbBitmaps[i] = nil
  end
  -- copy curr page bitmaps, to draw them for the transition
  for i = 1, #self.currThumbBitmaps, 1 do
    self.prevThumbBitmaps[i] = self.currThumbBitmaps[i]
  end
  -- generate bitmaps for new page
  local k = 1
  for path in pairs(page) do
    local tmb = page[path]
    self.currThumbBitmaps[k] = tmb:toBitmap()
    self.currFilepaths[k] = path
    tmb = nil
    k = k + 1
  end
  -- remove any unused bitmap slots for the new page, if there wasn't enough to fill the page
  for j = k, #self.currThumbBitmaps, 1 do
    self.currThumbBitmaps[j] = nil
  end
  -- transition time!
  if self.hasPrevPage then
    local transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, PLAYDATE_W, playdate.easingFunctions.inQuad)
    self.isTransitionActive = true
    self.transitionDir = pageIndex < self.currPage and -1 or 1
    self.transitionTimer = transitionTimer
    self.xOffset = 0
    -- on timer update
    transitionTimer.updateCallback = function (timer)
      self.xOffset = timer.value
    end
    -- page transition is done
    transitionTimer.timerEndedCallback = function ()
      self.xOffset = PLAYDATE_W
      self.isTransitionActive = false
      -- wipe old bitmaps
      for i = 1, #self.prevThumbBitmaps, 1 do
        self.prevThumbBitmaps[i] = nil
      end
      if self.transitionDir == -1 then
        self.selectedCol = 3
      else
        self.selectedCol = 0
      end
    end
  end
  self.currPage = pageIndex
  self.hasPrevPage = true
end

function NoteListScreen:drawGrid(xOffset, bitmaps)
  local w <const> = 64
  local h <const> = 48
  local gap <const> = 16
  local nRows <const> = 3
  local nCols <const> = 4
  local baseX <const> = 48
  local baseY <const> = 40
  local i = 1
  for row = 0, nRows - 1, 1 do
    for col = 0, nCols - 1, 1 do
      local x = xOffset + baseX + (col * w + gap * col)
      local y = baseY + (row * h + gap * row)
      if bitmaps[i] ~= nil then
        if self.selectedRow == row and self.selectedCol == col then
          -- selection outline
          gfx.setColor(gfx.kColorWhite)
          gfx.fillRect(x - 4, y - 4, w + 8, h + 8)
          gfx.setColor(gfx.kColorBlack)
          gfx.setLineWidth(3)
          gfx.drawRoundRect(x - 5, y - 5, w + 10, h + 10, 5)
        else
          -- shadow
          gfx.setLineWidth(1)
          gfx.setColor(gfx.kColorBlack)
          gfx.drawRect(x, y, w + 3, h + 3)
           -- black outer border
          gfx.drawRect(x - 2, y - 2, w + 4, h + 4)
          -- white inner boarder
          gfx.setColor(gfx.kColorWhite)
          gfx.drawRect(x - 1, y - 1, w + 2, h + 2)
        end
        -- thumbnail
        bitmaps[i]:draw(x, y)
      end
      i = i + 1
    end
  end
end

function NoteListScreen:update()
  -- page bg
  gfxUtils:drawBgGrid()
  -- page counter
  local pageString = string.format("%d/%d", self.currPage, noteManager.numPages)
  gfx.setFont(pageFont)
  gfx.setFontTracking(2)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(PLAYDATE_W - 63, PLAYDATE_H - 23, 64, 24)
  gfx.drawText(pageString, PLAYDATE_W - 52, PLAYDATE_H - 16)
  -- grid: right transition
  if self.isTransitionActive and self.transitionDir == 1 then
    self:drawGrid(-self.xOffset, self.prevThumbBitmaps)
    self:drawGrid(400 - self.xOffset, self.currThumbBitmaps)
  -- grid: left transition 
  elseif self.isTransitionActive and self.transitionDir == -1 then
    self:drawGrid(self.xOffset, self.prevThumbBitmaps)
    self:drawGrid(-400 + self.xOffset, self.currThumbBitmaps)
  -- grid: rest state
  else
    self:drawGrid(0, self.currThumbBitmaps)
  end
end