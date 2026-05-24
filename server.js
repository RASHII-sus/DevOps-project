const express = require('express');
const os = require('os');

const app = express();
let visitors = 0;
const startTime = new Date();

app.get('/', (req, res) => {
  visitors++;
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>DevOps Project — Node.js on Kubernetes</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
    }
    .card {
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 16px;
      padding: 48px 56px;
      max-width: 600px;
      width: 90%;
      backdrop-filter: blur(10px);
      text-align: center;
    }
    h1 { font-size: 1.8rem; font-weight: 600; margin-bottom: 8px; }
    .subtitle { font-size: 0.95rem; color: rgba(255,255,255,0.55); margin-bottom: 36px; }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 32px;
    }
    .info-box {
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 10px;
      padding: 20px 16px;
    }
    .info-box .label {
      font-size: 0.72rem;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: rgba(255,255,255,0.45);
      margin-bottom: 8px;
    }
    .info-box .value {
      font-size: 1.05rem;
      font-weight: 500;
      word-break: break-all;
    }
    .visitors-box {
      grid-column: 1 / -1;
      background: rgba(99,102,241,0.2);
      border-color: rgba(99,102,241,0.4);
    }
    .visitors-box .value { font-size: 2.2rem; color: #a5b4fc; }
    .badge {
      display: inline-block;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 0.8rem;
      background: rgba(34,197,94,0.15);
      border: 1px solid rgba(34,197,94,0.35);
      color: #86efac;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>🚀 Node.js on Kubernetes</h1>
    <p class="subtitle">AWS Free Tier · Docker · Minikube · GitHub Actions CI/CD</p>
    <div class="info-grid">
      <div class="info-box">
        <div class="label">Timestamp</div>
        <div class="value">${new Date().toISOString()}</div>
      </div>
      <div class="info-box">
        <div class="label">Container ID (hostname)</div>
        <div class="value">${os.hostname()}</div>
      </div>
      <div class="info-box">
        <div class="label">Node.js Version</div>
        <div class="value">${process.version}</div>
      </div>
      <div class="info-box">
        <div class="label">Platform</div>
        <div class="value">${os.platform()} / ${os.arch()}</div>
      </div>
      <div class="info-box visitors-box">
        <div class="label">👁 Total Visitors</div>
        <div class="value">${visitors}</div>
      </div>
    </div>
    <span class="badge">✅ Running healthy</span>
  </div>
</body>
</html>
  `);
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime_seconds: Math.floor(process.uptime()),
    started_at: startTime.toISOString(),
    hostname: os.hostname(),
    visitors: visitors
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[${new Date().toISOString()}] Server running on port ${PORT}`);
  console.log(`Container ID: ${os.hostname()}`);
});
