varying vec2 v_uv; // uv coord
varying vec2 v_px; // playdate pixel coord

const float PLAYDATE_WIDTH = 400.0 / 6.0;
const float PLAYDATE_HEIGHT = 240.0 / 6.0;

void main() {
  v_uv = uv;
  v_px = vec2(uv.x * PLAYDATE_WIDTH, uv.y * PLAYDATE_HEIGHT);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}