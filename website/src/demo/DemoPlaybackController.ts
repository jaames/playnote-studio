import { PpmParser } from 'flipnote.js/dist/PpmParser';
import { DemoCanvas, DitherType } from './DemoCanvas';

import { Point, makeLine, distToLine, pointToLineRatio } from '../demo/geom';
import { radToDeg, snap, mod } from '../demo/math';

export class DemoPlaybackController {

  canvas: DemoCanvas;
  video: HTMLVideoElement;
  // base settings
  ppm: PpmParser;
  dither1: DitherType;
  dither2: DitherType;
  // ppm state
  loop: boolean;
  totalFrames = 0;
  currFrame = 0;
  // crank controller
  crankLine = makeLine(530, 190, 520, 430);
  crankTicksPerRotation = 30;
  lastCrankAngle = 0;
  invertCrankInput = false;
  canCrankInvert = false;

  constructor(canvas: DemoCanvas, video: HTMLVideoElement) {
    this.canvas = canvas;
    this.video = video;
  }

  async loadUrl(url: string, dither1: DitherType, dither2: DitherType) {
    const resp = await fetch(url);
    const data = await resp.arrayBuffer();
    return await this.load(data, dither1, dither2);
  }

  async load(data: ArrayBuffer, dither1: DitherType, dither2: DitherType) {
    this.ppm = new PpmParser(data);
    this.dither1 = dither1;
    this.dither2 = dither2;
    this.loop = this.ppm.meta.loop;
    this.totalFrames = this.ppm.meta.frameCount;
    this.currFrame = 0;
    this.draw();
  }

  distFromCrank(p: Point) {
    return distToLine(p, this.crankLine);
  }

  handleCrankInteraction(p: Point) {
    const step = 360 / this.crankTicksPerRotation;
    // find closest point on the crank's visual area as a number in the range 0..1
    const t = pointToLineRatio(p, this.crankLine);
    // convert to angular rotation, angle will be in the range of 0..180
    const x = 0.5 - Math.abs(0.5 - t);
    const y = 0.5 - t;
    let crankAngle = snap(radToDeg(Math.atan2(x, y)), step);
    // if crank is nearly at the top or bottom of the arc, we know we can invert soon
    if (crankAngle === step || crankAngle === 180 - step)
      this.canCrankInvert = true;
    // if crank has reached the top of the arc, we can invert the angle to reach 180..360
    if (this.canCrankInvert && (crankAngle === 0 || crankAngle === 180)) {
      this.canCrankInvert = false;
      this.invertCrankInput = !this.invertCrankInput;
    }
    if (this.invertCrankInput)
      crankAngle = 180 + (180 - crankAngle);
    // calc change, taking angle wrapping into account
    const diff = crankAngle - this.lastCrankAngle;
    if (diff > 180 || diff < -180) {
      if (this.lastCrankAngle >= 180)
        this.lastCrankAngle -= 360;
      else
        this.lastCrankAngle += 360;
    }
    const thisSegment = Math.ceil(crankAngle / step);
    const lastSegment = Math.ceil(this.lastCrankAngle / step);
    const stepDiff = thisSegment - lastSegment;
    //
    this.video.currentTime = (this.video.duration / this.crankTicksPerRotation) * thisSegment;
    // finally
    this.lastCrankAngle = crankAngle;
    if (stepDiff !== 0) {
      this.advanceFrame(stepDiff);
    }
  }

  advanceFrame(change: number) {
    this.setFrame(this.currFrame + change);
  }

  setFrame(frame: number) {
    this.currFrame = mod(frame, this.totalFrames);
    this.draw();
  }

  draw() {
    const i = this.currFrame;
    const ppm = this.ppm;
    const [layer1, layer2] = ppm.decodeFrame(i);
    const [paperColor, layer1Color, layer2Color] = ppm.getFramePaletteIndices(i);
    // console.log(layer1Color, layer2Color);
    this.canvas.drawPpmLayers(layer1, layer2, this.dither1, this.dither2, i, this.totalFrames);
  }

}