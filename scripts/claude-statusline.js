const { execSync } = require('child_process');
const path = require('path');

const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return;

  let data;
  try { data = JSON.parse(raw); }
  catch { return; }

  const
    GREEN = '\x1b[32m',
    YELLOW = '\x1b[33m',
    RED = '\x1b[31m',
    RESET = '\x1b[0m';

  const bar = (pct, width = 5) => {
    const barColor = pct >= 88.9 ? RED : pct >= 66.7 ? YELLOW : GREEN;
    const filled = Math.round(pct * width / 100);
    return barColor + '▓'.repeat(filled) + '░'.repeat(width - filled) + ` ${Math.round(pct)}%${RESET}`;
  };

  const fmtHourCountdown = (unixSec) => {
    const ms = unixSec * 1000 - Date.now();
    if (ms <= 0) return 'now';
    const h = Math.floor(ms / 3600000);
    const m = Math.floor((ms % 3600000) / 60000);
    return `${h}h${String(m).padStart(2, '0')}m`;
  };

  const fmtDayCountdown = (unixSec) => {
    const ms = unixSec * 1000 - Date.now();
    if (ms <= 0) return 'now';
    const d = Math.floor(ms / 86400000);
    const h = Math.floor((ms % 86400000) / 3600000);
    return `${d}d${String(h).padStart(2, '0')}h`;
  };

  const partModel = () => {
    const model = data?.model?.display_name || '';
    const effort = data?.effort?.level;
    const usedPct = data?.context_window?.used_percentage ?? 0;
    return `${model} ${bar(usedPct)}${effort ? ` [${effort}]` : ''}`;
  }

  const partsRateLimit = () => {
    const five = data?.rate_limits?.five_hour;
    const seven = data?.rate_limits?.seven_day;
    const rateParts = [];
    if (five != null) {
      const reset = five.resets_at ? `${fmtHourCountdown(five.resets_at)}` : '?';
      rateParts.push(`${bar(five.used_percentage)} [${reset}]`);
    }
    if (seven != null) {
      const reset = seven.resets_at ? `${fmtDayCountdown(seven.resets_at)}` : '?';
      rateParts.push(`${bar(seven.used_percentage)} [${reset}]`);
    }
    return rateParts;
  }

  const parts = [partModel(), ...partsRateLimit()];
  process.stdout.write(parts.filter(Boolean).join(' · '));
});