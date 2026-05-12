# 調査プラン: Beatrice の仕様

## 目的・背景

[voice-changer-types](../specs/voice-changer-types.md) §1.3 ニューラル変換 / §2.1 ローカル OSS に **暫定置き** されている **Beatrice** を、個別ツールとして掘り下げる。voice-changer-types §1.3 で「一般にコンテンツ抽出 + 話者埋め込み合成として語られることが多いもの」のグループに入れているが、[同 §未確定事項](../specs/voice-changer-types.md#未確定事項-phase-3-以降で再評価) で「Beatrice / MMVC / DDSP-SVC などの分類は『一般にそう呼ばれている系統』に沿って暫定置きしているだけで、各ツールの正確な内部実装は個別ページで裏取りする」とされており、**この『裏取り』が本タスクの中心の目的**。

Beatrice は本ラボでの位置付けとして、

- **配信向け軽量を謳う系統**として一般に言及されることが多い（[CLAUDE.md](../../CLAUDE.md) の「触れがちな関連ツール」にも RVC / w-okada と並んで挙がっている）。リアルタイム性・軽量性の主張がどの公式情報源に書かれているかから裏取りする必要がある
- ホスト側（[w-okada/voice-changer](../specs/w-okada-voice-changer.md)）の **v.2 系で Beatrice v2** が、**v.1 系で Beatrice v1（Windows のみ）**が対応モデル表に挙がっている（[w-okada §3.1](../specs/w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より)）
- w-okada リリースノートに **「Beatrice: オートピッチシフト」「話者マージ」**の記載があり（[w-okada §3.3](../specs/w-okada-voice-changer.md#33-モデル別の補足リリースノートから読み取れる範囲)）、Beatrice 固有のパラメータが UI に露出している
- **Beatrice JVS Corpus Edition** という別ライセンスのチェックポイント配布が w-okada/voice-changer リポジトリ経由で案内されている（[w-okada §7.2](../specs/w-okada-voice-changer.md#72-同梱-参照されるモデルの利用条件)）— ライセンス整理を本書側に集約する価値が高い
- **公式リポジトリ・公式配布物・公式 README がどこにあるかから裏取りが必要**（RVC や so-vits-svc と違い、本ラボの spec / メモには現時点でリンクが整理されていない）

ため、ホスト側の調査と独立して **モデル/アルゴリズム側 + ライセンス側の整理**を 1 ファイルに集約しておく必要がある。

このドキュメントが揃うと、

- [RVC](../specs/rvc.md)（Retrieval ベース系）/ [so-vits-svc](../specs/so-vits-svc.md)（コンテンツ表現 + 話者条件付け系）/ Beatrice の三系統の構造比較が書けるようになる（voice-changer-types §1.3 の分類の解像度が上がる）
- w-okada/voice-changer 経由で Beatrice を触る際に、UI に出てくる **オートピッチシフト / 話者マージ / pitch / formant** 等のパラメータを**モデル側の知識**として裏付けられる
- Beatrice 系チェックポイント（特に JVS Corpus Edition）の**ライセンス判断軸**を、RVC / so-vits-svc とは独立した軸で明文化できる

## スコープ

含める:

- **公式系の情報源**（公式リポジトリ・公式 README・公式サイト・公式リリース。Phase 1 で位置関係を確定する）で公式に説明されている範囲での
  - 全体アーキテクチャ（コンテンツ抽出 / 話者表現 / 合成段の構成、voice-changer-types §1.3 のどのサブ系統に該当するか）
  - **v1 / v2 の差分**（README で明示されている範囲）と Windows のみ / クロスプラットフォーム可否
  - 学習プロセスの大枠（必要な学習データの形・前処理ステップ・配布チェックポイントを使う場合の手順）
  - 推論パラメータと UI 露出されているもの（**オートピッチシフト / 話者マージ / pitch / formant** 等、w-okada §3.3 で名指しされているもの）
  - 配布形態とライセンス（**リポジトリ本体ライセンス**、**Beatrice JVS Corpus Edition の利用条件**、その他事前学習物の利用条件）
- [voice-changer-types §4](../specs/voice-changer-types.md#4-配信用途で見るべき主な評価軸) 評価軸への暫定マッピング（モデル単体として答えられる項目に絞る）
- **w-okada/voice-changer 側で既に整理された内容との対応関係**
  - [w-okada §3.1](../specs/w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) のサポート表（v.1 / v.2 × Beatrice v1 / v2 × Windows のみ表記）の裏付け
  - [w-okada §3.3](../specs/w-okada-voice-changer.md#33-モデル別の補足リリースノートから読み取れる範囲) で挙がっている Beatrice 固有挙動（オートピッチシフト・話者マージ・pitch/formant）と Beatrice 本家側で語られているパラメータの対応
  - ホストで吸収される部分 / モデル本来の挙動 の責任分界の再確認
- **RVC / so-vits-svc との対比**（[rvc.md](../specs/rvc.md) / [so-vits-svc.md](../specs/so-vits-svc.md) との突き合わせ）
  - 構造上の違い（Retrieval ベース / コンテンツ表現+話者条件付け / Beatrice の系統 — 後者は Phase 1 で確定）
  - 配布チェックポイントの運用感の違い（特に JVS Corpus Edition がある点が Beatrice 固有）
  - 「配信向け軽量を謳う系統」という一般評価が公式情報源で裏取れるかどうか

含めない:

- 実測のレイテンシ / 音質 / GPU 使用量（自分で計測したものは別途 `experiments/` 配下に記録）
- **第三者の声を許諾なく再現するような利用方法**および**特定のキャラクター音声 / 歌唱モデルへのリンク・取得手順**（[CLAUDE.md](../../CLAUDE.md) 方針）
- インストール手順そのものの完全な再掲（必要になった時点で `experiments/` 側に書く）
- 学習スクリプトのコード詳細（ソース読解レベル）— 必要になった時点で別タスク化
- **Beatrice の派生フォーク・コミュニティ実装の個別深掘り**（公式 README / 公式リリース範囲を超える領域は別タスク化）

## 対応方針

成果物は `docs/specs/beatrice.md` の 1 ファイル。
冒頭に voice-changer-types での位置付けを 1 行で書く（**ただし §1.3 内のどの系統に該当するかは Phase 1 で確定するまで暫定表記**。例: 「技術アプローチ: 1.3 ニューラル変換（系統は Phase 1 で確定）/ 提供形態: 2.1 ローカル OSS / モデル形態: 3.x（Phase 1 で確定）」）。

構成案（[rvc.md](../specs/rvc.md) / [so-vits-svc.md](../specs/so-vits-svc.md) と並行できる形にする）:

1. 概要（Beatrice とは何か / 名前が指すレイヤの整理: アルゴリズム / 公式リポジトリ / 配布チェックポイント / JVS Corpus Edition）
2. アーキテクチャ概観（公式に明記されている構造をもとに、voice-changer-types §1.3 のどの系統に該当するかを確定。v1 / v2 の差分）
3. 学習プロセスの大枠 — **公式が学習スクリプトを公開しているかから確認**。配布チェックポイント前提の運用なのか、ユーザー側で学習が回せるのか
4. 推論パラメータ（オートピッチシフト / 話者マージ / pitch / formant 等。w-okada 側 UI 露出との対応表）
5. 配布形態とライセンス（リポジトリ本体・JVS Corpus Edition・その他事前学習物の利用条件、商用配信での扱い）
6. w-okada/voice-changer 経由で触る場合の責任分界（ホスト側で吸収される / モデル側で決まる部分の対応関係。**Beatrice v1 が Windows のみという制約がモデル側 / ホスト側どちらに由来するかも整理**）
7. **RVC / so-vits-svc との対比**（構造・パラメータ・運用面の差をまとめる。voice-changer-types §1.3 内の三系統対比の決定版にする）
8. voice-changer-types §4 評価軸への暫定マッピング（実測前提の項目は「未計測」と明記）
9. 未確認事項 / 後続タスク

記述ルール（[rvc.md](../specs/rvc.md) / [so-vits-svc.md](../specs/so-vits-svc.md) と統一）:

- **公式リポジトリ / 公式 README / 公式サイト** に書かれていることと、コミュニティで一般に言われていることを明確に分ける
- 実測値・断定的な性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）
- 「アルゴリズム Beatrice として共通」と「公式実装 / w-okada/voice-changer など実装側の話」を混ぜない
- 学習データ・配布チェックポイントのライセンスは、リポジトリ本体ライセンスと**分けて**書く
- 第三者キャラクター音声のチェックポイント取得手順は書かない（言及はしても、リンク・手順は記載しない）
- 「RVC / so-vits-svc との比較」を書くときは、自分達のラボでの実測ではなく **公式に書かれている特性ベースの構造比較** に留める
- **「配信向け軽量を謳う」という一般評価は、公式情報源で裏取れた範囲のみ採用**し、コミュニティ評価レベルの主張はその旨を明記する

## 影響範囲

- 新規追加: `docs/plans/beatrice.md`（本ファイル）, `docs/specs/beatrice.md`
- 既存ファイル変更:
  - `TODO.md` の該当項目に本プランへのリンク追記、Phase の子タスク化
  - （必要に応じて）`docs/specs/voice-changer-types.md` §1.3 / §3 の代表例記述で Beatrice の系統表記を確定値で更新（暫定置きを解消）
  - （必要に応じて）`docs/specs/w-okada-voice-changer.md` §3.1 / §3.3 / §7.2 から本書への相互リンク追加
  - （必要に応じて）`docs/specs/rvc.md` / `docs/specs/so-vits-svc.md` の対比箇所への相互リンク追加
- コードへの影響なし

## 進め方 (Phase)

- [x] Phase 1: **公式系の情報源を特定**（公式リポジトリ・公式 README・公式サイト・配布物）し、`docs/specs/beatrice.md` の §1〜2（概要・アーキテクチャ概観）と §5（配布形態とライセンス、特に **Beatrice JVS Corpus Edition** を含む）を埋める。**voice-changer-types §1.3 のどのサブ系統に該当するか**を確定する
- [x] Phase 2: 学習プロセスの大枠（§3）・推論パラメータ（§4。w-okada UI との対応表 — オートピッチシフト・話者マージ・pitch/formant）・w-okada との責任分界（§6）を整理
- [ ] Phase 3: RVC / so-vits-svc との対比（§7）・voice-changer-types §4 評価軸への暫定マッピング（§8）・後続調査タスクの起票（§9）

## 完了条件

- `docs/specs/beatrice.md` が上記構成で書かれている
- 冒頭に voice-changer-types での分類が **暫定表記なし**で 1 行で示されている（Phase 1 で系統を確定したことが反映されている）
- 「公式に書かれている内容 / コミュニティで一般に言われている内容 / 未確認」の区別が読み手に分かる
- 実測値・断定的な性能評価が含まれていない
- 第三者キャラクター音声 / 歌唱モデルへの取得導線が含まれていない
- [rvc.md](../specs/rvc.md) / [so-vits-svc.md](../specs/so-vits-svc.md) と相互参照可能な形になっており、voice-changer-types §1.3 内の三系統の構造比較が読み取れる
- w-okada/voice-changer の spec から Beatrice 固有挙動（オートピッチシフト・話者マージ等）を裏付けるためのリンク先として機能する
- **Beatrice JVS Corpus Edition の利用条件**が、リポジトリ本体ライセンスとは独立した節として明文化されている
