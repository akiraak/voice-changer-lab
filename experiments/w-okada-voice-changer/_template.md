# VCClient 実測ログ — `<タイトル: 1 行で何を測ったか>`

> **テンプレ運用メモ**: このファイルは値を一切含まない骨格です。コピーして `YYYY-MM-DD_<model>_<env>.md` にリネームして使ってください。記入ルールは [README.md](./README.md) / [../README.md](../README.md#共通の記入ルール) を参照。値が無い欄は空欄にせず `未計測` または `n/a` と明示し、計測値には必ず計測方法と計測時の負荷状況を併記してください。記入が終わったら、このテンプレ運用メモの引用ブロックは削除して構いません。

## 1. 計測概要

| 項目 | 値 |
| --- | --- |
| 計測日 | `YYYY-MM-DD` |
| 計測者 | `<name>` |
| 計測の目的 | `<モデル比較 / パラメータ調整 / 他環境再現 / etc>` |
| 計測条件サマリ（1 行） | `device mode=<Client / Server>, 主モデル=<...>, sampling rate=<...Hz>` |

- その他自由記入: 

## 2. 環境

### 2.1 ハードウェア

| 項目 | 値 |
| --- | --- |
| GPU 型番 | |
| VRAM | |
| CPU | |
| メモリ | |
| OS（ビルド番号まで） | |

### 2.2 音声機器

| 項目 | 値 |
| --- | --- |
| マイク | |
| ヘッドホン | |
| オーディオインターフェース | |
| 仮想オーディオデバイス（種別・バージョン） | `<VB-CABLE / VoiceMeeter Banana / VoiceMeeter Potato / BlackHole 2ch / BlackHole 16ch / BlackHole 64ch / その他>`（選定軸は [virtual-audio-devices.md §4](../../docs/specs/virtual-audio-devices.md#4-横断棚卸し表)） |

### 2.3 VCClient

| 項目 | 値 |
| --- | --- |
| エディション | `<vcclient_win_std_xxx / vcclient_win_cuda_xxx / vcclient_mac_xxx / onnx>`（[spec §2.4](../../docs/specs/w-okada-voice-changer.md#24-配布形態とエディション)） |
| バージョン | |

### 2.4 補助情報

| 項目 | 値 |
| --- | --- |
| ブラウザ（Chrome バージョン。Client device mode 計測時のみ。[spec §5.1](../../docs/specs/w-okada-voice-changer.md#51-2-系統の-device-mode)） | `<version / n/a>` |
| NVIDIA ドライバ（CUDA エディション利用時のみ） | `<version / n/a>` |
| CUDA Toolkit バージョン（CUDA エディション利用時のみ） | `<version / n/a>` |

- その他自由記入: 

## 3. VCClient 設定（共通 UI）

[spec §4.1](../../docs/specs/w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) / [§5](../../docs/specs/w-okada-voice-changer.md#5-io-構成) と 1:1 対応。

### 3.1 device mode

| 項目 | 値 |
| --- | --- |
| device mode | `<Client / Server>` |
| 選択理由 | |

### 3.2 IO デバイス

[spec §5.2](../../docs/specs/w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537):「input, output, monitor のそれぞれのデバイスはサンプリングレートが一致している必要があります」。

| 項目 | 値 |
| --- | --- |
| input デバイス | |
| output デバイス | |
| monitor デバイス（Server device mode のみ。WASAPI / ASIO の別を併記） | `<device / n/a>` |
| サンプリングレート | `<Hz>`（3 デバイス間で一致しているか確認） |

### 3.3 共通 UI パラメータ

[spec §4.1](../../docs/specs/w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記):

| 項目 | 値 |
| --- | --- |
| CHUNK (Input Chunk Num) | |
| EXTRA (Extra Data Length) | |
| GAIN (in) | |
| GAIN (out) | |
| TUNE | |
| Noise Gate (S.Thresh) | |

### 3.4 ノイズ処理（Client device mode 限定）

[spec §4.1](../../docs/specs/w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) / [§5.1](../../docs/specs/w-okada-voice-changer.md#51-2-系統の-device-mode):

| 項目 | 値 |
| --- | --- |
| Echo | `<on / off / n/a (Server device mode)>` |
| Sup1 | `<on / off / n/a (Server device mode)>` |
| Sup2 | `<on / off / n/a (Server device mode)>` |

- その他自由記入: 

## 4. モデル

[spec §3](../../docs/specs/w-okada-voice-changer.md#3-対応モデル一覧と切替の仕組み) / [§4.2](../../docs/specs/w-okada-voice-changer.md#42-モデル固有のパラメータ) / [§7](../../docs/specs/w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点)。

### 4.1 モデル基本情報

| 項目 | 値 |
| --- | --- |
| モデル種類 | `<RVC v.1 / RVC v.2 / Beatrice v1 / Beatrice v2 / MMVC / so-vits-svc / DDSP-SVC / etc>` |
| モデルファイル名 | |
| モデルバージョン | |
| 配布元（URL） | |
| モデルスロット番号（[spec §3.2](../../docs/specs/w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理)） | |

### 4.2 ライセンス / 利用条件確認

**未確認のモデルでは計測そのものを実施しない**（[../../CLAUDE.md](../../CLAUDE.md) 方針）。

| 項目 | 値 |
| --- | --- |
| 確認日 | `YYYY-MM-DD` |
| 確認したドキュメント名・URL | |
| 営利利用可否 | |
| 配信利用可否 | |
| その他制約（クレジット表記 / 派生作品扱い / etc） | |

### 4.3 モデルパラメータ

| 項目 | 値 |
| --- | --- |
| INDEX 比率（RVC のみ） | `<value / n/a>` |
| F0 抽出方式（RVC のみ） | `<dio / harvest / crepe / crepe full / crepe tiny / rmvpe / n/a>`（[spec §4.2](../../docs/specs/w-okada-voice-changer.md#42-モデル固有のパラメータ)） |

### 4.4 モデル固有パラメータ（自由記入）

Beatrice v2 のオートピッチシフト / 話者マージ / pitch / formant など、テンプレに専用欄を持たないものはここに集約する。各モデルの spec（例: [beatrice.md](../../docs/specs/beatrice.md) / [rvc.md](../../docs/specs/rvc.md) / [so-vits-svc.md](../../docs/specs/so-vits-svc.md)）の該当項目を併記する。

- 

- その他自由記入: 

## 5. 計測結果

**値だけの記入はしない**。各項目に「値 / 計測方法 / 計測時の負荷状況」をセットで併記すること（[../../CLAUDE.md](../../CLAUDE.md) 方針 / [../README.md](../README.md#共通の記入ルール)）。

### 5.1 レイテンシ

| 項目 | 値 |
| --- | --- |
| 値 | |
| 計測方法 | `<ループバック計測 / OBS タイムスタンプ比較 / VCClient のバッファ可視化（v.2.1.3-alpha〜、[spec §4.3](../../docs/specs/w-okada-voice-changer.md#43-ui-全体モニタリング系)） / etc>` |
| 計測時の負荷状況 | `<他に動かしていたアプリ / GPU 占有状況 / etc>` |
| バッファ可視化スクショの保管パス（任意） | |

- 補足: 

### 5.2 GPU 使用率

| 項目 | 値 |
| --- | --- |
| 値 | |
| 計測方法 | `<nvidia-smi / タスクマネージャ / Activity Monitor / etc>` |
| 計測時の負荷状況 | |

### 5.3 VRAM 使用量

| 項目 | 値 |
| --- | --- |
| 値 | |
| 計測方法 | `<nvidia-smi / タスクマネージャ / etc>` |
| 計測時の負荷状況 | |

### 5.4 CPU 負荷

| 項目 | 値 |
| --- | --- |
| 値 | |
| 計測方法 | `<タスクマネージャ / top / Activity Monitor / etc>` |
| 計測時の負荷状況 | |

### 5.5 音質メモ

| 項目 | 値 |
| --- | --- |
| 主観評価 | `<観察事実と推論を分けて書く。推論には「推測」「未確認」を明示>` |
| サンプル WAV 保管パス | |
| 計測時の負荷状況 | |

- その他自由記入: 

## 6. 配信ソフト連携（任意）

[spec §6](../../docs/specs/w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及)。配信ソフトと組み合わせていない計測では本セクション全体を `n/a` として構わない。

OBS Studio 側のレシピ（音声入力キャプチャ / グローバル SR / Audio Monitoring Device / 各ソースの Monitor Off/Only/Output / Sync Offset）は [obs-studio.md §5 P1〜P4 × OBS レシピ](../../docs/specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) のパターンに紐付ける（最終確認日 2026-05-12 / OBS Studio 32.1.2）。本セクションには**実機で実際に設定した値**を記入し、パターン番号と差分があれば「7.1 公式ドキュメントとのズレ」に書く。

| 項目 | 値 |
| --- | --- |
| 経路パターン | `<P1: シングル仮想ケーブル / P2: VoiceMeeter ハブ / P3: monitor 分離 / P4: BlackHole + Multi-Output / その他>`（[virtual-audio-devices.md §5](../../docs/specs/virtual-audio-devices.md#5-配信用途での典型構成) / [obs-studio.md §5](../../docs/specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ)） |
| VCClient output → 仮想オーディオデバイス → 配信先の経路 | |
| 配信ソフト側の音声入力キャプチャ設定（OBS の音声入力キャプチャ ソースのデバイス名 / Settings → Audio の Sample Rate と Channels） | OBS パターン別の標準値は [obs-studio.md §5.0 設定レシピ表](../../docs/specs/obs-studio.md#50-p1p4--obs-設定レシピ表) を参照し、本欄には実機で設定した値を記入 |
| monitor デバイスの繋ぎ先（OBS Audio Monitoring Device に何を選んだか / 各ソースの Monitor Off-Only-Output のどれにしたか） | 判断軸は [obs-studio.md §4.2.2 モニタリング設定をどれにするか](../../docs/specs/obs-studio.md#422-モニタリング設定をどれにするか3-3-モード) を参照 |
| Sync Offset (ms)（ソース別） | [obs-studio.md §6.1](../../docs/specs/obs-studio.md#61-sync-offsetオーディオ同期オフセットの適用ポリシー) のポリシーに従い、ソース名と値を記入 |

- その他自由記入: 

## 7. 所見 / 既知の問題

### 7.1 公式ドキュメントとのズレ

[w-okada-voice-changer.md](../../docs/specs/w-okada-voice-changer.md) の記述と実機挙動で食い違った点。

- 

### 7.2 再現条件

この計測結果を再現したいときに必要な手順 / 設定。

- 

### 7.3 遭遇したトラブルと回避策

- 

- その他自由記入: 
