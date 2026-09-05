// Mind-o-Mat Webapp Production-Server
// - Serviert statische Dateien aus dist/
// - Proxied /api/* zur Tool-Container-Notes-API
// - Optional: HMAC-Bearer-Auth-Check

import express from 'express';
import { createHmac } from 'node:crypto';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const app = express();
const PORT = process.env.PORT || 5173;
const TOOL_API_URL = process.env.TOOL_API_URL || 'http://mindomat-tool:3000';
const NOTES_API_TOKEN = process.env.NOTES_API_TOKEN || '';
const ALLOWED_ORIGINS = (process.env.NOTES_API_ALLOWED_ORIGINS || '').split(',').filter(Boolean);

// Statische Dateien
const distPath = join(process.cwd(), 'dist');
if (!existsSync(distPath)) {
  console.error(`FEHLER: dist/ nicht gefunden unter ${distPath}`);
  console.error('Hast du `npm run build` ausgefuehrt?');
  process.exit(1);
}

// Manifest und Service-Worker (PWA)
app.get('/manifest.webmanifest', (_req, res) => {
  res.sendFile(join(distPath, 'manifest.webmanifest'));
});
app.get('/service-worker.js', (_req, res) => {
  res.sendFile(join(distPath, 'service-worker.js'));
});

// CORS
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (ALLOWED_ORIGINS.length === 0 || ALLOWED_ORIGINS.includes(origin) || ALLOWED_ORIGINS.includes('*')) {
    if (origin) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, POST, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    }
  }
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  next();
});

// Auth-Middleware fuer /api/* (nur wenn Token konfiguriert)
function checkAuth(req, res, next) {
  if (!NOTES_API_TOKEN) return next();
  const auth = req.headers.authorization;
  if (!auth) {
    res.status(401).send('Authorization-Header fehlt');
    return;
  }
  const [scheme, token] = auth.split(' ');
  if (scheme !== 'Bearer' || !token) {
    res.status(401).send('Authorization-Schema ungueltig');
    return;
  }
  const [ts, hmac] = token.split('.');
  if (!ts || !hmac) {
    res.status(401).send('Token-Format ungueltig');
    return;
  }
  const expected = createHmac('sha256', NOTES_API_TOKEN).update(ts).digest('hex');
  if (expected.length !== hmac.length) {
    res.status(401).send('Token ungueltig');
    return;
  }
  if (!require('node:crypto').timingSafeEqual(Buffer.from(expected), Buffer.from(hmac))) {
    res.status(401).send('Token ungueltig');
    return;
  }
  next();
}

// API-Proxy
app.use('/api', checkAuth, createProxyMiddleware({
  target: TOOL_API_URL,
  changeOrigin: true,
  pathRewrite: { '^/api': '/api' },
  onError: (err, req, res) => {
    console.error('Notes-API-Proxy-Fehler:', err.message);
    res.status(502).send('Tool-Service nicht erreichbar');
  },
}));

// Statische Frontend-Dateien (Fallback)
app.use(express.static(distPath));

// SPA-Fallback
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api/')) return next();
  const indexPath = join(distPath, 'index.html');
  if (existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('index.html nicht gefunden');
  }
});

app.listen(PORT, () => {
  console.log(`Mind-o-Mat Webapp auf Port ${PORT}`);
  console.log(`Notes-API-Proxy zu: ${TOOL_API_URL}`);
  console.log(`Auth aktiv: ${NOTES_API_TOKEN ? 'JA' : 'NEIN (offen)'}`);
});
