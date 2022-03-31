import { Component, createRef } from 'preact';

import { DemoCanvas } from '../demo/canvas';

import {
  PpmParser
} from 'flipnote.js';

export default class PlaydatePlayer extends Component {

  wrapper = createRef<HTMLElement>();

  constructor() {
    super();
  }

  componentDidMount() {
    const canvas = new DemoCanvas(this.wrapper.current, 530, 530);
    canvas.init();
  }

  render(props, state) {
    return (
      <div class="PlaydatePlayer" ref={this.wrapper} style={{ background: `url('/assets/render.png')`, backgroundRepeat: 'no-repeat' }}>
      </div>
    );
  }

}