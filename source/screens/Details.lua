local gfx <const> = playdate.graphics
local newRect <const> = playdate.geometry.rect.new

local boxGfx <const> = gfx.nineSlice.new('./gfx/shape_box', 5, 5, 2, 2)

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local BOX_W <const> = 344
local BOX_X <const> = 16
local BOX_Y <const> = 24
local BOX_PAD <const> = 16
local DETAILS_W <const> = BOX_W - (BOX_PAD * 2)
local DETAILS_X <const> = BOX_X + BOX_PAD
local DETAILS_Y <const> = BOX_Y + BOX_PAD
local DETAILS_COL_GAP <const> = 12
local TEXT_LINE_ADV <const> = 5
local HR_ADV <const> = 16
local HR_REACH <const> = 6
local HR_W <const> = DETAILS_W + HR_REACH * 2
local HR_PATTERN <const> = {0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC}

DetailsScreen = {}
class('DetailsScreen').extends(ScreenBase)

function DetailsScreen:init()
  DetailsScreen.super.init(self)
  self.inputHandlers = {}
  self.cache = nil
  self.boxRect = newRect(0, 0, 0, 0)
  self.scrollHeight = 0
  self.scrollY = 0
  self.scrollBar = Scrollbar(PLAYDATE_W - 26, BOX_Y, PLAYDATE_H - BOX_Y * 2)
  self.inputHandlers = {
    cranked = function(change, acceleratedChange)
      self.scrollY = utils:clampScroll(self.scrollY + change, 0, self.scrollHeight)
      self.scrollBar.progress = -self.scrollY / self.scrollMax
    end,
  }
end

function DetailsScreen:renderNoteDetails(ppmPath)
  local tmb = noteFs:getNoteTmb(ppmPath)
  local authorName, links = noteFs:getNoteCredits(ppmPath)
  -- details items
  local rows = {
    {locales:getText('DETAILS_AUTHOR'), authorName or stringUtils:fromWideChars(tmb.currentAuthor)},
    {locales:getText('DETAILS_AUTHOR_ID'), stringUtils:hexFromBytes(tmb.currentAuthorId, true)},
    {locales:getText('DETAILS_LINKS'), links},
    '-',
    {locales:getText('DETAILS_LAST_EDIT'), locales:getFormattedTimestamp('DETAILS_DATE_FORMAT', playdate.timeFromEpoch(tmb.timestamp, 0)) },
    {locales:getText('DETAILS_FRAME_COUNT'), tostring(tmb.numFrames + 1)},
    '-',
    {locales:getText('DETAILS_FILE_SIZE'), fsUtils:formatFileSize(tmb.ppmSize)},
    {locales:getText('DETAILS_FILE_PATH'), stringUtils:escape(tmb.path)},
    '-',
    {locales:getText('DETAILS_PREV_AUTHOR'), stringUtils:fromWideChars(tmb.previousAuthor)},
    {locales:getText('DETAILS_ORIG_AUTHOR'), stringUtils:fromWideChars(tmb.originalAuthor)},
  }
  -- initial run to measure text height
  local detailsHeight = DETAILS_Y
  local valueOffsets = table.create(#rows, 0)
  for i, row in ipairs(rows) do
    if type(row) == 'table' and row[2] ~= nil then
      local labelW, labelH = gfx.getTextSizeForMaxWidth(row[1], DETAILS_W)
      local valueW, valueH = gfx.getTextSizeForMaxWidth(row[2], DETAILS_W)
      -- if there's not enough space for row label and value on same line, move value onto the next line
      if labelW + valueW + DETAILS_COL_GAP > DETAILS_W then
        valueOffsets[i] = valueH
        detailsHeight += labelH
      end
      detailsHeight += valueH + TEXT_LINE_ADV
    elseif row == '-' then
      detailsHeight += HR_ADV
    end
  end
  -- create 
  local cache = gfx.image.new(400, detailsHeight)
  local rect = newRect(DETAILS_X, DETAILS_Y, DETAILS_W, detailsHeight)
  gfx.pushContext(cache)
  gfx.setColor(gfx.kColorBlack)
  gfx.setPattern(HR_PATTERN)
  for i, row in ipairs(rows) do
    -- draw label/value row
    if type(row) == 'table' and row[2] ~= nil then
      gfx.drawTextInRect(row[1], rect, nil, nil, kTextAlignment.left)
      -- if there's not enough space for row label and value on same line, move value onto the next line
      if type(valueOffsets[i]) == 'number' then
        rect.y += valueOffsets[i] + TEXT_LINE_ADV
      end
      local valueW, valueH = gfx.drawTextInRect(row[2], rect, nil, nil, kTextAlignment.right)
      rect.y += valueH + TEXT_LINE_ADV
    -- or draw horizontal line rule
    elseif row == '-' then
      gfx.fillRect(rect.x - HR_REACH, rect.y + 4, HR_W, 1)
      rect.y += HR_ADV
    end 
  end
  gfx.popContext()
  self.cache = cache
  self.boxRect = newRect(BOX_X, BOX_Y, BOX_W, detailsHeight)
  self.scrollHeight = self.boxRect.h + BOX_Y * 2
  self.scrollMax = self.scrollHeight - PLAYDATE_H
end

function DetailsScreen:beforeEnter(ppmPath)
  DetailsScreen.super.beforeEnter(self)
  self:renderNoteDetails(ppmPath)
end

function DetailsScreen:afterLeave()
  DetailsScreen.super.afterLeave(self)
  self.cache = nil
  self.scrollHeight = 0
  self.scrollY = 0
end

function DetailsScreen:update()
  gfx.setDrawOffset(0, 0)
  gfxUtils:drawBgGridWithOffset(self.scrollY)
  self.scrollBar:draw()
  if self.cache then
    gfx.setDrawOffset(0, self.scrollY)
    boxGfx:drawInRect(self.boxRect)
    self.cache:draw(0, 0)
  end
end