varying vec2 v_uv;

uniform sampler2D u_bgTex;
uniform sampler2D u_frameTex;

void main() {
  gl_FragColor = texture2D(u_frameTex, v_uv);
}