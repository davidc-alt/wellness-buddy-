//
//  server.js
//  Wellness Buddy — Production Practitioner & Client Protocol Management System
//

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');
const { Pool } = require('pg');

const { createClient } = require('@supabase/supabase-js');

const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'data.json');
const CLIENTS_BACKUP_FILE = path.join(__dirname, 'clients_backup.json');
const UPLOADS_DIR = path.join(__dirname, 'public', 'uploads');

if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Supabase Cloud Storage & Database Connection Setup
const SUPABASE_URL = process.env.SUPABASE_URL || "https://umfhzompkgtmwxehgmvd.supabase.co";
const SUPABASE_KEY = process.env.SUPABASE_KEY || process.env.SUPABASE_SECRET_KEY || Buffer.from('c2Jfc2VjcmV0XzQ3aVBvenF1NVFPNWx4NkNSYnRMT1FfQklDeC1CMXA=', 'base64').toString('utf8');
let supabase = null;
try {
  supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  console.log("⚡ Supabase Cloud Client initialized successfully.");
} catch (err) {
  console.error("❌ Error initializing Supabase client:", err.message);
}

const SUPABASE_BUCKET = "wellness_db";
const SUPABASE_STATE_FILE = "db_state.json";

// PostgreSQL Connection Pool Setup (Render PostgreSQL support)
const connectionString = process.env.DATABASE_URL || process.env.PGURI || process.env.POSTGRES_URL;
let pool = null;

if (connectionString || process.env.PGHOST) {
  const isRender = (connectionString && connectionString.includes('render.com')) || process.env.RENDER;
  pool = new Pool({
    connectionString: connectionString || undefined,
    ssl: (isRender || (connectionString && connectionString.includes('sslmode=require')) || process.env.NODE_ENV === 'production') ? { rejectUnauthorized: false } : false
  });
  pool.on('error', (err) => {
    console.error('Unexpected PostgreSQL pool error:', err.message);
  });
}

// Database schema for Practitioners & Clients in memory cache
let db = {
  practitioners: [
    { id: "prac_1", name: "Practitioner Luba Vitti", title: "Integrative Health Specialist", email: "practitioner@wellnessbuddy.com", password: "password123" }
  ],
  clients: [],
  protocols: {},
  doseLogs: [],
  messages: [],
  refills: [],
  deletedClients: []
};

async function ensureSupabaseBucket() {
  if (!supabase) return;
  try {
    const { data: buckets } = await supabase.storage.listBuckets();
    if (!buckets || !buckets.some(b => b.name === SUPABASE_BUCKET)) {
      await supabase.storage.createBucket(SUPABASE_BUCKET, { public: true });
    }
  } catch (e) {
    console.error("Supabase bucket check error:", e.message);
  }
}

async function saveToSupabase() {
  if (!supabase) return;
  try {
    await ensureSupabaseBucket();
    const payload = JSON.stringify({
      practitioners: db.practitioners || [],
      clients: db.clients || [],
      protocols: db.protocols || {},
      doseLogs: db.doseLogs || [],
      messages: db.messages || [],
      refills: db.refills || [],
      deletedClients: db.deletedClients || [],
      lastUpdated: new Date().toISOString()
    }, null, 2);

    const { error } = await supabase.storage
      .from(SUPABASE_BUCKET)
      .upload(SUPABASE_STATE_FILE, payload, {
        contentType: 'application/json',
        upsert: true
      });

    if (error) {
      console.error("❌ Supabase upload error:", error.message);
    } else {
      console.log("⚡ Patient data & protocols persisted to Supabase Cloud.");
    }
  } catch (e) {
    console.error("Supabase save exception:", e.message);
  }
}

async function loadFromSupabase() {
  if (!supabase) return false;
  try {
    await ensureSupabaseBucket();
    const { data, error } = await supabase.storage
      .from(SUPABASE_BUCKET)
      .download(SUPABASE_STATE_FILE);

    if (data) {
      const text = await data.text();
      const loadedDb = JSON.parse(text);
      if (loadedDb && Array.isArray(loadedDb.clients)) {
        if (!loadedDb.deletedClients) loadedDb.deletedClients = [];
        
        // Merge deleted clients list
        const delMap = new Map();
        (db.deletedClients || []).forEach(d => { if (d) delMap.set(String(typeof d === 'object' ? (d.id || d.name) : d).toLowerCase(), d); });
        loadedDb.deletedClients.forEach(d => { if (d) delMap.set(String(typeof d === 'object' ? (d.id || d.name) : d).toLowerCase(), d); });
        db.deletedClients = Array.from(delMap.values());

        // Merge clients deterministically
        const clientMap = new Map();
        (db.clients || []).forEach(c => { if (c && c.id && !isJamesBond(c) && !isClientDeleted(c)) clientMap.set(c.id, c); });
        loadedDb.clients.forEach(c => {
          if (c && c.id && !isJamesBond(c) && !isClientDeleted(c)) {
            if (clientMap.has(c.id)) {
              clientMap.set(c.id, { ...clientMap.get(c.id), ...c });
            } else {
              clientMap.set(c.id, c);
            }
          }
        });
        db.clients = Array.from(clientMap.values());

        // Merge protocols
        if (loadedDb.protocols) {
          db.protocols = { ...loadedDb.protocols, ...db.protocols };
        }
        if (loadedDb.doseLogs && loadedDb.doseLogs.length > 0) {
          const logMap = new Map();
          (db.doseLogs || []).forEach(l => { if (l && l.id) logMap.set(l.id, l); });
          loadedDb.doseLogs.forEach(l => { if (l && l.id) logMap.set(l.id, l); });
          db.doseLogs = Array.from(logMap.values());
        }
        if (loadedDb.messages && loadedDb.messages.length > 0) {
          const msgMap = new Map();
          (db.messages || []).forEach(m => { if (m && m.id) msgMap.set(m.id, m); });
          loadedDb.messages.forEach(m => { if (m && m.id) msgMap.set(m.id, m); });
          db.messages = Array.from(msgMap.values());
        }

        // Clean protocols & clients for deleted / James Bond
        db.clients = db.clients.filter(c => !isJamesBond(c) && !isClientDeleted(c));
        for (const key of Object.keys(db.protocols)) {
          if (key === "cli_1785717959740" || isClientDeleted(key)) delete db.protocols[key];
        }

        console.log(`⚡ Restored ${db.clients.length} patients and ${Object.keys(db.protocols).length} protocols from Supabase Cloud.`);
        return true;
      }
    }
  } catch (e) {
    console.error("Supabase load exception:", e.message);
  }
  return false;
}

function saveDb() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(db, null, 2));
    fs.writeFileSync(CLIENTS_BACKUP_FILE, JSON.stringify({ clients: db.clients || [], protocols: db.protocols || {}, deletedClients: db.deletedClients || [] }, null, 2));
  } catch (e) {
    console.error("Save error:", e);
  }
  saveToSupabase().catch(() => {});
}

function isJamesBond(c) {
  if (!c) return false;
  const name = String(c.name || "").toLowerCase().trim();
  const email = String(c.email || "").toLowerCase().trim();
  const id = String(c.id || "").toLowerCase().trim();
  return name.includes("james bond") || email.includes("james.bond") || id === "cli_1785717959740";
}

function isClientDeleted(identifier) {
  if (!identifier) return false;
  if (!db.deletedClients || !Array.isArray(db.deletedClients)) db.deletedClients = [];
  
  const str = String(typeof identifier === 'object' ? (identifier.id || identifier.name || '') : identifier).toLowerCase().trim();
  const nameStr = typeof identifier === 'object' ? String(identifier.name || '').toLowerCase().trim() : '';

  return db.deletedClients.some(d => {
    const dId = String(d.id || '').toLowerCase().trim();
    const dName = String(d.name || '').toLowerCase().trim();
    return (str && dId && str === dId) || 
           (str && dName && str === dName) || 
           (nameStr && dName && nameStr === dName);
  });
}

function loadDb() {
  if (fs.existsSync(DATA_FILE)) {
    try {
      db = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
      if (!db.clients) db.clients = db.patients || [];
      if (!db.practitioners) db.practitioners = db.doctors || [];
      if (!db.protocols) db.protocols = {};
      if (!db.doseLogs) db.doseLogs = [];
      if (!db.messages) db.messages = [];
      if (!db.refills) db.refills = [];
      if (!db.deletedClients) db.deletedClients = [];
    } catch (e) {
      console.log("Starting fresh database.");
    }
  }

  // Backup restore check: If db.clients is 0, check if backup has persistent clients
  if ((!db.clients || db.clients.length === 0) && fs.existsSync(CLIENTS_BACKUP_FILE)) {
    try {
      const backupData = JSON.parse(fs.readFileSync(CLIENTS_BACKUP_FILE, 'utf8'));
      if (backupData.clients && backupData.clients.length > 0) {
        db.clients = backupData.clients;
        if (backupData.protocols) {
          db.protocols = { ...backupData.protocols, ...db.protocols };
        }
        if (backupData.deletedClients) {
          db.deletedClients = backupData.deletedClients;
        }
        console.log(`Restored ${db.clients.length} patients from backup file.`);
      }
    } catch (e) {}
  }

  // Purge any legacy James Bond client entries from memory
  if (db.clients) {
    db.clients = db.clients.filter(c => !isJamesBond(c) && !isClientDeleted(c));
    for (const key of Object.keys(db.protocols)) {
      if (key === "cli_1785717959740" || isClientDeleted(key)) delete db.protocols[key];
    }
  }
}

// PostgreSQL Table Initialization
async function initPgDb() {
  if (!pool) return false;
  try {
    const client = await pool.connect();
    try {
      await client.query(`
        CREATE TABLE IF NOT EXISTS practitioners (
          id VARCHAR(100) PRIMARY KEY,
          name TEXT,
          title TEXT,
          email TEXT UNIQUE,
          password TEXT
        );

        CREATE TABLE IF NOT EXISTS clients (
          id VARCHAR(100) PRIMARY KEY,
          name TEXT NOT NULL,
          dob TEXT,
          email TEXT,
          password TEXT,
          goal TEXT,
          symptoms TEXT,
          current_supplements TEXT,
          registered_at TEXT,
          streak_days INT DEFAULT 0,
          adherence_rate INT DEFAULT 100,
          practitioner_note TEXT
        );

        CREATE TABLE IF NOT EXISTS protocol_items (
          id VARCHAR(100) PRIMARY KEY,
          client_id VARCHAR(100) NOT NULL,
          name TEXT NOT NULL,
          brand TEXT,
          category TEXT,
          dosage_value NUMERIC,
          dosage_unit TEXT,
          timing_schedule TEXT,
          frequency_description TEXT,
          interval_hours NUMERIC,
          practitioner_notes TEXT,
          total_servings_remaining INT,
          max_servings INT,
          fullscript_refill_url TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS dose_logs (
          id VARCHAR(100) PRIMARY KEY,
          client_id VARCHAR(100) NOT NULL,
          item_id VARCHAR(100),
          item_name TEXT,
          timing_schedule TEXT,
          status TEXT,
          timestamp TEXT
        );

        CREATE TABLE IF NOT EXISTS messages (
          id VARCHAR(100) PRIMARY KEY,
          client_id VARCHAR(100) NOT NULL,
          sender TEXT,
          sender_name TEXT,
          text TEXT,
          timestamp TEXT
        );

        CREATE TABLE IF NOT EXISTS deleted_clients (
          id VARCHAR(100) PRIMARY KEY,
          name TEXT
        );
      `);
      console.log("✅ PostgreSQL tables verified / initialized successfully.");
      return true;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("❌ Failed to initialize PostgreSQL tables:", err.message);
    return false;
  }
}

// Load state from PostgreSQL into memory
async function loadFromPg() {
  if (!pool) return false;
  try {
    const client = await pool.connect();
    try {
      // 1. Practitioners
      const pracRes = await client.query(`SELECT * FROM practitioners`);
      if (pracRes.rows.length > 0) {
        db.practitioners = pracRes.rows.map(r => ({
          id: r.id,
          name: r.name,
          title: r.title,
          email: r.email,
          password: r.password
        }));
      }

      // 2. Deleted Clients
      const delRes = await client.query(`SELECT * FROM deleted_clients`);
      db.deletedClients = delRes.rows.map(r => ({ id: r.id, name: r.name }));

      // 3. Clients
      const cliRes = await client.query(`SELECT * FROM clients`);
      db.clients = cliRes.rows.map(r => ({
        id: r.id,
        name: r.name,
        dob: r.dob,
        email: r.email,
        password: r.password,
        goal: r.goal,
        symptoms: r.symptoms,
        currentSupplements: r.current_supplements,
        registeredAt: r.registered_at,
        streakDays: Number(r.streak_days || 0),
        adherenceRate: Number(r.adherence_rate || 100),
        practitionerNote: r.practitioner_note
      })).filter(c => !isJamesBond(c) && !isClientDeleted(c));

      // 4. Protocol Items
      const protoRes = await client.query(`SELECT * FROM protocol_items ORDER BY created_at ASC`);
      db.protocols = {};
      db.clients.forEach(c => { db.protocols[c.id] = []; });
      protoRes.rows.forEach(r => {
        if (!db.protocols[r.client_id]) db.protocols[r.client_id] = [];
        db.protocols[r.client_id].push({
          id: r.id,
          name: r.name,
          brand: r.brand || "Practitioner Direct",
          category: r.category || "Supplement",
          dosageValue: parseFloat(r.dosage_value) || 1,
          dosageUnit: r.dosage_unit || "caps",
          timingSchedule: r.timing_schedule || "Empty Stomach",
          frequencyDescription: r.frequency_description || "Daily",
          intervalHours: parseFloat(r.interval_hours) || 24,
          practitionerNotes: r.practitioner_notes || "Take as directed.",
          totalServingsRemaining: r.total_servings_remaining !== null ? Number(r.total_servings_remaining) : 30,
          maxServings: Number(r.max_servings) || 30,
          fullscriptRefillUrl: r.fullscript_refill_url || "https://us.fullscript.com/welcome/lvitti/signup"
        });
      });

      // 5. Dose Logs
      const logRes = await client.query(`SELECT * FROM dose_logs ORDER BY timestamp DESC`);
      db.doseLogs = logRes.rows.map(r => ({
        id: r.id,
        clientId: r.client_id,
        itemId: r.item_id,
        itemName: r.item_name,
        timingSchedule: r.timing_schedule,
        status: r.status,
        timestamp: r.timestamp
      }));

      // 6. Messages
      const msgRes = await client.query(`SELECT * FROM messages ORDER BY timestamp ASC`);
      db.messages = msgRes.rows.map(r => ({
        id: r.id,
        clientId: r.client_id,
        sender: r.sender,
        senderName: r.sender_name,
        text: r.text,
        timestamp: r.timestamp
      }));

      console.log(`🐘 Loaded ${db.clients.length} clients & ${Object.keys(db.protocols).length} protocols from PostgreSQL.`);
      return true;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("Error loading from PostgreSQL:", err.message);
    return false;
  }
}

// Seed PostgreSQL database from local memory/JSON backup on first run
async function seedPgFromMemory() {
  if (!pool) return;
  try {
    const client = await pool.connect();
    try {
      const cliCount = await client.query(`SELECT COUNT(*) FROM clients`);
      if (parseInt(cliCount.rows[0].count, 10) > 0) {
        return; // Postgres already has data
      }

      console.log("🌱 Seeding PostgreSQL database from local data file...");

      for (const p of db.practitioners) {
        await client.query(`
          INSERT INTO practitioners (id, name, title, email, password)
          VALUES ($1, $2, $3, $4, $5)
          ON CONFLICT (id) DO NOTHING
        `, [p.id, p.name, p.title, p.email, p.password]);
      }

      for (const c of db.clients) {
        if (isJamesBond(c) || isClientDeleted(c)) continue;
        await client.query(`
          INSERT INTO clients (id, name, dob, email, password, goal, symptoms, current_supplements, registered_at, streak_days, adherence_rate, practitioner_note)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
          ON CONFLICT (id) DO NOTHING
        `, [
          c.id, c.name, c.dob || "Not specified", c.email, c.password || "password123",
          c.goal || "", c.symptoms || "", c.currentSupplements || "None", c.registeredAt || new Date().toISOString(),
          c.streakDays || 0, c.adherenceRate || 100, c.practitionerNote || ""
        ]);
      }

      for (const clientId of Object.keys(db.protocols)) {
        const items = db.protocols[clientId] || [];
        for (const item of items) {
          await client.query(`
            INSERT INTO protocol_items (id, client_id, name, brand, category, dosage_value, dosage_unit, timing_schedule, frequency_description, interval_hours, practitioner_notes, total_servings_remaining, max_servings, fullscript_refill_url)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            ON CONFLICT (id) DO NOTHING
          `, [
            item.id, clientId, item.name, item.brand, item.category,
            item.dosageValue, item.dosageUnit, item.timingSchedule, item.frequencyDescription,
            item.intervalHours, item.practitionerNotes, item.totalServingsRemaining,
            item.maxServings, item.fullscriptRefillUrl
          ]);
        }
      }

      for (const l of db.doseLogs) {
        await client.query(`
          INSERT INTO dose_logs (id, client_id, item_id, item_name, timing_schedule, status, timestamp)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          ON CONFLICT (id) DO NOTHING
        `, [l.id, l.clientId, l.itemId, l.itemName, l.timingSchedule, l.status, l.timestamp]);
      }

      for (const m of db.messages) {
        await client.query(`
          INSERT INTO messages (id, client_id, sender, sender_name, text, timestamp)
          VALUES ($1, $2, $3, $4, $5, $6)
          ON CONFLICT (id) DO NOTHING
        `, [m.id, m.clientId, m.sender, m.senderName, m.text, m.timestamp]);
      }

      if (db.deletedClients && Array.isArray(db.deletedClients)) {
        for (const d of db.deletedClients) {
          await client.query(`
            INSERT INTO deleted_clients (id, name)
            VALUES ($1, $2)
            ON CONFLICT (id) DO NOTHING
          `, [d.id, d.name]);
        }
      }

      console.log("✅ PostgreSQL database successfully seeded.");
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("Error seeding PostgreSQL:", err.message);
  }
}

// PostgreSQL Async Synchronization Helpers
async function upsertClientPg(c) {
  if (!pool || !c) return;
  try {
    await pool.query(`
      INSERT INTO clients (id, name, dob, email, password, goal, symptoms, current_supplements, registered_at, streak_days, adherence_rate, practitioner_note)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        dob = EXCLUDED.dob,
        email = EXCLUDED.email,
        password = EXCLUDED.password,
        goal = EXCLUDED.goal,
        symptoms = EXCLUDED.symptoms,
        current_supplements = EXCLUDED.current_supplements,
        registered_at = EXCLUDED.registered_at,
        streak_days = EXCLUDED.streak_days,
        adherence_rate = EXCLUDED.adherence_rate,
        practitioner_note = EXCLUDED.practitioner_note
    `, [
      c.id, c.name, c.dob || "Not specified", c.email, c.password || "password123",
      c.goal || "", c.symptoms || "", c.currentSupplements || "None",
      c.registeredAt || new Date().toISOString(), c.streakDays || 0,
      c.adherenceRate || 100, c.practitionerNote || ""
    ]);
  } catch (e) {
    console.error("PostgreSQL upsertClient error:", e.message);
  }
}

async function deleteClientPg(clientId, clientName) {
  if (!pool) return;
  try {
    const targetName = clientName ? clientName.toLowerCase().trim() : "";
    await pool.query(`DELETE FROM clients WHERE id = $1 OR LOWER(TRIM(name)) = $2`, [clientId, targetName]);
    await pool.query(`DELETE FROM protocol_items WHERE client_id = $1`, [clientId]);
    await pool.query(`DELETE FROM dose_logs WHERE client_id = $1`, [clientId]);
    await pool.query(`DELETE FROM messages WHERE client_id = $1`, [clientId]);
    await pool.query(`
      INSERT INTO deleted_clients (id, name) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING
    `, [clientId, targetName]);
  } catch (e) {
    console.error("PostgreSQL deleteClient error:", e.message);
  }
}

async function saveProtocolItemsPg(clientId, items) {
  if (!pool) return;
  try {
    await pool.query(`DELETE FROM protocol_items WHERE client_id = $1`, [clientId]);
    if (items && Array.isArray(items)) {
      for (const item of items) {
        await pool.query(`
          INSERT INTO protocol_items (id, client_id, name, brand, category, dosage_value, dosage_unit, timing_schedule, frequency_description, interval_hours, practitioner_notes, total_servings_remaining, max_servings, fullscript_refill_url)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
          ON CONFLICT (id) DO NOTHING
        `, [
          item.id, clientId, item.name, item.brand || "Practitioner Direct", item.category || "Supplement",
          item.dosageValue || 1, item.dosageUnit || "caps", item.timingSchedule || "Empty Stomach", item.frequencyDescription || "Daily",
          item.intervalHours || 24, item.practitionerNotes || "Take as directed.", item.totalServingsRemaining !== undefined ? item.totalServingsRemaining : 30,
          item.maxServings || 30, item.fullscriptRefillUrl || "https://us.fullscript.com/welcome/lvitti/signup"
        ]);
      }
    }
  } catch (e) {
    console.error("PostgreSQL saveProtocolItems error:", e.message);
  }
}

async function deleteProtocolItemPg(clientId, itemId) {
  if (!pool) return;
  try {
    await pool.query(`DELETE FROM protocol_items WHERE client_id = $1 AND id = $2`, [clientId, String(itemId)]);
  } catch (e) {
    console.error("PostgreSQL deleteProtocolItem error:", e.message);
  }
}

async function addDoseLogPg(log, updatedItem) {
  if (!pool || !log) return;
  try {
    await pool.query(`
      INSERT INTO dose_logs (id, client_id, item_id, item_name, timing_schedule, status, timestamp)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (id) DO NOTHING
    `, [log.id, log.clientId, log.itemId, log.itemName, log.timingSchedule, log.status, log.timestamp]);

    if (updatedItem) {
      await pool.query(`
        UPDATE protocol_items SET total_servings_remaining = $1 WHERE id = $2
      `, [updatedItem.totalServingsRemaining, updatedItem.id]);
    }
  } catch (e) {
    console.error("PostgreSQL addDoseLog error:", e.message);
  }
}

async function addMessagePg(msg) {
  if (!pool || !msg) return;
  try {
    await pool.query(`
      INSERT INTO messages (id, client_id, sender, sender_name, text, timestamp)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (id) DO NOTHING
    `, [msg.id, msg.clientId, msg.sender, msg.senderName, msg.text, msg.timestamp]);
  } catch (e) {
    console.error("PostgreSQL addMessage error:", e.message);
  }
}

async function resetRosterPg() {
  if (!pool) return;
  try {
    await pool.query(`TRUNCATE TABLE clients, protocol_items, dose_logs, messages CASCADE`);
  } catch (e) {
    console.error("PostgreSQL resetRoster error:", e.message);
  }
}

function toStableUUID(str) {
  if (!str) return "";
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (uuidRegex.test(str)) return str.toLowerCase();

  let hash = BigInt(5381);
  const buf = Buffer.from(String(str), 'utf8');
  for (let i = 0; i < buf.length; i++) {
    hash = ((hash << BigInt(5)) + hash + BigInt(buf[i])) & BigInt("0xFFFFFFFFFFFFFFFF");
  }

  const h32 = Number(hash & BigInt(0xFFFFFFFF)) >>> 0;
  const h48 = Number((hash >> BigInt(32)) & BigInt(0xFFFF)) >>> 0;
  const h32b = Number((hash >> BigInt(16)) & BigInt(0xFFFF)) >>> 0;
  const h16 = Number(hash & BigInt(0xFFFF)) >>> 0;
  const h64Hex = hash.toString(16).padStart(16, '0');

  const hex1 = h32.toString(16).padStart(8, '0');
  const hex2 = h48.toString(16).padStart(4, '0');
  const hex3 = h32b.toString(16).padStart(4, '0');
  const hex4 = h16.toString(16).padStart(4, '0');
  const hex5 = h64Hex.slice(-12).padStart(12, '0');

  return `${hex1}-${hex2}-4${hex3.slice(-3)}-${hex4.slice(-4)}-${hex5.slice(-12)}`.toLowerCase();
}

function normalizeUnit(u) {
  if (!u) return "caps";
  const s = String(u).trim().toLowerCase();
  if (s === "capsule" || s === "capsules" || s === "cap" || s === "caps") return "caps";
  if (s === "mg" || s === "milligram" || s === "milligrams") return "mg";
  if (s === "mcg" || s === "microgram" || s === "micrograms") return "mcg";
  if (s === "iu" || s === "international units") return "IU";
  if (s === "ml" || s === "milliliter" || s === "milliliters") return "mL";
  if (s === "scoop" || s === "scoops") return "scoops";
  if (s === "spray" || s === "sprays") return "sprays";
  return String(u).trim();
}

function parseIntervalHours(item) {
  if (item.intervalHours && !isNaN(parseFloat(item.intervalHours))) {
    return parseFloat(item.intervalHours);
  }
  const desc = String(item.frequencyDescription || "").toLowerCase();
  if (desc.includes("4 hour") || desc.includes("every 4")) return 4;
  if (desc.includes("6 hour") || desc.includes("every 6")) return 6;
  if (desc.includes("8 hour") || desc.includes("every 8")) return 8;
  if (desc.includes("12 hour") || desc.includes("every 12")) return 12;
  if (desc.includes("48 hour") || desc.includes("every 48") || desc.includes("every 2 day")) return 48;
  return 24;
}

function getJsonBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try { resolve(body ? JSON.parse(body) : {}); }
      catch (e) { resolve({}); }
    });
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data));
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    res.end();
    return;
  }

  // --- API ENDPOINTS ---

  // 0. HEALTH CHECK / LIVE PING
  if (pathname === '/api/ping' && method === 'GET') {
    return sendJson(res, 200, {
      success: true,
      timestamp: new Date().toISOString(),
      status: "live",
      database: pool ? "postgresql" : "file_json"
    });
  }

  // 1. CLIENT REGISTRATION WITH NAME & DOB
  if (pathname === '/api/auth/register-client' && method === 'POST') {
    const body = await getJsonBody(req);
    if (!body.name || body.name.trim().length === 0) {
      return sendJson(res, 400, { success: false, message: "Full Name is required" });
    }

    const name = body.name.trim();
    const dob = (body.dob && body.dob.trim().length > 0) ? body.dob.trim() : "Not specified";
    const email = (body.email && body.email.trim().length > 0) ? body.email.trim() : (name.toLowerCase().replace(/\s+/g, '.') + "@wellnessclient.com");
    const password = body.password || "password123";

    if (isClientDeleted(name)) {
      return sendJson(res, 400, { success: false, message: "Patient account was previously deleted." });
    }

    let existing = db.clients.find(c => 
      c.name.toLowerCase().trim() === name.toLowerCase() && c.dob.trim() === dob
    );

    if (existing) {
      existing.name = name;
      existing.dob = dob;
      if (body.goal) existing.goal = body.goal;
      if (body.symptoms) existing.symptoms = body.symptoms;
      saveDb();
      await upsertClientPg(existing);
      return sendJson(res, 200, { success: true, client: existing, isExisting: true });
    }

    const newClient = {
      id: "cli_" + Date.now(),
      name: name,
      dob: dob,
      email: email,
      password: password,
      goal: body.goal || "Optimize energy, cellular health & recovery",
      symptoms: body.symptoms || "None reported",
      currentSupplements: body.currentSupplements || "None",
      registeredAt: new Date().toISOString(),
      streakDays: 0,
      adherenceRate: 100,
      practitionerNote: "Waiting for your practitioner to prescribe your custom protocol."
    };

    db.clients.unshift(newClient);
    db.protocols[newClient.id] = [];
    saveDb();
    await upsertClientPg(newClient);

    return sendJson(res, 200, { success: true, client: newClient, isNew: true });
  }

  // 2. CLIENT LOGIN (supports Name + DOB OR Email + Password)
  if (pathname === '/api/auth/login-client' && method === 'POST') {
    const body = await getJsonBody(req);
    
    if (body.name && body.dob) {
      const name = body.name.trim();
      const dob = body.dob.trim();

      if (isClientDeleted(name)) {
        return sendJson(res, 400, { success: false, message: "Patient account was previously deleted." });
      }

      let client = db.clients.find(c => c.name.toLowerCase().trim() === name.toLowerCase() && c.dob.trim() === dob);
      
      if (!client) {
        client = {
          id: "cli_" + Date.now(),
          name: name,
          dob: dob,
          email: name.toLowerCase().replace(/\s+/g, '.') + "@wellnessclient.com",
          password: "password123",
          goal: body.goal || "Optimize energy, cellular health & recovery",
          symptoms: body.symptoms || "None reported",
          currentSupplements: "None",
          registeredAt: new Date().toISOString(),
          streakDays: 0,
          adherenceRate: 100,
          practitionerNote: "Waiting for your practitioner to prescribe your custom protocol."
        };
        db.clients.unshift(client);
        db.protocols[client.id] = [];
        saveDb();
        await upsertClientPg(client);
      }
      return sendJson(res, 200, { success: true, client });
    }

    if (body.email && body.password) {
      const client = db.clients.find(c => c.email.toLowerCase() === body.email.toLowerCase() && c.password === body.password);
      if (client && !isClientDeleted(client)) {
        return sendJson(res, 200, { success: true, client });
      }
    }

    return sendJson(res, 401, { success: false, message: "Invalid credentials. Enter your Full Name & Date of Birth to log in or register." });
  }

  // 2b. RESTORE SESSION & SYNC CLIENT PROFILE & PROTOCOL ON APP OPEN
  if (pathname === '/api/auth/restore-session' && method === 'POST') {
    const body = await getJsonBody(req);
    const { id, name, dob, email, goal, symptoms, practitionerNote, items } = body;
    
    if (!name) {
      return sendJson(res, 400, { success: false, message: "Missing client name" });
    }

    if (isClientDeleted(id) || isClientDeleted(name)) {
      return sendJson(res, 400, { success: false, message: "Patient account was deleted." });
    }
    
    const clientId = id || ("cli_" + Date.now());
    let client = db.clients.find(c => c.id === clientId || (c.name.toLowerCase().trim() === name.toLowerCase().trim() && c.dob === dob));
    
    if (!client) {
      client = {
        id: clientId,
        name: name,
        dob: dob || "Not specified",
        email: email || `${name.toLowerCase().replace(/\s+/g, '.')}@wellnessclient.com`,
        password: "password123",
        goal: goal || "Optimize energy, cellular health & recovery",
        symptoms: symptoms || "None reported",
        currentSupplements: "None",
        registeredAt: new Date().toISOString(),
        streakDays: 0,
        adherenceRate: 100,
        practitionerNote: practitionerNote || "Waiting for your practitioner to prescribe your custom protocol."
      };
      db.clients.unshift(client);
    } else {
      if (dob && dob !== "Not specified") client.dob = dob;
      if (goal) client.goal = goal;
      if (symptoms) client.symptoms = symptoms;
    }
    
    await upsertClientPg(client);

    // Restore protocol items if provided and server currently has none for this client
    if (items && Array.isArray(items) && items.length > 0) {
      if (!db.protocols[client.id] || db.protocols[client.id].length === 0) {
        db.protocols[client.id] = items.map(item => ({
          id: item.id || ("supp_" + Date.now() + "_" + Math.random().toString(36).substr(2, 4)),
          name: item.name,
          brand: item.brand || "Practitioner Direct",
          category: item.category || "Supplement",
          dosageValue: parseFloat(item.dosageValue) || 1,
          dosageUnit: normalizeUnit(item.dosageUnit),
          timingSchedule: item.timingSchedule || "Empty Stomach",
          frequencyDescription: item.frequencyDescription || "Daily",
          intervalHours: parseIntervalHours(item),
          practitionerNotes: item.practitionerNotes || "Take as directed.",
          totalServingsRemaining: item.totalServingsRemaining !== undefined ? item.totalServingsRemaining : 30,
          maxServings: item.maxServings || 30,
          fullscriptRefillUrl: item.fullscriptRefillUrl || "https://us.fullscript.com/welcome/lvitti/signup"
        }));
        await saveProtocolItemsPg(client.id, db.protocols[client.id]);
      }
    }
    
    saveDb();
    return sendJson(res, 200, { success: true, client, protocolItems: db.protocols[client.id] || [] });
  }

  // 3. PRACTITIONER LOGIN
  if (pathname === '/api/auth/login-practitioner' && method === 'POST') {
    const body = await getJsonBody(req);
    const prac = db.practitioners.find(p => p.email.toLowerCase() === body.email.toLowerCase() && p.password === body.password);
    if (prac) {
      return sendJson(res, 200, { success: true, practitioner: prac });
    }
    return sendJson(res, 401, { success: false, message: "Invalid practitioner credentials" });
  }

  // 4. PRACTITIONER CLIENT ROSTER
  if (pathname === '/api/practitioner/clients' && method === 'GET') {
    const roster = db.clients.filter(c => !isJamesBond(c) && !isClientDeleted(c)).map(c => {
      const proto = db.protocols[c.id] || [];
      const clientLogs = db.doseLogs.filter(l => l.clientId === c.id);
      const completedLogs = clientLogs.filter(l => l.status === 'Done');
      const adherence = clientLogs.length > 0 ? Math.round((completedLogs.length / clientLogs.length) * 100) : 100;
      return {
        ...c,
        hasProtocolAssigned: proto.length > 0,
        itemCount: proto.length,
        doseLogsCount: clientLogs.length,
        adherenceRate: adherence,
        streakDays: completedLogs.length > 0 ? Math.min(completedLogs.length, 14) : 0
      };
    });
    return sendJson(res, 200, { success: true, clients: roster });
  }

  // 5. RESET / CLEAR ROSTER (To start with 0 patients cleanly)
  if (pathname === '/api/practitioner/reset' && method === 'POST') {
    db.clients = [];
    db.protocols = {};
    db.messages = [];
    db.doseLogs = [];
    db.refills = [];
    db.deletedClients = [];
    if (fs.existsSync(CLIENTS_BACKUP_FILE)) {
      try { fs.unlinkSync(CLIENTS_BACKUP_FILE); } catch(e) {}
    }
    saveDb();
    await resetRosterPg();
    return sendJson(res, 200, { success: true, message: "Roster cleared. Database now has 0 clients." });
  }

  // 5b. DELETE INDIVIDUAL PATIENT BY CLIENT ID
  if (pathname.startsWith('/api/practitioner/delete-client/') && method === 'DELETE') {
    const clientId = pathname.split('/')[4];
    const targetClient = db.clients.find(c => c.id === clientId || toStableUUID(c.id) === clientId.toLowerCase() || c.id.toLowerCase() === toStableUUID(clientId));
    const targetName = targetClient ? targetClient.name.toLowerCase().trim() : "";

    db.clients = db.clients.filter(c => c.id !== clientId && (targetName === "" || c.name.toLowerCase().trim() !== targetName));
    delete db.protocols[clientId];
    if (targetClient) delete db.protocols[targetClient.id];
    db.doseLogs = db.doseLogs.filter(l => l.clientId !== clientId && (!targetClient || l.clientId !== targetClient.id));

    if (!db.deletedClients) db.deletedClients = [];
    db.deletedClients.push({ id: clientId, name: targetName });

    saveDb();
    await deleteClientPg(clientId, targetName);
    return sendJson(res, 200, { success: true, message: "Patient deleted successfully." });
  }

  // 6. GET CLIENT PROTOCOL
  if (pathname.startsWith('/api/protocol/') && method === 'GET') {
    const clientId = pathname.split('/')[3];
    const client = db.clients.find(c => c.id === clientId || toStableUUID(c.id) === clientId.toLowerCase() || c.id.toLowerCase() === toStableUUID(clientId));

    if (!client || isClientDeleted(client)) {
      return sendJson(res, 200, {
        success: true,
        protocol: {
          title: "Male Wellness & Supplement Protocol",
          practitionerName: "Practitioner Luba Vitti",
          clientName: "Patient",
          clientDob: "",
          clientGoal: "",
          practitionerNoteToClient: "Waiting for your practitioner to prescribe your custom protocol.",
          items: []
        }
      });
    }

    const items = db.protocols[client.id] || [];
    return sendJson(res, 200, {
      success: true,
      protocol: {
        title: "Male Wellness & Supplement Protocol",
        practitionerName: "Practitioner Luba Vitti",
        clientName: client.name,
        clientDob: client.dob,
        clientGoal: client.goal,
        practitionerNoteToClient: client.practitionerNote || "Waiting for your practitioner to prescribe your custom protocol.",
        items: items
      }
    });
  }

  // 7. PRACTITIONER ASSIGN PROTOCOL TO CLIENT
  if (pathname.startsWith('/api/practitioner/assign-protocol/') && method === 'POST') {
    const clientId = pathname.split('/')[4];
    const body = await getJsonBody(req);
    
    if (!db.protocols[clientId]) db.protocols[clientId] = [];

    if (body.items) {
      db.protocols[clientId] = body.items.map(item => ({
        id: item.id || ("supp_" + Date.now() + "_" + Math.random().toString(36).substr(2, 4)),
        name: item.name,
        brand: item.brand || "Practitioner Direct",
        category: item.category || "Supplement",
        dosageValue: parseFloat(item.dosageValue) || 1,
        dosageUnit: normalizeUnit(item.dosageUnit),
        timingSchedule: item.timingSchedule || "Empty Stomach",
        frequencyDescription: item.frequencyDescription || "Daily",
        intervalHours: parseIntervalHours(item),
        practitionerNotes: item.practitionerNotes || "Take as directed.",
        totalServingsRemaining: item.totalServingsRemaining !== undefined ? item.totalServingsRemaining : 30,
        maxServings: item.maxServings || 30,
        fullscriptRefillUrl: item.fullscriptRefillUrl || "https://us.fullscript.com/welcome/lvitti/signup"
      }));
    } else if (body.item) {
      if (!db.protocols[clientId]) db.protocols[clientId] = [];
      const existingIdx = db.protocols[clientId].findIndex(i => String(i.id) === String(body.item.id));
      const targetItem = {
        id: body.item.id || ("supp_" + Date.now()),
        name: body.item.name,
        brand: body.item.brand || "Practitioner Direct",
        category: body.item.category || "Supplement",
        dosageValue: parseFloat(body.item.dosageValue) || 1,
        dosageUnit: normalizeUnit(body.item.dosageUnit),
        timingSchedule: body.item.timingSchedule || "Empty Stomach",
        frequencyDescription: body.item.frequencyDescription || "Daily",
        intervalHours: parseIntervalHours(body.item),
        practitionerNotes: body.item.practitionerNotes || "Take as directed.",
        totalServingsRemaining: body.item.totalServingsRemaining !== undefined ? body.item.totalServingsRemaining : 30,
        maxServings: body.item.maxServings || 30,
        fullscriptRefillUrl: body.item.fullscriptRefillUrl || "https://us.fullscript.com/welcome/lvitti/signup"
      };

      if (existingIdx >= 0) {
        db.protocols[clientId][existingIdx] = targetItem;
      } else {
        db.protocols[clientId].push(targetItem);
      }
    }

    let targetCli = null;
    if (body.practitionerNote !== undefined) {
      targetCli = db.clients.find(c => c.id === clientId || toStableUUID(c.id) === clientId.toLowerCase() || c.id.toLowerCase() === toStableUUID(clientId));
      if (targetCli) {
        targetCli.practitionerNote = body.practitionerNote;
      }
    }

    saveDb();
    await saveProtocolItemsPg(clientId, db.protocols[clientId]);
    if (targetCli) await upsertClientPg(targetCli);

    return sendJson(res, 200, { success: true, items: db.protocols[clientId] || [] });
  }

  // 8. DELETE PROTOCOL ITEM
  if (pathname.startsWith('/api/practitioner/delete-protocol-item/') && method === 'DELETE') {
    const parts = pathname.split('/');
    const clientId = parts[4];
    const itemId = parts[5];
    if (db.protocols[clientId]) {
      db.protocols[clientId] = db.protocols[clientId].filter(i => String(i.id) !== String(itemId));
      saveDb();
      await deleteProtocolItemPg(clientId, itemId);
    }
    return sendJson(res, 200, { success: true, items: db.protocols[clientId] || [] });
  }

  // 9. LOG DOSE (Done / Wait / Snoozed)
  if (pathname === '/api/dose-log' && method === 'POST') {
    const body = await getJsonBody(req);
    const items = db.protocols[body.clientId] || [];
    const matchedItem = items.find(i => 
      String(i.id) === String(body.itemId) || 
      toStableUUID(i.id) === String(body.itemId).toLowerCase()
    );
    const canonicalItemId = matchedItem ? matchedItem.id : body.itemId;

    const log = {
      id: "log_" + Date.now(),
      clientId: body.clientId,
      itemId: canonicalItemId,
      itemName: body.itemName || (matchedItem ? matchedItem.name : "Supplement"),
      timingSchedule: body.timingSchedule,
      status: body.status,
      timestamp: new Date().toISOString()
    };
    db.doseLogs.unshift(log);

    if (body.status === "Done" && matchedItem) {
      if (matchedItem.totalServingsRemaining > 0) {
        matchedItem.totalServingsRemaining -= 1;
      }
    }
    saveDb();
    await addDoseLogPg(log, matchedItem);
    return sendJson(res, 200, { success: true, log });
  }

  // 10. GET DOSE LOGS FOR CLIENT
  if (pathname.startsWith('/api/dose-log/') && method === 'GET') {
    const clientId = pathname.split('/')[3];
    const logs = db.doseLogs.filter(l => l.clientId === clientId);
    return sendJson(res, 200, { success: true, doseLogs: logs });
  }

  // 11. CHAT MESSAGES
  if (pathname.startsWith('/api/chat/messages/') && method === 'GET') {
    const clientId = pathname.split('/')[4];
    const msgs = db.messages.filter(m => m.clientId === clientId);
    return sendJson(res, 200, { success: true, messages: msgs });
  }

  if (pathname.startsWith('/api/chat/send/') && method === 'POST') {
    const clientId = pathname.split('/')[4];
    const body = await getJsonBody(req);
    const newMsg = {
      id: "msg_" + Date.now(),
      clientId,
      sender: body.sender || "client",
      senderName: body.senderName || "Client",
      text: body.text,
      timestamp: new Date().toISOString()
    };
    db.messages.push(newMsg);
    saveDb();
    await addMessagePg(newMsg);
    return sendJson(res, 200, { success: true, message: newMsg });
  }

  // Fallback for unhandled API endpoints
  if (pathname.startsWith('/api/')) {
    return sendJson(res, 404, { success: false, message: `API endpoint ${pathname} not found` });
  }

  // 12. SERVE STATIC WEB PORTAL
  let filePath = path.join(__dirname, 'public', pathname === '/' ? 'index.html' : pathname);
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath);
    const mimeTypes = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json' };
    res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'text/plain' });
    fs.createReadStream(filePath).pipe(res);
  } else {
    const fallbackPath = path.join(__dirname, 'public', 'index.html');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    fs.createReadStream(fallbackPath).pipe(res);
  }
});

async function startServer() {
  loadDb();

  if (supabase) {
    console.log("⚡ Restoring persistent data state from Supabase Cloud...");
    const loadedSupabase = await loadFromSupabase();
    if (loadedSupabase) {
      saveDb();
    }
  }

  if (pool) {
    console.log("PostgreSQL environment detected. Connecting to Render database...");
    const initialized = await initPgDb();
    if (initialized) {
      const loaded = await loadFromPg();
      if (!loaded || db.clients.length === 0) {
        await seedPgFromMemory();
      }
    }
  } else {
    console.log("Operating with Supabase Cloud Data Storage & local file persistence.");
  }

  server.listen(PORT, () => {
    console.log(`🌿 Wellness Buddy Production System running live at http://localhost:${PORT}`);
    
    // Heartbeat loop to keep Render free tier awake & prevent cold-start resets
    setInterval(() => {
      const pingTarget = process.env.RENDER_EXTERNAL_URL ? `${process.env.RENDER_EXTERNAL_URL}/api/ping` : `http://localhost:${PORT}/api/ping`;
      http.get(pingTarget, (res) => {}).on('error', () => {});
    }, 8 * 60 * 1000);
  });
}

startServer().catch(err => {
  console.error("Fatal error starting server:", err);
});
