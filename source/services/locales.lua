local LANGFILE_PATH <const> = '/data/'
local LANGS <const> = json.decodeFile(LANGFILE_PATH .. 'lang.json')

locales = {}

locales.currLocale = nil
locales.currStrings = {}
locales.fallbackStrings = nil

function locales:init()
  self:setLanguage(config.lang)
end

function locales:getAvailableLanguages()
  local t = {}
  for _, loc in ipairs(LANGS) do
    t[loc['key']] = loc['name']
  end
  return t
end

function locales:loadStringFile(languageKey)
  local path = LANGFILE_PATH .. languageKey .. '_strings.json'
  if playdate.file.exists(path) then
    return json.decodeFile(path)
  end
  print('Could not find string file for ' .. languageKey)
  return {}
end

function locales:setLanguage(languageKey)
  self.currLocale = languageKey
  self.currStrings = locales:loadStringFile(languageKey)
  if languageKey ~= 'en' and self.fallbackStrings == nil then
    self.fallbackStrings = locales:loadStringFile('en')
  end
end

function locales:getText(stringKey)
  local currStrings = self.currStrings
  local fallbackStrings = self.fallbackStrings
  if currStrings[stringKey] ~= nil then
    return currStrings[stringKey]
  elseif fallbackStrings ~= nil and fallbackStrings[stringKey] ~= nil then
    print('Using translation fallback string for ' .. stringKey)
    return fallbackStrings[stringKey]
  end
  print('Could not find translation string for ' .. stringKey)
  return stringKey
end

function locales:replaceKeysInText(text)
  return string.gsub(text, '%%([%w_]+)%%', self.currStrings)
end

function locales:getTextFormatted(key, ...)
  local str = self:getText(key)
  return string.format(str, ...)
end

-- function locales:getFormattedTimestamp(key, date)
--   local str = self:getText(key)
-- end