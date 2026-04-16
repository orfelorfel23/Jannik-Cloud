const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');

require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : '*',
    credentials: true,
}));
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Auth Middleware
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin';
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

// --- Auth Endpoints ---
app.post('/api/admin/login', (req, res) => {
  const { password } = req.body;
  if (password === ADMIN_PASSWORD) {
    const token = jwt.sign({ admin: true }, JWT_SECRET, { expiresIn: '1d' });
    res.json({ token });
  } else {
    res.status(401).json({ error: 'Falsches Passwort' });
  }
});

// --- Admin Links Endpoints ---
app.get('/api/admin/links', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM access_links ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/admin/links', authenticateToken, async (req, res) => {
  const { username, label, target_url_base, max_views, expires_at, is_active } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO access_links (username, label, target_url_base, max_views, expires_at, is_active) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [username, label, target_url_base || '', max_views || null, expires_at || null, is_active !== false]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Erstellen' });
  }
});

app.put('/api/admin/links/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { username, label, target_url_base, max_views, expires_at, is_active } = req.body;
  try {
    const result = await pool.query(
      `UPDATE access_links SET username = $1, label = $2, target_url_base = $3, max_views = $4, expires_at = $5, is_active = $6 
       WHERE id = $7 RETURNING *`,
      [username, label, target_url_base || '', max_views || null, expires_at || null, is_active, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Aktualisieren' });
  }
});

app.delete('/api/admin/links/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM access_links WHERE id = $1', [id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Löschen' });
  }
});

// --- Admin Routes Endpoints ---
app.get('/api/admin/links/:id/routes', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('SELECT * FROM content_routes WHERE link_id = $1', [id]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/admin/links/:id/routes', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { path, target_url, label } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO content_routes (link_id, path, target_url, label) VALUES ($1, $2, $3, $4) RETURNING *',
      [id, path, target_url, label]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Erstellen' });
  }
});

app.delete('/api/admin/routes/:routeId', authenticateToken, async (req, res) => {
  const { routeId } = req.params;
  try {
    await pool.query('DELETE FROM content_routes WHERE id = $1', [routeId]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Löschen' });
  }
});

// --- Admin Logs Endpoint ---
app.get('/api/admin/links/:id/logs', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('SELECT * FROM access_logs WHERE link_id = $1 ORDER BY accessed_at DESC', [id]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// --- Public Validate Endpoint ---
app.post('/api/validate', async (req, res) => {
  const { username, path } = req.body;
  
  try {
    const linkRes = await pool.query('SELECT * FROM access_links WHERE username = $1', [username]);
    if (linkRes.rows.length === 0) {
      return res.status(403).json({ error: 'Benutzer nicht gefunden' });
    }
    
    const link = linkRes.rows[0];
    
    if (!link.is_active) {
      return res.status(403).json({ error: 'Zugang deaktiviert' });
    }
    
    if (link.expires_at && new Date() > new Date(link.expires_at)) {
      return res.status(403).json({ error: 'Zugang abgelaufen' });
    }
    
    if (link.max_views !== null && link.views_count >= link.max_views) {
      return res.status(403).json({ error: 'Maximale Aufrufe erreicht' });
    }
    
    // Increment views immediately
    await pool.query('UPDATE access_links SET views_count = views_count + 1 WHERE id = $1', [link.id]);
    
    // Find target route
    const routeRes = await pool.query('SELECT * FROM content_routes WHERE link_id = $1 AND path = $2', [link.id, path]);
    
    let targetUrl = '';
    let label = '';
    if (routeRes.rows.length > 0) {
      targetUrl = routeRes.rows[0].target_url;
      label = routeRes.rows[0].label || link.label;
    } else {
      // Use fallback target base URL
      if (link.target_url_base) {
         targetUrl = `${link.target_url_base}${path}`;
         label = link.label;
      } else {
         return res.status(404).json({ error: 'Pfad nicht gefunden' });
      }
    }
    
    // Log access
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    await pool.query('INSERT INTO access_logs (link_id, path, ip_address) VALUES ($1, $2, $3)', [link.id, path, ip]);
    
    res.json({ target_url: targetUrl, label: label });
    
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server Fehler' });
  }
});

// Ensure tables exist on boot
pool.query(`
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

  CREATE TABLE IF NOT EXISTS access_links (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      username VARCHAR(255) NOT NULL UNIQUE,
      label VARCHAR(255),
      target_url_base VARCHAR(255),
      max_views INTEGER,
      expires_at TIMESTAMP WITH TIME ZONE,
      views_count INTEGER DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS content_routes (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      link_id UUID REFERENCES access_links(id) ON DELETE CASCADE,
      path VARCHAR(255) NOT NULL,
      target_url TEXT NOT NULL,
      label VARCHAR(255),
      UNIQUE(link_id, path)
  );

  CREATE TABLE IF NOT EXISTS access_logs (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      link_id UUID REFERENCES access_links(id) ON DELETE CASCADE,
      path VARCHAR(255) NOT NULL,
      ip_address VARCHAR(45) NOT NULL,
      accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
`).then(() => console.log('Database schema verified.'))
  .catch((err) => console.error('Error verifying database schema', err));


app.listen(port, () => {
  console.log(`Content Vault API listening on port ${port}`);
});
