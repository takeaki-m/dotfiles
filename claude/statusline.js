#!/usr/bin/env node

// ステータスライン表示スクリプト
// Claude Code 2.18.0以降のstatusline JSONから使用状況を取得し、
// プログレスバー・コスト・レート制限を1行で表示する

// Read JSON from stdin
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);

    // コンテキストウィンドウ情報（2.18.0以降、JSONから直接取得）
    const ctxWindow = data.context_window || {};
    const percentage = ctxWindow.used_percentage ?? 0;

    // コスト情報
    const costUsd = data.cost?.total_cost_usd ?? 0;

    // レート制限情報（Max利用者向け、5時間・7日間ウィンドウ）
    const rateLimit5h = data.rate_limits?.five_hour;
    const rateLimit7d = data.rate_limits?.seven_day;

    // 使用率に応じた色分け
    const percentageColor = getColorByUsage(percentage);

    // プログレスバー生成（視覚的にコンテキストウィンドウ使用率を表示）
    const progressBar = createProgressBar(percentage, 15);

    // コスト表示
    const costDisplay = `\x1b[36m$${costUsd.toFixed(2)}\x1b[0m`;

    // レート制限表示（存在する場合のみ、使用率とリセット時刻を表示）
    // 5h: HH:MM形式、7d: MM/DD HH:MM形式で時刻フォーマットを分ける
    let rl5hDisplay = '';
    if (rateLimit5h != null) {
      const pct = Math.round(rateLimit5h.used_percentage ?? 0);
      const color = getColorByUsage(pct);
      let reset = '';
      if (rateLimit5h.resets_at) {
        const t = new Date(rateLimit5h.resets_at * 1000);
        const hm = t.toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo', hour: '2-digit', minute: '2-digit', hour12: false });
        reset = ` ~${hm}`;
      }
      rl5hDisplay = `${color}${pct}%\x1b[0m${reset}`;
    }

    let rl7dDisplay = '';
    if (rateLimit7d != null) {
      const pct = Math.round(rateLimit7d.used_percentage ?? 0);
      const color = getColorByUsage(pct);
      let reset = '';
      if (rateLimit7d.resets_at) {
        const t = new Date(rateLimit7d.resets_at * 1000);
        const md = t.toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false });
        reset = ` ~${md}`;
      }
      rl7dDisplay = `${color}${pct}%\x1b[0m${reset}`;
    }

    const rateLimitParts = [rl5hDisplay, rl7dDisplay].filter(s => s !== '');
    const rateLimitDisplay = rateLimitParts.length > 0 ? ` | ${rateLimitParts.join(' / ')}` : '';

    // vim modeインジケーター（vim mode有効時のみ vim.mode が渡される）
    // カーソル形状の変化はClaude Code側が未対応のため、その代替として
    // ステータスライン行頭にモード名を背景反転で表示し、一目で判別可能にする
    const vimDisplay = createVimIndicator(data.vim?.mode);

    // 出力: [モード] プログレスバー 使用率% | コスト | レート制限(5h / 7d)
    const line = `${vimDisplay}${percentageColor}${progressBar}\x1b[0m ${percentageColor}${percentage}%\x1b[0m | ${costDisplay}${rateLimitDisplay}`;
    console.log(line);
  } catch (error) {
    // エラー時のフォールバック表示
    console.log('[Claude Code]');
  }
});

// 使用率に応じた色を返す（緑→黄→赤の3段階）
function getColorByUsage(percentage) {
  if (percentage >= 72) return '\x1b[91m'; // 赤（危険域）
  if (percentage >= 56) return '\x1b[33m'; // 黄（注意域）
  return '\x1b[32m'; // 緑（安全域）
}

// vim modeインジケーターを生成
// 全体方針: モードごとに色を変え、背景反転(\x1b[7m)で塗りつぶして強調する。
//   これによりカーソル形状が変わらなくても現在モードを瞬時に判別できる。
// 詳細: vim mode無効時は vim.mode 自体が渡されないので空文字を返し、
//   通常ユーザーの表示には一切影響を与えない。
function createVimIndicator(mode) {
  if (!mode) return '';

  // モード→色のマッピング（INSERTは編集中＝緑、NORMALは青、VISUAL系はマゼンタ）
  const colors = {
    'NORMAL': '\x1b[34m',       // 青
    'INSERT': '\x1b[32m',       // 緑
    'VISUAL': '\x1b[35m',       // マゼンタ
    'VISUAL LINE': '\x1b[35m',  // マゼンタ
  };
  const color = colors[mode] || '\x1b[37m';

  // 文字だけを色付きで表示（囲み無し）。末尾スペースで後続表示と区切る
  // ※囲み方式に戻す場合: return `${color}\x1b[7m ${mode} \x1b[0m `;
  return `${color}${mode}\x1b[0m `;
}

// プログレスバーを生成（ブロック文字で使用率を視覚化）
function createProgressBar(percentage, width) {
  const filled = Math.round(width * percentage / 100);
  const empty = width - filled;
  return '\u2588'.repeat(filled) + '\u2591'.repeat(empty);
}

