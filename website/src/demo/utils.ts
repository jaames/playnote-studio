export async function animateValue(duration: number, fromValue: number, toValue: number, updateFn: (v: number) => void) {
  const start = performance.now();
  const diff = toValue - fromValue;

  return new Promise<void>((done) => {
    requestAnimationFrame(function animate(time) {
      const t = Math.min((time - start) / duration, 1);
      const value = fromValue + diff * t;
      updateFn(value);
  
      if (t < 1)
        requestAnimationFrame(animate);
      else
        done();
    });
  });
}

export function abgr32ToArray(abgr: number) {
  const r = abgr & 0xFF;
  const g = (abgr >> 8) & 0xFF;
  const b = (abgr >> 16) & 0xFF;
  const a = (abgr >> 24) & 0xFF;
  return [r, g, b, a];
}