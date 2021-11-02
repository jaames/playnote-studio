import 'CoreLibs/object'
import './utils.lua'

local fs <const> = playdate.file

noteManager = {}

noteManager.folderList = {}
noteManager.currentFolder = ''
noteManager.notesPerPage = 12
noteManager.currentNote = nil

local noteList = {}
local notesPerPage <const> = noteManager.notesPerPage

function noteManager:initFs()
  -- create initial note folder with instructions if it doesn't exist yet
  if not fs.isdir('001') then
    fs.mkdir('001')
    local readme = fs.open('001/help.txt', fs.kFileWrite)
    readme:write('Drop all of your Flipnote .ppm files into this folder!\nYou can also organise your Flipnotes by creating more folders next to this one')
    readme:close()
  end
  -- build list of root folders
  local list = fs.listFiles('/')
  for i = 1, #list, 1 do
    local name = list[i]
    if (string.sub(name, -1) == '/') and not (name == 'fonts/' or name == 'img/' or name == 'screens/') then
      table.insert(noteManager.folderList, name)
    end
  end
  -- set samplememo as initial folder
  if fs.isdir('samplememo') then
    noteManager:setDirectory('samplememo')
  end
end

function noteManager:setCurrentNote(path)
  noteManager.currentNote = path
end

function noteManager:setDirectory(dir)
  noteManager.currentFolder = dir
  utils:clearArray(noteList)
  local list = fs.listFiles(dir)
  for i = 1, #list, 1 do
    local name = list[i]
    if string.sub(name, -3) == 'ppm' then
      table.insert(noteList, dir .. '/' .. name)
    end
  end
  numNotes, _ = table.getsize(noteList)
  noteManager.numPages = math.ceil(numNotes / notesPerPage)
end

function noteManager:getPage(pageIndex)
  local page = table.create(0, notesPerPage)
  local startIndex = ((pageIndex - 1) * notesPerPage) + 1 -- thanks lua, great programming language
  local endIndex = math.min(startIndex + notesPerPage - 1, numNotes)
  for i = startIndex, endIndex, 1 do
    local path = noteList[i]
    page[path] = TmbParser.new(path)
  end
  return page
end

function noteManager:releasePage(pageTable)
  utils:clearArray(pageTable)
end