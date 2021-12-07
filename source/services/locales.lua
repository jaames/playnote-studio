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
  return LANGS
end

function locales:loadStringFile(languageKey)
  local path = LANGFILE_PATH .. languageKey .. '_strings.json'
  if playdate.file.exists(path) then
    return json.decodeFile(path)
  end
  print('Could not find string file for ' .. languageKey)
  return {}
end

function locales:getLanguage()
  return self.currLocale
end

function locales:setLanguage(languageKey)
  config.lang = languageKey
  self.currLocale = languageKey
  self.currStrings = locales:loadStringFile(languageKey)
  if languageKey ~= 'en' and self.fallbackStrings == nil then
    self.fallbackStrings = locales:loadStringFile('en')
  end
end

-- Get a translation string by its key
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

-- Get a translation string by its key, and use it as a formating string with the given arguments
function locales:getTextFormatted(key, ...)
  local str = self:getText(key)
  return string.format(str, ...)
end

-- Get a translation string by its key, and use it as a formating string for a date
-- date format should match the playdate.getTime()
function locales:getFormattedTimestamp(key, date)
  local year, month, day, weekday, hour, minute, second = table.unpack(date)
  local str = self:getText(key)
  str = string.gsub(str, '$YEAR', year)
  str = string.gsub(str, '$MONTH', month)
  str = string.gsub(str, '$DAY', day)
  str = string.gsub(str, '$HOUR', hour)
  str = string.gsub(str, '$MINUTE', minute)
  str = string.gsub(str, '$SECOND', second)
  return str
end

-- Replace any string keys in a peice of text that are wrapped in percent signs (e.g. `%APP_TITLE%`)
function locales:replaceKeysInText(text)
  return string.gsub(text, '%%([%w_]+)%%', self.currStrings)
end