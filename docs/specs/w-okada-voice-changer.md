# w-okada/voice-changer (VCClient)

> [voice-changer-types](./voice-changer-types.md) 上の位置付け: **技術アプローチ: 1.4 ハイブリッド / 提供形態: 2.1 ローカル OSS / モデル形態: ロードするモデル依存**（RVC を載せれば §3.1 話者依存、MMVC を載せれば §3.2 多話者、など）
>
> 本ページは [docs/plans/w-okada-voice-changer.md](../plans/w-okada-voice-changer.md) のスコープに沿って、**公式リポジトリ（[w-okada/voice-changer](https://github.com/w-okada/voice-changer)）で述べられている内容**を中心にまとめる。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。
> 各項目について「公式に書かれている内容」「未確認」「未計測（実測タスク待ち）」を明示する。
>
> **進捗:** Phase 1 完了（§1〜3, §7）。§4〜6 は Phase 2、§8〜9 は Phase 3 で埋める。

## 1. 概要

- 公式 README (README.md 冒頭) より:
  > 「VCClient は、AI を用いてリアルタイム音声変換を行うソフトウェアです。」
- リポジトリ名は `voice-changer` だが、現行プロダクト名は **VCClient (VC Client)** として README 全体で統一されている。
- 「リアルタイム声変換のための実行ホスト」という呼び方は voice-changer-types 側で本ラボが付けた整理であり、公式は「リアルタイム音声変換ソフトウェア」と表現している。
- 公式 README に v.1 系と v.2 系のリリースが併記されており、対応モデルが両者で異なる（詳細は §3）。

### 立ち位置（本ラボの整理）

- 単一の声質変換アルゴリズム実装ではなく、**複数の VC モデル（RVC / Beatrice / MMVC / so-vits-svc / DDSP-SVC 等）を切り替えてホストする実行環境**として扱う。
- そのため、配信用途で「w-okada/voice-changer を使う」と言ったとき、評価軸の多く（音質・モデル形態・ライセンス）は**ロードする個別モデル側に依存する**ことになる。ホスト側の独立評価項目は IO 構成 / 配信ソフト連携 / 配布形態 / 共通の前処理-後処理 に絞られる。

## 2. アーキテクチャ概観

### 2.1 公式に書かれている範囲

- README:
  > 「スタンドアロン、ネットワーク経由の両構成をサポート」
  > 「REST API を提供」
- 1 台の PC で完結して動かす構成と、声変換処理を別 PC（高 GPU 機）にオフロードする構成の両方が公式に想定されている。
- リポジトリのトップ構成（GitHub の Tree 表示）:
  - `server/` — 声変換処理側（Python サーバ。詳細は未確認）
  - `client/` — UI 側
  - `tutorials/` — 機能別の使い方ドキュメント
  - `docs/` `docs_i18n/` — ドキュメント
  - `docker/` `docker_folder/` `docker_trainer/` `docker_vcclient/` — Docker 関連
  - `recorder/` `trainer/` — 学習/録音関連
  - `signatures/version1/` — リリース署名関連

### 2.2 入力 / 出力の制御モード（device mode）

`tutorials/tutorial_device_mode_ja.md` に明記:

- **Client device mode（旧来。v.1.5.2.9 より前）**
  > 「ブラウザが制御するマイクとスピーカを用いてボイチェンを行っていました」
  - UI を表示するブラウザの getUserMedia / Web Audio 経由で入出力を扱う形態
- **Server device mode（v.1.5.2.9〜）**
  > 「PC に接続されたマイクとスピーカーを直接 VC Client から制御」
  - サーバ側プロセスが OS のオーディオデバイスを直接扱う形態
- 公式は server device mode 側のほうが「遅延が少ない」と述べている（実測値の数値は記載なし）。

→ つまり**ホストの I/O 経路には 2 系統あり、配信時にどちらを使うかで仮想オーディオデバイスとの繋ぎ方が変わる**。配信用途を見る本ラボでは、§5 IO 構成 (Phase 2) で server device mode 側を中心に整理する想定。

### 2.3 GUI / 通信スタック

- README には GUI が Electron か通常ブラウザかは明示されていない。ローカルで HTTP サーバを立てる挙動と REST API 提供の言及までは確認済み。
- UI / サーバ間の具体的プロトコル（WebSocket か HTTP か、Socket.IO の使用有無など）は未確認。
- `client/` のフロントエンドスタック（React 等）は未確認。

→ Phase 2 でリポジトリ内コード or 公式ドキュメントを再確認する。

### 2.4 配布形態とエディション

- Hugging Face のリポジトリ `huggingface.co/wok000/vcclient000` で配布。
- 確認できているリリース名パターン:
  - `vcclient_win_std_xxx.zip` （Windows・標準）
  - `vcclient_win_cuda_xxx.zip` （Windows・NVIDIA GPU 向け）
  - `vcclient_mac_xxx.zip` （Mac / Apple Silicon）
- README には他に `onnx` というエディションへの言及もある（用途は README 明示なし。ONNX Runtime 経由の実行用と推測されるが**未確認**）。
- Linux は「リポジトリをクローンしてセットアップ」、Google Colab 用の Notebook も同梱（リポジトリ直下の `.ipynb` ファイル群）。
- v.2 の最新版は README の "What's New!" セクションで `-beta` 付きで案内されている。

## 3. 対応モデル一覧と切替の仕組み

### 3.1 v.2 と v.1 のサポートモデル差分（README 表より）

README に「v.2.2.2-beta よりエディション毎のサポートモデルが変わります」と明記されている。

| モデル | v.2 | v.1 (legacy) | voice-changer-types での位置 |
| --- | --- | --- | --- |
| RVC (v.2 / v.1) | ✅ | ✅ | §1.3 Retrieval ベース系 / §3.1 話者依存 |
| Beatrice v2 | ✅ | — | §1.3 ニューラル変換（系統は要裏取り） |
| Beatrice v1 | — | ✅ (Windows のみ) | 同上 |
| MMVC | — | ✅ | §1.3 コンテンツ表現+話者条件付け系 / §3.2 多話者 |
| so-vits-svc | — | ✅ | §1.3 コンテンツ表現+話者条件付け系 / §3.1 話者依存 |
| DDSP-SVC | — | ✅ | §1.4 ハイブリッド（DSP × ニューラル）/ §3.1 話者依存 |

- **v.2 系は新しいモデル（RVC, Beatrice v2）に絞られている**。MMVC / so-vits-svc / DDSP-SVC を使いたい場合は v.1 系を使う形になる。
- Beatrice v1 は Windows のみと README に明記されている。
- README 上の表は「サポート」「n/a」のような表記で、内部実装の共通化レベルや「同じ UI から切り替えるのか別アプリなのか」は明記されていない（**未確認**）。Phase 2 でモデル切替の UI フロー / モデルファイルの配置などを掘る。

### 3.2 ホストとモデルの責任分界（暫定整理）

公式の明示記述ベースで断定できるのは以下まで:

- 各モデルの**推論コードは VCClient 側のサーバプロセスに同梱されている**（モデル別の起動コマンドを使い分ける UI ではなく、共通の UI から選ぶ形態であることは README の「複数モデル対応」表記から読める）。
- ただし、モデルの重みファイルそのものはユーザが配布元から入手する必要があり、それぞれのモデルのライセンス確認が必要（§7 参照）。
- 共通でホスト側が面倒を見ていそうな範囲（device mode による I/O、モニター出力、配布物としてのパッケージング）と、モデル固有で挙動が変わる範囲（F0 抽出、話者埋め込み、サンプリングレートなど）は、現時点では README から完全には切り分けられていない。Phase 2 で `tutorials/` の RVC チュートリアル等を読みつつ整理する。

## 4. 前処理・後処理として提供されているもの

**TBD (Phase 2)** — README の "What's New!" にはバージョン履歴として
「バッファの可視化」「Beatrice: オートピッチシフト」「チャンクサイズ選択可能」
といった機能追加の言及があるが、Phase 1 では網羅的に拾えていない。
`tutorials/` 配下の RVC チュートリアル等で UI パラメータを確認する。

## 5. IO 構成

**TBD (Phase 2)** — §2.2 で device mode の 2 系統まで確認済み。
`tutorials/tutorial_monitor_consept_ja.md` には input / output / monitor の 3 デバイス構成と、モニタを WASAPI / ASIO に直接出力できる機能（v.1.5.3.7〜）の記述がある。Phase 2 でこれらを反映する。

## 6. 配信ソフト（OBS 等）との接続パターンの公式言及

**TBD (Phase 2)** — `tutorial_monitor_consept_ja.md` で Voicemeeter を経由しないモニタ出力の言及があることまでは確認済み。OBS への接続パターンの直接的な記述があるかは Phase 2 で再確認する。

## 7. ライセンス / 配布物の利用条件と本ラボで扱う際の注意点

### 7.1 リポジトリ本体

- リポジトリ直下の `LICENSE` は **MIT License**。複数の著作権者の連名で構成されており、確認できた範囲では:
  - Wataru Okada (2022)
  - Isle Tennos (2022)
  - Jaehyeon Kim (2021)
  - liujing04 / 源文雨 (2023)
  - yxlllc (2023)
  - （他にもブロックが続く可能性あり、全著作権者の網羅は Phase 2 で要再確認）
- `LICENSE-CLA` は **Contributor License Agreement**。本リポジトリへコントリビュートする際の条件（オリジナル性の保証・無償提供・派生物への許諾など）が定義されている。本ラボがコードを上流に投げる動きはないので、運用上の影響は当面なし。

### 7.2 LICENSE-NOTICE（同梱・参照される第三者素材）

- **DiffSinger Community Vocoders**: Diffusion SVC / DDSP SVC で利用。利用者は元プロジェクト側のライセンス確認が必要、と案内されている。代替モデルを `pretrain\nsf_hifigan` に置く運用が可能。
- **Beatrice JVS Corpus Edition**: 別ライセンス。voice-changer リポジトリ内の README を参照するよう案内されている。
- ※ LICENSE-NOTICE の本文を Phase 1 で 1 次ソース全文確認まではしていない（要約レベルで把握）。Phase 2 で全文確認して反映する。

### 7.3 本ラボで扱う際の注意点（実運用観点）

- **コードの MIT** と、**ロードして使うモデルの利用条件** は別物として扱う。
  - 例: RVC モデル（コミュニティで配布されているチェックポイント）の利用条件、Beatrice 同梱の JVS コーパス由来モデルの利用条件、つくよみちゃん / あみたろ / 琴葉茜 等のキャラクター音声を学習素材としたモデルの利用条件は、それぞれ**配布元の規約**で判断する。
  - README にも、特定の音声キャラクター（つくよみちゃん / あみたろ / 琴葉茜 など）に関する開示要件・使用範囲の注意書きの存在が示唆されている（Phase 2 で原文確認・引用予定）。
- 本ラボのコード・ドキュメントから、第三者の声を許諾なく再現する用途には誘導しない（[CLAUDE.md](../../CLAUDE.md) 方針）。
- 配布バイナリ（vcclient_*_xxx.zip）に含まれる依存ライブラリ / モデルがあれば、その個別ライセンス（PyTorch / ONNX Runtime / NVIDIA CUDA Runtime 等）の同梱条件も配布元（Hugging Face リポジトリ）側で要確認。

## 8. voice-changer-types §4 評価軸への暫定マッピング

**TBD (Phase 3)**

## 9. 未確認事項 / 後続タスク

**TBD (Phase 3)** — 現時点で残っている主な未確認は次のとおり（Phase 2/3 の入力材料）:

- GUI / 通信スタックの具体（Electron か / Socket.IO 使用か / フロントエンドフレームワーク） — Phase 2
- 各モデル切替の UI フローとモデルファイルの配置規約 — Phase 2
- 前処理 / 後処理として UI から触れるパラメータの網羅 — Phase 2
- input / output / monitor の 3 デバイス構成の詳細と、配信ソフト連携の公式言及 — Phase 2
- LICENSE / LICENSE-NOTICE の全文確認と、README 内の音声キャラクター利用条件記述の原文引用 — Phase 2
- voice-changer-types §4 評価軸（レイテンシ / GPU / 入出力 / カスタマイズ性 / 配信利用可否 / エコシステム）への暫定マッピング — Phase 3
- 実測タスク（レイテンシ / GPU 使用量）を起こすかどうかの判断と、起こす場合の `experiments/` 用テンプレート — Phase 3
