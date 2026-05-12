# w-okada/voice-changer (VCClient)

> [voice-changer-types](./voice-changer-types.md) 上の位置付け: **技術アプローチ: 1.4 ハイブリッド / 提供形態: 2.1 ローカル OSS / モデル形態: ロードするモデル依存**（RVC を載せれば §3.1 話者依存、MMVC を載せれば §3.2 多話者、など）
>
> 本ページは [docs/plans/w-okada-voice-changer.md](../plans/w-okada-voice-changer.md) のスコープに沿って、**公式リポジトリ（[w-okada/voice-changer](https://github.com/w-okada/voice-changer)）で述べられている内容**を中心にまとめる。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。
> 各項目について「公式に書かれている内容」「未確認」「未計測（実測タスク待ち）」を明示する。
>
> **進捗:** Phase 1〜3 完了。

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
- RVC チュートリアル `tutorials/tutorial_rvc_ja_latest.md` には「ブラウザ（Chrome のみサポート）でアクセスすると画面が表示」と明記されており、UI フロントエンドが **Chrome 限定** であることは公式に確認できる。一方で、Electron でラップされているのか、ユーザが手元の Chrome でローカル URL を開く構成なのかは README / チュートリアルからは判別できず**未確認**。
- UI / サーバ間の具体的プロトコル（WebSocket か HTTP か、Socket.IO の使用有無など）は依然**未確認**。
- `client/` のフロントエンドスタック（React 等）は依然**未確認**。

→ 詳細はリポジトリ内コードを直接読まないと確定しない領域。本ラボでは現時点では深追いせず、必要になった時点（実測タスク等）で再確認する。

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
| Beatrice v2 | ✅ | — | §1.3 ニューラル変換（コンテンツ表現 + 話者条件付け系）/ §3.1 話者依存。[beatrice.md](./beatrice.md) で確定 |
| Beatrice v1 | — | ✅ (Windows のみ) | 同上（v1 / v2 のモデル形式は非互換。[beatrice.md §1.4](./beatrice.md#14-beatrice-1と-beatrice-2というバージョンの呼び方) 参照） |
| MMVC | — | ✅ | §1.3 コンテンツ表現+話者条件付け系 / §3.2 多話者 |
| so-vits-svc | — | ✅ | §1.3 コンテンツ表現+話者条件付け系 / §3.1 話者依存 |
| DDSP-SVC | — | ✅ | §1.4 ハイブリッド（DSP × ニューラル）/ §3.1 話者依存 |

- **v.2 系は新しいモデル（RVC, Beatrice v2）に絞られている**。MMVC / so-vits-svc / DDSP-SVC を使いたい場合は v.1 系を使う形になる。
- Beatrice v1 は Windows のみと README に明記されている。
- README 上の表は「サポート」「n/a」のような表記で、内部実装の共通化レベルや「同じ UI から切り替えるのか別アプリなのか」は明記されていない（**未確認**）。Phase 2 でモデル切替の UI フロー / モデルファイルの配置などを掘る。

### 3.2 ホストとモデルの責任分界（暫定整理）

公式の明示記述ベースで断定できるのは以下まで:

- 各モデルの**推論コードは VCClient 側のサーバプロセスに同梱されている**（モデル別の起動コマンドを使い分ける UI ではなく、共通の UI から選ぶ形態であることは README の「複数モデル対応」表記から読める）。
- RVC チュートリアル `tutorials/tutorial_rvc_ja_latest.md` で、共通の **モデル選択エリア**（「モデルスロット」）の存在が確認できる。「モデル選択エリアから使いたいモデルをクリック」「編集ボタンを押すと、モデル一覧（モデルスロット）を編集することができます」と明記されており、複数モデルを同じ UI から差し替える設計であることは確定。
- ただし、モデルの重みファイルそのものはユーザが配布元から入手する必要があり、それぞれのモデルのライセンス確認が必要（§7 参照）。チュートリアルにはモデルスロット編集画面でのアップロード機能と「ファイル名をクリックすることでダウンロードすることができます」との記述がある。ファイルシステム上のモデル配置パス規約は**未確認**。
- 共通でホスト側が面倒を見ている範囲（device mode による I/O、モニター出力、ノイズゲートや GAIN 等の共通パラメータ）と、モデル固有で挙動が変わる範囲（F0 抽出方式選択は RVC で確認、Beatrice 固有のオートピッチシフトなど）は §4 で個別に整理する。MMVC / so-vits-svc / DDSP-SVC 側で UI が同様かは**未確認**。

## 4. 前処理・後処理として提供されているもの

公式チュートリアル（最新の RVC 用 `tutorials/tutorial_rvc_ja_latest.md`）と、README の "What's New!" バージョン履歴から確認できる範囲。RVC を例に説明されているため、ホスト共通とモデル固有の切り分けは別途記載する。

### 4.1 共通 UI 上のパラメータ（RVC チュートリアルでの表記）

- **ノイズ処理（Client device mode 限定）**: 「Echo: エコーキャンセル機能、Sup1, Sup2: ノイズ抑制機能」と明記。ブラウザ（Chrome）側の機能を経由するため、Server device mode では使えない（§5 参照）。
- **ノイズゲート**: 「S. Thresh (Noise Gate)」で音声変換の閾値を設定。
- **音量**: 「GAIN」の `in`（モデルへの入力音声の音量）と `out`（変換後の音声の音量）を個別に調整。
- **ピッチ**: 「TUNE で声のピッチをどれくらい変換するかの値」を指定。
- **チャンク**: 「CHUNK (Input Chunk Num)」で「一度の変換でどれくらいの長さを切り取って変換するか」を指定。
- **過去音声の混入量**: 「EXTRA (Extra Data Length)」で「入力にどれくらいの長さの過去の音声を入れるか」を指定。

### 4.2 モデル固有のパラメータ

- **F0 抽出方式（RVC）**: 「F0 Det (F0 Extractor)」で `dio / harvest / crepe / crepe full / crepe tiny / rmvpe` から選択可能（RVC チュートリアル）。
- **INDEX（RVC のみ）**: 「元の特徴量にすべて寄せ」る比率の設定。
- **Beatrice 系**（モデル側の構造・パラメータは [beatrice.md](./beatrice.md) で別途整理）:
  - v.2.0.76-beta の "What's New!" に **「Beatrice: オートピッチシフト」「話者マージの実装」** との記載あり。
  - v.2.0.73-beta では「beatrice v2 の pitch, formant が反映されないバグを修正」とあり、Beatrice 系で pitch / formant が UI から操作される設計であることが読み取れる。

→ MMVC / so-vits-svc / DDSP-SVC を選んだ場合に UI が同じ顔をしているか（同じ GAIN / TUNE / CHUNK / EXTRA を露出するか、固有パラメータがどう増えるか）は、本 Phase で確認できる範囲には含まれていない（**未確認**。後続の個別モデル調査で扱う）。

### 4.3 UI 全体・モニタリング系

README の "What's New!" から拾える、入出力ストリームの観察やレイテンシ調整に効く機能追加:

- **v.2.1.3-alpha**: 「ショートカットキー」「バッファの可視化」を実装。
- **v.2.0.78-beta**: 「選択できる chunk size を増やしました」（§4.1 の CHUNK の選択肢拡張）。

### 4.4 未確認 / 注意点

- 各パラメータが RVC 以外のモデルでも同じ UI 名で露出するかは**未確認**。
- サンプリングレート関連の前処理（入力リサンプリング、出力リサンプリングなど）が UI から触れるかは**未確認**。サンプリングレートの制約は §5.2 で 1 件のみ確認できている。
- 「クロスフェード」「リミッタ」など他ツールで一般的な後処理項目について、本 Phase で確認した公式ドキュメント内には直接の言及は見つからなかった（実装としては存在し得る／**未確認**）。

## 5. IO 構成

### 5.1 2 系統の device mode

`tutorials/tutorial_device_mode_ja.md` の記述を整理する（§2.2 と一部重複するが、IO 視点でまとめ直す）。

- **Client device mode（v.1.5.2.9 より前の従来形態）**
  > 「ブラウザが制御するマイクとスピーカを用いてボイチェンを行っていました」
  - ブラウザ（Chrome）の getUserMedia / Web Audio 経由で入出力を扱う。
  - Chrome 側のノイズ除去・エコーキャンセル等が利用できる（= §4.1 の Echo / Sup1 / Sup2 が有効）。
  - 公式は「遅延が増加する傾向」と説明。
- **Server device mode（v.1.5.2.9〜）**
  > 「PC に接続されたマイクとスピーカーを直接 VC Client から制御」
  - VC Client サーバプロセスが OS のオーディオデバイスを直接扱う。
  - 公式は「遅延が少ない」と説明（**数値の記載はなし／本ラボでも未計測**）。
  - 「対応していないデバイスが存在する可能性」「Chrome の便利機能（ノイズ除去など）が利用不可」と公式注記。
- ユーザは「それぞれのメリット・デメリットを考慮して使い分けることができます」と書かれている。配信用途では Chrome のノイズ除去より遅延を優先するケースが多く、本ラボでは server device mode を主に検討する想定。

### 5.2 input / output / monitor の 3 デバイス構成（Server device mode、v.1.5.3.7〜）

`tutorials/tutorial_monitor_consept_ja.md` より:

- 従来は「出力先デバイスが一つしか設定できず」、Discord / Zoom と連携する際は Voicemeeter 等の仮想オーディオデバイスを経由する必要があり、**「多くのオーバーヘッドがかかっていました」** と公式に評されている。
- v.1.5.3.7 で **「もう一つ出力先デバイスを設定できるようになり」**、3 系統（input / output / monitor）を独立に指定できるようになった。
- **monitor デバイスは Voicemeeter を経由せず直接 WASAPI / ASIO デバイスに出力できる** と明記。これにより「遅延が少ないモニタリングが可能」になる。
- 制約: 「**input, output, monitor のそれぞれのデバイスはサンプリングレートが一致している必要があります**」。
- 公式 Tips: 「Input, Monitor を Wasapi デバイス、output を任意にすることで遅延をかなり少なく運用することができました」（実測値の数値は記載なし）。

### 5.3 デバイス設定 UI 側の見え方

RVC チュートリアル `tutorials/tutorial_rvc_ja_latest.md` の記述:

- 「input: マイク入力など音声入力デバイス」を選択
- 「output: スピーカー出力など音声出力デバイス」を選択
- 「monitor」は server device モード時のみ選択可能

→ 同一の UI から 3 デバイスを切り替える形態で、モデル（モデルスロット）を切り替えても基本的な IO 設定 UI は共通であることが読み取れる。

### 5.4 サンプリングレート / 未確認事項

- 3 デバイス間でサンプリングレートを一致させる制約は確認済み（§5.2）。デバイス側に許される値の範囲や、モデルが期待するサンプリングレートと UI 側設定の関係は**未確認**。
- ブラウザサポートは Chrome のみ（§2.3 参照）。Electron でラップされた Chrome なのか手元の Chrome を開く構成かは**未確認**。

## 6. 配信ソフト（OBS 等）との接続パターンの公式言及

### 6.1 公式チュートリアルでの言及範囲

`tutorials/tutorial_monitor_consept_ja.md` で名指しされているのは主に **Discord / Zoom**（音声通話ソフト）であって、配信ソフトそのものではない。公式が示しているパターンは:

- **従来の単一出力構成**: VC Client の output → Voicemeeter（仮想オーディオデバイス）→ Discord / Zoom 等のアプリ
  - 公式は「多くのオーバーヘッドがかかっていました」と評する。
- **v.1.5.3.7 以降の 3 デバイス構成**: monitor は WASAPI / ASIO へ直接（自分用の低遅延モニタ）、output は別途仮想オーディオデバイス等を経由してアプリへ流す、と役割を分離。

### 6.2 OBS / 配信ソフトの直接言及

本 Phase で確認した範囲では、`tutorials/` 配下に **OBS Studio との接続パターンを名指しで説明する公式チュートリアルは見つかっていない**（**未確認**。配信ソフト連携は公式チュートリアル化されていない領域として扱う）。

### 6.3 本ラボでの一般論整理（公式言及ではない）

公式言及ではないが、本ラボとして配信用途で踏むであろう構成を一般論として整理しておく（後続の OBS 接続調査タスクで上書き予定）:

- VC Client の output を仮想オーディオデバイス（VB-CABLE / VoiceMeeter Banana・Potato / BlackHole 等）に流し、OBS の「音声入力キャプチャ」ソースでそのデバイスを拾う、というのがリアルタイム VC を OBS に流す一般的な形。**仮想オーディオデバイス側の選定軸 / OS 別の候補 / 経路パターンは [virtual-audio-devices.md](./virtual-audio-devices.md)（§4 横断棚卸し表 / §5 配信用途の典型構成 P1〜P4）に集約**しているので、ホスト側からはそこを参照する立て付け。
- monitor は §5.2 の通り ASIO / WASAPI に直接出して配信者自身のヘッドホンで低遅延モニタする、という分担と整合する（同じ発想を経路図化したのが [virtual-audio-devices.md §5.3 P3: monitor 分離経路](./virtual-audio-devices.md#53-p3-monitor-分離経路windows低遅延モニタリング-tip)）。

→ ここの整合性確認・実機検証は、後続の **「OBS Studio との接続パターンまとめ」タスク**（`TODO.md` の「配信周辺ツール調査」セクション）と紐付ける。

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
- **Beatrice JVS Corpus Edition**: 別ライセンス。voice-changer リポジトリ内の README（`server/voice_changer/Beatrice/README.md`、Beatrice 1 系の API 1.1.0）を参照するよう案内されている。v1 系特有の **「営利目的禁止」+ JVS Corpus 規約準拠** の整理は [beatrice.md §5.4](./beatrice.md#54-beatrice-jvs-corpus-editionv1-系w-okadavoice-changer-経由) に集約。
- ※ LICENSE-NOTICE の本文を Phase 1 で 1 次ソース全文確認まではしていない（要約レベルで把握）。Phase 2 で全文確認して反映する。

### 7.3 本ラボで扱う際の注意点（実運用観点）

- **コードの MIT** と、**ロードして使うモデルの利用条件** は別物として扱う。
  - 例: RVC モデル（コミュニティで配布されているチェックポイント）の利用条件、Beatrice 同梱の JVS コーパス由来モデルの利用条件、つくよみちゃん / あみたろ / 琴葉茜 等のキャラクター音声を学習素材としたモデルの利用条件は、それぞれ**配布元の規約**で判断する。
  - README にも、特定の音声キャラクター（つくよみちゃん / あみたろ / 琴葉茜 など）に関する開示要件・使用範囲の注意書きの存在が示唆されている（Phase 2 で原文確認・引用予定）。
- 本ラボのコード・ドキュメントから、第三者の声を許諾なく再現する用途には誘導しない（[CLAUDE.md](../../CLAUDE.md) 方針）。
- 配布バイナリ（vcclient_*_xxx.zip）に含まれる依存ライブラリ / モデルがあれば、その個別ライセンス（PyTorch / ONNX Runtime / NVIDIA CUDA Runtime 等）の同梱条件も配布元（Hugging Face リポジトリ）側で要確認。

## 8. voice-changer-types §4 評価軸への暫定マッピング

[voice-changer-types §4](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) の評価軸に、本ホスト（VCClient）単体としての位置付けを置く。**音質**等の「ロードするモデル次第」で決まる項目はホスト単独で値を出せないため、ホストとモデルの責任分界をそのまま反映する。実測値は本ドキュメントには書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。

| 評価軸 | ホストとしての暫定マッピング | 出どころ / 補足 |
| --- | --- | --- |
| レイテンシ | 公式は **server device mode が「遅延が少ない」**、また **monitor デバイス分離で「遅延が少ないモニタリングが可能」** と明記。Tips として「Input, Monitor を WASAPI、output を任意」を低遅延運用例として推奨。**数値は公式記載なし／本ラボでも未計測** | §2.2 / §5.1 / §5.2 |
| 音質 | ホストは変換アルゴリズムを内蔵せず、ロードする個別モデル（RVC / Beatrice / MMVC / so-vits-svc / DDSP-SVC）に依存。ホスト側で関与するのは前処理（Echo / Sup1 / Sup2 / Noise Gate / GAIN）と TUNE / CHUNK / EXTRA / F0 抽出方式の調整まで。**モデル横断の音質評価はホスト単体ではできない** | §3 / §4 |
| 必要 GPU 性能 | 配布物に **`vcclient_win_cuda_xxx.zip`**（NVIDIA GPU 向け）エディションがあり、CUDA 前提の構成が想定されている。`std` / `mac`（Apple Silicon）/ `onnx` のエディションも存在し、GPU 必須かどうかはエディションとロードモデル依存。**必要 VRAM はモデル依存で未計測** | §2.4 |
| CPU 負荷 | 公式に明示的な記述なし。**未計測** | — |
| 入出力構成 | **Client device mode（ブラウザ getUserMedia 経由）**と **Server device mode（OS デバイス直接）**の 2 系統。Server device mode では **input / output / monitor の 3 デバイス分離**（v.1.5.3.7〜）と **WASAPI / ASIO への monitor 直接出力**が可能。サンプリングレートは 3 デバイス間で一致が必要 | §5.1 / §5.2 / §5.3 |
| モデル形態 | ホストは voice-changer-types §3 のどの形態にもなり得る（ロードするモデルに依存）。v.2 系は **RVC / Beatrice v2**（共に §3.1 話者依存寄り）、v.1 系は加えて **MMVC（§3.2 多話者）/ so-vits-svc / DDSP-SVC（§3.1）** | §3.1 |
| カスタマイズ性 | **モデルスロット UI** から複数モデルを差し替え（アップロード / ダウンロード）可能。前処理パラメータ（GAIN / TUNE / CHUNK / EXTRA / Noise Gate）と F0 抽出方式（RVC は dio / harvest / crepe 系 / rmvpe）を UI から調整可。`trainer/` / `recorder/` ディレクトリが存在し自前学習系の機能が同梱されている点までは確認済み（**学習ワークフロー詳細は未確認**） | §3.2 / §4.1 / §4.2 / §2.1 |
| 配信での利用可否 | **コード本体は MIT**。ただしロードする個別モデル（RVC 系チェックポイント等）、同梱の DiffSinger Community Vocoders、Beatrice JVS Corpus Edition、README で言及されている音声キャラクター（つくよみちゃん / あみたろ / 琴葉茜 等）の利用条件は**それぞれ配布元規約で個別判断**が必要。**ホスト単体としては配信用途で利用可能だが、モデル毎の規約確認が前提** | §7.1 / §7.2 / §7.3 |
| エコシステム | 公式チュートリアル `tutorial_monitor_consept_ja.md` で **Voicemeeter 等の仮想オーディオデバイス**を介した Discord / Zoom 連携が明示的に語られている。一方で **OBS Studio を名指しで説明した公式チュートリアルは Phase 1〜2 で確認した範囲では未発見**（§6.3 の一般論で代用、§9 で TODO 引き継ぎ） | §6.1 / §6.2 |
| コスト | OSS。Hugging Face で配布されるバイナリは無償。**実質コストは GPU マシンの用意とロードするモデル配布元の有償素材有無に集約される** | §2.4 / §7 |

ホスト単体で評価できるのは **レイテンシの設計上の優位（server device mode + monitor 分離）**、**IO 構成の柔軟性（3 デバイス独立）**、**カスタマイズ性（モデルスロット差し替え）**、**ホストのライセンス（MIT）** の 4 つで、残りの評価軸（音質 / 必要 GPU / 配信利用可否のうちモデル由来部分）は本ラボでロードする個別モデルの調査結果を統合して初めて値が出る、というのが本 Phase の結論。

## 9. 未確認事項 / 後続タスク

### 9.1 既存タスクに引き継ぐ未確認事項

`TODO.md` の既存タスクで吸収できるものは、本ドキュメントで結論を出さずに引き継ぐ。

- **MMVC / so-vits-svc / DDSP-SVC / RVC / Beatrice それぞれの UI 露出パラメータ**（§4.1 の GAIN / TUNE / CHUNK / EXTRA / Noise Gate、§4.2 の F0 抽出方式やモデル固有パラメータがモデル横断で同じ顔をしているか） → `TODO.md` の **RVC / so-vits-svc / Beatrice の個別調査**で確認
- **モデルファイルのファイルシステム上の配置規約**（モデルスロット UI 経由以外の手動配置パス） → 個別モデル調査時に必要になった時点で確認
- **OBS Studio との具体的な接続パターン**（VC Client の output → 仮想オーディオデバイス → OBS の音声入力キャプチャ） → `TODO.md` の **「OBS Studio との接続パターンまとめ」**で実機検証
- **仮想オーディオデバイス選定の比較軸**（VB-CABLE / VoiceMeeter Banana・Potato / BlackHole） → [virtual-audio-devices.md](./virtual-audio-devices.md) で棚卸し済み（§4 横断棚卸し表 / §5 配信用途の典型構成 P1〜P4、最終確認日 2026-05-12）

### 9.2 本タスクの follow-up として新規起票するもの

本 Phase の調査範囲では結論が出ず、独立タスクとして切り出すべきもの。`TODO.md` に追加する。

- **w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認とキャラクター音声利用条件の整理** — Phase 1 で要約レベルまで確認したが、LICENSE-NOTICE の全文と README 内の音声キャラクター（つくよみちゃん / あみたろ / 琴葉茜 等）の利用条件の原文引用は未実施。本ラボでキャラクター音声を扱うモデルに踏み込む前段として独立タスク化する。
- **w-okada/voice-changer の実測タスク用 `experiments/` テンプレート整備** — レイテンシ / GPU 使用量の実測は個別モデルと組み合わせて初めて値が出るが、計測条件（device mode / monitor 分離有無 / サンプリングレート / CHUNK / EXTRA / F0 抽出方式 等）の記録テンプレを先に用意しておくと、後続モデルの実測タスク時に揃った形でログが残る。→ [`experiments/w-okada-voice-changer/`](../../experiments/w-okada-voice-changer/README.md) に整備済み（テンプレ本体: [`_template.md`](../../experiments/w-okada-voice-changer/_template.md)）。本ドキュメント §3 / §4 / §5 / §6 / §7 と 1:1 対応する記録項目を含む（対応表は [README](../../experiments/w-okada-voice-changer/README.md#記録項目の出典) 参照）。

### 9.3 当面は深追いしない領域

本ラボのスコープでは現時点で踏み込む必要がなく、必要になった時点で再開するもの。

- **GUI / 通信スタックの具体実装**（Electron か手元 Chrome か / WebSocket・Socket.IO 使用有無 / フロントエンドフレームワーク） — 配信パスのトラブルシュートで通信プロトコルを見ないと進まない局面が出てきた時点で `client/` / `server/` のコードを直接読む
- **`trainer/` / `recorder/` のワークフロー詳細** — 自前学習を検証する段になってから着手
