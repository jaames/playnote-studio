local bgGfx <const> = gfx.image.new('./gfx/gfx_bg_settings')

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
  self.scroll = ScrollController(self)
  self.scroll.selectionMode = ScrollController.kModeKeepCenter
  self.focus = FocusController(self)
end

function SettingsScreen:setupSprites()
  local scrollBar = ScrollBar(PLAYDATE_W - 26, MENU_GAP_TOP, PLAYDATE_H - MENU_GAP_TOP - MENU_GAP_BOTTOM)
  self.scroll:connectScrollBar(scrollBar)

  local layout = AutoLayout(16, 0, AutoLayout.kDirectionColumn, ITEM_WIDTH)
  self.layout = layout

  -- about button
  local about = Button(0, 0, ITEM_WIDTH, 48, locales:getText('SETTINGS_ABOUT'))
  about:setIcon('./gfx/icon_about')
  about:onClick(function ()
    dialog:show(''
      .. '*Playnote Studio*\n'
      .. 'https://playnote.studio\n'
      .. '\n'
      .. locales:getTextFormatted('ABOUT_VERSION', playdate.metadata.version) .. '\n'
      .. locales:getTextFormatted('ABOUT_BUILT_BY', 'James Daniel')
    )
  end)
  layout:add(about)

  -- credits button
  local credits = Button(0, 0, ITEM_WIDTH, 48, locales:getText('SETTINGS_CREDITS'))
  credits:setIcon('./gfx/icon_credits')
  credits:onClick(function ()
    screens:push('credits', screens.kTransitionFade)
  end)
  layout:add(credits)

  -- language select
  local language = Select(0, 0, ITEM_WIDTH, 48, locales:getText('SETTINGS_LANGUAGE'))
  language:setIcon('./gfx/icon_lang')
  for _, lang in pairs(locales:getAvailableLanguages()) do
    language:addOption(lang.key, lang.name, string.upper(lang.key))
  end
  language:setValue(locales:getLanguage())
  function language:onCloseEnded(value)
    locales:setLanguage(value)
    noteFs:refreshFolderNames()
    screens:reloadCurrent(screens.kTransitionNone)
  end
  layout:add(language)

  -- dithering button
  local dithering = Button(0, 0, ITEM_WIDTH, 48, locales:getText('SETTINGS_DITHERING'))
  dithering:setIcon('./gfx/icon_dither')
  dithering:onClick(function ()
    screens:push('dithering', screens.kTransitionFade, nil, config.dithering)
  end)
  layout:add(dithering)

  -- sound select
  local sound = Select(0, 0, ITEM_WIDTH, 48, locales:getText('SETTINGS_SOUND'))
  sound:setIcon('./gfx/icon_sound')
  sound:addOption(true,  locales:getText('SETTINGS_SOUND_ON'),  locales:getText('SETTINGS_ON'))
  sound:addOption(false, locales:getText('SETTINGS_SOUND_OFF'), locales:getText('SETTINGS_OFF'))
  sound:setValue(config.enableSoundEffects)
  function sound:onChange(value)
    config.enableSoundEffects = value
  end
  layout:add(sound)

  -- reset button
  local reset = Button(0, 0, ITEM_WIDTH, 48, locales:getText('SETTINGS_RESET'))
  reset:setIcon('./gfx/icon_reset')
  reset:onClick(function ()
    dialog:sequence({
      {type = 'confirm', message = locales:getText('SETTINGS_RESET_CONFIRM'), callback = function ()
        -- s:scrollToItemByIndex(1, true)
        config:reset()
        locales:setLanguage(config.lang)
        screens:reloadCurrent(screens.kTransitionNone)
      end},
      {type = 'alert', message = locales:getText('SETTINGS_RESET_DONE')}
    })
  end)
  layout:add(reset)

  self.scroll:setHeight(layout.height)
  self.focus:setFocus(about)

  return { scrollBar, about, credits, language, dithering, sound, reset }
end

function SettingsScreen:beforeEnter()
  SettingsScreen.super.beforeEnter(self)
end

function SettingsScreen:leave()
  SettingsScreen.super.leave(self)
  -- self.scroll:setOffset(0)
end

function SettingsScreen:enter()
  SettingsScreen.super.enter(self)
  -- self:scrollToItemByIndex(1)
end

-- function SettingsScreen:beforeEnter()
--   SettingsScreen.super.beforeEnter(self)
--   local s = self
--   -- don't let previous crank changes mess up the scrolling on this page
--   playdate.getCrankTicks(6)
--   -- set up setting items
--   local items <const> = {
--     -- ABOUT BUTTON
--     {
--       init = function(item)
--         local button = Button(0, 0, ITEM_WIDTH, 48)
--         button:setText(locales:getText('SETTINGS_ABOUT'))
--         button:setIcon(aboutGfx)
--         item.button = button
--       end,
--       draw = function(item, x, y)
--         item.button:drawAt(x, y)
--       end,
--       select = function (item)
--         item.button:select()
--       end,
--       deselect = function (item)
--         item.button:deselect()
--       end,
--       onClick = function (item)
--         item.button:click()
--         dialog:show(''
--           .. '*Playnote Studio*\n'
--           .. 'https://playnote.studio\n'
--           .. '\n'
--           .. locales:getTextFormatted('ABOUT_VERSION', playdate.metadata.version) .. '\n'
--           .. locales:getTextFormatted('ABOUT_BUILT_BY', 'James Daniel')
--         )
--       end
--     },
--     -- CREDITS BUTTON
--     {
--       init = function(item)
--         local button = Button(0, 0, ITEM_WIDTH, 48)
--         button:setText(locales:getText('SETTINGS_CREDITS'))
--         button:setIcon(creditsGfx)
--         item.button = button
--       end,
--       draw = function(item, x, y)
--         item.button:drawAt(x, y)
--       end,
--       select = function (item)
--         item.button:select()
--       end,
--       deselect = function (item)
--         item.button:deselect()
--       end,
--       onClick = function (item)
--         item.button:click()
--         screens:push('credits', screens.kTransitionFade)
--       end
--     },
--     -- LANGUAGE SELECT
--     {
--       init = function(item)
--         local select = Select(0, 0, ITEM_WIDTH, 48)
--         local langs = locales:getAvailableLanguages()
--         select:setText(locales:getText('SETTINGS_LANGUAGE'))
--         select:setIcon(langGfx)
--         for _, lang in pairs(langs) do
--           select:addOption(lang.key, lang.name, string.upper(lang.key))
--         end
--         select:setValue(locales:getLanguage())
--         function select:onCloseEnded(value)
--           locales:setLanguage(value)
--           noteFs:refreshFolderNames()
--           screens:reloadCurrent(screens.kTransitionNone)
--         end
--         item.selectButton = select
--       end,
--       draw = function(item, x, y)
--         item.selectButton:drawAt(x, y)
--       end,
--       select = function (item)
--         item.selectButton:select()
--       end,
--       deselect = function (item)
--         item.selectButton:deselect()
--       end,
--       onClick = function (item)
--         item.selectButton:click()
--         item.selectButton:openMenu()
--       end
--     },
--     -- DITHERING BUTTON
--     {
--       init = function(item)
--         local button = Button(0, 0, ITEM_WIDTH, 48)
--         button:setText(locales:getText('SETTINGS_DITHERING'))
--         button:setIcon(ditherGfx)
--         item.button = button
--       end,
--       draw = function(item, x, y)
--         item.button:drawAt(x, y)
--       end,
--       select = function (item)
--         item.button:select()
--       end,
--       deselect = function (item)
--         item.button:deselect()
--       end,
--       onClick = function (item)
--         item.button:click()
--         -- tell dithering screen to use the core dithering config
--         -- (since it call also edit dither values for specific notes)
--         screens:push('dithering', screens.kTransitionFade, nil, config.dithering)
--       end
--     },
--     -- SOUND EFFECTS ON/OFF
--     {
--       init = function(item)
--         local select = Select(0, 0, ITEM_WIDTH, 48)
--         select:setText(locales:getText('SETTINGS_SOUND'))
--         select:setIcon(soundFxGfx)
--         select:addOption(true,  locales:getText('SETTINGS_SOUND_ON'),  locales:getText('SETTINGS_ON'))
--         select:addOption(false, locales:getText('SETTINGS_SOUND_OFF'), locales:getText('SETTINGS_OFF'))
--         select:setValue(config.enableSoundEffects)
--         function select:onChange(value)
--           config.enableSoundEffects = value
--         end
--         item.selectButton = select
--       end,
--       draw = function(item, x, y)
--         item.selectButton:drawAt(x, y)
--       end,
--       select = function (item)
--         item.selectButton:select()
--       end,
--       deselect = function (item)
--         item.selectButton:deselect()
--       end,
--       onClick = function (item)
--         item.selectButton:click()
--         item.selectButton:openMenu()
--       end
--     },
--     -- RESET SETTINGS
--     {
--       init = function(item)
--         local button = Button(0, 0, ITEM_WIDTH, 48)
--         button:setText(locales:getText('SETTINGS_RESET'))
--         button:setIcon(resetGfx)
--         item.button = button
--       end,
--       draw = function(item, x, y)
--         item.button:drawAt(x, y)
--       end,
--       select = function (item)
--         item.button:select()
--       end,
--       deselect = function (item)
--         item.button:deselect()
--       end,
--       onClick = function (item)
--         item.button:click()
--         dialog:sequence({
--           {type = 'confirm', message = locales:getText('SETTINGS_RESET_CONFIRM'), callback = function ()
--             s:scrollToItemByIndex(1, true)
--             config:reset()
--             locales:setLanguage(config.lang)
--             screens:reloadCurrent(screens.kTransitionNone)
--           end},
--           {type = 'alert', message = locales:getText('SETTINGS_RESET_DONE')}
--         })
--       end
--     },
--     -- DELETE SAMPLES
--     -- {
--     --   init = function(item)
--     --     local button = Button(0, 0, ITEM_WIDTH, 48)
--     --     -- TODO: localise
--     --     button:setText('Delete Sample Notes')
--     --     button:setIcon(resetGfx)
--     --     item.button = button
--     --   end,
--     --   draw = function(item, x, y)
--     --     item.button:drawAt(x, y)
--     --   end,
--     --   select = function (item)
--     --     item.button:select()
--     --   end,
--     --   deselect = function (item)
--     --     item.button:deselect()
--     --   end,
--     --   onClick = function (item)
--     --     item.button:click()
--     --     dialog:sequence({
--     --       -- TODO: localise
--     --       {type = 'confirm', message = 'This will delete all of the sample Flipnotes from your Playdate\'s storage to save space.'},
--     --       -- TODO: localise
--     --       {type = 'confirm', message = 'Are you sure?', callback = function ()
--     --         -- TODO
--     --         print('delete notes here')
--     --       end},
--     --       -- TODO: localise
--     --       {type = 'alert', message = 'Sample Flipnotes have been deleted'}
--     --     })
--     --   end
--     -- }
--   }
--   -- init ui components
--   for _, item in pairs(items) do
--     item.init(item)
--   end
--   self.scroll:setHeight(#items * (ITEM_GAP + ITEM_HEIGHT) + MENU_GAP_TOP + MENU_GAP_BOTTOM)
--   self.scroll.range -= ITEM_GAP
--   self.numItems = #items
--   self.items = items
--   self:scrollToItemByIndex(self.activeItemIndex)
-- end

function SettingsScreen:afterLeave()
  SettingsScreen.super.afterLeave(self)
  config:save()
end

-- function SettingsScreen:scrollToItemByIndex(index, animate)
--   -- don't update if menu is transitioning to another item
--   if self.menuScrollTransitionActive then return end
--   -- ignore out of bounds option indecies
--   if index > self.numItems or index < 1 then
--     -- TODO: play 'not allowed' sound effect here
--     index = utils:clamp(index, 1, self.numItems)
--   end
--   -- deselect last item
--   local lastItem = self.items[self.activeItemIndex]
--   lastItem:deselect()
--   -- figure out how far to scroll for the selected option
--   local nextItem = self.items[index]
--   local nextItemY = nextItem.y
--   local nextOffset = -(nextItemY - (PLAYDATE_H / 2) + (ITEM_HEIGHT / 2))
--   -- do scroll
--   if animate == true then
--     self.scroll:animateToOffset(nextOffset, MENU_SCROLL_DUR, playdate.easingFunctions.outCubic)
--   else
--     self.scroll:setOffset(nextOffset)
--   end
--   -- update state
--   self.activeItemIndex = index
--   self.activeItem = nextItem
--   -- update selected item
--   nextItem:select()
-- end

-- function SettingsScreen:selectNext()
--   self:scrollToItemByIndex(self.activeItemIndex + 1, true)
-- end

-- function SettingsScreen:selectPrev()
--   self:scrollToItemByIndex(self.activeItemIndex - 1, true)
-- end

function SettingsScreen:drawBg(x, y, w, h)
  grid:drawWithOffset(x, y, w, h, self.scroll.offset)
  bgGfx:draw(0, 0)
end

function SettingsScreen:update()
  -- local crankChange = playdate.getCrankTicks(6)
  -- if crankChange ~= 0 then
  --   self:scrollToItemByIndex(self.activeItemIndex - crankChange, true)
  -- end
end