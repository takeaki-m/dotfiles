-- カスタムスニペットの定義
-- よく使う単語を登録し、nvim-cmpの補完候補として自動表示する
-- 全ファイルタイプで有効（"all"）
--
-- 使い方:
--   s("トリガー", { t("展開後のテキスト") })
--   トリガーを途中まで入力すると、補完候補に展開後のテキストが表示される

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

-- 全ファイルタイプ共通のスニペット
ls.add_snippets("all", {
  s(":k8s", { t("Kubernetes") }),
  s(":tf",  { t("Terraform") }),
  s(":ts",  { t("TypeScript") }),
  s(":gh",  { t("GitHub") }),
  s(":gl",  { t("Google") }),
  s(":ge",  { t("Gemini") }),
  s(":op",  { t("Open AI") }),
  s(":pr",  { t("Provider") }),
  s(":ll",  { t("LLM") }),
  s(":ms",  { t("Microsoft") }),
})

