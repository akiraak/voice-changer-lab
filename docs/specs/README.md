# docs/specs/ 目次

このフォルダには、リアルタイム声変換ツール・配信周辺ツール・クラウド SaaS の調査メモを置いている。各 spec は**公式情報源ベース**で書かれ、実測値・断定的性能評価は含まない（[CLAUDE.md](../../CLAUDE.md) 方針）。

リポジトリ全体の目的・スコープは [README.md](../../README.md)、各 spec の完了履歴とサマリは [DONE.md](../../DONE.md) を参照。

## 1. このフォルダの位置付け

- [README.md](../../README.md): プロジェクト全体の**目的・スコープ**
- [docs/specs/overview.md](./overview.md): **A4 一枚で読み切れる入門ページ**。提供形態（ローカル OSS / 商用デスクトップ / クラウド SaaS）を主軸に、種類・特徴・代表ツールをまとめる。**初見はここから読む**
- [docs/specs/voice-changer-types.md](./voice-changer-types.md): リアルタイム声変換ツールの**分類見取り図**（3 軸: 技術アプローチ / 提供形態 / モデル形態）。各分類から個別 spec へ降りる**ハブ**として機能する。overview.md より詳しく分類軸を見たいときに参照
- 本ファイル: `docs/specs/` フォルダの**目次**。各 spec を 2〜3 行で紹介し、読む順番を示す
- 各 spec ファイル: 個別ツールの詳細 / 横断棚卸し

`README → overview → 個別 spec` を入門ルート、`README → voice-changer-types → 個別 spec` を分類軸ルート、`README → 本ファイル → 個別 spec` を目次ルートとして、3 つの導線が成立するよう構成している。本ファイルでは voice-changer-types での位置付けタグを各エントリに付記する。

## 2. 一覧

### 2.1 全体の見取り図

- **[overview.md](./overview.md)** — リアルタイムボイスチェンジャー入門（A4 一枚）
  - **提供形態主軸**（ローカル OSS / ローカル商用 / クラウド SaaS）で 3 タイプに分け、それぞれの**特徴**と**有名/人気の代表ツール**を 1 セットで提示。
  - §2 ざっくり比較表（GPU 要否 / 料金 / 自前モデル / 配信ソフト連携 / 代表ツール）、§3 で技術アプローチとモデル形態の違いを軽く補足。
  - **初見の入口**: voice-changer-types.md の 3 軸クロスマトリクスは情報量が多いため、まずここを読んでから興味の枝へ降りる導線。

- **[voice-changer-types.md](./voice-changer-types.md)** — ボイスチェンジャーの分類見取り図
  - 3 軸（**技術アプローチ** / **提供形態** / **モデル形態**）で分類軸を提示し、各カテゴリに代表ツールを当てはめている（名前出しのみ）。
  - §4 では配信用途で見るべき主な評価軸（遅延 / 音質 / GPU 要件 / 入出力構成 / エコシステム / ライセンス）を整理。
  - **個別 spec のハブ**: 各 spec の冒頭ではここで定義した分類軸への位置付けタグを書く形で揃えてある。overview.md より細かい分類軸を見たいときに参照。
  - 進捗: Phase 1〜2 完了。

- **[vcclient-vs-beatrice.md](./vcclient-vs-beatrice.md)** — VCClient と Beatrice の違い（特定の混同を解きほぐすトピック）
  - **「VCClient = 実行ホスト」と「Beatrice = 声変換アルゴリズム / モデル」で階層が違う**ことを中心に据えた解説ページ。同じ Beatrice を使っても「公式 VST 単体 / VCClient + Beatrice ロード / 派生クライアント」の 3 経路で**ホストの責任分界**が変わる点を 1 表で整理。
  - §5 用語整理（VCClient / VC Client / w-okada/voice-changer の同一性、Beatrice v1 / v2 / JVS Corpus Edition / キャラクターエディションの指す範囲）、§6 で「Beatrice **だけ** 使うなら公式 VST、他モデルと切り替えるなら VCClient」という選び方ガイドと**経路ごとに読むべきライセンスが変わる**点の整理。
  - **§3 読む順番には組み込まない**（必要な人だけ読むトピック扱い）。w-okada-voice-changer.md / beatrice.md の補助として参照する。

### 2.2 OSS 実行ホスト

- **[w-okada-voice-changer.md](./w-okada-voice-changer.md)** — VCClient（リアルタイム音声変換の実行ホスト）
  - voice-changer-types の **1.4 ハイブリッド / 2.1 ローカル OSS / モデル形態はロードするモデル依存**。
  - RVC / so-vits-svc / Beatrice / MMVC / DDSP-SVC 等を切り替えて動かせる実行ホスト。前処理・後処理・IO 配線も担う。アーキ / 対応モデル / IO 構成 / ライセンス / 配信ソフトとの連携公式言及をまとめる。
  - 進捗: Phase 1〜3 完了。

### 2.3 OSS モデル

`w-okada-voice-changer` が実行ホストとして載せる代表モデルを 1 本ずつ深掘りする。3 本とも voice-changer-types の **1.3 ニューラル変換 / 2.1 ローカル OSS / 3.1 話者依存** に当てはまる。互いに構成を揃え（§1 概要レイヤ分け → §7 構造比較）、横で読める作りにしてある。

- **[rvc.md](./rvc.md)** — RVC (Retrieval-based Voice Conversion)
  - **1.3 ニューラル変換（Retrieval ベース系）**。kNN で学習話者の埋め込みを参照して特徴量を置換するタイプ。
  - 「アルゴリズム / WebUI 実装 / 実行ホスト」の 3 レイヤを分けて扱い、v1・v2 差分・推論パラメータ・ライセンスを整理。
  - 進捗: Phase 1〜3 完了。

- **[so-vits-svc.md](./so-vits-svc.md)** — so-vits-svc (SoftVC VITS Singing Voice Conversion)
  - **1.3 ニューラル変換（コンテンツ表現 + 話者条件付け系）**。SoftVC 系コンテンツエンコーダ + VITS デコーダ + NSF-HiFiGAN。歌声変換系の代表。
  - 4.0 / 4.1 差分、`4.1-Stable` がデフォルト（2023-11-11 アーカイブ済み）。学習プロセス / 推論パラメータ / RVC との対比。
  - 進捗: Phase 1〜3 完了。

- **[beatrice.md](./beatrice.md)** — Beatrice
  - **1.3 ニューラル変換（コンテンツ表現 + 話者条件付け系）**。PhoneExtractor + PitchEstimator + WaveGenerator 構成で**内部 VQ** を持つ（外部 retrieval は持たない）。
  - v1 / v2 差分、Project Beatrice 公式情報源（[prj-beatrice.com](https://prj-beatrice.com) / GitHub Org / HuggingFace 公式トレーナー）ベースで整理。RVC・so-vits-svc との対比あり。
  - 進捗: Phase 1〜3 完了。

### 2.4 クラウド SaaS

- **[cloud-saas-realtime.md](./cloud-saas-realtime.md)** — クラウド SaaS のリアルタイム入力対応棚卸し
  - voice-changer-types の **2.3 クラウド SaaS / API** の代表例（CoeFont / Resemble AI / ElevenLabs / Voice.ai）を**横断棚卸し**。1 ツール深掘りではない。
  - 「マイク → 別声 → 配信ソフトに流せるストリーム」の判定基準 R1 / R2 / R3 を §1 で定義し、§4 横断棚卸し表で判定ラベル A〜E を確定。配信向けにそのまま乗るのは **Voice.ai 1 件**という一次判断を出してある。
  - 進捗: Phase 1〜3 完了（最終確認日 2026-05-12）。CoeFont 再裏取りは [TODO.md](../../TODO.md) に残課題として起票済み。

### 2.5 配信周辺ツール（シリーズ）

`マイク → 声変換ホスト → 仮想オーディオデバイス → 配信ソフト` の経路を、上流から下流に向かって 1 本ずつ棚卸しするシリーズ。voice-changer-types の **§2 補助カテゴリ「周辺ツール」**を掘り下げる立て付け。両者とも 1 ツール深掘りではなく**複数ツールの横断棚卸し**。

- **第 1 弾: [virtual-audio-devices.md](./virtual-audio-devices.md)** — 仮想オーディオデバイスまとめ
  - VB-CABLE / VoiceMeeter Banana・Potato / BlackHole をコア集合、Soundflower / Linux PA・PW を補足として棚卸し。
  - §4 横断棚卸し表、§5 で配信用途の典型構成 4 パターン（P1: シングル仮想ケーブル / P2: VoiceMeeter ハブ / P3: monitor 分離 / P4: BlackHole + Multi-Output）を経路図化。
  - 進捗: Phase 1〜3 完了（最終確認日 2026-05-12）。

- **第 2 弾: [obs-studio.md](./obs-studio.md)** — OBS Studio との接続パターンまとめ
  - 第 1 弾の P1〜P4 経路の**下流側（配信ソフト＝OBS）**を補完。音声系 7 機能（音声入力キャプチャ / アプリケーション音声キャプチャ / 音声出力キャプチャ / 音声モニタリング / グローバル音声 SR / オーディオ同期オフセット / 音声フィルタ）を公式情報源ベースで個別エントリ化。
  - §4 機能 × 評価項目マトリクス + 配信用途の足切り早見表。§5 で virtual-audio-devices §5 P1〜P4 と 1:1 対応する OBS レシピ表 + 経路図。
  - 進捗: Phase 1〜3 完了（OBS Studio 32.1.2 / 最終確認日 2026-05-12）。

- **第 3 弾（未着手）**: ノイズ抑制 / ゲート系の棚卸し（NVIDIA Broadcast / Krisp / RNNoise / Speex / NVIDIA Audio Effects SDK）。[TODO.md](../../TODO.md) に起票済み。

### 2.6 セットアップ手順書（チュートリアル型）

「個別 spec の棚卸し結果を、実際に手を動かして組み立てる人向けに 1 本のチュートリアルにまとめ直す」立て付け。spec ではなく**操作手順ベース**。

- **[install-vcclient-beatrice-windows.md](./install-vcclient-beatrice-windows.md)** — VCClient + Beatrice + α インストールマニュアル（Windows 10/11）
  - [vcclient-vs-beatrice.md §4 経路 B](./vcclient-vs-beatrice.md#4-3-つの使い方パターン同じ-beatrice-を使っても起動経路が違う)（VCClient + Beatrice）を **Windows 10/11 で配信用途に組む**ためのチュートリアル。
  - VCClient（CUDA エディション主動線）/ Beatrice 2（主動線）+ Beatrice 1（営利目的禁止条項のみ言及）/ VB-CABLE / VoiceMeeter Banana / OBS Studio 32.1.x / ノイズ抑制（選択肢提示のみ）/ Discord・Zoom（汎用チェックリスト）までを 1 本でカバー。
  - §10 で P1〜P4 × OBS のレシピ表（Windows 配信用途は P2 / P3 中心）、§11 動作確認手順、§12 ハマりどころ早見表、§13 ライセンス・規約チェックリストを提示。
  - 進捗: Phase 1〜3 完了（最終確認日 2026-05-14）。

## 3. 読む順番（推奨）

新規にこのフォルダを開いたときの推奨ルート。

1. **[README.md](../../README.md)** — プロジェクトの目的・スコープを把握
2. **[overview.md](./overview.md)** — A4 一枚の入門ページで「種類 × 特徴 × 代表ツール」をつかむ
3. **興味の枝へ降りる**
   - 「もっと細かい分類軸を見たい」 → [voice-changer-types.md](./voice-changer-types.md)（3 軸クロスマトリクス）
   - 「ローカル OSS でリアルタイム声変換を試したい」 → [w-okada-voice-changer.md](./w-okada-voice-changer.md) → 載せるモデルとして [rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md)
   - 「クラウド SaaS でいけるか知りたい」 → [cloud-saas-realtime.md](./cloud-saas-realtime.md)
   - 「配信ソフトに繋ぐ経路を組みたい」 → [virtual-audio-devices.md](./virtual-audio-devices.md) → [obs-studio.md](./obs-studio.md)
4. **[DONE.md](../../DONE.md)** — 各 spec の 1〜2 行サマリで「何が確定し、何が未確認か」を俯瞰
5. **[TODO.md](../../TODO.md)** — 次に何を埋めるべきか

各 spec の冒頭ブロックには、`voice-changer-types` 上の位置付けタグと進捗状態（Phase 完了状況・最終確認日）が必ず書かれているので、深く読み始める前にそこで方角を確認できる。
