const RAD_TO_DEG = 180 / Math.PI;

const DEG_TO_RAD = Math.PI / 180; 

export const radToDeg = (rad: number) => RAD_TO_DEG * rad;

export const degToRad = (deg: number) => DEG_TO_RAD * deg;

export const snap = (x: number, n: number) => Math.round(x / n) * n;

export const mod = (x: number, n: number) => (x % n + n) % n;