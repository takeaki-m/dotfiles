#!/usr/bin/env python3
"""罫線(box-drawing)で描かれたテーブルを Markdown のテーブルに変換する。

全体構成:
  1. 標準入力を1行ずつ「枠線行」「データ行」「それ以外」に分類する
  2. 枠線行は捨て、データ行を `| セル | セル |` の形に変換する
  3. テーブルの最初のデータ行をヘッダとみなし、その直後に Markdown の
     区切り行(`| --- |`)を必ず生成して挿入する

3 の「枠線は一律で捨てて区切り行はこちら側で生成する」方針が設計の肝。
元のテーブルが区切り行(├─┼─┤)を持つかどうか、罫線が細線・太線・二重線・
角丸のどれかに依存せず、同じ経路で正しい Markdown を出力できる。
"""
import re
import sys

# 罫線の構成文字。細線・太線・二重線・角丸・破線をまとめて扱う
VERTICAL_CHARS = "│┃║╎╏┆┇┊┋"  # セルの区切りになる縦線
HORIZONTAL_CHARS = "─━═╌╍┄┅┈┉"  # 枠線の横線
JOINT_CHARS = (  # 角・T字・十字などの接続文字
    "┌┐└┘├┤┬┴┼"
    "╭╮╰╯"
    "┏┓┗┛┣┫┳┻╋"
    "┝┞┟┠┡┢┥┦┧┨┩┪┭┮┯┰┱┲┵┶┷┸┹┺┽┾┿╀╁╂╃╄╅╆╇╈╉╊"
    "╒╓╔╕╖╗╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬"
)
# テーブルの下端に現れる文字。連続する2つの表を取り違えないための終端判定に使う
BOTTOM_CHARS = "└┘╰╯┗┛╚╝┴┸┹┺┻╧╨╩"

BORDER_CHARS = VERTICAL_CHARS + HORIZONTAL_CHARS + JOINT_CHARS
HORIZONTAL_OR_JOINT = HORIZONTAL_CHARS + JOINT_CHARS
SPLIT_PATTERN = re.compile("[" + re.escape(VERTICAL_CHARS) + "]")


def is_border_line(stripped):
    """枠線だけで構成された行かどうか。

    横線か接続文字を必ず1つ以上含むことを条件にしているのは、中身が空の
    データ行(`│    │`)を枠線と誤判定させないため。
    """
    if not stripped:
        return False
    if not any(char in HORIZONTAL_OR_JOINT for char in stripped):
        return False
    return all(char in BORDER_CHARS or char.isspace() for char in stripped)


def is_data_line(stripped):
    """縦線を含む＝セルを持つ行かどうか"""
    return any(char in VERTICAL_CHARS for char in stripped)


def escape_cell(cell):
    """セル内の `|` は Markdown の列区切りと解釈されて表が崩れるためエスケープする"""
    return cell.strip().replace("|", r"\|")


def split_cells(stripped):
    """データ行を縦線で分割してセルの内容を取り出す。

    行頭・行末の縦線は分割結果の両端に空文字を生む。これは枠線由来なので
    落とすが、両端が空のときだけ落とすことで、縦線が片側にしか無い行でも
    セルを欠落させない。
    """
    cells = SPLIT_PATTERN.split(stripped)
    if cells and cells[0].strip() == "":
        cells = cells[1:]
    if cells and cells[-1].strip() == "":
        cells = cells[:-1]
    return [escape_cell(cell) for cell in cells]


def format_row(indent, cells):
    return indent + "| " + " | ".join(cells) + " |"


def process_text(text):
    lines = text.splitlines()
    result = []
    indent = ""  # テーブルのインデント。箇条書き内の表を崩さないよう保持する
    columns = 0  # ヘッダ行から決めた列数
    in_table = False  # ヘッダ行と区切り行を出力済みかどうか

    for line in lines:
        stripped = line.strip()

        if is_border_line(stripped):
            # 枠線は出力しない。下端の枠線であればテーブルの終わりとみなし、
            # 直後に別の表が続いても改めてヘッダとして扱えるようにする
            if any(char in BOTTOM_CHARS for char in stripped):
                in_table = False
            continue

        if is_data_line(stripped):
            cells = split_cells(stripped)
            if not in_table:
                # テーブル最初のデータ行 = ヘッダ。区切り行をここで生成する
                indent = line[: len(line) - len(line.lstrip())]
                columns = len(cells)
                result.append(format_row(indent, cells))
                result.append(format_row(indent, ["---"] * columns))
                in_table = True
            else:
                # 列数が足りない行は空セルで補い、表としての整合性を保つ
                if len(cells) < columns:
                    cells += [""] * (columns - len(cells))
                result.append(format_row(indent, cells))
            continue

        # 表以外の行はインデントを含め元のまま通す
        in_table = False
        result.append(line)

    return "\n".join(result)


def main():
    # ロケール未設定の環境でも UTF-8 で読み書きする。
    # 標準入出力を open() で開き直すと元のラッパが閉じられず二重クローズの
    # 恐れがあるため、reconfigure() で符号化方式だけを差し替える
    sys.stdin.reconfigure(encoding="utf-8")
    sys.stdout.reconfigure(encoding="utf-8")

    text = sys.stdin.read()
    converted = process_text(text)
    # splitlines() が落とす末尾の改行を、入力に合わせて復元する
    if text.endswith("\n"):
        converted += "\n"
    sys.stdout.write(converted)


if __name__ == "__main__":
    main()
