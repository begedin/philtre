/* globals process */

import esbuild from 'esbuild';
import { sassPlugin } from 'esbuild-sass-plugin';

// Decide which mode to proceed with
let mode = 'build';

const sass = sassPlugin();

process.argv.slice(2).forEach((arg) => {
  if (arg === '--watch') {
    mode = 'watch';
  } else if (arg === '--deploy') {
    mode = 'deploy';
  }
});

const opts = {
  entryPoints: ['src/index.ts'],
  outdir: 'dist',
  bundle: true,
  sourcemap: true,
  splitting: true,
  watch: false,
  minify: false,
  format: 'esm',
  target: ['esnext'],
  plugins: [sass],
};

if (mode === 'watch') {
  opts.entryPoints = ['playground/js/app.ts'];
  opts.outdir = 'playground/priv/static';
  opts.watch = true;
}

if (mode === 'deploy') {
  opts.minify = true;
}

esbuild
  .build(opts)
  .then((result) => {
    if (mode === 'watch') {
      process.stdin.pipe(process.stdout);
      process.stdin.on('end', () => {
        result.stop();
      });
    }
  })
  .catch(() => {
    process.exit(1);
  });
