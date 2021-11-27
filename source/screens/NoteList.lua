import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'CoreLibs/object'

import './ScreenBase'
import '../components/FolderSelect.lua'
import '../services/screens.lua'
import '../services/noteFs.lua'
import '../gfxUtils.lua'
import '../utils.lua'

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local FOLDERSELECT_ROW = -1
local gfx <const> = playdate.graphics
local baseFont <const> = gfx.font.new('./fonts/WhalesharkSans')
local pageCounterFont <const> = gfx.font.new('./fonts/UgoNumber_8')

local TRANSITION_DUR <const> = 250

NoteListScreen = {}
class('NoteListScreen').extends(ScreenBase)

function NoteListScreen:init()
  NoteListScreen.super.init(self)

  noteFs:initFs()

  self.currPage = 1
  self.currFilepaths = table.create(noteFs.notesPerPage, 0)
  self.currThumbBitmaps = table.create(noteFs.notesPerPage, 0)
  self.notesOnCurrPage = 0

  self.hasPrevPage = false
  self.hasNoNotes = false
  self.prevThumbBitmaps = table.create(noteFs.notesPerPage, 0)

  self.transitionDir = 1
  self.isTransitionActive = false
  self.transitionTimer = nil
  self.xOffset = 0

  self.selectedRow = 0
  self.selectedCol = 0
  
  self.inputHandlers = {
    leftButtonDown = function()
      if self.selectedCol == 0 then
        self:setCurrentPage(self.currPage - 1)
      else
        self:setSelected(self.selectedRow, self.selectedCol - 1)
      end
    end,
    rightButtonDown = function()
      if self.selectedCol == 3 then
        self:setCurrentPage(self.currPage + 1)
      else
        self:setSelected(self.selectedRow, self.selectedCol + 1)
      end
    end,
    upButtonDown = function()
      self:setSelected(self.selectedRow - 1, self.selectedCol)
    end,
    downButtonDown = function()
      self:setSelected(self.selectedRow + 1, self.selectedCol)
    end,
    BButtonDown = function()
      screenManager:setScreen('home', screenManager.CROSSFADE)
    end,
    AButtonDown = function()
      -- the file dropdown is selected
      if self.selectedRow == FOLDERSELECT_ROW then
        self.folderSelect:openMenu()
      else
        local i = self.selectedRow * 4 + self.selectedCol + 1
        local path = self.currFilepaths[i]
        noteFs:setCurrentNote(path)
        screenManager:setScreen('player', screenManager.CROSSFADE)
      end
    end,
  }
end

function NoteListScreen:beforeEnter()
  NoteListScreen.super.beforeEnter(self)
  self:setCurrentPage(self.currPage)
  -- setup folder select dropdown
  local folderSelect = FolderSelect(-4, -4, 220, 36)
  local s = self
  function folderSelect:onClose (value, index)
    s.setCurrentFolder(s, value)
  end
  for key, name in pairs(noteFs.folderList) do
    folderSelect:addOption(key, name)
  end
  folderSelect:setValue(noteFs.currentFolder)

  self.folderSelect = folderSelect
end

function NoteListScreen:afterLeave()
  NoteListScreen.super.afterLeave(self)
  self.hasPrevPage = false -- prevent initial transition when returning to this page
  if self.transitionTimer then
    self.transitionTimer:remove()
    self.transitionTimer = nil
  end
end

function NoteListScreen:setSelected(row, col)
  local numNotes = self.notesOnCurrPage
  if row == FOLDERSELECT_ROW or numNotes == 0 then
    self.folderSelect.isSelected = true
    self.selectedRow = FOLDERSELECT_ROW
  else
    row = math.max(0, math.min(2, row))
    col = math.max(0, math.min(3, col))
    local index = math.min((row * 4 + col) + 1, numNotes) - 1
    self.selectedRow = math.floor(index / 4)
    self.selectedCol = index % 4
    self.folderSelect.isSelected = false
  end
end

function NoteListScreen:setCurrentFolder(folder)
  noteFs:setDirectory(folder)
  if noteFs.hasNotes then
    self.hasNoNotes = false
    self.hasPrevPage = false
    self:setCurrentPage(1)
  else
    self.hasNoNotes = true
    self.currThumbBitmaps = {}
    self.currFilepaths = {}
    self.notesOnCurrPage = 0
    self.currPage = 0
    self:setSelected(FOLDERSELECT_ROW, 0) -- only the folder select button can be active
  end
end

function NoteListScreen:setCurrentPage(pageIndex)
  -- navigation guard
  if self.isTransitionActive or pageIndex < 1 or pageIndex > noteFs.numPages then 
    return
  end
  -- get paths and thumbnails for the requested page
  local page = noteFs:getPage(pageIndex)
  -- cleanup all old bitmaps
  for i = 1, #self.prevThumbBitmaps, 1 do
    self.prevThumbBitmaps[i] = nil
  end
  -- copy curr page bitmaps, to draw them for the transition
  for i = 1, #self.currThumbBitmaps, 1 do
    self.prevThumbBitmaps[i] = self.currThumbBitmaps[i]
  end
  -- generate bitmaps for new page
  local j = 1
  for path in pairs(page) do
    local tmb = page[path]
    self.currThumbBitmaps[j] = tmb:toBitmap()
    self.currFilepaths[j] = path
    tmb = nil
    j = j + 1
  end
  -- notes on page used for nagivation
  self.notesOnCurrPage = j - 1
  -- remove any unused bitmap slots for the new page, if there wasn't enough to fill the page
  for k = j, #self.currThumbBitmaps, 1 do
    self.currThumbBitmaps[k] = nil
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
      self.prevThumbBitmaps = table.create(noteFs.notesPerPage, 0)
      -- update selection
      if self.transitionDir == -1 then
        self:setSelected(self.selectedRow, 3)
      else
        self:setSelected(self.selectedRow, 0)
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
  -- folder select
  self.folderSelect:draw()
  -- show "no notes available"
  if self.hasNoNotes then
    -- TODO: prettier UI
    gfx.setFont(baseFont)
    gfx.drawTextInRect("There's no Flipnotes in this folder.", 0, 80, 400, 40, nil, nil, kTextAlignment.center)
  end
  -- page counter
  local pageString = string.format("%d/%d", self.currPage, noteFs.numPages)
  gfx.setFont(pageCounterFont)
  gfx.setFontTracking(2)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(PLAYDATE_W - 63, PLAYDATE_H - 23, 64, 24)
  gfx.drawText(pageString, PLAYDATE_W - 52, PLAYDATE_H - 16)
  -- grid: right transition
  if self.isTransitionActive and self.transitionDir == 1 then
    self:drawGrid(-self.xOffset, self.prevThumbBitmaps)
    self:drawGrid(PLAYDATE_W - self.xOffset, self.currThumbBitmaps)
  -- grid: left transition 
  elseif self.isTransitionActive and self.transitionDir == -1 then
    self:drawGrid(self.xOffset, self.prevThumbBitmaps)
    self:drawGrid(-PLAYDATE_W + self.xOffset, self.currThumbBitmaps)
  -- grid: rest state
  else
    self:drawGrid(0, self.currThumbBitmaps)
  end
end