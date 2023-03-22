import { fileURLToPath } from 'url';
import path, { dirname } from 'path';

import glsl from 'vite-plugin-glsl';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default {
  site: 'https://playnote-studio',
  sitemap: true,
  integrations: [
    // preact()
  ],
  vite: {
    ssr: {
      external: ["svgo"],
    },
    plugins: [glsl.default()],
    resolve: {
      alias: {
        '@': `${path.resolve(__dirname, 'src')}`
      }
    },
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `@import "src/styles/vars.scss";`
        }
      }
    }
  }
};
