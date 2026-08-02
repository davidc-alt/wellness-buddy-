//
//  server.js
//  Wellness Buddy — Production Practitioner & Client Protocol Management System
//

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'data.json');
const UPLOADS_DIR = path.join(__dirname, 'public', 'uploads');

if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Database schema for Practitioners & Clients
let db = {
  practitioners: [
    { id: "prac_1", name: "Practitioner Luba Vitti", title: "Integrative Health Specialist", email: "practitioner@wellnessbuddy.com", password: "password123" }
  ],
  clients: [],
  protocols: {},
  doseLogs: [],
  messages: [],
  refills: []
};

function saveDb() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(db, null, 2));
  } catch (e) {
    console.error("Save error:", e);
  }
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
    } catch (e) {
      console.log("Starting fresh database.");
    }
  }
}

loadDb();

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
    return sendJson(res, 200, { success: true, timestamp: new Date().toISOString(), status: "live" });
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

    let existing = db.clients.find(c => 
      c.name.toLowerCase().trim() === name.toLowerCase() && c.dob.trim() === dob
    );

    if (existing) {
      existing.name = name;
      existing.dob = dob;
      if (body.goal) existing.goal = body.goal;
      if (body.symptoms) existing.symptoms = body.symptoms;
      saveDb();
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

    return sendJson(res, 200, { success: true, client: newClient, isNew: true });
  }

  // 2. CLIENT LOGIN (supports Name + DOB OR Email + Password)
  if (pathname === '/api/auth/login-client' && method === 'POST') {
    const body = await getJsonBody(req);
    
    if (body.name && body.dob) {
      const name = body.name.trim();
      const dob = body.dob.trim();
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
      }
      return sendJson(res, 200, { success: true, client });
    }

    if (body.email && body.password) {
      const client = db.clients.find(c => c.email.toLowerCase() === body.email.toLowerCase() && c.password === body.password);
      if (client) {
        return sendJson(res, 200, { success: true, client });
      }
    }

    return sendJson(res, 401, { success: false, message: "Invalid credentials. Enter your Full Name & Date of Birth to log in or register." });
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
    const roster = db.clients.map(c => {
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
    saveDb();
    return sendJson(res, 200, { success: true, message: "Roster cleared. Database now has 0 clients." });
  }

  // 5b. DELETE INDIVIDUAL PATIENT BY CLIENT ID
  if (pathname.startsWith('/api/practitioner/delete-client/') && method === 'DELETE') {
    const clientId = pathname.split('/')[4];
    db.clients = db.clients.filter(c => c.id !== clientId);
    delete db.protocols[clientId];
    db.doseLogs = db.doseLogs.filter(l => l.clientId !== clientId);
    saveDb();
    return sendJson(res, 200, { success: true, message: "Patient deleted successfully." });
  }

  // 6. GET CLIENT PROTOCOL
  if (pathname.startsWith('/api/protocol/') && method === 'GET') {
    const clientId = pathname.split('/')[3];
    const client = db.clients.find(c => c.id === clientId);

    if (!client) {
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
        practitionerNotes: item.practitionerNotes || "Take as directed.",
        totalServingsRemaining: item.totalServingsRemaining !== undefined ? item.totalServingsRemaining : 30,
        maxServings: item.maxServings || 30,
        fullscriptRefillUrl: item.fullscriptRefillUrl || "https://fullscript.com"
      }));
    } else if (body.item) {
      const newItem = {
        id: body.item.id || ("supp_" + Date.now()),
        name: body.item.name,
        brand: body.item.brand || "Practitioner Direct",
        category: body.item.category || "Supplement",
        dosageValue: parseFloat(body.item.dosageValue) || 1,
        dosageUnit: normalizeUnit(body.item.dosageUnit),
        timingSchedule: body.item.timingSchedule || "Empty Stomach",
        frequencyDescription: body.item.frequencyDescription || "Daily",
        practitionerNotes: body.item.practitionerNotes || "Take as directed.",
        totalServingsRemaining: body.item.totalServingsRemaining !== undefined ? body.item.totalServingsRemaining : 30,
        maxServings: body.item.maxServings || 30,
        fullscriptRefillUrl: body.item.fullscriptRefillUrl || "https://fullscript.com"
      };
      db.protocols[clientId].push(newItem);
    }

    if (body.practitionerNote !== undefined) {
      const cli = db.clients.find(c => c.id === clientId);
      if (cli) cli.practitionerNote = body.practitionerNote;
    }

    saveDb();
    return sendJson(res, 200, { success: true, items: db.protocols[clientId] });
  }

  // 8. DELETE PROTOCOL ITEM
  if (pathname.startsWith('/api/practitioner/delete-protocol-item/') && method === 'DELETE') {
    const parts = pathname.split('/');
    const clientId = parts[4];
    const itemId = parts[5];
    if (db.protocols[clientId]) {
      db.protocols[clientId] = db.protocols[clientId].filter(i => String(i.id) !== String(itemId));
      saveDb();
    }
    return sendJson(res, 200, { success: true, items: db.protocols[clientId] || [] });
  }

  // 9. LOG DOSE (Done / Wait)
  if (pathname === '/api/dose-log' && method === 'POST') {
    const body = await getJsonBody(req);
    const log = {
      id: "log_" + Date.now(),
      clientId: body.clientId,
      itemId: body.itemId,
      itemName: body.itemName,
      timingSchedule: body.timingSchedule,
      status: body.status,
      timestamp: new Date().toISOString()
    };
    db.doseLogs.unshift(log);

    if (body.status === "Done" && body.itemId && body.clientId) {
      const items = db.protocols[body.clientId] || [];
      const item = items.find(i => String(i.id) === String(body.itemId));
      if (item && item.totalServingsRemaining > 0) {
        item.totalServingsRemaining -= 1;
      }
    }
    saveDb();
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
    return sendJson(res, 200, { success: true, message: newMsg });
  }

  // 10. SERVE STATIC WEB PORTAL
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

server.listen(PORT, () => {
  console.log(`🌿 Wellness Buddy Production System running live at http://localhost:${PORT}`);
  
  // Heartbeat loop to keep Render free tier awake & prevent cold-start resets
  setInterval(() => {
    const pingTarget = process.env.RENDER_EXTERNAL_URL ? `${process.env.RENDER_EXTERNAL_URL}/api/ping` : `http://localhost:${PORT}/api/ping`;
    http.get(pingTarget, (res) => {
      // Keep-alive heartbeat successful
    }).on('error', () => {});
  }, 8 * 60 * 1000); // Ping every 8 minutes
});
