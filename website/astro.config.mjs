import { fileURLToPath } from 'url';
import path, { dirname } from 'path';

import preact from '@astrojs/preact';
import glsl from 'vite-plugin-glsl';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default {
  // projectRoot: '.',     // Where to resolve all URLs relative to. Useful if you have a monorepo project.
  // pages: './src/pages', // Path to Astro components, pages, and data
  // dist: './dist',       // When running `astro build`, path to final static output
  // public: './public',   // A folder of static files Astro will copy to the root. Useful for favicons, images, and other files that don’t need processing.
  buildOptions: {
    site: 'https://playnote-studio',           // Your public domain, e.g.: https://my-site.dev/. Used to generate sitemaps and canonical URLs.
    sitemap: true,         // Generate sitemap (set to "false" to disable)
  },
  devOptions: {
    // hostname: 'localhost',  // The hostname to run the dev server on.
    // port: 3000,             // The port to run the dev server on.
  },
  integrations: [
    preact()
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
