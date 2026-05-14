# 作業プラン: plans / specs でフローチャートのような図も扱えるようにする

## 目的・背景

`docs/plans/` ・ `docs/specs/` 配下のドキュメントでは、現状フローチャート的な内容を ASCII アートで書いている。
代表例が [docs/specs/voice-changer-types.md](../specs/voice-changer-types.md) §「全体像」（L19〜L33）の 3 軸の見取り図で、ボックス + 罫線 + `◇` で交差点を表現している。

ASCII アートだと以下が辛い:

- 軸が増えたり項目が増えると整列が崩れる（罫線の桁数を手で揃える必要がある）
- 矢印の向き・分岐の意味がコードからは読み取れず、後から編集する人が再構築コストを払う
- vibeboard のプレビューでも GitHub Web でも、コードブロックとして等幅表示されるだけで「図」としての可読性は低い

リポジトリの描画基盤を確認したところ、

- **vibeboard は Mermaid をサポート済み**: [vibeboard/src/web/index.html](../../vibeboard/src/web/index.html) L40-L43 で Mermaid ESM を読み込み、[vibeboard/src/web/app.js](../../vibeboard/src/web/app.js) の `renderMermaidIn` (L352 付近) でレンダリングしている
- **GitHub もデフォルトで Mermaid を描画**: ` ```mermaid ` フェンスドコードブロックがそのまま図になる

つまり**追加依存なしで Mermaid を採用できる**。本タスクでは Mermaid を `docs/plans/` ・ `docs/specs/` の標準フローチャート記法として定め、まずは voice-changer-types.md §「全体像」の ASCII 図を Mermaid 化する。

このタスクが完了すると、

- 図を入れたい spec / plan で、表現方法を毎回考えずに「Mermaid で書く」と決め打ちできる
- voice-changer-types.md の全体像が、軸ごとの色分け・矢印の向き付きで読める形になる
- 後続で `docs/specs/` に増える図（接続パターン / 経路図 / 状態遷移 等）にも同じ書き方を流用できる

## スコープ

含める:

- Mermaid を `docs/plans/` ・ `docs/specs/` の標準フローチャート記法とすることをドキュメント化する
  - [CLAUDE.md](../../CLAUDE.md) の「作業のときに意識すること」or「ファイルの置き場所」近辺に、図は Mermaid で書く方針を 1 段落追記する
  - 既存の表記揺れ（ASCII アート）は許容するが、新規追加・既存差し替え時は Mermaid を選ぶ運用にする
- [docs/specs/voice-changer-types.md](../specs/voice-changer-types.md) §「全体像」L19〜L33 の ASCII 図を Mermaid 化する
  - 3 軸（技術アプローチ / 提供形態 / モデル形態）の包含関係と、3 軸が「ツール 1 個」を構成する関係性を、見て分かる形で描く
  - 元の文章（直前の箇条書きと例 「ニューラル変換 × ローカル OSS × 話者依存」）はそのまま残し、図の置き換えのみ
- vibeboard プレビューと GitHub Web の両方で表示崩れがないかを目視確認

含めない:

- voice-changer-types.md §「全体像」以外の図の追加（必要に応じて後続タスクで個別に起票する）
- 他 spec（rvc / so-vits-svc / beatrice / cloud-saas-realtime / virtual-audio-devices / obs-studio）の図追加・差し替え
- vibeboard 自体の改修（既に Mermaid 対応済みなので不要）
- 画像 (PNG/SVG) でのスクリーンショット生成（リポジトリ内テキストでメンテできることを優先するため）

## 対応方針

### Phase 1: 表記方針のドキュメント化

[CLAUDE.md](../../CLAUDE.md) の「作業のときに意識すること」の「ファイルの置き場所」直後あたりに、以下のような 1 項目を追加する。

> - 図（フローチャート / 関係図 / 状態遷移）は Mermaid (` ```mermaid ` フェンスドコードブロック) で書く。vibeboard のプレビューと GitHub Web の両方が標準で描画する。ASCII アート図を新規に書かない。既存の ASCII 図は、編集する機会があれば Mermaid に置き換えていく（一括置換タスクは作らない）。

文言は上記の趣旨に沿う形で実装時に微調整する。

### Phase 2: voice-changer-types.md §「全体像」の Mermaid 化

差し替え対象は L19〜L33 のコードブロック 1 つだけ。直前の箇条書き（L11〜L17）は触らない。

書き方の方針:

- 図のタイプは **`flowchart LR`**（左右に流す）を第一候補とする。3 軸 → ツールという包含関係を、左から右に流す形で表現する。
- 3 軸それぞれを `subgraph` で囲み、軸名（技術アプローチ / 提供形態 / モデル形態）をラベルにする。各軸の中に分類項目（信号処理 / ボコーダ系 / … 等）をノードとして並べる。
- 3 つの subgraph から「ツール 1 個（= 3 軸の組合せ）」を表すノードに矢印を集約し、文章で書いている「ニューラル変換 × ローカル OSS × 話者依存」のような組合せ例を 1 件、図中の例示ノードとしても載せる。
- 色分けは使うが、テーマカラーは vibeboard / GitHub のデフォルトテーマ（`default`）で破綻しないものに絞る（軸ごとの `class` 定義 + `classDef` の塗りつぶし指定で表現）。

実装時に図のラフを書いて、`flowchart LR` で読みやすくならない場合は `flowchart TB`（上下）や `graph TD` 系にフォールバックする。Mermaid 化に伴い、図の直前の箇条書きや直後の本文は触らない。

### Phase 3: 表示確認

- vibeboard を `node vibeboard/dist/cli.js --root .` で起動し、`http://localhost:3010` で voice-changer-types.md を開いて図が描画されることを目視確認する
- GitHub Web 側は本タスクのコミットを push 後、Web 上でのレンダリングを目視確認する（push 前は ローカル CLI / `gh` での確認手段が無いため、ここは push 後のチェックポイントとする）
- レンダリング崩れがあれば Phase 2 に戻して書き直す

## 影響範囲

- 新規追加: `docs/plans/diagrams-in-plans-and-specs.md`（本ファイル）
- 既存ファイル変更:
  - `CLAUDE.md`: 図の表記方針を 1 項目追記
  - `docs/specs/voice-changer-types.md`: §「全体像」の ASCII 図ブロック 1 つを Mermaid ブロックに差し替え
  - `TODO.md`: 該当項目に本プランファイルへのリンクを追記、Phase 子タスクを追加
- コードへの影響なし（vibeboard は既に Mermaid 対応済み）

## テスト方針

- vibeboard プレビューで voice-changer-types.md を開き、Mermaid 図が描画され、軸の関係が ASCII 版と同じ意味で読み取れることを目視確認
- GitHub Web 側でも push 後に同じ確認
- voice-changer-types.md を Markdown としてリンク切れがないか目視確認（図の差し替えなのでリンクへの影響は基本ないが、念のため）

## 進め方 (Phase)

- [ ] Phase 1: CLAUDE.md に図表記方針（Mermaid を使う旨）を追記
- [ ] Phase 2: voice-changer-types.md §「全体像」の ASCII 図を Mermaid 化
- [ ] Phase 3: vibeboard / GitHub Web で描画確認、崩れていれば Phase 2 へ戻して微修正

## 完了条件

- CLAUDE.md に図は Mermaid で書く方針が記載されている
- voice-changer-types.md §「全体像」が Mermaid で描かれ、vibeboard / GitHub Web の両方で破綻なく描画される
- 元の ASCII 図が伝えていた「3 軸 + 組合せ」という構造が、Mermaid 図でも読み取れる
- `TODO.md` から該当項目が `DONE.md` に移され、本プランファイルが `docs/plans/archive/` に移動している
