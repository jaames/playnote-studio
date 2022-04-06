import { Component, createRef } from 'preact';

import { DitherType, DemoPlaybackController } from '../demo';
import { Point } from '../demo/geom';

const size = 590;

interface State {
  loadState: number;
};

export default class PlaydatePlayer extends Component<{}, State> {

  canvasWrapper = createRef<HTMLElement>();
  video = createRef<HTMLVideoElement>();
  controller: DemoPlaybackController;

  state: State = {
    loadState: 0
  };

  componentDidMount() {
    this.initPlayer();
  }

  async setStateAsync(state: Partial<State>) {
    return new Promise<void>((resolve) => this.setState(state, resolve));
  }

  async initPlayer() {
    const { DemoCanvas, DemoPlaybackController } = await import('../demo');
    await this.setStateAsync({ loadState: 1 });
    const canvas = new DemoCanvas(this.canvasWrapper.current, size, size);
    await canvas.init();
    await this.setStateAsync({ loadState: 2 });
    this.controller = new DemoPlaybackController(canvas, this.video.current);
    await this.loadPpm();
    await this.setStateAsync({ loadState: 3 });
  }

  async loadPpm() {
    await this.controller.loadUrl('/assets/pekira_beach.ppm', DitherType.None, DitherType.Checker);
  }

  getInputPoint(e: MouseEvent & TouchEvent): Point {
    // Get the screen position of the component
    const bounds = this.canvasWrapper.current.getBoundingClientRect();
    // Prefect default browser action
    e.preventDefault();
    const point = e.touches ? e.changedTouches[0] : e;
    const x = point.clientX - bounds.left;
    const y = point.clientY - bounds.top;
    return {x, y};
  }

  interact(p: Point) {
    this.controller.handleCrankInteraction(p);
  }
 
  handleInputStart = (e: MouseEvent & TouchEvent) => {
    const p = this.getInputPoint(e);
    if (80 > this.controller.distFromCrank(p)) {
      document.addEventListener('mousemove', this.handleInputMove, { passive: false } as any);
      document.addEventListener('touchmove', this.handleInputMove, { passive: false } as any);
      document.addEventListener('mouseup',   this.handleInputEnd,  { passive: false } as any);
      document.addEventListener('touchend',  this.handleInputEnd,  { passive: false } as any);
      this.interact(p);
    }
  }

  handleInputMove = (e: MouseEvent & TouchEvent) => {
    this.interact(this.getInputPoint(e));
  }

  handleInputEnd = (e: MouseEvent & TouchEvent) => {
    this.interact(this.getInputPoint(e));
    document.removeEventListener('mousemove', this.handleInputMove, { passive: false } as any);
    document.removeEventListener('touchmove', this.handleInputMove, { passive: false } as any);
    document.removeEventListener('mouseup',   this.handleInputEnd,  { passive: false } as any);
    document.removeEventListener('touchend',  this.handleInputEnd,  { passive: false } as any);
  }

  render(props, state: State) {
    return (
      <div class="PlaydatePlayer" style={{ touchAction: 'none' }}>
        <div
          class="PlaydatePlayer__wrapper"
          ref={ this.canvasWrapper }
          style={{
            width: `${size}px`,
            height: `${size}px`,
            background: `url('/assets/render.png') 0% 0% / ${size}px no-repeat`,
            position: 'relative'
          }}
          // https://github.com/preactjs/preact/issues/2113#issuecomment-553408767
          onMouseDown={ this.handleInputStart }
          ontouchstart={ this.handleInputStart }
        >
          <video muted playsinline ref={ this.video } style={{ position: 'absolute', zIndex: -1 }}>
            <source src="/assets/output.mov" type="video/mp4;codecs=hvc1"/>
            <source src="/assets/output.webm" type="video/webm"/>
          </video>
        </div>
        <div>{ state.loadState }</div>
      </div>
    );
  }

}