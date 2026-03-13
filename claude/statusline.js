#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

// Constants
const COMPACTION_THRESHOLD = 200000
// Nerd Fontアイコン（Unicodeエスケープで定義し、可読性とメンテナンス性を確保）
const ICON_FOLDER = '\uea83';
const ICON_GIT = '\ueafe';

// Read JSON from stdin
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', async () => {
  try {
    const data = JSON.parse(input);

    // Extract values
    const model = data.model?.display_name || 'Unknown';
    const currentDir = data.workspace?.current_dir || data.cwd || '.';
    const dirName = path.basename(currentDir);
    const sessionId = data.session_id;

    // Gitブランチ名を取得
    let branch = '';
    if (currentDir && fs.existsSync(path.join(currentDir, '.git'))) {
      try {
        const branchName = execSync('git --no-optional-locks branch --show-current 2>/dev/null', {
          cwd: currentDir,
          encoding: 'utf-8'
        }).trim();
        if (branchName) {
          branch = ` ${ICON_GIT} \x1b[35m${branchName}\x1b[0m`;
        }
      } catch (e) {
        // Gitコマンドエラーは無視
      }
    }

    // Calculate token usage for current session
    let totalTokens = 0;

    if (sessionId) {
      // Find all transcript files
      const projectsDir = path.join(process.env.HOME, '.claude', 'projects');

      if (fs.existsSync(projectsDir)) {
        // Get all project directories
        const projectDirs = fs.readdirSync(projectsDir)
          .map(dir => path.join(projectsDir, dir))
          .filter(dir => fs.statSync(dir).isDirectory());

        // Search for the current session's transcript file
        for (const projectDir of projectDirs) {
          const transcriptFile = path.join(projectDir, `${sessionId}.jsonl`);

          if (fs.existsSync(transcriptFile)) {
            totalTokens = await calculateTokensFromTranscript(transcriptFile);
            break;
          }
        }
      }
    }

    // Calculate percentage
    const percentage = Math.min(100, Math.round((totalTokens / COMPACTION_THRESHOLD) * 100));

    // Format token display
    const tokenDisplay = formatTokenCount(totalTokens);

    // 使用率に応じた色分け（元記事の160Kベース比率を維持）
    let percentageColor = '\x1b[32m'; // 緑
    if (percentage >= 56) percentageColor = '\x1b[33m'; // 黄 (112K/200K)
    if (percentage >= 72) percentageColor = '\x1b[91m'; // 赤 (144K/200K)

    // プログレスバー生成（視覚的にトークン使用率を表示）
    const progressBar = createProgressBar(percentage, 15);

    // ステータスラインを複数行に分割（nvimバッファでの折り返し対応）
    //const line1 = `\x1b[1m[${model}]\x1b[0m ${ICON_FOLDER} \x1b[36m${dirName}\x1b[0m${branch}`;
    //const line2 = `\x1b[1m[${model}]\x1b[0m ${percentageColor}${progressBar}\x1b[0m ${tokenDisplay} ${percentageColor}${percentage}%\x1b[0m`;
    const line2 = `${percentageColor}${progressBar}\x1b[0m ${tokenDisplay} ${percentageColor}${percentage}%\x1b[0m`;

    //console.log(line1);
    console.log(line2);
  } catch (error) {
    // Fallback status line on error
    console.log('[Claude Code]');
  }
});

async function calculateTokensFromTranscript(filePath) {
  return new Promise((resolve, reject) => {
    let lastUsage = null;

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity
    });

    rl.on('line', (line) => {
      try {
        const entry = JSON.parse(line);

        // Check if this is an assistant message with usage data
        if (entry.type === 'assistant' && entry.message?.usage) {
          lastUsage = entry.message.usage;
        }
      } catch (e) {
        // Skip invalid JSON lines
      }
    });

    rl.on('close', () => {
      if (lastUsage) {
        // The last usage entry contains cumulative tokens
        const totalTokens = (lastUsage.input_tokens || 0) +
          (lastUsage.output_tokens || 0) +
          (lastUsage.cache_creation_input_tokens || 0) +
          (lastUsage.cache_read_input_tokens || 0);
        resolve(totalTokens);
      } else {
        resolve(0);
      }
    });

    rl.on('error', (err) => {
      reject(err);
    });
  });
}

// プログレスバーを生成（ブロック文字で使用率を視覚化）
function createProgressBar(percentage, width) {
  const filled = Math.round(width * percentage / 100);
  const empty = width - filled;
  return '\u2588'.repeat(filled) + '\u2591'.repeat(empty);
}

function formatTokenCount(tokens) {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(1)}M`;
  } else if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}K`;
  }
  return tokens.toString();
}
