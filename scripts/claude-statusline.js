const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return;

  let json;
  try { json = JSON.parse(raw); } catch { return; }

  const bar = (pct, width = 5) => {
    const filled = Math.round(pct * width / 100);
    return '▓'.repeat(filled) + '░'.repeat(width - filled);
  };

  const fmtCountdown = (unixSec) => {
    const ms = unixSec * 1000 - Date.now();
    if (ms <= 0) return 'now';
    const h = Math.floor(ms / 3600000);
    const m = Math.floor((ms % 3600000) / 60000);
    return h > 0 ? `${h}h${String(m).padStart(2, '0')}m` : `${m}m`;
  };

  const fmtDatetime = (unixSec) => {
    const d = new Date(unixSec * 1000);
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const hh = String(d.getHours()).padStart(2, '0');
    const mm = String(d.getMinutes()).padStart(2, '0');
    return `${days[d.getDay()]} ${hh}:${mm}`;
  };

  const model = json?.model?.display_name || '';
  const effort = json?.effort?.level;
  const modelPart = effort ? `${model} [${effort}]` : model;

  const usedPct = json?.context_window?.used_percentage ?? 0;
  const ctxPart = `${bar(usedPct)} ${Math.round(usedPct)}%`;

  const five = json?.rate_limits?.five_hour;
  const seven = json?.rate_limits?.seven_day;
  const rateParts = [];
  if (five != null) {
    const reset = five.resets_at ? `${fmtCountdown(five.resets_at)}` : '';
    rateParts.push(`${reset} ${bar(five.used_percentage)} ${Math.round(five.used_percentage)}%`);
  }
  if (seven != null) {
    const reset = seven.resets_at ? `${fmtDatetime(seven.resets_at)}` : '';
    rateParts.push(`${reset} ${bar(seven.used_percentage)} ${Math.round(seven.used_percentage)}%`);
  }

  const parts = [modelPart, ctxPart];
  if (rateParts.length) parts.push(...rateParts);

  process.stdout.write(parts.join(' | '));
});
