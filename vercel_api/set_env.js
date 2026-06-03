const fs = require('fs');
const { spawn } = require('child_process');
const path = require('path');

function addVercelEnv(key, value) {
  return new Promise((resolve, reject) => {
    console.log(`Setting Vercel env variable: ${key}...`);
    const child = spawn('npx', ['vercel', 'env', 'add', key, 'production'], {
      cwd: __dirname,
      shell: true
    });

    child.stdin.write(value + '\n');
    child.stdin.end();

    let output = '';
    child.stdout.on('data', (data) => {
      output += data.toString();
    });

    child.stderr.on('data', (data) => {
      output += data.toString();
    });

    child.on('close', (code) => {
      if (code === 0) {
        console.log(`Successfully added ${key}`);
        resolve();
      } else {
        console.error(`Failed to add ${key}:`, output);
        reject(new Error(output));
      }
    });
  });
}

async function run() {
  const envPath = path.join(__dirname, '.env');
  const envLocalPath = path.join(__dirname, '.env.local');

  const envs = {};

  if (fs.existsSync(envPath)) {
    let content = fs.readFileSync(envPath, 'utf8');
    if (content.charCodeAt(0) === 0xFEFF) {
      content = content.slice(1);
    }
    parseEnv(content, envs);
  }

  if (fs.existsSync(envLocalPath)) {
    let content = fs.readFileSync(envLocalPath, 'utf8');
    if (content.charCodeAt(0) === 0xFEFF) {
      content = content.slice(1);
    }
    parseEnv(content, envs);
  }

  for (const [key, val] of Object.entries(envs)) {
    // Skip VERCEL_OIDC_TOKEN as it's a temporary CLI token
    if (key === 'VERCEL_OIDC_TOKEN') continue;
    try {
      await addVercelEnv(key, val);
    } catch (err) {
      console.error(`Error setting ${key}:`, err.message);
    }
  }
}

function parseEnv(content, envs) {
  const lines = content.split('\n');
  let currentKey = null;
  let currentValue = [];
  let inQuotes = false;
  let quoteChar = '';

  for (let line of lines) {
    line = line.trim();
    if (!line && !inQuotes) continue;
    if (line.startsWith('#') && !inQuotes) continue;

    if (!inQuotes) {
      const eqIdx = line.indexOf('=');
      if (eqIdx > 0) {
        const key = line.substring(0, eqIdx).trim();
        let val = line.substring(eqIdx + 1).trim();

        if ((val.startsWith('"') && val.endsWith('"') && val.length >= 2) ||
            (val.startsWith("'") && val.endsWith("'") && val.length >= 2)) {
          // Single-line quoted value
          envs[key] = val.substring(1, val.length - 1).replace(/\\n/g, '\n');
        } else if (val.startsWith('"') || val.startsWith("'")) {
          // Multi-line quoted value starts
          inQuotes = true;
          quoteChar = val[0];
          currentKey = key;
          currentValue.push(val.substring(1));
        } else {
          // Unquoted value
          envs[key] = val;
        }
      }
    } else {
      if (line.endsWith(quoteChar)) {
        currentValue.push(line.substring(0, line.length - 1));
        envs[currentKey] = currentValue.join('\n').replace(/\\n/g, '\n');
        inQuotes = false;
        currentKey = null;
        currentValue = [];
      } else {
        currentValue.push(line);
      }
    }
  }
}

run().catch(console.error);
