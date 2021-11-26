import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/ui'

import './ScreenBase'
import '../services/screens.lua'
import '../services/config.lua'
import '../services/dialog.lua'
import '../gfxUtils.lua'

import '../components/Button.lua'
import '../components/Select.lua'

local gfx <const> = playdate.graphics

SettingsScreen = {}
class('SettingsScreen').extends(ScreenBase)

function SettingsScreen:init()
  SettingsScreen.super.init(self)
  -- init config file, makes self.config available
  configManager:init()
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
    BButtonDown = function()
      screenManager:setScreen('home', screenManager.CROSSFADE)
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
  -- set up setting items
  local items <const> = {
    -- ABOUT BUTTON
    {
      init = function(item)
        local button = Button(0, 0, 336, 48)
        button:setText('About')
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
          .. 'Version ' .. playdate.metadata.version .. '\n'
          .. 'Built by James Daniel'
        dialogManager:show(aboutText)
      end
    },
    -- CREDITS BUTTON
    {
      init = function(item)
        local button = Button(0, 0, 336, 48)
        button:setText('Credits')
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
        screenManager:setScreen('credits', screenManager.CROSSFADE)
      end
    },
    -- SOUND EFFECTS ON/OFF
    {
      init = function(item)
        local select = Select(0, 0, 336, 48)
        select:setText('Sound Effects')
        select:addOption(true,  'Sound Effects On',  'On')
        select:addOption(false, 'Sound Effects Off', 'Off')
        select:setValue(configManager.enableSoundEffects)
        function select:onChange(value)
          configManager.enableSoundEffects = value
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
        select:setText('Language')
        select:addOption('en',    'English (American)', 'EN US')
        select:addOption('en_gb', 'English (British)',  'EN GB')
        select:addOption('fr',    'Francais',           'FR')
        select:addOption('es',    'Espanol',            'ES')
        select:addOption('jp',    '日本語',              'JP')
        select:setValue(configManager.lang)
        function select:onChange(value)
          configManager.lang = value
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
        button:setText('Reset Settings')
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
        dialogManager.handleClose = function ()
          configManager:reset()
          self:beforeEnter()
        end
        dialogManager:confirm('*Settings will be cleared*')
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
  configManager:save()
  -- free ui items
  self.items = nil
  self.uiView = nil
end

function SettingsScreen:update()
  gfx.setDrawOffset(0, 0)
  gfxUtils:drawBgGridWithOffset(0)
  self.uiView:drawInRect(0, 0, 400, 240)
end