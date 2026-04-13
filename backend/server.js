'use strict';

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const axios = require('axios');
const FormData = require('form-data');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static');
const { Readable, PassThrough } = require('stream');

// Point fluent-ffmpeg to the bundled binary — no manual ffmpeg install needed
ffmpeg.setFfmpegPath(ffmpegPath);

// ─── Config ────────────────────────────────────────────────────────────────────
const BOT_TOKEN = process.env.BOT_TOKEN;
const CHAT_ID = process.env.CHAT_ID;
const PORT = process.env.PORT || 3000;

if (!BOT_TOKEN || !CHAT_ID) {
  console.error('ERROR: BOT_TOKEN and CHAT_ID must be set in .env');
  process.exit(1);
}

const TELEGRAM_API = `https://api.telegram.org/bot${BOT_TOKEN}`;
const TELEGRAM_SIZE_LIMIT  = 20 * 1024 * 1024; 
const COMPRESS_THRESHOLD   = 20 * 1024 * 1024; 
const TARGET_SIZE_BYTES    = 16 * 1024 * 1024;    // Lowered to 16MB for faster upload
const BITRATE_MIN_KBPS     = 32;
const BITRATE_MAX_KBPS     = 128;
const NETWORK_TIMEOUT      = 600000;              // 10 minutes 


// ─── Express Setup ─────────────────────────────────────────────────────────────
const app = express();
app.use(cors());
app.use(express.json());

// ─── Multer — accept up to 500MB (we compress before sending to Telegram) ─────
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 500 * 1024 * 1024 }, // 500MB server-side limit
});

// ─── Helper: probe audio duration (seconds) via ffprobe ──────────────────────
function getDuration(inputBuffer) {
  return new Promise((resolve, reject) => {
    const inputStream = new Readable();
    inputStream.push(inputBuffer);
    inputStream.push(null);

    ffmpeg(inputStream).ffprobe((err, metadata) => {
      if (err) return reject(new Error(`ffprobe failed: ${err.message}`));
      const duration = metadata?.format?.duration;
      if (!duration || duration <= 0) return reject(new Error('Could not determine audio duration.'));
      resolve(duration);
    });
  });
}

// ─── Helper: compress audio buffer with a specific bitrate → mono MP3 ────────
// inputBuffer  : raw audio bytes (any format ffmpeg understands)
// bitrateKbps  : integer, e.g. 96
function compressAudioAtBitrate(inputBuffer, bitrateKbps) {
  return new Promise((resolve, reject) => {
    const inputStream = new Readable();
    inputStream.push(inputBuffer);
    inputStream.push(null);

    const outputChunks = [];
    const outputStream = new PassThrough();

    outputStream.on('data', chunk => outputChunks.push(chunk));
    outputStream.on('end', () => resolve(Buffer.concat(outputChunks)));
    outputStream.on('error', reject);

    ffmpeg(inputStream)
      .audioCodec('libmp3lame')
      .audioBitrate(`${bitrateKbps}k`)  // dynamic — calculated from duration
      .audioChannels(1)                  // mono for size efficiency
      .audioFrequency(44100)             // 44.1 kHz standard
      .format('mp3')
      .on('error', err => reject(new Error(`ffmpeg failed: ${err.message}`)))
      .pipe(outputStream, { end: true });
  });
}

// ─── Helper: smart compress — targets ~18.5 MB, retries on overshoot ─────────
// Returns { buffer, bitrateKbps, finalSizeMB }
async function smartCompress(inputBuffer) {
  // 1. Probe duration
  const duration = await getDuration(inputBuffer);
  console.log(`[compress] Duration: ${duration.toFixed(1)}s`);

  // 2. Calculate ideal bitrate: target_bits / duration
  const targetBits    = TARGET_SIZE_BYTES * 8;
  let bitrateKbps     = Math.round(targetBits / duration / 1000);

  // 3. Clamp within safe limits
  bitrateKbps = Math.max(BITRATE_MIN_KBPS, Math.min(BITRATE_MAX_KBPS, bitrateKbps));
  console.log(`[compress] Calculated bitrate: ${bitrateKbps} kbps`);

  // 4. First compression attempt
  console.log(`[compress] Pass 1 — encoding at ${bitrateKbps} kbps...`);
  console.time('[compress] pass1_time');
  let compressed = await compressAudioAtBitrate(inputBuffer, bitrateKbps);
  console.timeEnd('[compress] pass1_time');
  
  let finalSizeMB = compressed.length / (1024 * 1024);
  console.log(`[compress] Pass 1 result: ${finalSizeMB.toFixed(2)} MB`);

  // 5. Fail-safe: if still > 20 MB, retry with 20% lower bitrate
  if (compressed.length >= TELEGRAM_SIZE_LIMIT) {
    const retryBitrate = Math.max(BITRATE_MIN_KBPS, Math.floor(bitrateKbps * 0.80));
    console.log(`[compress] ⚠ Still over 20 MB! Retrying at ${retryBitrate} kbps...`);
    console.time('[compress] pass2_time');
    compressed  = await compressAudioAtBitrate(inputBuffer, retryBitrate);
    console.timeEnd('[compress] pass2_time');
    
    finalSizeMB = compressed.length / (1024 * 1024);
    bitrateKbps = retryBitrate;
    console.log(`[compress] Pass 2 result: ${finalSizeMB.toFixed(2)} MB`);
  }


  return { buffer: compressed, bitrateKbps, finalSizeMB };
}

// ─── Helper: get a fresh streaming URL from a Telegram file_id ────────────────
async function getFileUrl(fileId) {
  const res = await axios.get(`${TELEGRAM_API}/getFile`, {
    params: { file_id: fileId },
  });
  if (!res.data.ok) throw new Error(`getFile failed: ${res.data.description}`);
  return `https://api.telegram.org/file/bot${BOT_TOKEN}/${res.data.result.file_path}`;
}

// ─── POST /upload ──────────────────────────────────────────────────────────────
// Flow:
//   1. Receive any audio file (any size, any format)
//   2. If < 20 MB  → upload original (no quality loss)
//   3. If >= 20 MB → smart-compress targeting ~18.5 MB
//   4. Upload to Telegram (5-minute timeout)
//   5. Return stream_url (proxy) + file_id (permanent)
app.post('/upload', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file received. Field name must be "audio".' });
  }

  const originalMB    = (req.file.size / (1024 * 1024)).toFixed(2);
  const needsCompress = req.file.size >= COMPRESS_THRESHOLD;

  console.log(`[upload] Received: ${req.file.originalname} (${originalMB} MB)`);

  let audioBuffer   = req.file.buffer;
  let audioFilename = req.file.originalname;
  let compressedMB  = null;
  let finalBitrate  = null;
  let wasCompressed = false;

  // ── Skip compression for files under 20 MB ──────────────────────────────────
  if (!needsCompress) {
    console.log(`[upload] File is ${originalMB} MB < 20 MB — uploading original (no compression).`);
  } else {
    // ── Smart-compress files >= 20 MB ─────────────────────────────────────────
    console.log(`[compress] File is ${originalMB} MB >= 20 MB — starting smart compression...`);
    try {
      const result  = await smartCompress(req.file.buffer);
      audioBuffer   = result.buffer;
      finalBitrate  = result.bitrateKbps;
      compressedMB  = result.finalSizeMB.toFixed(2);
      audioFilename = audioFilename.replace(/\.[^.]+$/, '') + '_compressed.mp3';
      wasCompressed = true;
      console.log(`[compress] ✓ Done. ${originalMB} MB → ${compressedMB} MB @ ${finalBitrate} kbps`);

      // Validate compressed size before upload
      if (audioBuffer.length >= TELEGRAM_SIZE_LIMIT) {
        console.error(`[compress] ✗ Compressed file (${compressedMB} MB) still exceeds 20 MB limit!`);
        return res.status(500).json({ error: `Compression could not reduce file below 20 MB (result: ${compressedMB} MB).` });
      }
    } catch (err) {
      console.error(`[compress] Failed: ${err.message}`);
      return res.status(500).json({ error: `Compression failed: ${err.message}` });
    }
  }

  // ── Upload to Telegram ──────────────────────────────────────────────────────
  try {
    const form = new FormData();
    form.append('chat_id', CHAT_ID);
    form.append('audio', audioBuffer, {
      filename: audioFilename,
      contentType: 'audio/mpeg',
      knownLength: audioBuffer.length,
    });

    console.log(`[upload] Sending to Telegram (${(audioBuffer.length / (1024 * 1024)).toFixed(2)} MB)...`);
    console.time('[upload] telegram_time');
    
    const sendRes = await axios.post(`${TELEGRAM_API}/sendAudio`, form, {
      headers: { ...form.getHeaders() },
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      timeout: NETWORK_TIMEOUT, 
    });
    
    console.timeEnd('[upload] telegram_time');

    if (!sendRes.data.ok) {
      throw new Error(`Telegram sendAudio failed: ${sendRes.data.description}`);
    }

    const fileId = sendRes.data.result.audio.file_id;
    console.log(`[upload] Success. file_id: ${fileId}`);

    // Get a fresh streaming URL
    const telegramUrl = await getFileUrl(fileId);

    return res.json({
      success: true,
      file_id: fileId,          // ← permanent — store in data.json
      stream_url: `${req.protocol}://${req.get('host')}/stream/${fileId}`,
      telegram_url: telegramUrl,
      original_mb: originalMB,
      compressed_mb: wasCompressed ? compressedMB : null,
      was_compressed: wasCompressed,
      bitrate_kbps: finalBitrate,
    });

  } catch (err) {
    const message = err.response?.data?.description || err.message;
    console.error(`[upload] Error: ${message}`);
    return res.status(500).json({ error: `Upload failed: ${message}` });
  }
});

// ─── GET /stream/:fileId ───────────────────────────────────────────────────────
// Generates a fresh Telegram URL and redirects. just_audio follows the redirect.
// Store "http://your-server.com/stream/<file_id>" as audio_url in data.json.
app.get('/stream/:fileId', async (req, res) => {
  try {
    const freshUrl = await getFileUrl(req.params.fileId);
    return res.redirect(302, freshUrl);
  } catch (err) {
    const message = err.response?.data?.description || err.message;
    console.error(`[stream] Error: ${message}`);
    return res.status(500).json({ error: `Stream failed: ${message}` });
  }
});

// ─── GET / ─────────────────────────────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.send('PrepMantra backend running 🎧');
});

// ─── GET /health ───────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Error handler ─────────────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error(`[error] ${err.message}`);
  res.status(err.status || 500).json({ error: err.message });
});

// ─── Start ─────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`PrepMantra backend running on http://localhost:${PORT}`);
  console.log(`  GET  /           — health (Render ping)`);
  console.log(`  POST /upload     — upload any audio (auto-compresses if > 20MB)`);
  console.log(`  GET  /stream/:id — stream via file_id`);
  console.log(`  GET  /health     — health check JSON`);
});
