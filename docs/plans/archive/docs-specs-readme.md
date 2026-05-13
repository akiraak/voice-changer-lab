# 作業プラン: docs/specs/README.md（インデックスページ）

## 目的・背景

`docs/specs/` 配下の spec が 8 本に増えたが、フォルダを開いたときに「何が並んでいるか」を一覧する入口が無い。トップの [README.md](../../README.md) は**プロジェクトとしての目的・スコープ**を述べ、[docs/specs/voice-changer-types.md](../specs/voice-changer-types.md) は**分類軸の見取り図**を担うため、両者の中間に位置する「specs フォルダの目次」が空白になっている。

このタスクが空白のままだと、

- 新規にリポジトリを訪れたとき、`docs/specs/` を直接開いてもファイル名だけが並び、各 spec が何を扱っているかが分からない。
- voice-changer-types.md は分類軸のドキュメントであって目次ではないため、「クラウド SaaS をまとめて見たい」「配信周辺ツールシリーズを順に読みたい」のような視点での読み始めができない。
- [DONE.md](../../DONE.md) は完了履歴であり、最新の各 spec のスナップショットとして使えるが、本来は**履歴**であって**目次**ではない。

このページが揃うと、

- `docs/specs/` フォルダを開いたとき、各 spec を 2〜3 行で見渡せる目次が最初に表示される。
- 「OSS モデル」「OSS 実行ホスト」「クラウド SaaS」「配信周辺ツール（シリーズ）」「分類見取り図」といった**読み口のグルーピング**から spec に降りられる。
- 推奨される読む順番が示される（README → voice-changer-types → 個別 spec）。

## スコープ

含める:

- `docs/specs/README.md` の新規作成
- 各 spec の 1 行ヘッドライン + 2〜3 行の中身紹介 + 進捗状態（Phase 完了 / 最終確認日）の明示
- voice-changer-types.md 上の分類タグ（技術アプローチ / 提供形態 / モデル形態）を簡潔に付記
- 配信周辺ツール調査シリーズ（virtual-audio-devices → obs-studio → 第3弾候補）の連番関係を示す
- 末尾に「読む順番（推奨）」を提示

含めない:

- 各 spec の内容を再要約しすぎること（各 spec の冒頭ブロックを読めば分かる粒度で止める）
- 実測値・断定的性能評価（[CLAUDE.md](../../CLAUDE.md) 方針）
- 後続タスクの再列挙（[TODO.md](../../TODO.md) と重複させない）

## 対応方針

1. **構成（ファイル内）**:
   - §1 このフォルダの位置付け（README / voice-changer-types との関係を 1 段落）
   - §2 一覧（5 グループに分けて各 spec を紹介）
     - §2.1 全体の見取り図: voice-changer-types
     - §2.2 OSS 実行ホスト: w-okada-voice-changer
     - §2.3 OSS モデル: rvc / so-vits-svc / beatrice
     - §2.4 クラウド SaaS: cloud-saas-realtime
     - §2.5 配信周辺ツール（シリーズ）: virtual-audio-devices / obs-studio
   - §3 読む順番（推奨）
2. **各エントリの粒度**: 「タイトル + 1 行ヘッドライン + voice-changer-types での位置付け + 何が書かれているか 2〜3 行 + 進捗状態」を守る。
3. **リンク**: 各 spec への相対リンクと、関連 spec への横リンクを最低限張る。

## 影響範囲

- 新規: `docs/specs/README.md`
- 更新: `TODO.md`（着手時に追加 → 完了で削除）、`DONE.md`（完了行追加）、`docs/plans/docs-specs-readme.md`（本ファイル）→ 完了後 `docs/plans/archive/` へ移動
- 既存 spec への変更は行わない

## テスト方針

- vibeboard で `docs/specs/README.md` がプレビュー表示されることを目視確認
- 各リンクが正しい相対パスで動くことを目視確認（リンク切れがないか）
