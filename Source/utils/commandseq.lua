
local buttonSeqs = {}

local function getPressedButtons()
  local btn <const> = playdate.buttonIsPressed
  local mask = 0
  if btn(playdate.kButtonA)     then mask = mask | playdate.kButtonA end
  if btn(playdate.kButtonB)     then mask = mask | playdate.kButtonB end
  if btn(playdate.kButtonUp)    then mask = mask | playdate.kButtonUp end
  if btn(playdate.kButtonDown)  then mask = mask | playdate.kButtonDown end
  if btn(playdate.kButtonLeft)  then mask = mask | playdate.kButtonLeft end
  if btn(playdate.kButtonRight) then mask = mask | playdate.kButtonRight end
  return mask
end

function updateButtonSequences()
  local currPressedButtons = getPressedButtons()
  local currTime = playdate.getCurrentTimeMilliseconds()
  for _, seq in pairs(buttonSeqs) do
    local cmd = seq.cmd
    local nextStep = seq.currStep + 1
    -- if we're at the end of the button sequence, call the function and reset
    if seq.currStep == #cmd then
      print('done')
      seq.currStep = 0
      seq.state = 'up'
      seq.fn()
    -- move into the 'down' state if the next set of buttons in the sequenece are pressed
    elseif seq.state == 'up' and cmd[nextStep] == currPressedButtons then
      print('down')
      seq.state = 'down'
    -- progress forward if the next set of buttons have now been lifted after being pressed
    elseif seq.state == 'down' and cmd[nextStep] & currPressedButtons == 0 then
      print('up')
      seq.currStep = nextStep
      seq.state = 'up'
    -- cancel sequence if the timer runs out
    elseif seq.currStep > 0 and currTime - seq.currTime > seq.timeout then
      print('timeout')
      seq.currStep = 0
      seq.state = 'up'
    end
    seq.currTime = currTime
  end
end

function addButtonSequence(cmd, fn, timeout)
  table.insert(buttonSeqs, {
    cmd = cmd,
    fn = fn,
    timeout = timeout or 500,
    currTime = 0,
    currStep = 0,
    state = 'up'
  })
end

addButtonSequence({
  playdate.kButtonA,
  playdate.kButtonA,
  playdate.kButtonB,
}, function ()
  print('A then B')
end)