const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const output = path.join(root, 'dist');

fs.rmSync(output, { recursive: true, force: true });
fs.mkdirSync(output, { recursive: true });
fs.copyFileSync(path.join(root, 'index.html'), path.join(output, 'index.html'));

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';

fs.writeFileSync(
  path.join(output, 'config.js'),
  'window.VPU_CONFIG = Object.freeze(' + JSON.stringify({ supabaseUrl, supabaseAnonKey }, null, 2) + ');\n',
  'utf8'
);

console.log('Build concluido em dist/');
