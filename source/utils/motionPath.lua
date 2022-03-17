motionPath = {}

function motionPath:new(src)
  local l = src:length()
  local mt = getmetatable(src)

  if mt == playdate.geometry.arc then
    return function (t)
      return src:pointOnArc(t * l):unpack()
    end
  elseif mt == playdate.geometry.lineSegment then
    return function (t)
      return src:pointOnLine(t * l):unpack()
    end
  elseif mt == playdate.geometry.polygon then
    return function (t)
      return src:pointOnPolygon(t * l):unpack()
    end
  elseif mt == playdate.geometry.rect then
    src = src:toPolygon()
    return function (t)
      return src:pointOnPolygon(t * l):unpack()
    end
  end
end

-- https://pomax.github.io/bezierinfo/#decasteljau
-- avoiding creating new point objects here
local function getPoint(curve, t, n)
  if n == 1 then
    return curve:getPointAt(1):unpack()
  else
    n = n - 1
    for i = 1, n do
      local a = curve:getPointAt(i)
      local b = curve:getPointAt(i + 1)
      curve:setPointAt(i,
        (1 - t) * a.x + t * b.x,
        (1 - t) * a.y + t * b.y
      )
    end
    return getPoint(curve, t, n)
  end
end

function motionPath:newCurve(x1, y1, x2, y2, x3, y3)
  local curve = playdate.geometry.polygon.new(x1, y1, x2, y2, x3, y3)
  local curvePoints = curve:count()

  return function (t)
    if t == 0 then
      return x1, y1
    elseif t == 1 then
      return x3, y3
    end
    local c = curve:copy()
    return getPoint(c, t, curvePoints)
  end
end