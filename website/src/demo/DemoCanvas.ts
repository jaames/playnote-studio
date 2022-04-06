import {
  WebGLRenderer,
  Object3D,
  Scene,
  Camera,
  Mesh,
  Material,
  ShaderMaterial,
  Uniform,
  DataTexture,
  TextureLoader,
  LinearFilter
} from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader';

import { FntRenderer } from './FntRenderer';
import { abgr32ToArray, animateValue } from './utils';

import vertexShader from './vert.glsl';
import fragmentShader from './frag.glsl';
import screenUrl from '@assets/screen.png';

const PLAYDATE_WIDTH = 400;
const PLAYDATE_HEIGHT = 240;
// ABGR order 
const PLAYDATE_WHITE = 0xFFA6AEB0;
const PLAYDATE_BLACK = 0xFF262E30;

export const enum DitherType {
  None = 0,
  InversePolka,
  Checker,
  Polka
};
// 2x2 dither masks
const DITHER_MASKS = {
  [DitherType.None]:         [[1, 1], [1, 1]], 
  [DitherType.InversePolka]: [[0, 0], [1, 0]], 
  [DitherType.Checker]:      [[0, 1], [1, 0]],
  [DitherType.Polka]:        [[1, 1], [0, 1]],
};

const modelLoader = new GLTFLoader();
const textureLoader = new TextureLoader();

export class DemoCanvas {

  width: number;
  height: number;

  private scene: Scene;
  private renderer: WebGLRenderer;
  private camera: Camera;

  private frameBuffer: Uint32Array; // AABBGGRRR
  private frameTexture: DataTexture;
  private fadeLevel = new Uniform(0); 

  private counterFont: FntRenderer;

  constructor(parent: HTMLElement, width: number, height: number) {
    this.scene = new Scene();

    this.renderer = new WebGLRenderer({ alpha: true, antialias: true });
    this.renderer.setPixelRatio(window.devicePixelRatio || 1);
    this.renderer.setSize(width, height);
    parent.appendChild(this.renderer.domElement);

    this.frameBuffer = new Uint32Array(PLAYDATE_WIDTH * PLAYDATE_HEIGHT * 4);
    this.frameTexture = new DataTexture(new Uint8Array(this.frameBuffer.buffer), PLAYDATE_WIDTH, PLAYDATE_HEIGHT);
    this.frameTexture.magFilter = LinearFilter;
    this.frameTexture.minFilter = LinearFilter;
  }

  async init() {
    const gltf = await modelLoader.loadAsync('/assets/playdate_screen.glb');
    const screenTexture = await textureLoader.loadAsync(screenUrl);
    screenTexture.flipY = false;

    this.counterFont = await FntRenderer.fromUrl('/assets/WhalesharkCounter.fnt');
    this.counterFont.tracking = 2;
    await this.counterFont.init();

    this.overrideMaterials(gltf.scene, new ShaderMaterial({
      vertexShader,
      fragmentShader,
      uniforms: {
        u_fadeColor: new Uniform([0xB1, 0xAE, 0xA7, 0xFF]),
        u_fadeLevel: this.fadeLevel,
        u_bgTex: new Uniform(screenTexture),
        u_frameTex: new Uniform(this.frameTexture),
      }
    }));

    this.scene.add(gltf.scene);
    this.camera = gltf.cameras[0];
    this.render();
    await this.fadeInOut()
  }

  render() {
    this.renderer.render(this.scene, this.camera);
  }

  setFade(l: number) {
    this.fadeLevel.value = l;
    this.render();
  }

  async fadeInOut() {
    await animateValue(200, 0, 1, (v) => this.setFade(v));
    await animateValue(200, 1, 0, (v) => this.setFade(v));
  }

  drawPpmLayers(layer1: Uint8Array, layer2: Uint8Array, dither1 = DitherType.None, dither2 = DitherType.None, currentFrame: number, totalFrame: number) {
    const fb = this.frameBuffer;
    const xOffs = 72;
    const yOffs = 16;
    const width = 256;
    const height = 192;
    const dstStride = 400;
    const pattern1 = DITHER_MASKS[dither1];
    const pattern2 = DITHER_MASKS[dither2];
    fb.fill(0);
    for (let srcY = 0, dstY = yOffs; srcY < height; srcY++, dstY++) {
      const patternLine1 = pattern1[srcY % 2]; 
      const patternLine2 = pattern2[srcY % 2];
      for (let srcX = 0, dstX = xOffs; srcX < width; srcX++, dstX++) {
        const srcPtr = srcY * width + srcX;
        const dstPtr = dstY * dstStride + dstX;
        const a = layer1[srcPtr];
        if (a && patternLine1[srcX % 2]) {
          fb[dstPtr] = PLAYDATE_BLACK;
          continue;
        }
        const b = layer2[srcPtr];
        if (b && patternLine2[srcX % 2]) {
          fb[dstPtr] = PLAYDATE_BLACK;
          continue;
        }
        fb[dstPtr] = PLAYDATE_WHITE;
      }
    }
    this.frameTexture.needsUpdate = true;
    this.counterFont.drawCenteredText(currentFrame.toString(), fb, 321, 215, dstStride, PLAYDATE_BLACK);
    this.counterFont.drawCenteredText('/', fb, 345, 215, dstStride, PLAYDATE_BLACK);
    this.counterFont.drawCenteredText(totalFrame.toString(), fb, 370, 215, dstStride, PLAYDATE_BLACK);
    this.render();
  }

  private isMesh = (o: Object3D): o is Mesh => o.type === 'Mesh';

  private overrideMaterials(object: Object3D, material: Material) {
    if (this.isMesh(object)) {
      object.material = material;
    }
    object.children.forEach(child => this.overrideMaterials(child, material));
  }

}