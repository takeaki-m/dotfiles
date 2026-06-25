-- =============================================================================
-- vim.pack 向け 軽量 遅延ロードヘルパ
-- =============================================================================
-- 全体構成:
--   vim.pack(Neovim 0.12 組み込み)には lazy.nvim のような cmd/ft/event トリガが無い。
--   さらに「起動時に vim.pack.add したプラグイン」は load=false(packadd!)であっても
--   起動末尾の load-plugins ステップで plugin/ が必ず source されてしまう(実機検証済み)。
--   つまり真の遅延読み込みには「起動時には add せず、トリガ発火時に初めて add する」しかない。
--
--   そこで本モジュールは以下を提供する:
--     1) cmd / ft / event をトリガに、その時点で vim.pack.add(load) + setup を一度だけ実行
--     2) 初回 add 時に lockfile へ登録されるため、一度でも発火すれば
--        :lua vim.pack.update() の対象にも含まれる(未発火のものは未インストールのまま)
--
-- 設計詳細:
--   - registry: name -> { spec, setup, loaded } の登録簿。name は vim.pack の
--     デフォルト命名(src 末尾のディレクトリ名)に合わせる。
--   - load(name): 登録済みプラグインを一度だけロード+setup する。冪等。
--     octo→telescope のような「遅延プラグイン同士の依存」も load() を呼ぶだけで解決できる。
-- =============================================================================

local M = {}

-- name(リポジトリのディレクトリ名) -> { spec, setup, loaded }
local registry = {}

-- spec.src の末尾セグメントを vim.pack のデフォルト plugin 名として使う
-- 例: https://github.com/nvim-telescope/telescope.nvim -> "telescope.nvim"
local function name_of(spec)
  return spec.name or spec.src:match("([^/]+)$")
end

-- 登録済みプラグインを一度だけ vim.pack.add(load=true) + setup する
--- @param name string プラグインのディレクトリ名
function M.load(name)
  local entry = registry[name]
  if not entry or entry.loaded then
    return
  end
  entry.loaded = true
  -- confirm=false: 初回トリガ時のインストールを確認バッファ無しで即実行する(UXのため)
  vim.pack.add({ entry.spec }, { load = true, confirm = false })
  if entry.setup then
    entry.setup()
  end
end

-- 共通: registry へ登録して name を返す
local function register(spec, setup)
  local name = name_of(spec)
  registry[name] = { spec = spec, setup = setup, loaded = false }
  return name
end

-- コマンド発火で遅延ロードする
-- 全体: 本体ロード前は stub コマンドを置き、初回呼び出しで本体をロード→stub削除→本体を再実行する。
--- @param spec table vim.pack の spec ({ src=..., version=... })
--- @param cmds string[] 遅延発火させるコマンド名
--- @param setup? function ロード後に一度だけ実行する設定
function M.on_cmd(spec, cmds, setup)
  local name = register(spec, setup)
  for _, cmd in ipairs(cmds) do
    vim.api.nvim_create_user_command(cmd, function(o)
      -- 本体が同名コマンドを再定義するため、先に stub を全削除しておく
      for _, c in ipairs(cmds) do
        pcall(vim.api.nvim_del_user_command, c)
      end
      M.load(name)
      -- range / bang / args を引き継いで本体コマンドを再実行する
      local range = ""
      if o.range == 1 then
        range = tostring(o.line2)
      elseif o.range == 2 then
        range = o.line1 .. "," .. o.line2
      end
      pcall(vim.cmd, string.format("%s%s%s %s", range, cmd, o.bang and "!" or "", o.args))
    end, { nargs = "*", bang = true, range = true, desc = "lazy-load " .. name })
  end
end

-- FileType 発火で遅延ロードする
-- 全体: 対象 filetype のバッファを開いた瞬間にロードし、本体の autocmd を効かせるため
--   現在のバッファへ FileType を再発火する(once で自身は一度きり)。
--- @param spec table vim.pack の spec
--- @param fts string[] 対象 filetype
--- @param setup? function
function M.on_ft(spec, fts, setup)
  local name = register(spec, setup)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = fts,
    once = true,
    callback = function(ev)
      M.load(name)
      -- ロードのきっかけになった現バッファへ、本体が登録した FileType autocmd を適用する。
      -- 既に FileType 処理は済んでいるため、対象バッファを再発火させる必要がある。
      -- 注意: nvim_exec_autocmds は pattern と buffer の同時指定を許さない(Conflict エラー)。
      --   そのため nvim_buf_call で対象バッファを current にし、pattern のみで発火する。
      local ft = vim.bo[ev.buf].filetype
      vim.api.nvim_buf_call(ev.buf, function()
        vim.api.nvim_exec_autocmds("FileType", { pattern = ft })
      end)
    end,
  })
end

-- イベント発火で遅延ロードする(once)
--- @param spec table vim.pack の spec
--- @param events string|string[] 対象イベント(例: "InsertEnter")
--- @param setup? function
function M.on_event(spec, events, setup)
  local name = register(spec, setup)
  vim.api.nvim_create_autocmd(events, {
    once = true,
    callback = function()
      M.load(name)
    end,
  })
end

return M
