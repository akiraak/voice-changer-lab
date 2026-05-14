# VCClient と Beatrice の違い解説ページ作成プラン

## 目的・背景

新規ユーザー（および本ラボの README / overview から入った読者）が混同しやすい代表例として **「VCClient と Beatrice の違いがよく分からない」** という論点がある。混同が起きる理由は次の構造に由来する。

- **VCClient（w-okada/voice-changer）** は単一の声変換アルゴリズムを実装したものではなく、**複数モデルをロードして動かす実行ホスト**。本ラボでは [w-okada-voice-changer.md](../specs/w-okada-voice-changer.md) §1〜§3 で「実行ホスト」と整理済み。
- **Beatrice** は **Project Beatrice が開発した声変換アルゴリズム / モデル / 公式 VST バイナリ / キャラクターエディション**の総称で、4 つのレイヤを持つ（[beatrice.md §1.1〜§1.4](../specs/beatrice.md) で整理済み）。
- 配信用途で実際に使われる経路としては、
  1. **Beatrice 公式 VST 単体**で動かす（DAW / VST ホスト経由）
  2. **VCClient に Beatrice モデルをロード**して動かす（[w-okada-voice-changer.md §3.1](../specs/w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) の表で v.2 / v.1 ともサポート）
  3. **`aq2r/beatrice-client` 等の派生クライアント**で動かす（[beatrice.md §1.2](../specs/beatrice.md#12-公式系リポジトリ--配布物としての-beatrice) の「派生クライアント」言及）

  という 3 系統が同時に存在しており、「VCClient で使う Beatrice」と「公式 VST の Beatrice」と「Beatrice というクライアント」が混在する。

> ユーザー要望（2026-05-14）:
> - VCClient と Beatrice の違いを分かりやすく解説する

既存 spec（[w-okada-voice-changer.md](../specs/w-okada-voice-changer.md) / [beatrice.md](../specs/beatrice.md)）にはそれぞれの内部に「他方への参照」が散在しているが、**「両者を並べて違いを示す」専用ページは存在しない**。この穴を埋める。

## 対応方針

- 新規ファイル **`docs/specs/vcclient-vs-beatrice.md`** を作成する。
- **「実行ホスト vs 声変換アルゴリズム」という階層の違い**を中心に据える。3 軸クロスマトリクスの説明（voice-changer-types.md）には踏み込まず、**混同しやすい点を解きほぐすことだけに集中**した A4 1〜2 枚規模のページ。
- **既存資料の再利用に徹し、新規の Web 調査は行わない**（[w-okada-voice-changer.md](../specs/w-okada-voice-changer.md) / [beatrice.md](../specs/beatrice.md) / [overview.md](../specs/overview.md) / [voice-changer-types.md](../specs/voice-changer-types.md) からの引用と相互リンク中心）。
- 実測値・断定的性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。「公式が標榜する」「本ラボの整理」を区別する。
- AskUserQuestion でユーザーが選んだプレビュー構成（§1〜§6）をベースに肉付けする。

## ファイル構成（案）

```
docs/specs/vcclient-vs-beatrice.md
├── 前置きブロック（voice-changer-types での位置付け / 出典 / 進捗）
├── §1. そもそも比較対象が違う
│     - VCClient は「実行ホスト」、Beatrice は「声変換アルゴリズム / モデル」
│     - 1 行で言うと: 「VCClient は土俵、Beatrice は出場するレスラーの 1 人」
│     - voice-changer-types の分類軸での位置の違いを 1 表で
├── §2. VCClient（w-okada/voice-changer）= 実行ホスト
│     - 何をするソフトか（マイク入力 → モデル → 出力、IO 配線、UI、配信ソフト連携）
│     - 内蔵しないもの（アルゴリズム本体、モデル重み）
│     - ロードできるモデル一覧（RVC / Beatrice v1・v2 / so-vits-svc / MMVC / DDSP-SVC）
│     - → 詳細は w-okada-voice-changer.md §1〜§5
├── §3. Beatrice = 声変換アルゴリズム / モデル
│     - Project Beatrice が開発したアルゴリズム本体
│     - 「Beatrice」が指す 4 レイヤ（アルゴリズム / 公式系リポジトリ / 配布チェックポイント / バージョン）の超要約
│     - 配布形態が **VST プラグイン** であることの意味
│     - → 詳細は beatrice.md §1〜§3
├── §4. 3 つの使い方パターン（同じ Beatrice を使っても起動経路が違う）
│     - A) 公式 VST 単体（DAW / VST ホスト経由）
│     - B) VCClient + Beatrice モデルロード（配信ラボの主流経路）
│     - C) 派生クライアント（aq2r/beatrice-client 等。本ラボでは深追いしない）
│     - 各経路で「ホストの責任分界」がどう変わるかの 1 表
├── §5. 用語の整理（よく出る単語の対応表）
│     - VCClient = VC Client = w-okada/voice-changer
│     - Beatrice = Project Beatrice 製のアルゴリズム名（VST 名でもある）
│     - VST = プラグイン形式。DAW / VST ホストが読み込む
│     - 「Beatrice v1 / v2」「Beatrice JVS Corpus Edition」「キャラクターエディション」の指す範囲
├── §6. どう選ぶか（実用的なガイド）
│     - Beatrice **だけ** 使いたい → 公式 VST が一番素直（CPU のみ・約 35 MB・Windows）
│     - 他のモデル（RVC など）も切り替えたい → VCClient
│     - 配信での仮想オーディオデバイス連携 / monitor 分離 / IO 設定の柔軟性が欲しい → VCClient
│     - 注意: 経路によって**ライセンス確認の所在が変わる**（公式 VST EULA / Beatrice JVS Corpus Edition の規約 / キャラクターエディションの個別 EULA）
└── §7. 次に読むもの
      - w-okada-voice-changer.md / beatrice.md / overview.md / voice-changer-types.md
```

## 影響範囲

- **新規**:
  - `docs/specs/vcclient-vs-beatrice.md`
- **更新**:
  - `docs/specs/README.md` — §2 一覧 に新ファイルを追記する。位置は **§2.1 全体の見取り図** の中、`overview.md` と `voice-changer-types.md` の後ろに「特定の混同を解きほぐすトピック」として置く案で進める。§3 読む順番には組み込まない（必要な人だけ読むトピック扱い）。
  - `TODO.md` / `DONE.md` — タスク管理ルールに従って移動。
  - 関連 spec（`overview.md` / `w-okada-voice-changer.md` / `beatrice.md`）からの相互リンクは、本タスクでは**追加しない**（呼び出される側の文脈で必要性を判定してからにする）。
- **触れない**:
  - 既存 spec の本文（引用・抜粋のみ）

## テスト方針

- vibeboard で `vcclient-vs-beatrice.md` をプレビュー表示し、相互リンクが切れていないかを目視確認する。
- `docs/specs/README.md` の §2.1 に追加したエントリが既存の整理（overview → voice-changer-types → 個別 spec）の導線を壊していないことを確認する。
- 既存 spec（[w-okada-voice-changer.md](../specs/w-okada-voice-changer.md) §3.1 / [beatrice.md](../specs/beatrice.md) §1.1〜§1.4）と矛盾しないこと（特に「v2 サポートモデル」「Beatrice の 4 レイヤ」の表記）を本タスクの執筆過程で照合する。

## 段取り

1. `TODO.md` の既存項目「VCClient と Beatrice の違いを分かりやすく解説する」に本プランへのリンクを追記。
2. `docs/specs/vcclient-vs-beatrice.md` を新規作成（既存 spec の引用ベース、新規 Web 調査なし）。
3. `docs/specs/README.md` §2.1 にエントリを追記。
4. 完了時に `TODO.md` から `DONE.md` へ移動 / 本プランを `docs/plans/archive/` へ移動。

## やらないこと（スコープ外）

- Beatrice / VCClient の新規調査（既存 spec の範囲を超える内部実装の掘り下げ）。
- 派生クライアント（`aq2r/beatrice-client` 等）の個別深掘り。本ページでは存在の言及まで。
- voice-changer-types.md / overview.md の構成変更。
- 実測値の追加。
