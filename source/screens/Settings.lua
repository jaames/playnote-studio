local gfx <const> = playdate.graphics

local aboutGfx <const> =   gfx.image.new('./gfx/icon_about')
local creditsGfx <const> = gfx.image.new('./gfx/icon_credits')
local ditherGfx <const> =  gfx.image.new('./gfx/icon_dither')
local soundFxGfx <const> = gfx.image.new('./gfx/icon_sound')
local langGfx <const> =    gfx.image.new('./gfx/icon_lang')
local resetGfx <const> =   gfx.image.new('./gfx/icon_reset')

local bgGfx <const> = gfx.image.new('./gfx/gfx_bg_settings')

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local ITEM_GAP <const> = 12
local ITEM_WIDTH <const> = 300
local ITEM_HEIGHT <const> = 48
local MENU_X <const> = (PLAYDATE_W / 2) - (ITEM_WIDTH / 2)
local MENU_GAP_TOP <const> = 24
local MENU_GAP_BOTTOM <const> = 24
local MENU_MID <const> = (PLAYDATE_H / 2) - ITEM_HEIGHT
local MENU_SCROLL_DUR = 200

SettingsScreen = {}
class('SettingsScreen').extends(ScreenBase)

function SettingsScreen:init()
  SettingsScreen.super.init(self)
  self.inputHandlers = {
    upButtonDown = function ()
      self:selectPrev()
    end,
    downButtonDown = function ()
      self:selectNext()
    end,
    AButtonDown = function()
      local item = self.items[self.activeItemIndex]
      item:onClick(item)
    end
  }
  self.scrollBar = Scrollbar(PLAYDATE_W - 26, MENU_GAP_TOP, PLAYDATE_H - MENU_GAP_TOP - MENU_GAP_BOTTOM)
  self.menuScroll = 0
  self.menuHeight = 0
  self.menuScrollTransitionActive = false
  self.activeItemIndex = 1
end

function SettingsScreen:beforeEnter()
  SettingsScreen.super.beforeEnter(self)
  local s = self
  -- set up setting items
  local items <const> = {
    -- ABOUT BUTTON
    {
      init = function(item)
        local button = Button(0, 0, ITEM_WIDTH, 48)
        button:setText(locales:getText('SETTINGS_ABOUT'))
        button:setIcon(aboutGfx)
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button:select()
      end,
      deselect = function (item)
        item.button:deselect()
      end,
      onClick = function (item)
        item.button:click()
        dialog:show(''
          .. '*Playnote Studio*\n'
          .. 'https://playnote.studio\n'
          .. '\n'
          .. locales:getTextFormatted('ABOUT_VERSION', playdate.metadata.version) .. '\n'
          .. locales:getTextFormatted('ABOUT_BUILT_BY', 'James Daniel')
        )
      end
    },
    -- CREDITS BUTTON
    {
      init = function(item)
        local button = Button(0, 0, ITEM_WIDTH, 48)
        button:setText(locales:getText('SETTINGS_CREDITS'))
        button:setIcon(creditsGfx)
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button:select()
      end,
      deselect = function (item)
        item.button:deselect()
      end,
      onClick = function (item)
        item.button:click()
        screens:push('credits', transitions.CROSSFADE)
      end
    },
    -- LANGUAGE SELECT
    {
      init = function(item)
        local select = Select(0, 0, ITEM_WIDTH, 48)
        local langs = locales:getAvailableLanguages()
        select:setText(locales:getText('SETTINGS_LANGUAGE'))
        select:setIcon(langGfx)
        for _, lang in pairs(langs) do
          select:addOption(lang.key, lang.name, string.upper(lang.key))
        end
        select:setValue(locales:getLanguage())
        function select:onCloseEnded(value)
          locales:setLanguage(value)
          noteFs:updateFolderNames()
          screens:reloadCurrent(transitions.NONE)
        end
        item.selectButton = select
      end,
      draw = function(item, x, y)
        item.selectButton:drawAt(x, y)
      end,
      select = function (item)
        item.selectButton:select()
      end,
      deselect = function (item)
        item.selectButton:deselect()
      end,
      onClick = function (item)
        item.selectButton:click()
        item.selectButton:openMenu()
      end
    },
    -- DITHERING BUTTON
    {
      init = function(item)
        local button = Button(0, 0, ITEM_WIDTH, 48)
        button:setText(locales:getText('SETTINGS_DITHERING'))
        button:setIcon(ditherGfx)
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button:select()
      end,
      deselect = function (item)
        item.button:deselect()
      end,
      onClick = function (item)
        item.button:click()
        screens:push('dithering', transitions.CROSSFADE)
      end
    },
    -- SOUND EFFECTS ON/OFF
    {
      init = function(item)
        local select = Select(0, 0, ITEM_WIDTH, 48)
        select:setText(locales:getText('SETTINGS_SOUND'))
        select:setIcon(soundFxGfx)
        select:addOption(true,  locales:getText('SETTINGS_SOUND_ON'),  locales:getText('SETTINGS_ON'))
        select:addOption(false, locales:getText('SETTINGS_SOUND_OFF'), locales:getText('SETTINGS_OFF'))
        select:setValue(config.enableSoundEffects)
        function select:onChange(value)
          config.enableSoundEffects = value
        end
        item.selectButton = select
      end,
      draw = function(item, x, y)
        item.selectButton:drawAt(x, y)
      end,
      select = function (item)
        item.selectButton:select()
      end,
      deselect = function (item)
        item.selectButton:deselect()
      end,
      onClick = function (item)
        item.selectButton:click()
        item.selectButton:openMenu()
      end
    },
    -- RESET SETTINGS
    {
      init = function(item)
        local button = Button(0, 0, ITEM_WIDTH, 48)
        button:setText(locales:getText('SETTINGS_RESET'))
        button:setIcon(resetGfx)
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button:select()
      end,
      deselect = function (item)
        item.button:deselect()
      end,
      onClick = function (item)
        item.button:click()
        dialog:sequence({
          {type = 'confirm', message = locales:getText('SETTINGS_RESET_CONFIRM')},
          -- TODO: localise
          {type = 'confirm', message = 'Are you sure?', callback = function ()
            s:scrollToItemByIndex(1, true)
            config:reset()
            locales:setLanguage(config.lang)
            screens:reloadCurrent(transitions.NONE)
          end},
          -- TODO: localise
          {type = 'alert', message = 'Settings have been cleared.'}
        })
      end
    },
    -- DELETE SAMPLES
    {
      init = function(item)
        local button = Button(0, 0, ITEM_WIDTH, 48)
        -- TODO: localise
        button:setText('Delete Sample Notes')
        button:setIcon(resetGfx)
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button:select()
      end,
      deselect = function (item)
        item.button:deselect()
      end,
      onClick = function (item)
        item.button:click()
        dialog:sequence({
          -- TODO: localise
          {type = 'confirm', message = 'This will delete all of the sample Flipnotes from your Playdate\'s storage to save space.'},
          -- TODO: localise
          {type = 'confirm', message = 'Are you sure?', callback = function ()
            -- TODO
            print('delete notes here')
          end},
          -- TODO: localise
          {type = 'alert', message = 'Sample Flipnotes have been deleted'}
        })
      end
    }
  }
  -- init ui components
  for _, item in pairs(items) do
    item.init(item)
  end

  self.menuHeight = #items * (ITEM_GAP + ITEM_HEIGHT) + MENU_GAP_TOP + MENU_GAP_BOTTOM
  self.numItems = #items
  self.items = items
  self.scrollMax = self.menuHeight - PLAYDATE_H - ITEM_GAP
  self:scrollToItemByIndex(self.activeItemIndex)
end

function SettingsScreen:afterLeave()
  SettingsScreen.super.afterLeave(self)
  -- autosave on leave
  config:save()
  -- free ui items
  self.items = nil
end

function SettingsScreen:scrollToItemByIndex(index, animate)
  -- don't update if menu is transitioning to another item
  if self.menuScrollTransitionActive then return end
  -- ignore out of bounds option indecies
  if index > self.numItems or index < 1 then
    -- TODO: play 'not allowed' sound effect here
    index = utils:clamp(index, 1, self.numItems)
  end
  -- deselect last item
  local lastItem = self.items[self.activeItemIndex]
  lastItem.deselect(lastItem)
  -- figure out how far to scroll for the selected option
  local currScroll = self.menuScroll
  local nextItemY = (index - 1) * (ITEM_HEIGHT + ITEM_GAP)
  local nextScroll = utils:clamp(nextItemY - MENU_MID, 0, self.scrollMax)
  -- scroll with animation
  if animate == true then
    self.menuScrollTransitionActive = true
    local timer = playdate.timer.new(MENU_SCROLL_DUR, currScroll, nextScroll, playdate.easingFunctions.outCubic)
    timer.updateCallback = function ()
      self:setScroll(timer.value)
    end
    timer.timerEndedCallback = function ()
      self:setScroll(nextScroll)
      self.menuScrollTransitionActive = false
    end
  -- or not
  else
    self:setScroll(nextScroll)
  end
  -- update state
  self.activeItemIndex = index
  self.activeItem = self.items[index]
  -- update selected item
  local currItem = self.activeItem
  currItem.select(currItem)
end

function SettingsScreen:setScroll(pos)
  self.menuScroll = pos
  self.scrollBar.progress = pos / self.scrollMax
end

function SettingsScreen:selectNext()
  self:scrollToItemByIndex(self.activeItemIndex + 1, true)
end

function SettingsScreen:selectPrev()
  self:scrollToItemByIndex(self.activeItemIndex - 1, true)
end

function SettingsScreen:update()
  gfx.setDrawOffset(0, 0)
  gfxUtils:drawBgGridWithOffset(self.menuScroll)
  bgGfx:draw(0, 0)
  self.scrollBar:draw()
  local y = 0 - self.menuScroll + MENU_GAP_TOP
  for _, item in pairs(self.items) do
    if y < -ITEM_HEIGHT then
      goto nextItem
    elseif y > PLAYDATE_H then
      break
    else
      item.draw(item, MENU_X, y)
    end
    ::nextItem::
    y = y + ITEM_GAP + ITEM_HEIGHT
  end
  -- use crank to scroll through items
  local crankChange = playdate.getCrankTicks(6)
  if crankChange ~= 0 then
    self:scrollToItemByIndex(self.activeItemIndex + crankChange, true)
  end
end