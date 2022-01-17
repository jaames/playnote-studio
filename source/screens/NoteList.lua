local gfx <const> = playdate.graphics

local pageCounterFont <const> = gfx.font.new('./fonts/WhalesharkCounter')

local bgGfx <const> = gfx.image.new('./gfx/gfx_bg_notelist')
local helpQrGfx <const> = gfx.image.new('./gfx/qr_filehelp')
local boxGfx <const> = gfx.nineSlice.new('./gfx/shape_box', 5, 5, 2, 2)

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local FOLDERSELECT_ROW = -1
local PAGE_TRANSITION_DUR <const> = 250
local THUMB_W <const> = 64
local THUMB_H <const> = 48
local GRID_GAP <const> = 16
local GRID_ROWS <const> = 3
local GRID_COLS <const> = 4
local GRID_X <const> = 48
local GRID_Y <const> = 48

NoteListScreen = {}
class('NoteListScreen').extends(ScreenBase)

function NoteListScreen:init()
  NoteListScreen.super.init(self)

  self.currPage = 1
  self.notesOnCurrPage = 0
  self.currThumbs = table.create(noteFs.notesPerPage, 0)
  self.prevThumbs = table.create(noteFs.notesPerPage, 0)
  self.hasPrevPage = false
  self.hasNoNotes = false

  self.transitionDir = 1
  self.isTransitionActive = false
  self.transitionTimer = nil
  self.xOffset = 0

  self.selectedRow = 0
  self.selectedCol = 0
  self.selectedThumb = nil

  -- setup folder select dropdown
  local folderSelect = FolderSelect(0, 0, 232, 34)
  folderSelect.variant = 'folderselect'
  local s = self
  function folderSelect:onClose(value, index)
    s.setCurrentFolder(s, value)
  end
  self.folderSelect = folderSelect

  self:setSelected(0, 0)
  
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
    AButtonDown = function()
      -- the file dropdown is selected
      if self.selectedRow == FOLDERSELECT_ROW then
        self.folderSelect:click()
        self.folderSelect:openMenu()
      -- thumbnail is selected
      else
        noteFs:setCurrentNote(self.selectedThumb.path)
        screens:push('player', transitions.kTransitionFade)
      end
    end,
  }
end

function NoteListScreen:setupMenuItems(menu)
  local detailsItem = menu:addMenuItem(locales:getText('VIEW_MENU_DETAILS'), function()
    if self.selectedThumb then
      screens:push('details', transitions.kTransitionFade, nil, self.selectedThumb.path)
    end
  end)
  return {detailsItem}
end

function NoteListScreen:beforeEnter()
  NoteListScreen.super.beforeEnter(self)
  self:setCurrentPage(self.currPage)
  -- update folderselect
  local folderSelect = self.folderSelect
  folderSelect:clearOptions()
  for _, folderItem in pairs(noteFs.folderList) do
    folderSelect:addOption(folderItem.path, folderItem.name)
  end
  folderSelect:setValue(noteFs.workingFolder)
  -- if there's no notes to display, force the folder button to be selected
  if self.notesOnCurrPage == 0 then
    self.hasNoNotes = true
    self:setSelected(FOLDERSELECT_ROW, self.selectedCol)
  end
end

function NoteListScreen:afterLeave()
  NoteListScreen.super.afterLeave(self)
  utils:clearArray(self.prevThumbs)
  utils:clearArray(self.currThumbs)
  self.hasPrevPage = false -- prevent initial transition when returning to this page
  if self.transitionTimer then
    self.transitionTimer:remove()
    self.transitionTimer = nil
  end
end

function NoteListScreen:setSelected(row, col)
  local numNotes = self.notesOnCurrPage
  if row == FOLDERSELECT_ROW or numNotes == 0 then
    self.folderSelect:select()
    self.selectedRow = FOLDERSELECT_ROW
    self.selectedThumb = nil
  else
    row = math.max(0, math.min(GRID_ROWS - 1, row))
    col = math.max(0, math.min(GRID_COLS - 1, col))
    local index = math.min((row * 4 + col) + 1, numNotes) - 1
    self.selectedRow = math.floor(index / GRID_COLS)
    self.selectedCol = index % 4
    self.folderSelect:deselect()
    local i = self.selectedRow * 4 + self.selectedCol + 1
    self.selectedThumb = self.currThumbs[i]
  end
end

function NoteListScreen:setCurrentFolder(folder)
  noteFs:setWorkingFolder(folder)
  if noteFs.hasNotes then
    self.hasNoNotes = false
    self.hasPrevPage = false
    self:setCurrentPage(1)
  else
    self.hasNoNotes = true
    utils:clearArray(self.currThumbs)
    utils:clearArray(self.prevThumbs)
    self.currThumbs = table.create(noteFs.notesPerPage, 0)
    self.prevThumbs = table.create(noteFs.notesPerPage, 0)
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
  local page = noteFs:getNotePage(pageIndex)
  -- prepare previous and current thumbnail pages for the page transition
  self.prevThumbs = self.currThumbs
  self.currThumbs = page
  self.notesOnCurrPage = #page
  -- transition time!
  if self.hasPrevPage then
    local transitionTimer = playdate.timer.new(PAGE_TRANSITION_DUR, 0, PLAYDATE_W, playdate.easingFunctions.inQuad)
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
      -- cleanup all old thumbnails
      utils:clearArray(self.prevThumbs)
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

function NoteListScreen:drawGrid(xOffset, thumbs)
  local i = 1
  for row = 0, GRID_ROWS - 1, 1 do
    for col = 0, GRID_COLS - 1, 1 do
      local x = GRID_X + xOffset + (col * THUMB_W + GRID_GAP * col)
      local y = GRID_Y + (row * THUMB_H + GRID_GAP * row)
      if thumbs[i] ~= nil then
        if self.isTransitionActive == false and self.selectedRow == row and self.selectedCol == col then
          -- selection outline
          gfx.setColor(gfx.kColorWhite)
          gfx.fillRect(x - 4, y - 4, THUMB_W + 8, THUMB_H + 8)
          gfx.setColor(gfx.kColorBlack)
          gfx.setLineWidth(2)
          gfx.drawRoundRect(x - 3, y - 3, THUMB_W + 6, THUMB_H + 6, 4)
        else
          -- shadow
          gfx.setLineWidth(1)
          gfx.setColor(gfx.kColorBlack)
          gfx.drawRect(x, y, THUMB_W + 3, THUMB_H + 3)
           -- black outer border
          gfx.drawRect(x - 2, y - 2, THUMB_W + 4, THUMB_H + 4)
          -- white inner boarder
          gfx.setColor(gfx.kColorWhite)
          gfx.drawRect(x - 1, y - 1, THUMB_W + 2, THUMB_H + 2)
        end
        -- thumbnail
        thumbs[i].bitmap:draw(x, y)
      end
      i = i + 1
    end
  end
end

function NoteListScreen:update()
  gfx.setDrawOffset(0, 0)
  -- page bg
  gfxUtils:drawBgGrid()
  bgGfx:draw(0, 0)
  -- folder select
  self.folderSelect:draw()
  -- show 'no notes available'
  if self.hasNoNotes then
    boxGfx:drawInRect(20, 52, PLAYDATE_W - 38, PLAYDATE_H - 72)
    gfx.drawTextInRect(locales:getText('VIEW_NO_FLIPNOTES'), 40, 76, 360, 200, nil, nil)
    helpQrGfx:draw(PLAYDATE_W - 134, 102)
    gfx.drawTextInRect(locales:getText('VIEW_NO_FLIPNOTES_INFO'), 40, 116, 232, 200, nil, nil)
    return
  end
  -- page counter
  local counterText = string.format('%d/%d', self.currPage, noteFs.numPages)
  gfx.setFontTracking(2)
  local w = pageCounterFont:getTextWidth(counterText)
  gfx.fillRoundRect(PLAYDATE_W - w - 28, 4, w + 28, 24, 4)
  pageCounterFont:drawTextAligned(counterText, PLAYDATE_W - 12, 8, kTextAlignment.right)
  -- grid: right transition
  if self.isTransitionActive and self.transitionDir == 1 then
    self:drawGrid(-self.xOffset,             self.prevThumbs)
    self:drawGrid(PLAYDATE_W - self.xOffset, self.currThumbs)
  -- grid: left transition 
  elseif self.isTransitionActive and self.transitionDir == -1 then
    self:drawGrid(self.xOffset,               self.prevThumbs)
    self:drawGrid(-PLAYDATE_W + self.xOffset, self.currThumbs)
  -- grid: rest state
  else
    self:drawGrid(0, self.currThumbs)
  end
end