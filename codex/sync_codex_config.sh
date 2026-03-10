#!/usr/bin/env bash
set -euo pipefail

# このスクリプトの全体方針:
# - dotfiles側の静的設定（codex/config.toml）を正とする
# - Codex実行時に更新される動的設定（projects/notice）は ~/.codex/config.toml から保持する
# - 最終的に両者をマージした内容で ~/.codex/config.toml を更新する
#
# 詳細:
# - 保持対象セクションは [projects.*], [notice], [notice.*]
# - source側に同セクションが存在しても除去したうえで、target側の保持対象を末尾に再付与する
# - 既定では更新前にバックアップを作成する

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE="${SCRIPT_DIR}/config.toml"
DEFAULT_TARGET="${HOME}/.codex/config.toml"

source_path="${DEFAULT_SOURCE}"
target_path="${DEFAULT_TARGET}"
backup=true
dry_run=false

usage() {
  cat <<'EOF'
Usage:
  sync_codex_config.sh [--source PATH] [--target PATH] [--no-backup] [--dry-run]

Options:
  --source PATH   マージ元の静的設定ファイル（既定: codex/config.toml）
  --target PATH   更新先の実行設定ファイル（既定: ~/.codex/config.toml）
  --no-backup     更新前バックアップを作成しない
  --dry-run       ファイルは更新せず、マージ後内容を標準出力に表示
  -h, --help      ヘルプを表示
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_path="${2:-}"
      shift 2
      ;;
    --target)
      target_path="${2:-}"
      shift 2
      ;;
    --no-backup)
      backup=false
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${source_path}" || -z "${target_path}" ]]; then
  echo "--source と --target にはパス指定が必要です。" >&2
  exit 1
fi

if [[ ! -f "${source_path}" ]]; then
  echo "source が見つかりません: ${source_path}" >&2
  exit 1
fi

target_dir="$(dirname "${target_path}")"
mkdir -p "${target_dir}"

tmp_base="$(mktemp)"
tmp_preserve="$(mktemp)"
tmp_merged="$(mktemp)"
cleanup() {
  rm -f "${tmp_base}" "${tmp_preserve}" "${tmp_merged}"
}
trap cleanup EXIT

# 動的セクション判定:
# - [projects.*]
# - [notice]
# - [notice.*]
#
# source側から動的セクションを取り除き、静的設定のみを抽出する。
awk '
  function is_dynamic_header(h) {
    return (h ~ /^\[projects\./ || h ~ /^\[notice(\.|])/)
  }
  /^\[[^]]+\][[:space:]]*$/ {
    skip = is_dynamic_header($0)
  }
  !skip { print }
' "${source_path}" > "${tmp_base}"

if [[ -f "${target_path}" ]]; then
  # target側から動的セクションだけ抽出し、マージ時に保持する。
  awk '
    function is_dynamic_header(h) {
      return (h ~ /^\[projects\./ || h ~ /^\[notice(\.|])/)
    }
    /^\[[^]]+\][[:space:]]*$/ {
      keep = is_dynamic_header($0)
    }
    keep { print }
  ' "${target_path}" > "${tmp_preserve}"
else
  : > "${tmp_preserve}"
fi

cat "${tmp_base}" > "${tmp_merged}"

if [[ -s "${tmp_preserve}" ]]; then
  printf "\n" >> "${tmp_merged}"
  cat "${tmp_preserve}" >> "${tmp_merged}"
fi

if [[ "${dry_run}" == "true" ]]; then
  cat "${tmp_merged}"
  exit 0
fi

if [[ -f "${target_path}" && "${backup}" == "true" ]]; then
  backup_path="${target_path}.bak.$(date +%Y%m%d_%H%M%S)"
  cp "${target_path}" "${backup_path}"
  echo "backup: ${backup_path}"
fi

mv "${tmp_merged}" "${target_path}"
echo "updated: ${target_path}"
