local BOX_W <const> = 344
local BOX_X <const> = 16
local BOX_Y <const> = 24
local MENU_GAP_TOP <const> = 24
local MENU_GAP_BOTTOM <const> = 24

DetailsScreen = {}
class('DetailsScreen').extends(ScreenBase)

function DetailsScreen:init()
  DetailsScreen.super.init(self)
  self.inputHandlers = {}
  self.scroll = ScrollController(self)
  self.scroll:useDpad()
end

function DetailsScreen:setupSprites()
  -- setup folder select dropdown
  local scrollBar = ScrollBar(PLAYDATE_W - 26, MENU_GAP_TOP, PLAYDATE_H - MENU_GAP_TOP - MENU_GAP_BOTTOM)
  self.scroll:connectScrollBar(scrollBar)

  self.list = KeyValList(BOX_X, BOX_Y, BOX_W)

  return { self.list, scrollBar  }
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
  self.scroll:setHeight(self.list.height + BOX_Y * 2)
end

function DetailsScreen:beforeEnter(ppmPath)
  self:renderNoteDetails(ppmPath)
  self.list:add()
end

function DetailsScreen:afterLeave()
  self.list:clear()
  self.scroll:setOffset(0)
end

function DetailsScreen:drawBg(x, y, w, h)
  grid:drawWithOffset(x, y, w, h, self.scroll.offset)
end

function DetailsScreen:updateTransitionIn(t, fromScreen)
  local p = playdate.easingFunctions.outQuad(t, -60, 60, 1)
  self.list:offsetByY(p)
end

function DetailsScreen:updateTransitionOut(t, toScreen)
  local p = playdate.easingFunctions.inQuad(t, 0, -60, 1)
  self.list:offsetByY(p)
end

return DetailsScreen