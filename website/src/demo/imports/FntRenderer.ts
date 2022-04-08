// inspired by https://github.com/shockie/node-iniparser/blob/master/lib/node-iniparser.js
const REGEX_LINEBREAK = /[\r\n]+/;
const REGEX_GLYPH = /^\s*([\S]+)\s*(.*?)\s*$/;
const REGEX_PARAM = /^\s*([\w\.\-\_]+)\s*=\s*(.*?)\s*$/;
const REGEX_COMMENT = /^\s*--\s*(.*)$/;

interface PdGlyph {
  chr: string;
  cellId: number;
  width: number;
};

export class FntRenderer {

  glyphIndex = 0;
  glyphMap = new Map<string, PdGlyph>();
  glyphPixels = new Map<string, Uint8Array>();
  pairMap = new Map<string, number>();

  metrics: Record<string, any> = {};

  tracking: number;
  tableData: string;
  tableDataLen: number;
  cellWidth: number;
  cellHeight: number;

  pixelData = []

  static async fromUrl(url: string) {
    const resp = await fetch(url);
    const data = await resp.arrayBuffer();
    const fnt = new FntRenderer(data);
    await fnt.init();
    return fnt;
  }

  constructor(fntBuffer: ArrayBuffer) {
    this.parseFnt(fntBuffer);
  }

  async init() {
    const table = await this.parseTableData();
    const tableData = table.data;
    const tableW = table.width;
    const tableH = table.height;
    const tablePixels = new Uint8Array(tableW * tableH);
    const cellWidth = this.cellWidth;
    const cellHeight = this.cellHeight;
    const cellsAcross = tableW / cellWidth;
    const cellsDown = tableH / cellHeight;
    const elSize = 4;
    for (let i = 0; i < tablePixels.length; i++) {
      const src = i * elSize + 3;
      tablePixels[i] = tableData[src] ? 1 : 0;
    }
    this.glyphMap.forEach(({chr, cellId, width}) => {
      const map = new Uint8Array(width * cellHeight);
      const srcX = (cellId % cellsAcross) * cellWidth;
      const srcY = Math.floor(cellId / cellsAcross) * cellHeight;
      let srcPtr, dstPtr;
      for (let y = 0; y < cellHeight; y++) {
        srcPtr = (srcY + y) * tableW + srcX;
        dstPtr = y * width;
        for (let x = 0; x < width; x++) {
          map[dstPtr] = tablePixels[srcPtr];
          srcPtr++;
          dstPtr++;
        }
      }
      this.glyphPixels.set(chr, map);
    });
  }

  getTextWidth(text: string) {
    const chars = text.split('');
    return chars.reduce((width, char, i) => {
      const glpyh = this.glyphMap.get(char);
      return width + glpyh.width + this.tracking;
    }, 0);
  }

  drawText(text: string, dst: Uint32Array, dstX: number, dstY: number, dstStride: number, color: number) {
    dstX = Math.floor(dstX);
    dstY = Math.floor(dstY);
    const chars = text.split('');
    chars.map((char) => {
      const { width } = this.glyphMap.get(char);
      const pixels = this.glyphPixels.get(char);
      for (let srcY = 0; srcY < this.cellHeight; srcY++) {
        let dstPtr = (dstY + srcY) * dstStride + dstX;
        let srcPtr = srcY * width;
        for (let srcX = 0; srcX < width; srcX++) {
          if (pixels[srcPtr])
            dst[dstPtr] = color;
          dstPtr++;
          srcPtr++;
        }
      }
      dstX += width + this.tracking;
    });
  }

  drawCenteredText(text: string, dst: Uint32Array, dstX: number, dstY: number, dstStride: number, color: number) {
    const textWidth = this.getTextWidth(text);
    this.drawText(text, dst, Math.floor(dstX - textWidth / 2), dstY, dstStride, color);
  }

  private parseFnt(fntBuffer: ArrayBuffer) {
    const decoder = new TextDecoder(); // defaults to utf-8
    const text = decoder.decode(fntBuffer);
    const lines = text.split(REGEX_LINEBREAK);
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (REGEX_COMMENT.test(line)) {
        const [_, comment] = line.match(REGEX_COMMENT);
        this.parseComment(comment);
      }
      else if (REGEX_PARAM.test(line)) {
        const [_, key, value] = line.match(REGEX_PARAM);
        this.parseParam(key, value);
      }
      else if (REGEX_GLYPH.test(line)) {
        const [_, glyph, width] = line.match(REGEX_GLYPH);
        this.parseGlyph(glyph, width);
      }
    }
  }

  private parseComment(comment: string) {
    if (comment.startsWith('metrics')) {
      const [_, key, value] = comment.match(REGEX_PARAM);
      if (key === 'metrics')
        this.metrics = JSON.parse(value);
    }
  }

  private parseParam(key: string, strVal: string) {
    const intVal = parseInt(strVal);
    switch (key) {
      case 'datalen':
        this.tableDataLen = intVal;
        break;
      case 'data':
        this.tableData = `data:image/png;base64,${strVal}`;
        break;
      case 'width':
        this.cellWidth = intVal;
        break;
      case 'height':
        this.cellHeight = intVal;
        break;
      case 'tracking':
        this.tracking = intVal;
        break;
      default:
        break;
    }
  }


  private parseGlyph(glyph: string, value: string) {
    if (glyph === 'space') {
      this.glyphMap.set(' ', {
        cellId: this.glyphIndex,
        width: parseInt(value),
        chr: ' '
      });
      this.glyphIndex += 1;
    }
    else if (glyph.length === 1) {
      this.glyphMap.set(glyph, {
        cellId: this.glyphIndex,
        width: parseInt(value),
        chr: glyph
      });
      this.glyphIndex += 1;
    }
    else if (glyph.length === 2) {
      this.pairMap.set(glyph, parseInt(value));
    }
  }

  private async parseTableData() {
    return new Promise<ImageData>((resolve) => {
      const img = new Image();
      img.src = this.tableData;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.naturalWidth;
        canvas.height = img.naturalHeight;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        resolve(ctx.getImageData(0, 0, canvas.width, canvas.height));
      }
    });
  }

}