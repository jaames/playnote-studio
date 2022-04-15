varying vec2 v_uv; // uv coord
varying vec2 v_px; // playdate pixel coord

uniform vec2 u_texSize;
uniform vec2 u_screenSize;

void main() {
  v_uv = uv;
  v_px = vec2(uv.x * u_texSize.x, uv.y * u_texSize.y);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}