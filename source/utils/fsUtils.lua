fsUtils = {}

local INTERNAL_FOLDERS <const> = {
  'data/',
  'fonts/',
  'img/',
  'components/',
  'screens/',
  'services/',
  'utils/',
}
local VOICED_SOUND_MARK <const> = 12441
local SEMI_VOICED_SOUND_MARK <const> = 12442

-- read a text file line by line and return it as a single string
function fsUtils:readText(path)
  local f = playdate.file.open(path, playdate.file.kFileRead)
  local text = ''
  while true do
    local line = f:readline()
    if line == nil then break end
    text = text .. line .. '\n'
  end
  f:close()
  return text
end

-- returns true if a given folder is internal
function fsUtils:isInternalFolder(name)
  return table.indexOfElement(INTERNAL_FOLDERS, name) ~= nil
end

-- fix weird hiragana/katakana encoding in filename lists
-- this will apparently be fixed in version 1.5.0
function fsUtils:fixFolderName(name)
  local i = 1
  local size = utf8.len(name)
  local res = ''
  while i <= size do
    local char = utf8.codepoint(name, utf8.offset(name, i))
    if i ~= size then
      local nextChar = utf8.codepoint(name, utf8.offset(name, i + 1))
      if nextChar == VOICED_SOUND_MARK then
        i = i + 2
        res = res .. utf8.char(char + 1)
        goto continue
      elseif nextChar == SEMI_VOICED_SOUND_MARK then
        i = i + 2
        res = res .. utf8.char(char + 2)
        goto continue
      end
    end
    i = i + 1
    res = res .. utf8.char(char)
    ::continue::
  end
  return res
end