local fs <const> = playdate.file

noteFs = {}

noteFs.folderList = {}
noteFs.folderPaths = {}
noteFs.currentFolder = ''
noteFs.notesPerPage = 12
noteFs.currentNote = nil

local noteList = {}
local notesPerPage <const> = noteFs.notesPerPage

function noteFs:init()
  -- create initial note folder with instructions if it doesn't exist yet
  if not fs.isdir('001') then
    fs.mkdir('001')
    local readme = fs.open('001/help.txt', fs.kFileWrite)
    readme:write('Drop all of your Flipnote .ppm files into this folder!\nYou can also organise your Flipnotes by creating more folders next to this one')
    readme:close()
  end
  -- get list of all files and folders in the root directory,
  -- filter out files, or folders that are part of the app's internal folder structure
  -- then add the path and resolved name to folderList
  local folderList = {}
  for _, path in ipairs(fs.listFiles('/')) do
    if (string.sub(path, -1) == '/') and not fsUtils:isInternalFolder(path) then
      table.insert(self.folderPaths, path)
      table.insert(folderList, {
        path = path,
        name = self:getFolderName(path)
      })
    end
  end
  -- sort folderList so that ones with custom titles come first
  table.sort(folderList, function (a, b)
    if string.sub(a.name, -1) ~= '/' then
      return true
    end
    return false
  end)
  self.folderList = folderList
  -- set samplememo as initial folder
  assert(fs.isdir('samplememo'), 'Sample Flipnote folder is missing?')
  self:setDirectory(config.lastFolder)
  self:getArtistCredits()
end

function noteFs:getFolderMeta(folderPath)
  local jsonPath = folderPath .. 'playnote.json'
  if fs.exists(jsonPath) then
    return json.decodeFile(jsonPath)
  end
  return nil
end

function noteFs:getFolderName(folderPath)
  local meta = self:getFolderMeta(folderPath)
  if meta ~= nil then
    local folderTitle = meta.folderTitle
    if type(folderTitle) == 'string' then
      return stringUtils:escape(folderTitle)
    elseif type(folderTitle) == 'table' and folderTitle[config.lang] ~= nil then
      return stringUtils:escape(folderTitle[config.lang])
    elseif type(folderTitle) == 'table' and folderTitle['en'] ~= nil then
      return stringUtils:escape(folderTitle['en'])
    end
  end
  return stringUtils:escape(fsUtils:fixFolderName(folderPath))
end

-- update folder names after locale has been changed
function noteFs:updateFolderNames()
  for _, folder in ipairs(self.folderList) do
    folder.name = self:getFolderName(folder.path)
  end
end

function noteFs:getArtistCredits()
  local creditList = {}
  for _, path in ipairs(self.folderPaths) do
    local meta = self:getFolderMeta(path)
    if meta ~= nil and meta.credits	~= nil then
      for _, item in ipairs(meta.credits) do
        local id = item.id
        -- artist id should be unique
        if creditList[id] == nil then
          creditList[id] = item
        end
      end
    end
  end
  return creditList
end

function noteFs:setDirectory(folderPath)
  assert(table.indexOfElement(self.folderPaths, folderPath) ~= nil, 'Folder does not exist')
  config.lastFolder = folderPath
  self.currentFolder = folderPath
  noteList = {}
  local list = fs.listFiles(folderPath)
  for _, name in ipairs(list) do
    if string.sub(name, -3) == 'ppm' then
      table.insert(noteList, folderPath .. name)
    end
  end
  numNotes, _ = table.getsize(noteList)
  self.hasNotes = numNotes > 1
  self.numPages = math.ceil(numNotes / notesPerPage)
end

function noteFs:setCurrentNote(notePath)
  self.currentNote = notePath
end

function noteFs:getPage(pageIndex)
  local page = table.create(notesPerPage, 0)
  local i = 1
  local startIndex = ((pageIndex - 1) * notesPerPage) + 1 -- thanks lua, great programming language
  local endIndex = math.min(startIndex + notesPerPage - 1, numNotes)
  for j = startIndex, endIndex do
    local path = noteList[j]
    page[i] = TmbParser.new(path)
    i = i + 1
  end
  return page
end

function noteFs:releasePage(pageTable)
  utils:clearArray(pageTable)
end