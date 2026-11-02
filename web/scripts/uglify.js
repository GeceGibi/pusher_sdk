const fs = require('fs');
const path = require('path');
const terser = require('terser');

const root = path.join(__dirname, '..');
const sourcePath = path.join(root, 'pusher.js');
const outDir = path.join(root, 'dist');
const outPath = path.join(outDir, 'pusher.js');

const source = fs.readFileSync(sourcePath, 'utf8');

terser
  .minify(source, {
    compress: {
      passes: 3,
      defaults: true,
    },
    mangle: {
      toplevel: true,
    },
    format: {
      comments: false,
    },
  })
  .then((result) => {
    if (result.error) {
      throw result.error;
    }

    if (!result.code) {
      throw new Error('uglify produced empty output');
    }

    fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(outPath, result.code);
    process.stdout.write(
      `dist/pusher.js ${Buffer.byteLength(source)} -> ${Buffer.byteLength(result.code)}\n`,
    );
  })
  .catch((error) => {
    process.stderr.write(`${error.stack || error}\n`);
    process.exitCode = 1;
  });
