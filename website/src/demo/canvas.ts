import { 
  WebGLRenderer,
  Scene,
  Object3D,
  Mesh,
  Camera,
  Material,
  ShaderMaterial,
  Uniform,
  TextureLoader,
  DataTexture
} from 'three';

import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader';

import vertexShader from './vert.glsl';
import fragmentShader from './frag.glsl';

import screenUrl from '@assets/screen.png';

const PLAYDATE_WIDTH = 400;
const PLAYDATE_HEIGHT = 240;

const modelLoader = new GLTFLoader();
const textureLoader = new TextureLoader();

export class DemoCanvas {

  width: number;
  height: number;

  private scene: Scene;
  private renderer: WebGLRenderer;
  private camera: Camera;

  frameBuffer: Uint32Array; // AABBGGRRR
  frameTexture: DataTexture;

  constructor(parent: HTMLElement, width: number, height: number) {
    this.scene = new Scene();

    this.renderer = new WebGLRenderer({ alpha: true, antialias: true });
    this.renderer.setPixelRatio(window.devicePixelRatio || 1);
    this.renderer.setSize(width, height);
    parent.appendChild(this.renderer.domElement);

    this.frameBuffer = new Uint32Array(PLAYDATE_WIDTH * PLAYDATE_HEIGHT * 4);
    this.frameTexture = new DataTexture(new Uint8Array(this.frameBuffer.buffer), PLAYDATE_WIDTH, PLAYDATE_HEIGHT);

    (window as any).demo = this;
  }

  async init() {
    const gltf = await modelLoader.loadAsync('/assets/playdate_screen.glb');

    const screenTexture = await textureLoader.loadAsync(screenUrl);
    screenTexture.flipY = false;

    this.overrideMaterials(gltf.scene, new ShaderMaterial({
      vertexShader,
      fragmentShader,
      uniforms: {
        u_bgTex: new Uniform(screenTexture),
        u_frameTex: new Uniform(this.frameTexture),
      }
    }));

    this.scene.add(gltf.scene);
    this.camera = gltf.cameras[0];
    this.render();
  }

  render() {
    this.renderer.render(this.scene, this.camera);
  }

  updatePpmTexture() {
    this.frameBuffer.fill(0x0000FFFF);
    this.frameTexture.needsUpdate = true;
    this.render();
  }

  private overrideMaterials(object: Object3D, material: Material) {
    if (object instanceof Mesh)
      object.material = material;
    object.children.forEach(child => this.overrideMaterials(child, material));
  }

}