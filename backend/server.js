'use strict';

require('dotenv').config();

const express   = require('express');
const cors      = require('cors');
const multer    = require('multer');
const axios     = require('axios');
const FormData  = require('form-data');
const ffmpeg    = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static');
const { Readable, PassThrough } = require('stream');

// Point fluent-ffmpeg to the bundled binary — no manual ffmpeg install needed
ffmpeg.setFfmpegPath(ffmpegPath);

// ─── Config ────────────────────────────────────────────────────────────────────
const BOT_TOKEN = process.env.BOT_TOKEN;
const CHAT_ID   = process.env.CHAT_ID;
const PORT      = process.env.PORT || 3000;

if (!BOT_TOKEN || !CHAT_ID) {
  console.error('ERROR: BOT_TOKEN and CHAT_ID must be set in .env');
  process.exit(1);
}

const TELEGRAM_API        = `https://api.telegram.org/bot${BOT_TOKEN}`;
const TELEGRAM_SIZE_LIMIT = 20 * 1024 * 1024; // getFile only works for <= 20MB

// ─── Express Setup ─────────────────────────────────────────────────────────────
const app = express();
app.use(cors());
app.use(express.json());

// ─── Multer — accept up to 500MB (we compress before sending to Telegram) ─────
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 500 * 1024 * 1024 }, // 500MB server-side limit
});

// ─── Helper: compress audio buffer → 64kbps mono MP3 ─────────────────────────
// Uses bundled ffmpeg. Works on any audio format (m4a, wav, ogg, mp3, etc.)
function compressAudio(inputBuffer) {
  return new Promise((resolve, reject) => {
    const inputStream  = new Readable();
    inputStream.push(inputBuffer);
    inputStream.push(null);

    const outputChunks = [];
    const outputStream = new PassThrough();

    outputStream.on('data',  chunk => outputChunks.push(chunk));
    outputStream.on('end',   ()    => resolve(Buffer.concat(outputChunks)));
    outputStream.on('error', reject);

    ffmpeg(inputStream)
      .audioCodec('libmp3lame')
      .audioBitrate('64k')      // 64kbps — good enough for speech
      .audioChannels(1)         // mono — halves the size vs stereo
      .audioFrequency(22050)    // 22kHz — sufficient for voice
      .format('mp3')
      .on('error', (err) => reject(new Error(`ffmpeg failed: ${err.message}`)))
      .pipe(outputStream, { end: true });
  });
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
//   2. If > 20MB → auto-compress to 64kbps mono MP3
//   3. Upload to Telegram
//   4. Return stream_url (proxy) + file_id (permanent)
app.post('/upload', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file received. Field name must be "audio".' });
  }

  const originalMB  = (req.file.size / (1024 * 1024)).toFixed(1);
  const needsCompress = req.file.size > TELEGRAM_SIZE_LIMIT;

  console.log(`[upload] Received: ${req.file.originalname} (${originalMB} MB)`);

  let audioBuffer   = req.file.buffer;
  let audioFilename = req.file.originalname;
  let compressedMB  = null;
  let wasCompressed = false;

  // ── Auto-compress if too large ──────────────────────────────────────────────
  if (needsCompress) {
    console.log(`[compress] File is ${originalMB}MB > 20MB — compressing to 64kbps mono MP3...`);
    try {
      audioBuffer = await compressAudio(req.file.buffer);
      audioFilename = audioFilename.replace(/\.[^.]+$/, '') + '_compressed.mp3';
      compressedMB  = (audioBuffer.length / (1024 * 1024)).toFixed(1);
      wasCompressed = true;
      console.log(`[compress] Done. ${originalMB}MB → ${compressedMB}MB`);
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
      filename:    audioFilename,
      contentType: 'audio/mpeg',
      knownLength:  audioBuffer.length,
    });

    console.log(`[upload] Sending to Telegram (${(audioBuffer.length / (1024 * 1024)).toFixed(1)}MB)...`);

    const sendRes = await axios.post(`${TELEGRAM_API}/sendAudio`, form, {
      headers: { ...form.getHeaders() },
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      timeout: 120000,
    });

    if (!sendRes.data.ok) {
      throw new Error(`Telegram sendAudio failed: ${sendRes.data.description}`);
    }

    const fileId = sendRes.data.result.audio.file_id;
    console.log(`[upload] Success. file_id: ${fileId}`);

    // Get a fresh streaming URL
    const telegramUrl = await getFileUrl(fileId);

    return res.json({
      success:       true,
      file_id:       fileId,          // ← permanent — store in data.json
      stream_url:    `${req.protocol}://${req.get('host')}/stream/${fileId}`,
      telegram_url:  telegramUrl,
      original_mb:   originalMB,
      compressed_mb: wasCompressed ? compressedMB : null,
      was_compressed: wasCompressed,
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
