fsUtils = {}

local PDX_FILENAME = nil
local PDX_FOLDERS <const> = {
  -- Playdate data
  'Screenshots/',
  -- internal folders (MAKE SURE TO UPDATE THIS LIST WHEN ADDING NEW FOLDERS)
  'samplememo/',
  'data/',
  'fonts/',
  'gfx/',
  'ui/',
  'controllers/',
  'sounds/',
  'components/',
  'scenes/',
  'services/',
  'utils/',
}

-- read a text file line by line and return it as a single string
function fsUtils:readText(path)
  local f = playdate.file.open(path, playdate.file.kFileRead)
  local size = playdate.file.getSize(path)
  local text = f:read(size)
  f:close()
  return text
end

function fsUtils:pathGetDirectory(path)
  if playdate.file.isdir(path) then
    return path
  end
  local filedir, filename = string.match(path, '(.*%S/)(.*%S)$')
  return filedir
end

function fsUtils:pathGetFilename(path)
  if playdate.file.isdir(path) then
    return nil
  end
  local filedir, filename = string.match(path, '(.*%S/)(.*%S)$')
  return filename
end

function fsUtils:pathGetRootDirectory(path)
  return string.match(path, '([.*%S][^/]+)') .. '/'
end

function fsUtils:pathIsInPdx(path)
  local rootDir = fsUtils:pathGetRootDirectory(path)
  return table.indexOfElement(PDX_FOLDERS, rootDir) ~= nil
end

function fsUtils:getPdxFilename()
  if PDX_FILENAME then return PDX_FILENAME end
  if playdate.isSimulator then
    -- no way to reliably get pdx name in the simulator...
    PDX_FILENAME = 'Playnote.pdx'
  else
    -- on device, the first argument in playdate.argv is always the game path (e.g. "/Games/MyGame.pdx")
    local arg = playdate.argv[1]
    PDX_FILENAME = string.sub(arg, string.find(arg, 'Games/') + 6, #arg)
  end
  return PDX_FILENAME
end

function fsUtils:getDiskPath(path)
  if fsUtils:pathIsInPdx(path) then
    return '/Games/' .. self:getPdxFilename() .. '/' .. path
  end
  return '/Data/' ..  playdate.metadata.bundleID .. '/' .. path
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