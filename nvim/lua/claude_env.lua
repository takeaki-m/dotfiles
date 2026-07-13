--[[
  Claude 連携の実行環境(マルチプレクサ)判定モジュール

  全体構成:
    claude をどこで動かすかは実行環境で決まる。この判定を claude.lua(キーマップ)と
    init.lua(claudecode.setup の terminal provider 選択)の両方が必要とするため、
    ロジックの二重管理を避けて独立モジュールに切り出す。

  モードの定義:
    - "pane"  : herdr(AIエージェント特化のマルチプレクサ)配下。nvim buffer ではなく
                別 pane で起動した claude と WebSocket 経由でやり取りする。
                nvim 側は terminal を一切開かない(provider="none")。
    - "buffer": tmux 配下や素の端末。従来どおり nvim buffer 内で claude を扱う。

  判定方針:
    herdr は HERDR_ENV などの環境変数を出すため、それを積極判定に使う。
    「herdr でなければ buffer」とすることで、素の端末で nvim を単独起動した場合も
    従来挙動(buffer)へフォールバックし破綻しない。
    ※ 積極判定(HERDR_ENV がある)は消極判定(TMUX が無い)より安全。後者は
      「tmux も herdr も無い第3の環境」を pane に誤分類しうるため使わない。

  判定タイミング:
    環境変数はセッション中固定だが、参照コスト自体が無視できるほど小さいため
    キャッシュせず都度評価する(呼び出し側の初期化順に依存しない利点もある)。
--]]

local M = {}

---現在の実行環境に対応する Claude 連携モードを返す
---@return "pane"|"buffer"
function M.detect_target()
  if (vim.env.HERDR_ENV or "") ~= "" then
    return "pane"
  end
  return "buffer"
end

---pane モード(= herdr 配下で nvim buffer を使わない)かどうか
---@return boolean
function M.is_pane_mode()
  return M.detect_target() == "pane"
end

return M
