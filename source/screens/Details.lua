local BOX_W <const> = 344
local BOX_X <const> = 16
local BOX_Y <const> = 24

DetailsScreen = {}
class('DetailsScreen').extends(ScreenBase)

function DetailsScreen:init()
  DetailsScreen.super.init(self)
  self.inputHandlers = {}
  self.scroll = ScrollController(self)
  self.scrollBar = ScrollBar(PLAYDATE_W - 26, BOX_Y, PLAYDATE_H - BOX_Y * 2)
  self.list = KeyValList(BOX_X, BOX_Y, BOX_W)
end

function DetailsScreen:renderNoteDetails(ppmPath)
  local list = self.list
  local tmb = noteFs:getNoteTmb(ppmPath)
  local authorName, links = noteFs:getNoteCredits(ppmPath)
  -- details items
  list:clear()
  list:addRow(locales:getText('DETAILS_AUTHOR'), authorName or stringUtils:fromWideChars(tmb.currentAuthor))
  list:addRow(locales:getText('DETAILS_AUTHOR_ID'), stringUtils:hexFromBytes(tmb.currentAuthorId, true))
  list:addRow(locales:getText('DETAILS_LINKS'), links)
  list:addBreak()
  list:addRow(locales:getText('DETAILS_LAST_EDIT'), locales:getFormattedTimestamp('DETAILS_DATE_FORMAT', playdate.timeFromEpoch(tmb.timestamp, 0)))
  list:addRow(locales:getText('DETAILS_FRAME_COUNT'), tostring(tmb.numFrames + 1))
  list:addBreak()
  list:addRow(locales:getText('DETAILS_FILE_SIZE'), fsUtils:formatFileSize(tmb.ppmSize))
  list:addRow(locales:getText('DETAILS_FILE_PATH'), stringUtils:escape(tmb.path))
  list:addBreak()
  list:addRow(locales:getText('DETAILS_PREV_AUTHOR'), stringUtils:fromWideChars(tmb.previousAuthor))
  list:addRow(locales:getText('DETAILS_ORIG_AUTHOR'), stringUtils:fromWideChars(tmb.originalAuthor))
  -- initial run to measure text height
  self.scroll:setHeight(self.list.h + BOX_Y * 2)
end

function DetailsScreen:beforeEnter(ppmPath)
  DetailsScreen.super.beforeEnter(self)
  self:renderNoteDetails(ppmPath)
  self.list:add()
end

function DetailsScreen:afterLeave()
  DetailsScreen.super.afterLeave(self)
  self.list:clear()
  self.list:remove()
  self.scroll:setOffset(0)
end

-- function DetailsScreen:update()
--   gfx.setDrawOffset(0, 0)
--   gfxUtils:drawBgGridWithOffset(self.scroll.offset)
--   self.scrollBar:draw()
--   gfx.setDrawOffset(0, self.scroll.offset)
--   -- self.list:draw(0, 0)
-- end