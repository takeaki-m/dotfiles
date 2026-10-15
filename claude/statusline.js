#!/usr/bin/env node

// ステータスライン表示スクリプト
//
// 全体構成:
//   Claude Code から stdin で渡される JSON (公式: https://code.claude.com/docs/en/statusline)
//   を読み、2行のステータスラインを出力する。
//     1行目「どこで作業しているか」(変化が少ない情報)
//       [vim] モデル·effort │ repo  branch ⎇worktree │ PR#N✓ │ issue #N │ +追加 -削除 · 経過時間
//     2行目「どれだけ使ったか」(頻繁に変化する情報)
//       コンテキストバー 使用率 トークン数 │ $コスト │ 5h レート · 7d レート │ cache ヒット率 ~期限
//   静的な情報と動的な情報を行で分けることで、目で追うべき値を2行目に集中させる。
//
// 設計方針:
//   - ステータスラインは更新のたびに実行され、遅いと表示が止まる(公式 Troubleshooting)。
//     そのため外部コマンドは git のブランチ取得のみとし、結果は数秒キャッシュする。
//     Issue 番号はフォルダ名・worktree 名から抽出し、外部コマンドを使わない。
//   - スクリプト内では tput 等で端末幅を取れないため、Claude Code が設定する COLUMNS を使い、
//     幅が足りない場合は優先度の低いセグメントから省略する。
//   - JSON の多くのフィールドは条件付きで存在する(null / 欠落あり)ため、全て存在チェックする。

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

// ---- ANSI エスケープ定義 ----
const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const RED = '\x1b[91m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const MAGENTA = '\x1b[35m';
const CYAN = '\x1b[36m';
const GRAY = '\x1b[90m';
const SEP = ` ${GRAY}│${RESET} `;

// git ブランチのキャッシュ有効期間(公式の caching 例に合わせて5秒)
const GIT_CACHE_TTL_MS = 5_000;

let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    // COLUMNS 未設定(手動テスト時など)は幅制限なしとして扱う
    const columns = parseInt(process.env.COLUMNS, 10) || Infinity;

    const line1 = fitSegments(buildLine1Segments(data), columns, createVimIndicator(data.vim?.mode));
    const line2 = fitSegments(buildLine2Segments(data), columns, '');
    console.log(line1);
    console.log(line2);
  } catch (error) {
    // エラー時のフォールバック表示(非0終了や無出力だとステータスラインが空になるため)
    console.log('[Claude Code]');
  }
});

// =====================================================================
// 1行目: 作業コンテキスト
// =====================================================================

// セグメントは { text, priority } の配列。priority が小さいものから幅不足時に省略される。
function buildLine1Segments(data) {
  const segments = [];

  // モデル·effort(·fast)  /model や /effort の切り替え結果を即座に確認するため
  const model = data.model?.display_name;
  if (model) {
    const effort = data.effort?.level ? `${GRAY}·${RESET}${effortColor(data.effort.level)}${data.effort.level}${RESET}` : '';
    const fast = data.fast_mode ? `${GRAY}·${RESET}${YELLOW}fast${RESET}` : '';
    segments.push({ text: `${BOLD}${model}${RESET}${effort}${fast}`, priority: 90 });
  }

  // 作業単位(ブランチ / worktree / フォルダのいずれか1つ)
  //   「ブランチごとに同階層へ worktree を作る」運用では worktree 名とブランチ名は基本的に同じため、
  //   どちらか一方だけを表示する。ブランチ名を優先し、取得できない場合は worktree 名、
  //   それも無ければ(git 管理外など)現在のフォルダ名を表示する。
  //   リポジトリ名(workspace.repo.name)は origin 由来で全 worktree 共通となり、作業の識別に
  //   寄与しないため表示しない。
  const cwd = data.workspace?.current_dir || data.cwd;
  const git = getGitInfo(cwd, data.session_id);
  const worktree = data.worktree?.name || data.workspace?.git_worktree;
  const workUnit = git.branch ? { color: MAGENTA, icon: ' ', name: git.branch }
    : worktree ? { color: GRAY, icon: '⎇ ', name: worktree }
    : cwd ? { color: CYAN, icon: '', name: path.basename(cwd) }
    : null;
  if (workUnit) {
    const build = max => `${workUnit.color}${workUnit.icon}${truncate(workUnit.name, max)}${RESET}`;
    // 幅不足時は欄ごと消さず、名前を段階的に短くして残す(alts を先頭から順に適用)
    //   短縮は PR(70)・Issue(75) を消すより先に行う(shrinkPriority: 65)。
    //   ブランチ名は先頭32文字あれば作業を識別でき、全文より PR/Issue の方が情報価値が高いため。
    segments.push({ text: build(Infinity), priority: 80, alts: [build(32), build(20)], shrinkPriority: 65 });
  }

  // PR(OSC 8 でクリック可能なリンク + レビュー状態の色/記号)
  if (data.pr?.number) {
    const [color, mark] = reviewStateStyle(data.pr.review_state);
    const label = `${data.pr.kind === 'mr' ? '!' : 'PR#'}${data.pr.number}`;
    segments.push({ text: `${color}${hyperlink(data.pr.url, label)}${mark}${RESET}`, priority: 70 });
  }

  // Issue(フォルダ名・worktree 名から抽出。番号が無いフォルダでは非表示)
  const issue = resolveIssueFromFolder(data);
  if (issue) {
    const repo = data.workspace?.repo;
    const url = repo ? `https://${repo.host}/${repo.owner}/${repo.name}/issues/${issue}` : null;
    // 作業対象を示す主要情報のため、PR(70) より優先して残す
    segments.push({ text: `${YELLOW}${hyperlink(url, `issue #${issue}`)}${RESET}`, priority: 75 });
  }

  // 変更行数 · 経過時間(作業量の目安。最も省略されやすい)
  const added = data.cost?.total_lines_added ?? 0;
  const removed = data.cost?.total_lines_removed ?? 0;
  const duration = formatDuration(data.cost?.total_duration_ms);
  const activity = [
    (added || removed) ? `${GREEN}+${added}${RESET} ${RED}-${removed}${RESET}` : '',
    duration ? `${GRAY}${duration}${RESET}` : '',
  ].filter(Boolean).join(` ${GRAY}·${RESET} `);
  if (activity) segments.push({ text: activity, priority: 10 });

  return segments;
}

// effort レベルの色(高いほど目立つ色。コスト/速度への影響を意識しやすくする)
function effortColor(level) {
  return { low: GRAY, medium: BLUE, high: GREEN, xhigh: YELLOW, max: RED }[level] || '';
}

// PR レビュー状態 → [色, 記号]
//   "…" は名前の切り詰め記号と紛らわしいため使わない
function reviewStateStyle(state) {
  switch (state) {
    case 'approved': return [GREEN, '✓'];
    case 'changes_requested': return [RED, '✗'];
    case 'draft': return [GRAY, '✎'];
    case 'pending': return [YELLOW, '○'];
    default: return [BLUE, ''];
  }
}

// =====================================================================
// 2行目: 使用状況
// =====================================================================

function buildLine2Segments(data) {
  const segments = [];

  // コンテキストウィンドウ
  //   used_percentage はセッション開始直後に null になりうる(公式)。
  //   0% と表示すると「未使用」と区別できないため、null 時は "--" で表示する。
  const ctx = data.context_window || {};
  const pct = ctx.used_percentage;
  if (pct == null) {
    segments.push({ text: `${GRAY}${createProgressBar(0, 15)} --%${RESET}`, priority: 100 });
  } else {
    const color = getColorByUsage(pct);
    // 1M コンテキストのモデルでは同じ % でも残量が大きく違うため、トークン数を併記する
    const tokens = ctx.context_window_size
      ? ` ${GRAY}${formatTokens(ctx.total_input_tokens ?? 0)}/${formatTokens(ctx.context_window_size)}${RESET}`
      : '';
    segments.push({ text: `${color}${createProgressBar(pct, 15)} ${Math.round(pct)}%${RESET}`, priority: 100 });
    if (tokens) segments.push({ text: tokens.trim(), priority: 30, attach: true });
  }

  // コスト
  const costUsd = data.cost?.total_cost_usd ?? 0;
  segments.push({ text: `${CYAN}$${costUsd.toFixed(2)}${RESET}`, priority: 90 });

  // レート制限(Pro/Max のみ存在。各ウィンドウは独立して欠落しうる)
  //   5h: HH:MM、7d: MM/DD HH:MM で時刻フォーマットを分ける
  const rl5h = formatRateLimit('5h', data.rate_limits?.five_hour, { hour: '2-digit', minute: '2-digit' });
  const rl7d = formatRateLimit('7d', data.rate_limits?.seven_day, { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
  if (rl5h) segments.push({ text: rl5h, priority: 80 });
  if (rl7d) segments.push({ text: rl7d, priority: 50, attach: !!rl5h, joiner: ` ${GRAY}·${RESET} ` });

  // プロンプトキャッシュ
  //   キャッシュが切れると次のリクエストは再書き込みで高コスト・低速になる。
  //   離席から戻った時に warm/cold を一目で判断できるよう、期限時刻を表示する。
  //   expires_at 到達時は Claude Code が自動で再描画するため refreshInterval は不要(公式)。
  const pc = data.prompt_cache;
  if (pc?.caching_observed) {
    const ratio = pc.hit_ratio != null ? ` ${Math.round(pc.hit_ratio * 100)}%` : '';
    const text = pc.warm && pc.expires_at
      ? `${GREEN}cache${ratio}${RESET} ${GRAY}~${formatTime(pc.expires_at, { hour: '2-digit', minute: '2-digit' })}${RESET}`
      : `${BLUE}cache cold${RESET}${GRAY}${ratio}${RESET}`;
    segments.push({ text, priority: 20 });
  }

  return segments;
}

function formatRateLimit(label, window, timeFormat) {
  if (window == null) return '';
  const pct = Math.round(window.used_percentage ?? 0);
  const reset = window.resets_at ? ` ${GRAY}~${formatTime(window.resets_at, timeFormat)}${RESET}` : '';
  return `${GRAY}${label}${RESET} ${getColorByUsage(pct)}${pct}%${RESET}${reset}`;
}

// =====================================================================
// git / Issue 情報の取得
// =====================================================================

// キャッシュファイルのパス
//   公式例は /tmp を使うが、共有ディレクトリの予測可能なファイル名は他ユーザーによる
//   シンボリックリンク攻撃の余地がある。macOS の os.tmpdir() はユーザー専用ディレクトリのため
//   こちらを使う(最小権限・攻撃面の縮小)。
//   また session_id は外部入力なので、パス区切り等を除去してからファイル名に使う。
function cacheFile(sessionId, kind) {
  const safeId = String(sessionId || 'default').replace(/[^A-Za-z0-9_-]/g, '');
  return path.join(os.tmpdir(), `claude-statusline-${safeId}-${kind}.json`);
}

function readJson(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return null; }
}

function writeJson(file, value) {
  try { fs.writeFileSync(file, JSON.stringify(value)); } catch { /* キャッシュ失敗は表示に影響させない */ }
}

// ブランチ名を取得(cwd 単位で5秒キャッシュ)
//   statusline JSON にはブランチ名が含まれないため git から取得する。
function getGitInfo(cwd, sessionId) {
  if (!cwd) return {};
  const file = cacheFile(sessionId, 'git');
  const cached = readJson(file);
  if (cached && cached.cwd === cwd && Date.now() - cached.at < GIT_CACHE_TTL_MS) return cached;

  let branch = '';
  try {
    const opts = { cwd, encoding: 'utf8', timeout: 500, stdio: ['ignore', 'pipe', 'ignore'] };
    branch = execFileSync('git', ['branch', '--show-current'], opts).trim();
    // detached HEAD の場合は短縮ハッシュを表示
    if (!branch) branch = execFileSync('git', ['rev-parse', '--short', 'HEAD'], opts).trim();
  } catch { /* git リポジトリ外 */ }

  const info = { cwd, branch, at: Date.now() };
  writeJson(file, info);
  return info;
}

// Issue 番号をフォルダ名・worktree 名から解決する
//   Issue は statusline JSON に含まれないため、作業フォルダの命名から推定する。
//   worktree ベース開発では「フォルダ＝作業単位」であり、フォルダ名に Issue 番号を含める
//   運用であれば、外部コマンドもネットワークも使わずに即座に取得できる。
//   候補は「作業単位を表す可能性が高い順」に見て、最初に番号が取れたものを採用する。
//     1. worktree.name             … Claude Code の worktree セッション名
//     2. workspace.git_worktree    … git worktree add で作られた linked worktree 名
//     3. workspace.project_dir の末尾 … Claude Code を起動したフォルダ
//     4. workspace.current_dir の末尾 … 現在の作業フォルダ
//   どれにも番号が無ければ null を返し、Issue セグメントは非表示になる。
function resolveIssueFromFolder(data) {
  const candidates = [
    data.worktree?.name,
    data.workspace?.git_worktree,
    data.workspace?.project_dir && path.basename(data.workspace.project_dir),
    (data.workspace?.current_dir || data.cwd) && path.basename(data.workspace?.current_dir || data.cwd),
  ];
  for (const name of candidates) {
    const issue = parseIssueNumber(name);
    if (issue) return issue;
  }
  return null;
}

// 名前から Issue 番号を抽出
//   対応例: issue-123 / issues_123 / gh-123 / #123 / 123-foo / foo-issue-123-bar
//           feature-1510-excel-output / fix_42_typo (ブランチ名由来の worktree 名)
//   1つ目の正規表現: 「issue」「gh」「#」の直後の番号(名前のどこにあってもよい)
//   2つ目の正規表現: 先頭の番号、または「英字の種別 + 区切り」に続く番号(例: 123-foo, feature-1510-foo)
//   番号の後ろは区切り文字か末尾に限定し、app2 / v2.1 のような名前を誤検出しないようにする。
function parseIssueNumber(name) {
  if (!name) return null;
  const m = name.match(/(?:^|[_.-])(?:issues?|gh|#)[-_]?(\d+)(?=$|[_.-])/i)
    || name.match(/^(?:[a-z]+[-_])?#?(\d+)(?=$|[_.-])/i);
  return m ? Number(m[1]) : null;
}

// =====================================================================
// 表示ユーティリティ
// =====================================================================

// 端末幅に収まるようセグメントを結合する
//   幅不足時は priority の低いセグメントから順に縮める。
//   縮め方: alts(短縮版テキストの配列)を持つセグメントは先頭から順に差し替え、
//           短縮版を使い切ったら(または持たなければ)除外する。
//           短縮中の優先度は shrinkPriority(省略時は priority)を使い、除外とは別の順番で縮められる。
//   attach: true のセグメントは直前のセグメントにスペース(または joiner)で連結し、区切り線を入れない。
function fitSegments(segments, columns, prefix) {
  const render = segs => prefix + segs.map((s, i) =>
    i === 0 ? s.text : (s.attach ? (s.joiner ?? ' ') : SEP) + s.text
  ).join('');

  // 呼び出し元の配列を書き換えないようコピーして扱う
  let current = segments.map(s => ({ ...s, alts: [...(s.alts || [])] }));
  while (current.length > 1 && visibleWidth(render(current)) > columns) {
    const effective = s => (s.alts.length > 0 ? (s.shrinkPriority ?? s.priority) : s.priority);
    const lowest = current.reduce((min, s) => (effective(s) < effective(min) ? s : min));
    if (lowest.alts.length > 0) {
      lowest.text = lowest.alts.shift();
    } else {
      current = current.filter(s => s !== lowest);
    }
  }
  return render(current);
}

// 最大長を超える文字列を末尾 "…" で切り詰める
function truncate(str, max) {
  return str.length > max ? `${str.slice(0, max - 1)}…` : str;
}

// エスケープシーケンス(SGR 色 / OSC 8 リンク)を除いた表示幅
//   全角文字の幅は考慮しない簡易実装(ブランチ名等は概ね ASCII のため)。
function visibleWidth(str) {
  return str.replace(/\x1b\[[0-9;]*m/g, '').replace(/\x1b\]8;;[^\x07]*\x07/g, '').length;
}

// OSC 8 ハイパーリンク(Ghostty / iTerm2 等で Cmd+クリックで開ける)
function hyperlink(url, text) {
  return url ? `\x1b]8;;${url}\x07${text}\x1b]8;;\x07` : text;
}

function formatTime(epochSec, options) {
  return new Date(epochSec * 1000).toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo', hour12: false, ...options });
}

function formatTokens(n) {
  if (n >= 1_000_000) return `${+(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
  return String(n);
}

function formatDuration(ms) {
  if (!ms) return '';
  const totalMin = Math.floor(ms / 60_000);
  if (totalMin < 60) return `${totalMin}m`;
  return `${Math.floor(totalMin / 60)}h${String(totalMin % 60).padStart(2, '0')}m`;
}

// 使用率に応じた色を返す（緑→黄→赤の3段階）
function getColorByUsage(percentage) {
  if (percentage >= 72) return RED; // 赤（危険域）
  if (percentage >= 56) return YELLOW; // 黄（注意域）
  return GREEN; // 緑（安全域）
}

// vim modeインジケーターを生成
//
// 全体方針: 「読む前に見分けられる」状態にするため、2つの符号を重ねる。
//   (1) モードごとの文字色 …… 前景色のみで区別する
//   (2) モードごとの記号   …… 色＋形状の冗長符号化。色覚特性やテーマに依存せず識別できる
//   さらに固定幅(padEnd)で全モードの表示幅を揃え、後続の表示開始列を固定する。
//
// 背景塗り(囲み)を使わない理由:
//   以前は「背景色 + 白文字」の囲み表示だったが、端末テーマを切り替えると ANSI パレットが
//   テーマ側で一律に差し替わり、背景色と文字色が同系色になって読めなくなった。
//   前景色だけなら、背景は常にテーマ本来の背景色になり、ANSI 色はテーマ作者が
//   「その背景上で読める色」として設計しているため、どのテーマでもコントラストが保たれる。
//   (色の組み合わせを自前で固定せず、テーマの設計に委ねる)
//
// 詳細: vim mode無効時は vim.mode 自体が渡されないので空文字を返し、
//   通常ユーザーの表示には一切影響を与えない。
function createVimIndicator(mode) {
  if (!mode) return '';

  // モード→[文字色, 記号, 表示ラベル]のマッピング。
  //   記号: ● 待機(NORMAL) / ▶ 編集(INSERT) / ◆ 選択(VISUAL系) で動作の質を連想させる。
  //   ラベル: "VISUAL LINE" を "V-LINE" に縮め、全モードを6字に揃える。
  //     最長の11字に padEnd すると短いモードの後ろに空白が目立つため、
  //     埋め草ではなくラベル自体の長さを揃えて固定幅を実現する。
  const styles = {
    'NORMAL':      [BLUE, '●', 'NORMAL'],
    'INSERT':      [GREEN, '▶', 'INSERT'],
    'VISUAL':      [MAGENTA, '◆', 'VISUAL'],
    'VISUAL LINE': [MAGENTA, '◆', 'V-LINE'],
  };
  // 未知のモードはテーマの標準文字色・元のモード名のまま表示する
  const [color, icon, label] = styles[mode] || ['', '◆', mode];

  // 形式: `記号 ラベル` を文字色＋太字で表示し、末尾スペースで後続表示と区切る。
  return `${color}${BOLD}${icon} ${label}${RESET} `;
}

// プログレスバーを生成（ブロック文字で使用率を視覚化）
function createProgressBar(percentage, width) {
  const filled = Math.max(0, Math.min(width, Math.round(width * percentage / 100)));
  return '█'.repeat(filled) + '░'.repeat(width - filled);
}
