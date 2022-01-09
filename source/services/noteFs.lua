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
  for _, path in pairs(fs.listFiles('/')) do
    if fs.isdir(path) and not fsUtils:isInternalFolder(path) then
      table.insert(self.folderPaths, path)
      table.insert(folderList, {
        path = path,
        name = self:getFolderName(path)
      })
    end
  end
  -- sort folderList so that ones with custom titles come first
  table.sort(folderList, function (a, b)
    return string.sub(a.name, -1) ~= '/'
  end)
  self.folderList = folderList
  -- set samplememo as initial folder
  assert(fs.isdir('samplememo'), 'Sample Flipnote folder is missing?')
  self:setDirectory(config.lastFolder)
  -- self:getArtistCredits()
end

function noteFs:getFolderData(folderPath)
  local jsonPath = folderPath .. 'playnote.json'
  if fs.exists(jsonPath) then
    local data = json.decodeFile(jsonPath)
    if type(data) == 'table' then
      return data
    end
  else
    json.encodeToFile(jsonPath, false, {})
  end
  return {}
end

function noteFs:getFolderName(folderPath)
  local data = self:getFolderData(folderPath)
  local folderTitle = data.folderTitle
  if type(folderTitle) == 'string' then
    return stringUtils:escape(folderTitle)
  elseif type(folderTitle) == 'table' and folderTitle[config.lang] ~= nil then
    return stringUtils:escape(folderTitle[config.lang])
  elseif type(folderTitle) == 'table' and folderTitle['en'] ~= nil then
    return stringUtils:escape(folderTitle['en'])
  end
  return stringUtils:escape(fsUtils:fixFolderName(folderPath))
end

-- update folder names after locale has been changed
function noteFs:refreshFolderNames()
  for _, folder in pairs(self.folderList) do
    folder.name = self:getFolderName(folder.path)
  end
end

function noteFs:getNoteData(folderPath, filename)
  local data = self:getFolderData(folderPath)
  if type(data.notes) == 'table' then
    for _, noteData in pairs(data.notes) do
      if type(noteData) == 'table' and noteData.filename == filename then
        return noteData
      end
    end
  end
  return {}
end

function noteFs:updateNoteData(folderPath, filename, newData)
  local data = self:getFolderData(folderPath)
  -- if there's no notes array, add it
  if type(data.notes) ~= 'table' then
    data.notes = {}
  end
  -- loop through note list to see if there's already an entry for this note
  -- if there is, merge newData in with the existing data
  local wasFound = false
  for _, noteData in pairs(data.notes) do
    if type(noteData) == 'table' and noteData.filename == filename then
      for k, v in pairs(newData) do
        noteData[k] = v
      end
      wasFound = true
      break
    end
  end
  -- if there's no entry for this note, insert a new one
  if not wasFound then
    newData.filename = filename
    table.insert(data.notes, newData)
  end
  -- save changes to file
  local jsonPath = folderPath .. 'playnote.json'
  json.encodeToFile(jsonPath, false, data)
end

function noteFs:getArtistCredits()
  local creditList = {}
  for _, path in pairs(self.folderPaths) do
    local data = self:getFolderData(path)
    if type(data.credits) == 'table' then
      for _, item in pairs(data.credits) do
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

function noteFs:getNoteDitherSettings(filename)
  local data = self:getNoteData(self.currentFolder, filename)
  if type(data.dithering) == 'table' then
    return data.dithering
  end
  return table.deepcopy(config.dithering)
end

function noteFs:updateNoteDitherSettings(filename, ditherSettings)
  self:updateNoteData(self.currentFolder, filename, {
    dithering = ditherSettings
  })
end

function noteFs:setDirectory(folderPath)
  if folderPath == '/samplememo' and not fs.isdir(folderPath) then
    fs.mkdir(folderPath)
    table.insert(self.folderList, { path = folderPath, name = folderPath })
    noteFs:setDirectory(folderPath)
    return
  elseif not fs.isdir(folderPath) then
    noteFs:setDirectory('/samplememo')
    return
  end
  config.lastFolder = folderPath
  self.currentFolder = folderPath
  noteList = {}
  local list = fs.listFiles(folderPath)
  for _, name in pairs(list) do
    if string.sub(name, -3) == 'ppm' then
      table.insert(noteList, folderPath .. name)
    end
  end
  numNotes = #noteList
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

function noteFs:deleteSampleMemo()

end