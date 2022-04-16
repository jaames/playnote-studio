export { } // make this file a module to enable top-level await

import { Point, makeLine, distToLine, pointToLineRatio, lineRatioToPoint } from './geom';
import { radToDeg, snap, mod } from './math';
import { animateValue, domReady, nextTick, abgr32ToGlArray } from './utils';

import type {
  Mesh,
  Object3D,
  Material,
} from './imports';

const {
  // three js
  WebGLRenderer,
  Scene,
  ShaderMaterial,
  Uniform,
  DataTexture,
  TextureLoader,
  LinearFilter,
  NearestFilter,
  GLTFLoader,
  // shaders and such
  vertexShader,
  fragmentShader,
  //
  PpmParser,
  WebAudioPlayer,
  FntRenderer
} = await import('./imports');

const enum DitherType {
  None = 0,
  InversePolka,
  Checker,
  Polka
};

interface DemoPpm {
  url: string;
  thumbUrl: string;
  authorUrl: string;
  startFrame: number;
  dithering: [[DitherType, DitherType, DitherType], [DitherType, DitherType, DitherType]]
};

// config
const IS_HIDPI = window.devicePixelRatio > 1;
const CANVAS_SIZE = 590;
const PLAYDATE_WIDTH = 400;
const PLAYDATE_HEIGHT = 240;
const PLAYDATE_WHITE = 0xFFA7AEB1; // ABGR order 
const PLAYDATE_BLACK = 0xFF322F28;
const DITHER_MASKS = {
  [DitherType.None]:         [[1, 1], [1, 1]],
  [DitherType.InversePolka]: [[0, 0], [1, 0]],
  [DitherType.Checker]:      [[0, 1], [1, 0]],
  [DitherType.Polka]:        [[1, 1], [0, 1]],
};

const URL_SCREEN_MODEL = '/assets/playdate_screen.glb';
const URL_SCREEN_IMAGE = '/assets/screen.png';
const URL_COUNTER_FONT = '/assets/WhalesharkCounter.fnt';
const SOURCE_VIDEOS = [
  { src1x: '/assets/playdate_1x.mov',  src2x: '/assets/playdate_2x.mov',  type: 'video/mp4;codecs=hvc1' },
  { src1x: '/assets/playdate_1x.webm', src2x: '/assets/playdate_2x.webm', type: 'video/webm' },
];

const DEMO_PPM_INFO: Record<string, DemoPpm> = {
  'pekira': {
    url: '/assets/pekira_beach.ppm',
    thumbUrl: 'TODO',
    authorUrl: 'https://twitter.com/pekira1227',
    startFrame: 94,
    dithering: [
      [DitherType.None, DitherType.Checker, DitherType.Polka],
      [DitherType.None, DitherType.Checker, DitherType.Polka],
    ],
  },
  'keke': {
    url: '/assets/keke.ppm',
    thumbUrl: 'TODO',
    startFrame: 0,
    authorUrl: 'https://twitter.com/Kekeflipnote',
    dithering: [
      [DitherType.None, DitherType.Checker, DitherType.Polka],
      [DitherType.None, DitherType.Checker, DitherType.Polka],
    ],
  },
  'mrjohn': {
    url: '/assets/mrjohn.ppm',
    thumbUrl: 'TODO',
    startFrame: 70,
    authorUrl: 'https://www.sudomemo.net/user/9F990EE00074AC4D@DSi',
    dithering: [
      [DitherType.None, DitherType.Checker, DitherType.Polka],
      [DitherType.None, DitherType.Checker, DitherType.Polka],
    ],
  }
};

await domReady();

// elements
const root = document.querySelector('.Demo');
const wrapper = document.querySelector('.Demo__wrapper');
const video = document.querySelector<HTMLVideoElement>('.Demo__video');
const canvas = document.querySelector<HTMLCanvasElement>('.Demo__canvas');
const crankHint = document.querySelector('.Demo__crankHint');
const creditLink = document.querySelector('.Demo__creditLink');
const playToggle = document.querySelector('.Demo__playToggle');
const muteToggle = document.querySelector('.Demo__muteToggle');

// load in video
await new Promise<void>((resolve) => {
  video.addEventListener('canplaythrough', () => resolve());
  SOURCE_VIDEOS.forEach(({src1x, src2x, type}) => {
    const sourceEl = document.createElement('source');
    sourceEl.src = IS_HIDPI? src2x : src1x;
    sourceEl.type = type;
    video.appendChild(sourceEl);
  });
  video.load();
});

// load assets in parallel
const modelLoader = new GLTFLoader();
const textureLoader = new TextureLoader();
const [gltf, screenTexture, counterFont] = await Promise.all([
  modelLoader.loadAsync(URL_SCREEN_MODEL),
  await textureLoader.loadAsync(URL_SCREEN_IMAGE),
  await FntRenderer.fromUrl(URL_COUNTER_FONT)
]);
// set up abgr framebuffer and a render texture for it
const frameBuffer = new Uint32Array(PLAYDATE_WIDTH * PLAYDATE_HEIGHT * 4);
const frameTexture = new DataTexture(new Uint8Array(frameBuffer.buffer), PLAYDATE_WIDTH, PLAYDATE_HEIGHT);
frameTexture.magFilter = LinearFilter;
frameTexture.minFilter = LinearFilter;
// set up ui 
counterFont.tracking = 2;
const seekerLine = makeLine(126, 218, PLAYDATE_WIDTH - 126, 218);
const fadeLevel = new Uniform(0);
const showFrame = new Uniform(0);
// set up screen
const scene = new Scene();
const renderer = new WebGLRenderer({ canvas, alpha: true, antialias: true });
const camera = gltf.cameras[0];
renderer.setPixelRatio(window.devicePixelRatio || 1);
renderer.setSize(canvas.clientWidth, canvas.clientHeight);
screenTexture.flipY = false;
overrideMaterials(gltf.scene, new ShaderMaterial({
  vertexShader,
  fragmentShader,
  uniforms: {
    u_showFrame: showFrame,
    u_fadeColor: new Uniform(abgr32ToGlArray(PLAYDATE_WHITE)),
    u_fadeLevel: fadeLevel,
    u_bgTex: new Uniform(screenTexture),
    u_frameTex: new Uniform(frameTexture),
    u_texSize: new Uniform([PLAYDATE_WIDTH, PLAYDATE_HEIGHT]),
  }
}));
scene.add(gltf.scene);

// ppm state
let ppm: InstanceType<typeof PpmParser>;
let ppmAudio: InstanceType<typeof WebAudioPlayer>;
let dither1: [DitherType, DitherType, DitherType];
let dither2: [DitherType, DitherType, DitherType];
let isPlaying = false;
let loop = false;
let totalFrames = 0;
let currFrame = 0;
let startTime = 0;
let currTime = 0;

// crank controller state
const crankLine = makeLine(530, 200, 520, 415);
const crankTicksPerRotation = 30;
let hasInteracted = false;
let lastCrankAngle = 0;
let invertCrankInput = true;
let canCrankInvert = false;

async function loadDemoPpm(key: string) {
  pause();
  const { url, authorUrl, dithering, startFrame } = DEMO_PPM_INFO[key];
  const resp = await fetch(url);
  const data = await resp.arrayBuffer();
  await fadeOut();
  // load flipnote
  ppm = new PpmParser(data);
  console.log('loaded ppm:', ppm);
  // setup ppm state
  dither1 = dithering[0];
  dither2 = dithering[1];
  isPlaying = false;
  loop = true; // ignore ppm loop flag and always loop
  totalFrames = ppm.meta.frameCount;
  startTime = 0;
  currFrame = startFrame;
  currTime = startFrame * (1 / ppm.framerate);
  // load audio
  if (ppmAudio) ppmAudio.destroy();
  ppmAudio = new WebAudioPlayer();
  ppmAudio.setBuffer(ppm.getAudioMasterPcm(), ppm.sampleRate);
  ppmAudio.loop = true;
  // display author credit
  creditLink.textContent = ppm.meta.current.username;
  creditLink.setAttribute('href', authorUrl);
  // set frame visible flag if it wasn't set already
  showFrame.value = true;
  drawPpm();
  await fadeIn();
}

function play() {
  if (ppm && !isPlaying) {
    isPlaying = true;
    startTime = performance.now() / 1000 - currTime;
    requestAnimationFrame(playbackLoop);
    ppmAudio.playFrom(currTime);
    root.classList.add('Demo--isPlaying');
  }
}

function pause() {
  if (ppm && isPlaying) {
    isPlaying = false;
    ppmAudio.stop();
    root.classList.remove('Demo--isPlaying');
  }
}

function togglePlay() {
  if (isPlaying)
    pause();
  else
    play();
}

function toggleMute() {
  if (ppmAudio) {
    if (ppmAudio.volume === 1) {
      ppmAudio.volume = 0;
      root.classList.add('Demo--isMuted');
    }
    else {
      root.classList.remove('Demo--isMuted');
      ppmAudio.volume = 1;
    }
  }
}

function playbackLoop(timestamp: DOMHighResTimeStamp) {
  if (!isPlaying)
    return;
  currTime = timestamp / 1000 - startTime;
  const nextFrame = Math.floor(currTime / (1 / ppm.framerate));
  if (currFrame !== nextFrame) {
    // loop back to start
    if (nextFrame >= totalFrames) {
      startTime = performance.now() / 1000;
      setFrame(0);
      ppmAudio.stop();
      ppmAudio.playFrom(0);
    }
    // next frame
    else
      setFrame(nextFrame);
    drawPpm();
  }
  requestAnimationFrame(playbackLoop);
}

function setFrame(frame: number) {
  currFrame = mod(frame, totalFrames);
  currTime = currFrame * (1 / ppm.framerate);
  drawPpm();
}

function updateScreen() {
  renderer.render(scene, camera);
}

function setFade(l: number) {
  fadeLevel.value = l;
  updateScreen();
}

async function fadeOut() {
  await animateValue(400, 0, 1, (v) => setFade(v));
}

async function fadeIn() {
  await animateValue(400, 1, 0, (v) => setFade(v));
}

function overrideMaterials(object: Object3D, material: Material) {
  if (object.type === 'Mesh')
    (object as Mesh).material = material;
  object.children.forEach(child => overrideMaterials(child, material));
}

function drawPpm() {
  const [layer1, layer2] = ppm.decodeFrame(currFrame);
  const [paperColor, layer1Color, layer2Color] = ppm.getFramePaletteIndices(currFrame);
  const xOffs = 72;
  const yOffs = 16;
  const width = 256;
  const height = 192;
  const dstStride = 400;
  const pattern1 = DITHER_MASKS[dither1[Math.max(layer1Color - 1, 1)]];
  const pattern2 = DITHER_MASKS[dither2[Math.max(layer2Color - 1, 1)]];
  const pen = paperColor === 1 ? PLAYDATE_WHITE : PLAYDATE_BLACK;
  const paper = paperColor === 1 ? PLAYDATE_BLACK : PLAYDATE_WHITE;
  frameBuffer.fill(0);
  for (let srcY = 0, dstY = yOffs; srcY < height; srcY++, dstY++) {
    const patternLine1 = pattern1[srcY % 2];
    const patternLine2 = pattern2[srcY % 2];
    for (let srcX = 0, dstX = xOffs; srcX < width; srcX++, dstX++) {
      const srcPtr = srcY * width + srcX;
      const dstPtr = dstY * dstStride + dstX;
      const a = layer1[srcPtr];
      if (a && patternLine1[srcX % 2]) {
        frameBuffer[dstPtr] = pen;
        continue;
      }
      const b = layer2[srcPtr];
      if (b && patternLine2[srcX % 2]) {
        frameBuffer[dstPtr] = pen;
        continue;
      }
      frameBuffer[dstPtr] = paper;
    }
  }
  // draw
  counterFont.drawCenteredText((currFrame + 1).toString(), frameBuffer, 321, 215, dstStride, PLAYDATE_BLACK);
  counterFont.drawCenteredText('/', frameBuffer, 345, 215, dstStride, PLAYDATE_BLACK);
  counterFont.drawCenteredText(totalFrames.toString(), frameBuffer, 370, 215, dstStride, PLAYDATE_BLACK);
  // draw seek bar handle
  const {x, y} = lineRatioToPoint(seekerLine, currFrame / totalFrames) 
  counterFont.drawText('H', frameBuffer, x - 4, y, dstStride, PLAYDATE_WHITE);
  counterFont.drawText('h', frameBuffer, x - 4, y, dstStride, PLAYDATE_BLACK);
  //
  frameTexture.needsUpdate = true;
  updateScreen();
}

function getInputPoint(e: MouseEvent & TouchEvent): Point {
  // Get the screen position of the component
  const bounds = wrapper.getBoundingClientRect();
  // Prefect default browser action
  e.preventDefault();
  const point = e.touches ? e.changedTouches[0] : e;
  const xNorm = (point.clientX - bounds.left) / bounds.width;
  const yNorm = (point.clientY - bounds.top) / bounds.height;
  const x = xNorm * CANVAS_SIZE;
  const y = yNorm * CANVAS_SIZE;
  return {x, y};
}

function interact(p: Point) {
  pause();
  // hide crank hint if visible
  if (!hasInteracted) {
    crankHint.classList.add('is-hidden');
    hasInteracted = true;
  }
  const step = 360 / crankTicksPerRotation;
  // find closest point on the crank's visual area as a number in the range 0..1
  const t = pointToLineRatio(p, crankLine);
  // convert to angular rotation, angle will be in the range of 0..180
  const x = 0.5 - Math.abs(0.5 - t);
  const y = 0.5 - t;
  let crankAngle = snap(radToDeg(Math.atan2(x, y)), step);
  // if crank is nearly at the top or bottom of the arc, we know we can invert soon
  if (crankAngle === step || crankAngle === 180 - step)
    canCrankInvert = true;
  // if crank has reached the top of the arc, we can invert the angle to reach 180..360
  if (canCrankInvert && (crankAngle <= 0 || crankAngle >= 180)) {
    canCrankInvert = false;
    invertCrankInput = !invertCrankInput;
  }
  if (invertCrankInput)
    crankAngle = 180 + (180 - crankAngle);
  // calc change, taking angle wrapping into account
  const diff = crankAngle - lastCrankAngle;
  if (diff > 180 || diff < -180) {
    if (lastCrankAngle >= 180)
      lastCrankAngle -= 360;
    else
      lastCrankAngle += 360;
  }
  const thisSegment = Math.ceil(crankAngle / step);
  const lastSegment = Math.ceil(lastCrankAngle / step);
  const stepDiff = thisSegment - lastSegment;
  lastCrankAngle = crankAngle;
  if (stepDiff !== 0) {
    video.currentTime = (video.duration / crankTicksPerRotation) * thisSegment;
    setFrame(currFrame - stepDiff);
  }
}

function handleInputStart(e: MouseEvent & TouchEvent) {
  const p = getInputPoint(e);
  if (80 > distToLine(p, crankLine)) {
    root.classList.add('Demo--isInteractionActive');
    interact(p);
    document.addEventListener('mousemove', handleInputMove, { passive: false } as any);
    document.addEventListener('touchmove', handleInputMove, { passive: false } as any);
    document.addEventListener('mouseup',   handleInputEnd,  { passive: false } as any);
    document.addEventListener('touchend',  handleInputEnd,  { passive: false } as any);
  }
}

function handleInputMove(e: MouseEvent & TouchEvent) {
  interact(getInputPoint(e));
}

function handleInputEnd(e: MouseEvent & TouchEvent) {
  interact(getInputPoint(e));
  root.classList.remove('Demo--isInteractionActive');
  document.removeEventListener('mousemove', handleInputMove, { passive: false } as any);
  document.removeEventListener('touchmove', handleInputMove, { passive: false } as any);
  document.removeEventListener('mouseup',   handleInputEnd,  { passive: false } as any);
  document.removeEventListener('touchend',  handleInputEnd,  { passive: false } as any);
}

// load initial note
await loadDemoPpm('pekira');

// init dom
canvas.addEventListener('mousedown', handleInputStart, { passive: false });
canvas.addEventListener('touchstart', handleInputStart, { passive: false });
playToggle.addEventListener('click', togglePlay);
muteToggle.addEventListener('click', toggleMute);
nextTick(() => {
  crankHint.classList.remove('is-hidden');
  root.classList.add('Demo--isActive');
});

// resize canvas to fit wrapper
const resizeObserver = new ResizeObserver(([entry]) => {
  const box = entry.contentRect;
  renderer.setSize(box.width, box.height);
  updateScreen();
});
resizeObserver.observe(wrapper);

// init render
updateScreen();

(window as any).loadDemoPpm = loadDemoPpm;