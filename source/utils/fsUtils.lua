fsUtils = {}

-- read a text file line by line and return it as a single string
function fsUtils:readText(path)
  local f = playdate.file.open(path, playdate.file.kFileRead)
  local size = playdate.file.getSize(path)
  local text = f:read(size)
  f:close()
  return text
end

local INTERNAL_FOLDERS <const> = {
  -- Playdate data
  'Screenshots/',
  -- internal contents
  'data/',
  'fonts/',
  'gfx/',
  'ui/',
  'controllers/',
  'sounds/',
  'components/',
  'screens/',
  'services/',
  'utils/',
}

-- returns true if a given folder is internal
function fsUtils:isInternalFolder(name)
  return table.indexOfElement(INTERNAL_FOLDERS, name) ~= nil
end

-- return size of file formatted in a human readable way
function fsUtils:formatFileSize(nBytes)
  if not nBytes or nBytes == 0 then
    return 'Nil'
  end
  local k = 1000
  local units = locales:getArray('FILESIZE_UNITS')
  local exp = math.floor(math.log(nBytes) / math.log(k))
  return string.format('%.1f %s', nBytes / (k ^ exp), units[exp + 1]);
end

local VOICED_SOUND_MARK <const> = 12441
local SEMI_VOICED_SOUND_MARK <const> = 12442

-- fix weird hiragana/katakana encoding in filename lists
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