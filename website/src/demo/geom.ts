export type Point = {
  x: number;
  y: number;
};

export type Line = {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
};

export const makePoint = (x: number, y: number) => ({ x, y });

export const makeLine = (x1: number, y1: number, x2: number, y2: number): Line => ({ x1, y1, x2, y2 });

export const dist = (x1: number, y1: number, x2: number, y2: number) => Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2);

export function distToLine(p: Point, line: Line) {
  const t = pointToLineRatio(p, line);
  const tp = lineRatioToPoint(line, t);
  return dist(p.x, p.y, tp.x, tp.y);
}

export function pointToLineRatio({ x, y }: Point, { x1, y1, x2, y2 }: Line) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  const lenSquared = dx * dx + dy * dy;
  if (lenSquared === 0)
    return 1;
  const t = ((x - x1) * dx + (y - y1) * dy) / lenSquared;
  return Math.max(0, Math.min(t, 1));
}

export function lineRatioToPoint({ x1, y1, x2, y2 }: Line, t: number) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  return {
    x: x1 + t * dx,
    y: y1 + t * dy
  };
}