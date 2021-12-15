local gfx <const> = playdate.graphics

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
      local row = self.uiView:getSelectedRow()
      local item = self.items[row]
      item:onClick(item)
    end,
    cranked = function(change, acceleratedChange)
      local x, y = self.uiView:getScrollPosition()
      self.uiView:setScrollPosition(x, y - change, false)
    end,
  }
end

function SettingsScreen:beforeEnter()
  SettingsScreen.super.beforeEnter(self)
  self.selectedItem = nil
  local scr = self
  -- set up setting items
  local items <const> = {
    -- ABOUT BUTTON
    {
      init = function(item)
        local button = Button(0, 0, 336, 48)
        button:setText(locales:getText('SETTINGS_ABOUT'))
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button.isSelected = true
      end,
      deselect = function (item)
        item.button.isSelected = false
      end,
      onClick = function (item)
        local aboutText = ''
          .. '*Playnote Studio*\n'
          .. 'https://playnote.studio\n'
          .. '\n'
          .. locales:getTextFormatted('ABOUT_VERSION', playdate.metadata.version) .. '\n'
          .. locales:getTextFormatted('ABOUT_BUILT_BY', 'James Daniel')
        dialog:show(aboutText)
      end
    },
    -- CREDITS BUTTON
    {
      init = function(item)
        local button = Button(0, 0, 336, 48)
        button:setText(locales:getText('SETTINGS_CREDITS'))
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button.isSelected = true
      end,
      deselect = function (item)
        item.button.isSelected = false
      end,
      onClick = function (item)
        screens:push('credits', transitions.CROSSFADE)
      end
    },
    -- DITHERING BUTTON
    {
      init = function(item)
        local button = Button(0, 0, 336, 48)
        button:setText(locales:getText('SETTINGS_DITHERING'))
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button.isSelected = true
      end,
      deselect = function (item)
        item.button.isSelected = false
      end,
      onClick = function (item)
        screens:push('dithering', transitions.CROSSFADE)
      end
    },
    -- SOUND EFFECTS ON/OFF
    {
      init = function(item)
        local select = Select(0, 0, 336, 48)
        select:setText(locales:getText('SETTINGS_SOUND'))
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
        item.selectButton.isSelected = true
      end,
      deselect = function (item)
        item.selectButton.isSelected = false
      end,
      onClick = function (item)
        item.selectButton:openMenu()
      end
    },
    -- LANGUAGE SELECT
    {
      init = function(item)
        local select = Select(0, 0, 336, 48)
        local langs = locales:getAvailableLanguages()
        select:setText(locales:getText('SETTINGS_LANGUAGE'))
        for i, lang in ipairs(langs) do
          select:addOption(lang.key, lang.name, string.upper(lang.key))
        end
        select:setValue(locales:getLanguage())
        function select:onClose(value)
          locales:setLanguage(value)
          noteFs:updateFolderNames() -- update folder name list
          -- todo: wait until select menu is closed, keep selection state, reload w transition
          scr:reload()
        end
        item.selectButton = select
      end,
      draw = function(item, x, y)
        item.selectButton:drawAt(x, y)
      end,
      select = function (item)
        item.selectButton.isSelected = true
      end,
      deselect = function (item)
        item.selectButton.isSelected = false
      end,
      onClick = function (item)
        item.selectButton:openMenu()
      end
    },
    -- RESET SETTINGS
    {
      init = function(item)
        local button = Button(0, 0, 336, 48)
        button:setText(locales:getText('SETTINGS_RESET'))
        item.button = button
      end,
      draw = function(item, x, y)
        item.button:drawAt(x, y)
      end,
      select = function (item)
        item.button.isSelected = true
      end,
      deselect = function (item)
        item.button.isSelected = false
      end,
      onClick = function (item)
        dialog.handleClose = function ()
          config:reset()
          SettingsScreen:reload()
        end
        dialog:confirm(locales:getText('SETTINGS_RESET_CONFIRM'))
      end
    }
  }
  -- init ui components
  for _, item in pairs(items) do
    item.init(item)
  end
  -- set up settings ui view
  local uiView <const> = playdate.ui.gridview.new(336, 48)
  uiView:setNumberOfRows(#items)
  uiView:setContentInset(28, 28, 12, 12)
  uiView:setCellPadding(4, 4, 4, 4)
  
  self.items = items
  self.uiView = uiView
  self:_updateSelectedItem(1)

  function uiView:drawCell(section, row, column, selected, x, y, width, height)
    local item <const> = items[row]
    playdate.graphics.setClipRect(0, 0, 400, 240)
    item.draw(item, x, y)
  end
end

function SettingsScreen:selectNext()
  self.uiView:selectNextRow(false, true)
  local i = self.uiView:getSelectedRow()
  self:_updateSelectedItem(i)
end

function SettingsScreen:selectPrev()
  self.uiView:selectPreviousRow(false, true)
  local i = self.uiView:getSelectedRow()
  self:_updateSelectedItem(i)
end

function SettingsScreen:_updateSelectedItem(i)
  local curr = self.selectedItem
  if curr ~= nil then
    curr.deselect(curr)
  end
  local next = self.items[i]
  if next ~= nil then
    next.select(next)
    self.selectedItem = next
  end
end

function SettingsScreen:afterLeave()
  SettingsScreen.super.afterLeave(self)
  -- autosave on leave
  config:save()
  -- free ui items
  self.items = nil
  self.uiView = nil
end

function SettingsScreen:update()
  gfx.setDrawOffset(0, 0)
  gfxUtils:drawBgGridWithOffset(0)
  self.uiView:drawInRect(0, 0, 400, 240)
end