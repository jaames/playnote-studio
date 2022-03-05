local bgGfx <const> = gfx.image.new('./gfx/gfx_bg_notelist')

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
  self.currThumbs = {}
  self.prevThumbs = {}
  self.hasPrevPage = false
  self.hasNoNotes = false

  self.transitionDir = 1
  self.isTransitionActive = false
  self.transitionTimer = nil
  self.xOffset = 0

  self.selectedRow = 0
  self.selectedCol = 0

  self.focus = FocusController(self)
  self.focus.cantMoveCallback = function(dir)
    local i = self.currPage
    if self.folderSelect.isSelected then
      return false
    end
    if dir == FocusController.kDirectionLeft then
      self:setCurrentPage(i - 1)
      return i > 1
    elseif dir == FocusController.kDirectionRight then
      self:setCurrentPage(i + 1)
      return i < noteFs.numPages
    end
  end
end

function NoteListScreen:setupSprites()
  -- setup folder select dropdown
  local folderSelect = FolderSelect(-5,-5, 260, 44)
  folderSelect.variant = 'folderselect'
  folderSelect:onClose(function (value)
    self:setCurrentFolder(value)
  end)
  self.folderSelect = folderSelect

  local counter = Counter(PLAYDATE_W - 6, 6)
  counter:setAnchor('right', 'top')
  self.counter = counter

  self.noNoteDialog = NoNoteDialog(20, 52, PLAYDATE_W - 38, PLAYDATE_H - 72)

  self.focus:setFocus(folderSelect)
  return { folderSelect, counter, self.noNoteDialog }
end

function NoteListScreen:setupMenuItems(menu)
  local detailsItem = menu:addMenuItem(locales:getText('VIEW_MENU_DETAILS'), function()
    local selectedComponent = self.focus.selection
    if getmetatable(selectedComponent) == Thumbnail then
      screens:push('details', screens.kTransitionFade, nil, selectedComponent:getPath())
    end
  end)
  return {detailsItem}
end

function NoteListScreen:beforeEnter()
  NoteListScreen.super.beforeEnter(self)
  self:setCurrentPage(self.currPage)
  -- update folderselect
  local folderSelect = self.folderSelect
  local counter = self.counter
  folderSelect:clearOptions()
  for _, folderItem in pairs(noteFs.folderList) do
    folderSelect:addOption(folderItem.path, folderItem.name)
  end
  folderSelect:setValue(noteFs.workingFolder)
  -- if there's no notes to display, force the folder button to be selected
  if self.notesOnCurrPage == 0 then
    self.hasNoNotes = true
    self.noNoteDialog.show = true
    self.focus:setFocus(self.folderSelect)
  end
  -- update counter
  counter:setTotal(noteFs.numPages)
  counter:setVisible(not self.hasNoNotes)
end

function NoteListScreen:leave()
  NoteListScreen.super.leave(self)
  self:removeThumbComponents(self.currThumbs)
  self.noNoteDialog.show = false
  self.currThumbs = {}
  self.hasPrevPage = false -- prevent initial transition when returning to this page
end

function NoteListScreen:setCurrentFolder(folder)
  noteFs:setWorkingFolder(folder)
  self:removeThumbComponents(self.currThumbs)
  self:removeThumbComponents(self.prevThumbs)
  if noteFs.hasNotes then
    self.hasNoNotes = false
    self.hasPrevPage = false
    self:setCurrentPage(1)
    self.noNoteDialog.show = false
  else
    self.hasNoNotes = true
    self.currThumbs = {}
    self.prevThumbs = {}
    self.notesOnCurrPage = 0
    self.currPage = 0
    self.noNoteDialog.show = true
    self.focus:setFocus(self.folderSelect)
  end
  self.counter:setVisible(not self.hasNoNotes)
  self.counter:setTotal(noteFs.numPages)
end

function NoteListScreen:setCurrentPage(pageIndex)
  -- navigation guard
  if self.isTransitionActive or pageIndex < 1 or pageIndex > noteFs.numPages then
    return
  end
  -- swap page
  self.prevThumbs = self.currThumbs
  self.currThumbs = {}
  -- get paths and thumbnails for the requested page
  local page = noteFs:getNotePage(pageIndex)
  self:addThumbComponents(page, self.currThumbs)
  self.notesOnCurrPage = #page
  -- transition time!
  if self.hasPrevPage then
    self.isTransitionActive = true
    self.focus.allowNavigation = false
    self.focus:setFocus(nil)

    local transitionTimer = playdate.timer.new(PAGE_TRANSITION_DUR, 0, PLAYDATE_W, playdate.easingFunctions.inQuad)
    local transitionDir = pageIndex < self.currPage and -1 or 1 -- 1 = to left, -1 to right

    if transitionDir == -1 then
      self:setThumbComponentsOffset(self.currThumbs, -PLAYDATE_W)
    end

    transitionTimer.updateCallback = function (timer)
      local x = timer.value
      if transitionDir == 1 then
        self:setThumbComponentsOffset(self.prevThumbs, -x)
        self:setThumbComponentsOffset(self.currThumbs, PLAYDATE_W - x)
      elseif transitionDir == -1 then
        self:setThumbComponentsOffset(self.prevThumbs, x)
        self:setThumbComponentsOffset(self.currThumbs, -PLAYDATE_W + x)
      end
    end

    transitionTimer.timerEndedCallback = function ()
      self:setThumbComponentsOffset(self.currThumbs, 0)
      self:removeThumbComponents(self.prevThumbs)
      -- update selection
      if transitionDir == -1 then
        self.focus:setFocus(self.currThumbs[#self.currThumbs])
      else
        self.focus:setFocus(self.currThumbs[1])
      end
      self.isTransitionActive = false
      self.focus.allowNavigation = true
    end
  end
  self.currPage = pageIndex
  self.counter:setValue(pageIndex)
  self.hasPrevPage = true
end

function NoteListScreen:addThumbComponents(tmbs, list)
  local n = #tmbs
  local i = 1
  for row = 0, GRID_ROWS - 1, 1 do
    for col = 0, GRID_COLS - 1, 1 do
      if i > n then return end
      local x = GRID_X + (col * THUMB_W + GRID_GAP * col)
      local y = GRID_Y + (row * THUMB_H + GRID_GAP * row)
      local thumb = Thumbnail(x, y, tmbs[i])
      self:addSprite(thumb)
      table.insert(list, thumb)
      i = i + 1
    end
  end
end

function NoteListScreen:removeThumbComponents(list)
  if type(list) == "table" then
    for i, thumb in ipairs(list) do
      self:removeSprite(thumb)
      list[i] = nil
    end
  end
end

function NoteListScreen:setThumbComponentsOffset(list, xOffset)
  for _, tmb in pairs(list) do
    tmb:offsetBy(xOffset, 0)
  end
end

function NoteListScreen:drawBg(x, y, w, h)
  grid:draw(x, y, w, h)
  bgGfx:draw(0, 0)
end