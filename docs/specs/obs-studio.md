# OBS Studio との接続パターンまとめ

> [voice-changer-types §2 補助カテゴリ「周辺ツール」](./voice-changer-types.md#補助カテゴリ-周辺ツール) のうち **「配信ソフト・通話ソフト」レイヤーの OBS Studio（本家）** を扱い、[virtual-audio-devices.md §5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) の仮想オーディオデバイス層を前提に、**OBS 側の音声入力キャプチャ・モニタリング・遅延ハンドリング**を公式情報源ベースで横断棚卸しする横断補完ページ。
>
> **進捗:** Phase 1〜3 完了（最終確認日 2026-05-12 / OBS Studio 32.1.2）。Phase 2 までで §1 範囲定義・§3 各音声系機能エントリを公式情報源ベースで記入。Phase 3 で §4 機能 × 評価項目マトリクス + 配信用途の足切り早見表 / §5 [virtual-audio-devices.md §5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) と 1:1 対応する OBS レシピ表 + 各パターンの経路図 / §6 遅延ハンドリング（Sync Offset / OS API バッファ整合 / 内部バッファリング / 公称値 vs 実測の分離ポリシー）/ §7 上流ドキュメントへの反映 / §8 後続タスク起票を実施し、§7 に沿って [voice-changer-types §2・§4](./voice-changer-types.md) / [w-okada-voice-changer §6.3・§9.1](./w-okada-voice-changer.md) / [experiments/w-okada-voice-changer/_template.md §6](../../experiments/w-okada-voice-changer/_template.md) / [virtual-audio-devices.md §5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) を更新済み（プラン: [docs/plans/archive/obs-studio-connection.md](../plans/archive/obs-studio-connection.md)）。

## 1. 概要

### 1.1 本書の位置付け

配信周辺ツール調査シリーズの第 2 弾。前段の [virtual-audio-devices.md](./virtual-audio-devices.md)（最終確認日 2026-05-12）で `マイク → 声変換ホスト → 仮想オーディオデバイス → 配信ソフト` の経路のうち **仮想オーディオデバイス側**を `VB-CABLE / VoiceMeeter Banana・Potato / BlackHole` のコア集合で棚卸しし、[§4 横断棚卸し表](./virtual-audio-devices.md#4-横断棚卸し表) / [§5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) として配信用途の典型構成を経路図化済み。一方で [§6.5 反映の境界](./virtual-audio-devices.md#65-反映の境界本書で扱わない上流) で明示している通り、**OBS Studio の音声入力キャプチャ設定値・モニタリング設計・配信出力のサンプリングレート整合・遅延ハンドリング**は前段書のスコープ外として残されており、本書がそれを埋める。

本書が空白のままだと、

- [voice-changer-types §4 配信用途で見るべき主な評価軸](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) の「入出力構成」「エコシステム」軸が、**配信ソフト側に渡してからの設定**まで含めて評価できない（仮想ケーブル側だけ揃っても「OBS でモニターするとエコーする」「48 kHz / 44.1 kHz の不整合で音が乗らない」等の具体的なハマりどころが見えない）。
- [w-okada-voice-changer.md §6](./w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) の「公式チュートリアルに OBS 名指しの記述は見つかっていない（未確認）」「§6.3 本ラボでの一般論整理は後続の OBS 接続調査タスクで上書き予定」という未確定状態が解消されない。同 [§9.1](./w-okada-voice-changer.md#91-既存タスクに引き継ぐ未確認事項) の「OBS Studio との具体的な接続パターン」未確認項目も塞がらない。
- [experiments/w-okada-voice-changer/_template.md §6 配信ソフト連携](../../experiments/w-okada-voice-changer/_template.md) で「経路パターン: P1〜P4」までは選べるが、**OBS 側で何を設定したか**を記録する欄が抽象記入のままになる。

本書は前段の [virtual-audio-devices.md](./virtual-audio-devices.md) と同じ立て付け（**1 ツール深掘り + 横断的な経路レシピの混合型**）で書く。1 製品なのでツール別エントリは OBS Studio に集中するが、[§4](#4-横断棚卸し表phase-3-で記入) で OBS の音声系機能を横断棚卸しし、[§5](#5-配信用途での典型構成p1p4--obs-レシピphase-3-で記入) で前段書 §5 P1〜P4 の各経路に対する OBS 側レシピを並べる。

### 1.2 対象 OBS バージョン

**本書が基準にする OBS Studio バージョン:**

- **OBS Studio 32.1.2**（2026-04-21 リリース、本書確認時点での最新 stable）
- 直近の系統: 32.0.4（2025-12-13）→ 32.1.0（2026-03-11）→ 32.1.1（2026-04-02）→ 32.1.2（2026-04-21）
- 出典: [obsproject.com](https://obsproject.com/) / [GitHub Releases](https://github.com/obsproject/obs-studio/releases)

OBS のメジャー / マイナーリリースは活発で、UI 表記・設定項目名・推奨デフォルト値が随時変動する。本書では **2026-05-12 時点の 32.1.x 系**を基準に書き、過去メジャー（30.x / 31.x）固有の表記差分には踏み込まない。利用時点で OBS の表記が変わっていた場合は、本書の **最終確認日（[§1.5](#15-最終確認日)）** を起点に再確認する。

### 1.3 派生版・関連プロダクトの線引き

**本書のコア対象（§3 で個別エントリを書く対象）:**

- **OBS Studio**（OBS Project が公式配布する本家。Windows / macOS / Linux）

**参考扱い（§1 で位置付けだけ示し、§3 では個別エントリを書かない対象。差分のうち本ラボで把握できたものは [§8 未確認事項](#8-未確認事項--後続タスクphase-3-で記入) に残す）:**

- **Streamlabs Desktop**（旧 Streamlabs OBS、現 Streamlabs）— OBS のソースコードを派生して開発される別プロダクト。UI / 内部の音声処理パスが本家と異なる箇所があり、本書の §5 レシピがそのまま当てはまらない可能性が高い。**本書のスコープ外**として §8 後続タスク候補に名前のみ残す。
- **OBS.Live**（StreamElements が提供する OBS Studio + プラグインのバンドル配布。派生版ではなく、本家 OBS にプラグインを追加した構成）— 音声系の挙動は基本的に本家 OBS に準じる前提で、差分が見えた時点で本書 §8 に追記する。
- **OBS Studio + 個別プラグイン**（StreamFX, obs-vst, NVIDIA Audio Effects SDK プラグイン等）— 本家 OBS のプラグイン拡張。本書 §3 の音声フィルタエントリで「内蔵フィルタとプラグイン拡張は別レイヤー」として境界だけ示し、プラグイン個別の選定軸は **配信周辺ツール調査シリーズ第 3 弾候補（ノイズ抑制 / ゲート系の棚卸し）** に分離する。

### 1.4 「OBS Studio との接続パターン」と本書で呼ぶ範囲

本書では「OBS Studio との接続パターン」を、次のスコープに**音声側のみ**で限定する。

**含めるもの:**

- **音声入力キャプチャ（Audio Input Capture）** ソースの仕様（対応する OS のデバイス種別 / モノラル・ステレオ・マルチチャンネルの扱い / サンプリングレート整合 / レイテンシ要因）
- **アプリケーション音声キャプチャ（Application Audio Output Capture）** の OS 別対応状況と、仮想オーディオデバイス経由との使い分け
- **音声出力キャプチャ（Audio Output Capture / デスクトップ音声）** と OS 別の取り回し（とくに macOS のデスクトップ音声キャプチャの制約）
- **音声モニタリング設定**（モニターオフ / モニターのみ（出力をミュート）/ モニターと出力）と「**モニタリングデバイス**」グローバル設定の選び方
- **グローバル音声設定のサンプリングレート**（44.1 kHz / 48 kHz）と、OS / 仮想オーディオデバイス / 声変換ホスト側との整合（[virtual-audio-devices.md §5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) を基準に）
- **オーディオ同期オフセット（Sync Offset）**による遅延補正の仕組み（公式ヘルプの説明範囲、適用される処理段、正負の意味）
- **音声フィルタ**の選択肢列挙（Compressor / Noise Gate / Noise Suppression（内蔵で選べる種別）/ VST）。**ノイズ抑制プラグインの選定軸自体**はシリーズ第 3 弾のスコープなので、本書では「OBS 内蔵で何が選べるか」までの粒度に止める
- 配信エンコーダー側の **Audio Bitrate / トラック数**設定と本書の経路設計との関係
- 既知の制約 / 公式 FAQ / Forum / GitHub Issues に書かれているハマりどころ（仮想オーディオデバイス連携時のサンプリングレート不一致、Apple Silicon での音声入力キャプチャの挙動、Windows のアプリケーション音声キャプチャの WGC 制約 等）

**含めないもの:**

- **OBS Studio の映像側機能全般**（映像キャプチャソース / シーン構成 / エンコーダー設定の映像部分 / 配信先プラットフォームの映像設定）。音声トラックの**配信エンコーダー側の音声ビットレート / トラック数**は経路設計との関係で触れるが、映像側のビットレート・解像度・キーフレーム間隔等には踏み込まない。
- **実測のレイテンシ / 音質 / CPU 負荷**（[CLAUDE.md](../../CLAUDE.md) 方針）。公式ヘルプ記載値・OBS 公称の推奨値は出典付きで明示し、本ラボでの実測値とは混ぜない。実測は後続の experiments タスクで個別モデルと組み合わせて取る。
- **ノイズ抑制 / ゲート系プラグインの選定軸**（NVIDIA Broadcast / Krisp / RNNoise / Speex の比較）— **配信周辺ツール調査シリーズ第 3 弾候補**として §8 に残す。本書では「OBS 内蔵のノイズ抑制フィルタで何が選べるか」までの粒度。
- **通話アプリ（Discord / Zoom）固有の仮想デバイス取り回し**（[virtual-audio-devices.md §7.3 後続タスク](./virtual-audio-devices.md#73-後続タスクtodomd-に上げるべき項目) と同じく独立タスク扱い）。本書では OBS Studio 単体への接続までを扱う。
- **Streamlabs Desktop / OBS.Live 等の派生版固有挙動の網羅**（[§1.3](#13-派生版関連プロダクトの線引き) 参照）。
- **第三者の声を許諾なく再現するモデル**を前提とした配信フロー — [CLAUDE.md](../../CLAUDE.md) 方針。
- **配信プラットフォーム固有の規約解釈**（YouTube / Twitch / niconico の音声配信ルール、収益化規約等）— 本書では推奨値の公式記述があれば引用するに留め、規約解釈には踏み込まない。

### 1.5 最終確認日

- **最終確認日**: 2026-05-12
- **対象 OBS Studio バージョン**: 32.1.2（2026-04-21 リリース）
- **前段の [virtual-audio-devices.md](./virtual-audio-devices.md) 最終確認日**: 2026-05-12（同日）

OBS のリリースは活発なため、本書を参照するときは必ずこの最終確認日と当時の OBS バージョンを確認し、UI 表記・設定項目名が現行リリースと異なる可能性を踏まえて読むこと。

### 1.6 公式情報源（エントリ冒頭で参照する集合）

§3 各エントリは下記の公式情報源を出典として記入する。本ラボから到達可能な OBS 公式の一次情報を**ここで一度集約**し、§3 では各エントリで実際に該当する URL のみを引用する形を取る。

**OBS Project 公式（一次情報）:**

- 製品トップ / ダウンロード: <https://obsproject.com/> / <https://obsproject.com/download>
- ヘルプポータル（KB・Forum・Discord・Developer Docs への入口）: <https://obsproject.com/help>
- Knowledge Base（KB）トップ: <https://obsproject.com/kb/>
- KB Audio カテゴリ: <https://obsproject.com/kb/category/7>
- Forum: <https://obsproject.com/forum/>
- Discord（公式）: <https://obsproject.com/discord>
- Developer / API ドキュメント: <https://docs.obsproject.com/>（プラグイン・libobs 開発者向け）
- Ideas Portal: <https://ideas.obsproject.com/>
- Certified Devices: <https://obsproject.com/certified-devices>

**GitHub（一次情報。本家リポジトリ）:**

- リポジトリ: <https://github.com/obsproject/obs-studio>
- Releases: <https://github.com/obsproject/obs-studio/releases>
- GitHub Wiki（インストール / ビルド / 機能ガイド計 71 ページ）: <https://github.com/obsproject/obs-studio/wiki>
- GitHub Issues: <https://github.com/obsproject/obs-studio/issues>

**KB の音声関連個別ガイド（§3 で頻出する出典）:**

- Audio Mixer Guide: <https://obsproject.com/kb/audio-mixer-guide>
- Application Audio Capture Guide: <https://obsproject.com/kb/application-audio-capture-guide>
- macOS Desktop Audio Capture Guide: <https://obsproject.com/kb/macos-desktop-audio-capture-guide>
- Multiple Audio Track Recording Guide: <https://obsproject.com/kb/multiple-audio-track-recording-guide>
- Surround Sound Guide: <https://obsproject.com/kb/surround-sound-guide>

> **注意**: 旧 OBS Studio Help Portal の `obsproject.com/wiki/` パスは本書確認時点でリダイレクトループになっており、機能ガイドの一次参照先は **KB（`obsproject.com/kb/`）** と **GitHub Wiki（`github.com/obsproject/obs-studio/wiki`）** に二分されている。§3 各エントリでは KB を優先し、KB に該当ガイドが存在しない項目（モニタリング設定の正負・サンプリングレート整合の詳細・Sync Offset 等）は GitHub Wiki / Forum / GitHub Issues を出典として引く。

### 1.7 記述ルール

本書は前段の [virtual-audio-devices.md](./virtual-audio-devices.md) と同等の記述ルールに揃える（[cloud-saas-realtime.md](./cloud-saas-realtime.md) / [rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md) / [w-okada-voice-changer.md](./w-okada-voice-changer.md) 共通）。

- **公式 Help / Knowledge Base / GitHub Wiki / 公式 Forum / GitHub Issues** に書かれていることと、コミュニティで一般に言われていることを**明確に分ける**。出典を行ごとに明記する
- 実測値・断定的な性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**OBS 公式が公称している値（推奨サンプリングレート / 推奨ビットレート 等）は「公式記述」として明示**し、本ラボでの実測値とは混ぜない
- 機能名・設定名は **OBS Studio UI / 公式ドキュメントが使っている名称**をそのまま書く（UI 上の表記が和訳されているかどうかは公式記述がある場合のみ採用）
- ライセンス / 商用配信での利用可否（OBS Studio 本体の GPL-2.0）は**ベンダー公式の明示がある項目のみ書く**。明示がない場合は「公式記述なし」と明記し、勝手に判断しない
- 仮想オーディオデバイス側のラベル参照は [virtual-audio-devices.md §4.1](./virtual-audio-devices.md#41-ツール--評価項目マトリクス) に揃え、本書内で名称を再定義しない（**前段書の横断棚卸し済みラベルを使う**）
- 公式ドキュメントから読み取れなかった項目は **未確認事項**として明示する。推測で埋めない

## 2. 評価項目（Phase 2 で本文記入）

§3 各エントリで埋め、§4 横断棚卸し表のカラムとして使う評価項目の定義。Phase 2 で本文を埋める時点では、ここに列挙したカラムをエントリ別に書く。

| 評価項目 | 何を書くか |
| --- | --- |
| 公式情報源 | KB / GitHub Wiki / Forum / GitHub Issues / Developer Docs の URL。§3 では各エントリ冒頭にまとめる |
| 機能の概要 | OBS 公式が何と呼んでいるか・どの用途を公式に想定しているか |
| OS 別対応状況 | Windows / macOS / Linux。Apple Silicon / ARM Windows での挙動の公式記述があれば明記 |
| 仮想オーディオデバイスとの噛み合い | [virtual-audio-devices.md §4.1](./virtual-audio-devices.md#41-ツール--評価項目マトリクス) のコア集合（VB-CABLE / VoiceMeeter / BlackHole）との接続要件 |
| 遅延要因 | 公式が説明している処理段・バッファ・SR 変換等の遅延要因。**実測は書かない** |
| 既知の制約 | 公式 FAQ / Forum / GitHub Issues に書かれているハマりどころ |
| 未確認事項 | 公式ドキュメントから読み取れなかった項目を明示。**推測で埋めない** |

## 3. OBS Studio の音声系機能エントリ

> **Phase 1 で公式情報源 URL を、Phase 2 で各エントリの公式説明範囲 / OS 別対応 / 仮想オーディオデバイスとの噛み合い / 遅延要因 / 既知の制約 / 未確認事項を記入済み。** 各エントリは §1.6 の公式情報源集合のうち、実際に該当する KB / GitHub Wiki / Forum / GitHub Issues のみを引用する。

### 3.1 音声入力キャプチャ（Audio Input Capture）

- **公式情報源:**
  - KB Audio カテゴリ: <https://obsproject.com/kb/category/7>
  - KB Audio Sources: <https://obsproject.com/kb/audio-sources>
  - KB Audio Mixer Guide: <https://obsproject.com/kb/audio-mixer-guide>
  - Forum（個別事例 / ハマりどころの一次情報）: <https://obsproject.com/forum/>
  - GitHub Issues（バグ / 既知制約）: <https://github.com/obsproject/obs-studio/issues>
- **機能の概要:** KB Audio Sources の公式説明は "This source allows you to add an audio input or output device (i.e. microphone or headset respectively) to a specific scene, and simply pick the device you wish to capture so the audio from that device will be captured when the source is active"。**シーン単位**でデバイスを選別したい場合に用い、Settings → Audio のグローバル設定（Mic/Aux 等）とは別レイヤー（"if you only want specific audio devices active in specific scenes, rather than globally through all of OBS"）。
- **OS 別対応:** Windows / macOS で標準提供（KB Audio Sources）。Linux では PulseAudio または ALSA ベースの "Audio Input Capture" 系ソースとして提供され、ALSA 経由の場合は "Rate" プロパティの既定値が **44100 Hz** と公式記述（KB Audio Sources）。Apple Silicon / ARM Windows での挙動差分の公式記述は本書確認時点で未特定。
- **仮想オーディオデバイスとの噛み合い:** [virtual-audio-devices.md §4.1](./virtual-audio-devices.md#41-ツール--評価項目マトリクス) のコア集合（`CABLE Output (VB-Audio Virtual Cable)` / `Voicemeeter Out B1` / `Voicemeeter Out B2` / `BlackHole 2ch` ほか）は OS の音声入力デバイスとして露出するため、本ソースのデバイスドロップダウンから直接選択する形で受け取る。KB Audio Sources の **sample rate issues** トピックは「Settings → Audio で Sample Rate を 48 kHz、OS 側（Windows サウンド設定 → デバイスのプロパティ → 詳細）も 48000 Hz に合わせる」を公式手順として明示しており、仮想オーディオデバイス側（前段書 [§3.1 VB-CABLE](./virtual-audio-devices.md#31-vb-cable) / [§3.2 VoiceMeeter Banana](./virtual-audio-devices.md#32-voicemeeter-banana) / [§3.4 BlackHole](./virtual-audio-devices.md#34-blackhole)）の SR も同一値で揃えることが整合条件。
- **遅延要因:** グローバル SR とデバイス SR が一致しない場合、OBS 内でリサンプリングが入る（KB Audio Sources の sample rate issues 節）。具体的なミリ秒数値の公式記述はなく、ベンダー公称値も特定できていない（本書 [§6 遅延ハンドリング](#6-遅延ハンドリングphase-3-で記入)）。
- **既知の制約:** KB Audio Sources の公式警告 — "Audio Input/Output Capture source can cause an echo effect if you have the same device selected in Settings → Audio. If you plan on adding audio devices directly to your scenes, make sure they are disabled globally first."（Settings → Audio とソースの両方に同じデバイスを置くと**エコー**）。**ASIO 入力は OBS Studio 本体にネイティブサポートなし**（OBS の GPL-2.0 と Steinberg ASIO SDK 規約の非互換が公式 Forum での説明、サードパーティプラグイン `Andersama/obs-asio` 等で補う構成）。
- **未確認事項:** Audio Input Capture ソース側に独立した chs 選択（モノラル / ステレオ / マルチ）が存在するかの公式 UI 仕様（**Downmix to Mono** は Advanced Audio Properties 側にあるが、ソース側は KB に明示なし）。Apple Silicon / ARM Windows での挙動差分。リサンプリングの実装位置（DSP 経路のどこで再サンプルされるか）の公式仕様。

### 3.2 アプリケーション音声キャプチャ（Application Audio Output Capture）

- **公式情報源:**
  - KB Application Audio Capture Guide: <https://obsproject.com/kb/application-audio-capture-guide>
  - KB macOS Desktop Audio Capture Guide（macOS 側プロセス別キャプチャの参照先）: <https://obsproject.com/kb/macos-desktop-audio-capture-guide>
  - GitHub Issues（WGC / プロセス対応の制約報告）: <https://github.com/obsproject/obs-studio/issues>
- **機能の概要:** OBS Studio 28 以降で導入された **Application Audio Capture (BETA)** ソース。プロセス（アプリケーション）単位で音声を拾う。OBS Studio 30.1 以降は **Window Capture / Game Capture ソース**側にも `Capture Audio (BETA)` オプションが追加され、ウィンドウ/ゲームキャプチャと音声を同一ソースで束ねられる（KB Application Audio Capture Guide で明示）。公式に "BETA" 表記が KB / UI 共に維持されている（本書最終確認日 2026-05-12 / OBS 32.1.2 時点）。
- **OS 別対応:** **Windows 10 (Version 2004 or later) / Windows 11** のみ（KB 明示）。実装は Windows Graphics Capture (WGC) 系の API に依存。**macOS は本ソース自体は非提供**で、macOS でアプリ別音声を拾うには OBS 30 + macOS 13 (Ventura) 以降の **macOS Audio Capture Source**（[§3.3](#33-音声出力キャプチャaudio-output-capture--デスクトップ音声) 参照）または外部仮想ドライバ経由（Loopback / Sound Siphon。VB-CABLE for Mac は per-application 非対応）。**Linux 非対応**（KB Audio Sources の OS マトリクスで Linux 列なし）。
- **仮想オーディオデバイスとの噛み合い:** 本ソースを使うと「仮想オーディオデバイスを経由せず」特定アプリの音声を OBS シーンに直接乗せられるため、[virtual-audio-devices.md §5.1 P1](./virtual-audio-devices.md#51-p1-シングル仮想ケーブル経路windows--macos最小構成) / [§5.2 P2](./virtual-audio-devices.md#52-p2-voicemeeter-ハブ経路windows複数音源を混ぜる) の「ゲーム音 / BGM を仮想ケーブルに流す」段を**部分的に置き換えうる代替経路**になる（Windows 限定）。ただし KB が明記する**互換性問題**として、Valorant や Call of Duty のゲーム内ボイスチャットなど一部の音声出力は "incompatible with the Application Audio Capture (BETA) source" と明示されており、その場合は **VB-CABLE 経由（前段書 P1〜P2）に戻す**ことが KB の公式回避策。
- **遅延要因:** BETA 表記の通り、安定性・遅延特性ともに変動の可能性。WGC 経路の音声遅延に関する数値ベースの公式記述は未特定。バッファリング上限は OBS グローバルの "Max Audio Buffering"（最大約 1 秒、Forum / GitHub PR の一次情報）に従う前提（[§3.4](#34-音声モニタリング設定audio-monitoring) と関連）。
- **既知の制約:** 上記のゲーム内ボイスチャット非互換（Valorant / Call of Duty 例示）が KB に明示。BETA 表記が継続中。OBS 30 系列の一部リリースで本ソースの不具合報告が GitHub Issues に散在（個別の Issue 番号特定は本書では未踏査）。
- **未確認事項:** WGC が要件とする具体的なプロセス特性（UWP / Win32 / 子プロセス音声等、対応範囲の網羅記述）。Window Capture / Game Capture 側の `Capture Audio (BETA)` が macOS Window Capture / Game Capture でも将来有効になるか（公式ロードマップは特定できず）。

### 3.3 音声出力キャプチャ（Audio Output Capture / デスクトップ音声）

- **公式情報源:**
  - KB macOS Desktop Audio Capture Guide: <https://obsproject.com/kb/macos-desktop-audio-capture-guide>
  - KB Audio Sources: <https://obsproject.com/kb/audio-sources>
  - KB Audio カテゴリ: <https://obsproject.com/kb/category/7>
  - Forum: <https://obsproject.com/forum/>
- **機能の概要:**
  - Windows: インストール直後から **Desktop Audio**（規定で 1 系統が Settings → Audio に出る）または **Audio Output Capture** ソース経由で OS のデスクトップ音声を拾える（KB Audio Sources の OS マトリクスで Windows 列が緑）。
  - macOS: KB が以下の選択肢を公式に提示。
    - **OBS Studio 30 以降 + macOS 13 (Ventura) 以降**: 新規追加された **macOS Audio Capture Source** を使う。"You can choose to capture all desktop audio or just a certain application"（= 全体 / 特定アプリのいずれか）。
    - **OBS Studio 28〜29**: **macOS Screen Capture** ソース経由（"The macOS Screen Capture Source also captures audio"。音声は自動的に Audio Mixer に追加される）。
    - **それ以前のバージョン / 古い macOS**: 外部の仮想オーディオドライバ経由 — KB が **VB-CABLE** / **Loopback (Rogue Amoeba)** / **Sound Siphon (Static Z Software)** を公式に列挙。
  - Linux: PulseAudio / ALSA 経由（[virtual-audio-devices.md §3.6 Linux PulseAudio / PipeWire の仮想シンク](./virtual-audio-devices.md#36-linux-pulseaudio--pipewire-の仮想シンク参考)）。本ラボは参考扱い。
- **OS 別対応:** Windows ネイティブ対応。macOS は OS / OBS バージョン依存（上記）。**macOS Audio Capture Source / macOS Screen Capture は ScreenCaptureKit (SCK) 経由**で動作。Linux は ALSA / PulseAudio。
- **仮想オーディオデバイスとの噛み合い:** macOS で OBS 30 未満を使う、または OBS 30 以降でも本ソースが拾えない用途では、**BlackHole / VB-CABLE for Mac / Loopback / Sound Siphon** などの外部ドライバが必要（KB が公式列挙）。KB が明示する公式比較として、**VB-CABLE for Mac は "does not support per-application audio capture"**、Loopback / Sound Siphon は per-application 対応。BlackHole + Multi-Output Device で組む macOS 経路は前段書 [§5.4 P4](./virtual-audio-devices.md#54-p4-macos-blackhole--multi-output-経路macos自分用モニタリング併用) と一致する。
- **遅延要因:** macOS Audio Capture Source / macOS Screen Capture 経由は SCK 経由のため OS API 制約に従う（公式の数値レイテンシ記述は未特定）。BlackHole / VB-CABLE 経由は前段書 §3.1 / §3.4 の SR / バッファ仕様に従う。
- **既知の制約:** macOS 旧 OBS / 旧 OS でデスクトップ音声を取りたい場合、外部ドライバの導入が必須（KB が "VB-CABLE ... must be set up manually" と明示し、Multi-Output Device の手動セットアップも要求）。Multi-Output Device 構成時のドリフト補正・Built-in Output の Top 配置は前段書 §3.4 / §5.4 の BlackHole FAQ 引用と一致。
- **未確認事項:** macOS Sonoma (14.x) / Sequoia (15.x) 以降での挙動（KB は Ventura までの言及）。macOS Audio Capture Source の「特定アプリ」モードでアプリ別音声を拾うときの内部実装の詳細（SCK + アプリ識別の挙動）。Apple Silicon 固有の差分（KB 上は明示なし）。

### 3.4 音声モニタリング設定（Audio Monitoring）

- **公式情報源:**
  - KB Audio Mixer Guide（Monitor Button の説明あり）: <https://obsproject.com/kb/audio-mixer-guide>
  - Forum タグ Audio Monitoring: <https://obsproject.com/forum/tags/audio-monitoring/>
  - Forum タグ Monitor and Output: <https://obsproject.com/forum/tags/monitor-and-output/>
  - GitHub Issues #4531（Audio Monitoring Buffer Buildup / Offsync）: <https://github.com/obsproject/obs-studio/issues/4531>
- **機能の概要:** **Edit → Advanced Audio Properties** の "Audio Monitoring" 列で**ソース単位**に 3 モードを選択（KB Audio Mixer Guide / Forum 通則）:
  - **Monitor Off**: モニタリングデバイスには音を送らず、出力（配信先）にのみ送る
  - **Monitor Only (mute output)**: モニタリングデバイスに送るが、出力には送らない
  - **Monitor and Output**: モニタリングデバイスと出力の両方に送る
  - グローバルの **Audio Monitoring Device** は **Settings → Advanced → Audio → Audio Monitoring Device** で 1 つだけ選択可能（KB Audio Mixer Guide の Monitor Button が "configured in Settings" と公式に参照）。
- **OS 別対応:** Windows / macOS / Linux 共通。デバイス選択の裏側 API は OS の音声サブシステム（WASAPI / CoreAudio / PulseAudio・PipeWire）に依存する。OS 別の挙動差分を KB が明示している箇所は未特定。
- **仮想オーディオデバイスとの噛み合い:** [virtual-audio-devices.md §5.3 P3 monitor 分離経路](./virtual-audio-devices.md#53-p3-monitor-分離経路windows低遅延モニタリング-tip) と同じ発想で、**声変換ホスト側で monitor を物理デバイスに直接出す**設計（= モニタが OBS の外で完結）なら、OBS 側の各ソースは **Monitor Off** が整合。逆に **OBS 側でモニタする設計**にする場合、Audio Monitoring Device に **VB-CABLE Input / Voicemeeter Input / BlackHole 等の仮想ケーブル**を選んではいけない — それらは OBS のソース側でも拾うため [§3.1](#31-音声入力キャプチャaudio-input-capture) の KB 警告と同根のエコーループが起こる。[§5.2 P2 VoiceMeeter ハブ経路](./virtual-audio-devices.md#52-p2-voicemeeter-ハブ経路windows複数音源を混ぜる) では Bus A1（物理出力）がモニタを担うため、OBS 側は Monitor Off で運用するのが整合。
- **遅延要因:** モニタ経路は**出力エンコード側とは別バッファ**で処理されるため、Sync Offset の影響を受けない（Forum 通則、[§3.6](#36-オーディオ同期オフセットsync-offset--audio-delay) と関連）。長時間運用でモニタ側バッファが膨張して映像と非同期になる事例が **GitHub Issue #4531** に**未解決**で報告されている（一次情報）。
- **既知の制約:** Audio Monitoring Device に「OBS がキャプチャしているデバイス」を選ぶとフィードバックになる、というのが Forum・コミュニティで繰り返し言及される運用上の原則（KB 直接の独立記事は未特定）。Issue #4531 のモニタ側バッファ蓄積による音ズレが公式 Issue として未解決。
- **未確認事項:** モニタリング経路のバッファサイズと処理段の公式仕様（KB 上の明示なし）。複数モニタリングデバイスへの同時出力サポート予定（Ideas Portal / Issues に要望散見、公式採否は未特定）。macOS / Linux でのモニタリング経路のレイテンシ特性の公式記述。

### 3.5 グローバル音声サンプリングレート（Audio Settings → Sample Rate）

- **公式情報源:**
  - KB Audio Mixer Guide（Settings の Audio セクションで Stereo / Sample Rate が設定可能との記述）: <https://obsproject.com/kb/audio-mixer-guide>
  - KB Audio Sources（sample rate issues の整合手順）: <https://obsproject.com/kb/audio-sources>
  - KB Surround Sound Guide（Channels の選択肢と再起動要件）: <https://obsproject.com/kb/surround-sound-guide>
  - KB Multiple Audio Track Recording Guide（トラック設計との関係）: <https://obsproject.com/kb/multiple-audio-track-recording-guide>
- **機能の概要:** **Settings → Audio → General** に **Sample Rate** と **Channels** の選択肢がある。
  - Sample Rate: KB / Forum で出てくる公式選択肢は **44.1 kHz / 48 kHz** の 2 値（KB Audio Sources が "set the global Sample Rate to 48 kHz" を公式手順として明示）。
  - Channels: **Mono〜7.1（最大 8 ch）**の選択肢（KB Surround Sound Guide）。Channels を変更した場合は **OBS の再起動が必須**（KB Surround Sound Guide）。
- **OS 別対応:** 共通機能。デバイス側 SR との整合は OS の音声 API（WASAPI / CoreAudio / PulseAudio・PipeWire）に従う。
- **仮想オーディオデバイスとの噛み合い:** KB Audio Sources の公式手順は "set the global Sample Rate to 48 kHz, then check your Windows sound settings (right-click speaker icon > Sound settings > Device properties > Advanced) and make sure your device is also set to 48000 Hz"。**OBS グローバル / OS / 仮想オーディオデバイス**の 3 段で SR を揃えるのが整合条件。前段書のコア集合は以下の SR 仕様（詳細は [virtual-audio-devices.md §4.1](./virtual-audio-devices.md#41-ツール--評価項目マトリクス)）:
  - **VB-CABLE**: 8〜192 kHz、内部 SR 切替 UI あり（[§3.1](./virtual-audio-devices.md#31-vb-cable)）
  - **VoiceMeeter Banana / Potato**: A1（メイン物理出力）の SR に従属（[§3.2](./virtual-audio-devices.md#32-voicemeeter-banana) / [§3.3](./virtual-audio-devices.md#33-voicemeeter-potato)）
  - **BlackHole**: 8〜768 kHz / 32-bit float（[§3.4](./virtual-audio-devices.md#34-blackhole)）
- **遅延要因:** SR 不整合時、OBS 内部でリサンプリング（KB Audio Sources が **sample rate issues** を独立トピックとして扱う）。SR がデバイス間で揃わないと、Forum / コミュニティで共通則として言われる "audio drift over time or sound distortion" が起こる（公式 KB 自体は drift / distortion の語を明示で書いていないため、本書では **コミュニティ通説**として記録）。
- **既知の制約:**
  - **Channels をデバイス側と異なる値にする**と、KB Surround Sound Guide が明言する **automatic rematrixing**（"channel mixing or LFE channel removal" 等の副作用）が発生（"choose the same channel layout as your input"）。
  - 配信プラットフォーム別のサラウンド対応（KB Surround Sound Guide）:
    - **Twitch** / **Facebook Live 360** (ambisonics): 対応
    - **YouTube Live**: **5.1 のみ、TV 経由のみ**対応
    - **Facebook Live**（通常配信）: 全チャネルを**ダウンミックス**
- **未確認事項:** 88.2 kHz / 96 kHz / 176.4 kHz / 192 kHz 等を Settings → Audio で**選択可能か**の公式 UI 仕様（KB は 44.1 / 48 のみ言及、コミュニティでも 2 値選択の認識が一般。本書では UI で実物確認は未踏査）。リサンプリングアルゴリズムの公式仕様（FFmpeg / 独自 DSP）。配信エンコーダー側に渡る前の最終 SR 変換の処理段。

### 3.6 オーディオ同期オフセット（Sync Offset / Audio Delay）

- **公式情報源:**
  - KB Audio Mixer Guide（Advanced Audio Properties の参照元）: <https://obsproject.com/kb/audio-mixer-guide>
  - Forum タグ Sync Offset: <https://obsproject.com/forum/tags/sync-offset/>
  - GitHub Issues #11656（Audio Sync Offset resets when opening the Advanced Audio Properties window）: <https://github.com/obsproject/obs-studio/issues/11656>
- **機能の概要:** **Edit → Advanced Audio Properties** の "Sync Offset (ms)" 列で**ソース単位**に出力タイムスタンプへのオフセットを加える（KB Audio Mixer Guide が Advanced Audio Properties への入口を示し、Forum 一次情報で操作手順が確認できる）。単位は**ミリ秒**（1000 ms = 1 sec）。**適用先は出力エンコード側のみ**で、モニタリング経路には作用しない — これは Forum で繰り返し説明される運用上の挙動であり、KB の独立記事自体は未特定（本書では **Forum 通則**として記録）。
- **OS 別対応:** UI 上は共通機能。OS 別の挙動差分の公式記述は未特定。
- **仮想オーディオデバイスとの噛み合い:** 仮想ケーブル経由のソース（CABLE Output / Voicemeeter Out B1 / BlackHole）は経路上のバッファに起因する**入力側遅延**を持ちうるため、他のソース（Desktop Audio / アプリケーション音声キャプチャ）との**相対同期**を取る用途で Sync Offset を使うのが典型。[virtual-audio-devices.md §5.2 P2 VoiceMeeter ハブ経路](./virtual-audio-devices.md#52-p2-voicemeeter-ハブ経路windows複数音源を混ぜる) のように複数ソースを混ぜる構成では、ソース間オフセットを**実測で詰める**前提（公式の数値ガイダンスなし）。
- **遅延要因:** **正のオフセット**は該当ソースを遅らせて出力へ送る方向（Forum 通則）。**負のオフセット**の UI 動作については「他ソースを先に出すような効果は得られにくい」と Forum で見解が散見するが、KB に明確な定義は無く本書では**未確認**として扱う（[§6 遅延ハンドリング](#6-遅延ハンドリングphase-3-で記入) でベンダー公称値と本ラボ実測の分離ポリシーを明示）。モニタ側に作用しないため、**モニタ ⇄ 出力で同期がずれる**設計上の前提として理解しておく必要がある。
- **既知の制約:** **GitHub Issue #11656** — Sync Offset 値が Advanced Audio Properties ウィンドウを再オープンするとリセットされる事例（一次情報、本書最終確認日時点で**未クローズ**）。Forum 一次情報では「Sync Offset で取り切れない音ズレ」（例: ビデオキャプチャ側の遅延が支配的なケース）が頻出。
- **未確認事項:** 正負の意味の公式定義（KB に独立記事なし、Forum 通則で補う状態）。ASIO（[§3.1](#31-音声入力キャプチャaudio-input-capture) で示したとおり OBS 本体ネイティブ非対応）/ WASAPI / CoreAudio とのバッファ整合との関係。monitor 側にも独立した遅延補正を入れる UI / API の有無。

### 3.7 音声フィルタ（Compressor / Noise Gate / Noise Suppression / VST）

- **公式情報源:**
  - KB Filters Guide: <https://obsproject.com/kb/filters-guide>
  - KB Noise Suppression Filter: <https://obsproject.com/kb/noise-suppression-filter>
  - KB Audio カテゴリ: <https://obsproject.com/kb/category/7>
  - Forum / GitHub Issues（フィルタ追加・改修の一次情報）: <https://obsproject.com/forum/> / <https://github.com/obsproject/obs-studio/issues>
- **機能の概要（KB Filters Guide の公式列挙）:**
  - **Compressor**: "Prevent audio levels exceeding a certain threshold, or enable ducking to make one Audio Source quieten when another Audio Source makes sound"
  - **Expander**: "Reduce background sounds. Similar to a Noise Gate but with an adjustable ratio"
  - **Gain**: "Boost the volume of quiet Audio Sources"
  - **Invert Polarity**: "Used to correct phase cancellation issues"
  - **Limiter**: "Prevent audio distortion"
  - **Noise Gate**: "Cut off background noise when not speaking"
  - **Noise Suppression**: "Remove background or white noise in Audio Sources"
  - **VST 2.x Plugin**: "Use VST 2.x plugins to filter audio"
- **Noise Suppression Filter の方式別公式記述（KB Noise Suppression Filter）:**
  - **RNNoise**: "higher quality but at the cost of greater CPU usage"（既定方式）
  - **Speex**: 抑制レベルが configurable / 既定の Suppression Level は **−30 dB** / 強めにかけると "this can distort other sounds (like your voice)"
  - **NVIDIA Noise Removal**: "requires the Broadcast SDK"（= **NVIDIA Broadcast SDK redistributable** のインストールが必須）。インストール後に RNNoise / Speex と並んで選択肢化される
  - 共通注意: "generally not effective at large amounts of background noise"（**強いノイズには効かない**ことを公式に明言）
- **OS 別対応:** Compressor / Expander / Gain / Invert Polarity / Limiter / Noise Gate は OBS Studio 標準で OS 横断（Windows / macOS / Linux）。Noise Suppression の **RNNoise / Speex** も OS 横断、**NVIDIA Noise Removal** は NVIDIA Broadcast SDK の前提から **Windows + 対応 NVIDIA GPU 限定**。VST 2.x Plugin は内蔵ホスト機能だが、プラグイン本体は OS / アーキ別に別途インストールが必要（.dll / .vst / .so）。
- **仮想オーディオデバイスとの噛み合い:** フィルタはソース単位で適用されるため、仮想ケーブルを経路に挟むか否かに直接の依存はない。ただし VST プラグインで **lookahead**（先読みバッファ）を持つ実装を選ぶと、配信側（出力エンコード）に遅延が加算され、[§3.6](#36-オーディオ同期オフセットsync-offset--audio-delay) で他ソースとの相対同期を取り直す必要が出る。ノイズ抑制は**声変換ホストの入力前段で適用**するか **OBS 側で適用**するかで遅延加算の発生段が異なる — 本書では境界の明示のみで、実測比較は [CLAUDE.md](../../CLAUDE.md) 方針に従い行わない。
- **遅延要因:** KB Noise Suppression Filter には**遅延 (latency) への影響に関する数値記述なし**（CPU 負荷と品質の言及のみ）。RNNoise / Speex / NVIDIA Noise Removal いずれも**公式の遅延値は未特定**。VST プラグインの遅延は実装依存（公式 KB は本トピックの記述なし）。
- **既知の制約:**
  - KB Noise Suppression Filter: 強いノイズには効かない（"generally not effective at large amounts of background noise"）。
  - Speex の Suppression Level を強めると音声が歪む（公式注意）。
  - **VST 2.x のみ対応**（VST 3 は OBS Studio 本体非対応。本書最終確認日時点）。
- **未確認事項 / 後続:**
  - 各フィルタの**実測遅延 / CPU 負荷 / 音質**比較 → **配信周辺ツール調査シリーズ第 3 弾候補**として [§8 後続タスク](#8-未確認事項--後続タスクphase-3-で記入) に分離。本書では「OBS 内蔵で何が選べるか」までの粒度にとどめる（[§1.4](#14-obs-studio-との接続パターンと本書で呼ぶ範囲) のスコープ通り）。
  - NVIDIA Noise Removal の対応 GPU / Broadcast SDK バージョン要件の公式網羅記述。
  - VST 3 対応の公式ロードマップ。
  - 内蔵フィルタと**外部プラグイン**（StreamFX / obs-vst / NVIDIA Audio Effects SDK プラグイン等）の境界は [§1.3](#13-派生版関連プロダクトの線引き) で示したとおり、本書では境界の明示のみ。

## 4. 横断棚卸し表

§3 で個別エントリを書いた音声系機能を、§2 評価項目の主要カラムで横並びに比較する。配信用途で「音声入力キャプチャ vs アプリケーション音声キャプチャをどう使い分けるか」「モニタリング設定をどれにするか」の足切り判断を 1 表で出すことを優先し、各セルは公式情報源で裏取りした要点のみを抜粋する。詳細・出典・原文引用は §3 各エントリを参照。

### 4.1 機能 × 評価項目マトリクス

| 評価項目 | 3.1 音声入力キャプチャ | 3.2 アプリケーション音声キャプチャ | 3.3 音声出力キャプチャ（デスクトップ音声） | 3.4 音声モニタリング | 3.5 グローバル SR | 3.6 Sync Offset | 3.7 音声フィルタ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 公式情報源 | [KB Audio Sources](https://obsproject.com/kb/audio-sources) / [KB Audio Mixer Guide](https://obsproject.com/kb/audio-mixer-guide) | [KB Application Audio Capture Guide](https://obsproject.com/kb/application-audio-capture-guide) | [KB macOS Desktop Audio Capture Guide](https://obsproject.com/kb/macos-desktop-audio-capture-guide) / [KB Audio Sources](https://obsproject.com/kb/audio-sources) | [KB Audio Mixer Guide](https://obsproject.com/kb/audio-mixer-guide) / [Issue #4531](https://github.com/obsproject/obs-studio/issues/4531) | [KB Audio Sources](https://obsproject.com/kb/audio-sources) / [KB Surround Sound Guide](https://obsproject.com/kb/surround-sound-guide) | [KB Audio Mixer Guide](https://obsproject.com/kb/audio-mixer-guide) / [Issue #11656](https://github.com/obsproject/obs-studio/issues/11656) | [KB Filters Guide](https://obsproject.com/kb/filters-guide) / [KB Noise Suppression Filter](https://obsproject.com/kb/noise-suppression-filter) |
| 機能の概要 | シーン単位で OS の音声入出力デバイスを選んで拾う | プロセス単位で音声を拾う（OBS 28+。**BETA 表記**継続中） | OS のデスクトップ音声を拾う（Win は規定 Desktop Audio／macOS は OS / OBS バージョン依存） | ソース単位の 3 モード切替 + グローバルの Audio Monitoring Device | Settings → Audio の Sample Rate / Channels（KB 上は **44.1 / 48 kHz** 言及、Channels は Mono〜7.1） | Advanced Audio Properties のソース単位ミリ秒オフセット | Compressor / Expander / Gain / Invert Polarity / Limiter / Noise Gate / Noise Suppression / VST 2.x |
| OS 別対応 | Windows / macOS / Linux（Linux ALSA は既定 SR **44100 Hz**） | **Win 10 (2004+) / Win 11 のみ**。macOS / Linux 非対応 | Win ネイティブ／macOS は OBS 30 + macOS 13 で macOS Audio Capture Source、OBS 28〜29 は macOS Screen Capture、それ以前は外部ドライバ／Linux は PA・ALSA | Win / macOS / Linux 共通（裏側 API は WASAPI / CoreAudio / PA・PW） | 共通機能 | 共通機能（OS 別差分の公式記述なし） | 標準フィルタは OS 横断／**NVIDIA Noise Removal は Win + 対応 NVIDIA GPU 限定** |
| 仮想オーディオデバイスとの噛み合い | 仮想ケーブル（[VAD §4.1](./virtual-audio-devices.md#41-ツール--評価項目マトリクス)）を OS の入力デバイスとして直接ドロップダウンから選ぶ。SR は OBS / OS / 仮想デバイスの 3 段で揃える | **仮想ケーブルを経由せず**特定アプリ音声を直接拾える（Win 限定）。ただしゲーム内ボイスチャット等の非互換アプリは VB-CABLE 経由（P1〜P2）に戻す | macOS で OBS 30 未満／拾えないアプリは BlackHole / Loopback / Sound Siphon が必須（VB-CABLE for Mac は per-application 非対応） | Audio Monitoring Device に**仮想ケーブルを選ぶとエコーループ**。物理出力 or VoiceMeeter A1 を選ぶ | 仮想ケーブル側 SR と **48 kHz** で揃えるのが KB 公式手順 | 仮想ケーブル経由の入力側遅延の相対同期に使う典型 | フィルタはソース単位なので仮想ケーブル有無に直接依存しない（VST の lookahead 分は加算） |
| 遅延要因（公式記述） | SR 不一致時のリサンプリング（数値記述なし） | WGC 経路（数値記述なし）／Max Audio Buffering 約 1 秒（Forum） | macOS は SCK 経由（数値記述なし）／BlackHole 経路は VAD §3.4 仕様 | 出力エンコード経路と**別バッファ**（Sync Offset の影響を受けない） | リサンプリング段（数値記述なし）／Channels をデバイスと不一致にすると **automatic rematrixing**（KB 明示） | 適用先は出力エンコードのみ（Forum 通則）。モニタには作用しない | KB に**遅延数値記述なし**（CPU 負荷と品質の言及のみ）／VST lookahead は実装依存 |
| 既知の制約 | Settings → Audio とソースで同じデバイスを置くとエコー（KB 明示）／**ASIO 入力は本体ネイティブ非対応**（GPL-2.0 と ASIO SDK の非互換） | Valorant / Call of Duty 等のゲーム内ボイスチャットは "incompatible"（KB 明示）／BETA 継続 | macOS 旧 OBS / 旧 OS は外部ドライバ必須（KB 明示）／Multi-Output Device は Built-in Top + drift correction（VAD §3.4 / §5.4 と同根） | [Issue #4531](https://github.com/obsproject/obs-studio/issues/4531)（モニタ側バッファ蓄積で映像と非同期、**未解決**）／キャプチャ中デバイスを Audio Monitoring Device に選ぶとフィードバック（Forum 通則） | Channels をデバイスと不一致にすると channel mixing / LFE 除去（KB Surround Sound）／Channels 変更で OBS 再起動必須（KB） | [Issue #11656](https://github.com/obsproject/obs-studio/issues/11656)（Advanced Audio Properties 再オープンで Sync Offset がリセット、**未クローズ**） | KB Noise Suppression: 強いノイズには効かない／Speex 強掛けで音声歪み／**VST 3 非対応**（本体） |
| 未確認事項 | ソース側の chs 選択 UI 仕様 / Apple Silicon・ARM Win 差分 / リサンプリング実装位置 | WGC のプロセス特性網羅 / macOS Window・Game Capture の `Capture Audio (BETA)` 将来対応 | macOS 14・15 以降の挙動 / macOS Audio Capture Source の特定アプリモード内部実装 | モニタ経路バッファサイズと処理段の公式仕様 / 複数モニタリングデバイス同時出力対応 | 88.2k / 96k / 176.4k / 192k の UI 選択可否（KB は 44.1 / 48 のみ） / リサンプリングアルゴリズム | 正負の意味の公式定義（KB 独立記事なし） / ASIO・WASAPI・CoreAudio バッファ整合 / モニタ側独立遅延補正 UI | RNNoise / Speex / NVIDIA NR の実測遅延・CPU 負荷比較（**シリーズ第 3 弾**）／NVIDIA NR の対応 GPU 網羅 / VST 3 ロードマップ |

> **注意**: 各セルは要点抜粋。出典原文・KB 引用は [§3 各エントリ](#3-obs-studio-の音声系機能エントリ) を参照。「未確認事項」は本書最終確認日（[§1.5](#15-最終確認日)）時点で公式ドキュメントから読み取れなかった項目。

### 4.2 配信用途での足切り早見表

「配信ソフト側で何を選ぶか」の一次フィルタとして使う。本ラボのメイン環境は Windows / macOS。

#### 4.2.1 ゲーム / アプリ音声をどう拾うか（音声入力キャプチャ vs アプリケーション音声キャプチャ）

| 要件 | 第一候補 | 補足 / 注意 |
| --- | --- | --- |
| Windows で**特定 1 アプリの音声**だけ拾いたい（仮想ケーブルを増やしたくない） | **3.2 アプリケーション音声キャプチャ**（Win 10 2004+ / Win 11） | BETA 表記継続中。Valorant / CoD のゲーム内ボイスチャット等は KB 明示で非対応 → 該当時は VB-CABLE 経由（P1〜P2）に戻す |
| Windows で**複数アプリ音 + マイク + 声変換出力**を 1 経路に合流させたい | **3.1 音声入力キャプチャ + VoiceMeeter Banana / Potato（[VAD §5.2 P2](./virtual-audio-devices.md#52-p2-voicemeeter-ハブ経路windows複数音源を混ぜる)）** | アプリケーション音声キャプチャでは複数アプリの相対バランスを mixer で取れない |
| **macOS で**特定 1 アプリの音声を拾いたい | **OBS 30 + macOS 13+** なら **3.3 macOS Audio Capture Source**（"特定アプリ" モード） | OBS 30 未満 / 旧 macOS は **Loopback / Sound Siphon**（per-app 対応）。**VB-CABLE for Mac は per-app 非対応**（KB 明示） |
| **macOS で**デスクトップ全体の音声を拾いたい | **OBS 30 + macOS 13+** の macOS Audio Capture Source、または **OBS 28〜29** の macOS Screen Capture（音声同梱） | OBS 28 未満 or 旧 macOS は **BlackHole + Multi-Output**（[VAD §5.4 P4](./virtual-audio-devices.md#54-p4-macos-blackhole--multi-output-経路macos自分用モニタリング併用)） |
| 声変換ホストの output（仮想ケーブル）を OBS に渡したい | **3.1 音声入力キャプチャ**で `CABLE Output (VB-Audio Virtual Cable)` / `Voicemeeter Out B1`・`B2` / `BlackHole 2ch` 等を直接選ぶ | KB 公式手順: OBS / OS / 仮想ケーブルの 3 段で SR を **48 kHz** に揃える |
| ASIO 入力を直接 OBS に取り込みたい | **本体ネイティブ非対応**（[§3.1](#31-音声入力キャプチャaudio-input-capture)）。`Andersama/obs-asio` 等の**サードパーティプラグイン**または **VoiceMeeter Insert ASIO 経由** | OBS 本体は GPL-2.0 / Steinberg ASIO SDK 規約の非互換が公式 Forum 説明 |

#### 4.2.2 モニタリング設定をどれにするか（[§3.4](#34-音声モニタリング設定audio-monitoring) 3 モード）

| 要件 | モード | Audio Monitoring Device に置くもの |
| --- | --- | --- |
| 声変換ホスト側で **monitor を物理ヘッドホンに直接出している**（[VAD §5.3 P3](./virtual-audio-devices.md#53-p3-monitor-分離経路windows低遅延モニタリング-tip)） | 全ソース **Monitor Off** | 何も選ばないか、使わない物理出力を当てる（経路上は無視されるが、誤って仮想ケーブルを選ぶとエコー要因） |
| **VoiceMeeter Bus A1（物理出力）でモニタしている**（[VAD §5.2 P2](./virtual-audio-devices.md#52-p2-voicemeeter-ハブ経路windows複数音源を混ぜる)） | 全ソース **Monitor Off** | （A1 がモニタを担うので）OBS 側モニタは触らない |
| **OBS 側でモニタしたい**（声変換ホストの monitor を切って OBS に集約） | 該当ソースのみ **Monitor and Output**（配信にも乗せる）／**Monitor Only (mute output)**（自分だけ聴く） | **物理出力（ヘッドホンの実デバイス）**。**VB-CABLE Input / Voicemeeter Input / BlackHole 等の仮想ケーブルは選ばない**（[§3.1](#31-音声入力キャプチャaudio-input-capture) KB 警告と同根のフィードバックループ） |
| **macOS で OBS 側モニタ + BlackHole 経由配信**（[VAD §5.4 P4](./virtual-audio-devices.md#54-p4-macos-blackhole--multi-output-経路macos自分用モニタリング併用) 改） | Monitor and Output / Monitor Only | **Built-in Output / 物理ヘッドホン**。Multi-Output Device 自体を選ぶと OBS が拾った音をまた Multi-Output 経由で BlackHole に流すループになる可能性があるため、Multi-Output Device 構成では声変換ホスト側で分配する [VAD §5.4 P4](./virtual-audio-devices.md#54-p4-macos-blackhole--multi-output-経路macos自分用モニタリング併用) を優先 |

> **エコーループの典型パターン（Forum 通則）**: ① Settings → Audio とソースで同じデバイス → KB 明示。② Audio Monitoring Device にキャプチャ中の仮想ケーブルを選ぶ → 自前出力をまた拾うループ。③ macOS Multi-Output に BlackHole を含めた状態で OBS の Audio Monitoring Device に Multi-Output を選ぶ → ②の派生。

#### 4.2.3 グローバル SR をどう揃えるか（[§3.5](#35-グローバル音声サンプリングレートaudio-settings--sample-rate)）

| 経路 | OBS Settings → Audio | OS（Windows サウンド設定 / macOS Audio MIDI Setup） | 仮想ケーブル | 声変換ホスト |
| --- | --- | --- | --- | --- |
| Windows + VB-CABLE / VoiceMeeter | **48 kHz**（KB 公式手順） | デバイスのプロパティ → 詳細で **48000 Hz** | VB-CABLE Audio Repeater / VoiceMeeter A1 SR を **48 kHz** | w-okada VC Client SR を **48 kHz**（[w-okada §5.4](./w-okada-voice-changer.md#54-サンプリングレート--未確認事項) と整合） |
| macOS + BlackHole | **48 kHz** | Audio MIDI Setup の各デバイスを **48000 Hz** | BlackHole は 8〜768 kHz 任意。**48 kHz で固定**するのが整合 | 同上 |
| Channels | **デバイス側と同値**（Stereo を既定。Mono / 5.1 / 7.1 が必要なら入力デバイス側と一致させる） | — | — | KB Surround Sound: 不一致は automatic rematrixing |

44.1 kHz 経路を選ぶ理由（DAW 経由の素材合流など）が無ければ、**全体を 48 kHz に揃える**のが KB 公式手順との整合が取りやすい。

### 4.3 表の使い方（足切りの一例）

- **Windows でゲーム音 + マイク + 声変換を 1 経路に合流したい** → §4.2.1 の 2 行目で VoiceMeeter ハブ経路（[VAD §5.2 P2](./virtual-audio-devices.md#52-p2-voicemeeter-ハブ経路windows複数音源を混ぜる)）を選び、§5.2 の OBS レシピで 3.1 音声入力キャプチャを `Voicemeeter Out B1` に向ける。
- **macOS で 1 アプリの音声だけ拾いたい** → §4.2.1 の 3 行目。OBS 30 + macOS 13+ なら 3.3 macOS Audio Capture Source の "特定アプリ" モード一択で済み、外部ドライバ導入が不要。
- **声変換ホスト monitor を WASAPI 直接出力にして遅延を詰めている** → §4.2.2 の 1 行目で OBS 側 monitor は全ソース Off にする（[VAD §5.3 P3](./virtual-audio-devices.md#53-p3-monitor-分離経路windows低遅延モニタリング-tip) 思想）。
- **配信音声が時間とともに映像と非同期になる** → [Issue #4531](https://github.com/obsproject/obs-studio/issues/4531)（モニタ側バッファ蓄積、未解決）の症状に該当する可能性。OBS 側モニタを Off にして声変換ホスト側 monitor 経路に逃がすか、OBS の再起動で再現性を切り分ける。本書では実測値ベースの判断は行わない。
- **Sync Offset の値が勝手に消える** → [Issue #11656](https://github.com/obsproject/obs-studio/issues/11656)（Advanced Audio Properties 再オープンでリセット、未クローズ）の事例と一致するか確認。

## 5. 配信用途での典型構成（P1〜P4 × OBS レシピ）

[virtual-audio-devices.md §5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) を行に、OBS 側の **音声入力キャプチャ / グローバル音声サンプリングレート / Audio Monitoring Device / 各ソースのモニタリング設定 / Sync Offset の取り方**を列にしたレシピ表 + 各パターンの経路図（OBS 側の音声 mixer ブロックまで描く）。本書の中核。

各パターンの「声変換ホスト」は [w-okada-voice-changer.md §5.2 input / output / monitor の 3 デバイス構成](./w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537) を主な想定として書く（他 OSS 声変換ホスト [RVC](./rvc.md) / [so-vits-svc](./so-vits-svc.md) / [Beatrice](./beatrice.md) でも IO 構成 UI が同等なら経路図は同じ）。

### 5.0 P1〜P4 × OBS 設定レシピ表

[VAD §5 P1〜P4](./virtual-audio-devices.md#5-配信用途での典型構成) と**1 対 1 対応**。

| OBS 設定 | P1: 単一仮想ケーブル | P2: VoiceMeeter ハブ | P3: monitor 分離 | P4: macOS BlackHole + Multi-Output |
| --- | --- | --- | --- | --- |
| **音声入力キャプチャ ソースのデバイス** | `CABLE Output (VB-Audio Virtual Cable)`（Win） / `BlackHole 2ch`（macOS） | `Voicemeeter Out B1`（声変換 + ゲーム音 mix）。マイク素 + 声変換を別トラックで送るなら `B2` を別ソース化 | `CABLE Output (VB-Audio Virtual Cable)` または `Voicemeeter Out B1` | `BlackHole 2ch`（声変換 output 単体） / `BlackHole 16ch`（アプリ別の独立経路を切る場合の 2ch ペア単位） |
| **Settings → Audio: Sample Rate** | **48 kHz**（KB 公式手順、[§3.5](#35-グローバル音声サンプリングレートaudio-settings--sample-rate)） | **48 kHz**（A1 SR と整合させる） | **48 kHz** | **48 kHz** |
| **Settings → Audio: Channels** | デバイス側と同値（既定 Stereo） | 同左。ゲーム音側に 5.1 が要るなら入力デバイスと一致 | 同左 | 同左 |
| **Settings → Audio: Desktop Audio / Mic-Aux のグローバル割当** | OBS 経路で重複を避けるため、シーン側 Audio Input Capture と**同じデバイスを重ねない**（[§3.1](#31-音声入力キャプチャaudio-input-capture) KB 警告） | グローバル Desktop Audio は無効化（Voicemeeter 経由で B1 に集約済み）。Mic/Aux も同様に無効化し、シーンの音声入力キャプチャに統一 | 同左 | グローバル Desktop Audio は **無効化**（Multi-Output 経由で BlackHole に既に流れている。重ねるとエコー） |
| **Settings → Advanced → Audio Monitoring Device** | 物理ヘッドホン（実出力）／OBS 側でモニタしないなら未設定でも可 | **物理ヘッドホン**（A1 で物理出力済みなので OBS 側 Monitoring は使わない方針なら未設定） | **物理ヘッドホン**（声変換ホスト monitor が物理出力済みなので OBS 側 monitor は基本オフ。**仮想ケーブルは絶対に選ばない**） | **Built-in Output / 物理ヘッドホン**。**Multi-Output Device 自体は選ばない**（[§4.2.2](#422-モニタリング設定をどれにするか3-3-モード) 警告） |
| **各ソースの Audio Monitoring** | 全ソース **Monitor Off**（声変換ホスト monitor が物理出力済み） | 全ソース **Monitor Off**（A1 でモニタ済み） | **全ソース Monitor Off**（[VAD §5.3 P3](./virtual-audio-devices.md#53-p3-monitor-分離経路windows低遅延モニタリング-tip) 思想） | 全ソース **Monitor Off**（Multi-Output で物理出力済み） |
| **Sync Offset の取り方** | 単一ソースなので相対同期は不要。映像キャプチャとのリップシンクが必要なときのみソースに正のオフセットを入れる | ゲーム音 / マイクが Voicemeeter で 1 ソースに合流済み。**Voicemeeter 内 EQ / Delay** で先に詰めてから OBS 側 Sync Offset を**最小限**に使うのが整合 | 単一の合流ソース。映像とのリップシンク時のみ | 同 P1 |
| **配信エンコーダー側 Audio Bitrate / トラック** | 単一トラック（既定 Track 1） | B1 を Track 1、B2（マイク素）を Track 2 にしてアーカイブ用 multi-track（[KB Multiple Audio Track Recording](https://obsproject.com/kb/multiple-audio-track-recording-guide)） | 単一トラック | 単一トラック（16ch 構成で別経路を立てるなら別ソースで Track 分け） |
| **エコーループ要警戒ポイント** | グローバル Desktop Audio とシーン音声入力キャプチャを重ねない（KB 明示） | Audio Monitoring Device に `Voicemeeter Input` を選ばない | 同左に加え、声変換ホスト monitor 先と OBS Audio Monitoring Device を**同じ物理デバイスに**しない（同じならどちらかをミュート） | Audio Monitoring Device に Multi-Output Device 自体を選ばない |

### 5.1 P1 × OBS: シングル仮想ケーブル経路（Windows / macOS、最小構成）

```
[マイク (物理入力)]
        │
        ▼
[声変換ホスト (w-okada VCClient 等)]
   output ──▶ [仮想ケーブル: VB-CABLE Input / BlackHole 2ch]
   monitor ──▶ [物理ヘッドホン (WASAPI / ASIO / CoreAudio 直接)]
                                │
                                ▼
              [仮想ケーブル: CABLE Output / BlackHole 2ch]
                                │
                                ▼
        ┌─────────────────────────────────┐
        │ OBS Studio                       │
        │  ┌─ Sources ──────────┐          │
        │  │ Audio Input Capture │ ◀─── ここでデバイス選択
        │  │  device: CABLE Output│          │
        │  │  Monitor: Off        │          │
        │  └──────────────────────┘          │
        │  ┌─ Audio Mixer ──────┐            │
        │  │ Volume / Mute / FX │            │
        │  └────────────────────┘            │
        │  ┌─ Output ───────────┐            │
        │  │ Track 1 → Encoder │            │
        │  └────────────────────┘            │
        └─────────────────────────────────┘
                                │
                                ▼
                  [配信先 / アーカイブ]
```

- **OBS 音声入力キャプチャ ソース**: デバイス = `CABLE Output (VB-Audio Virtual Cable)`（Win） / `BlackHole 2ch`（macOS）。
- **Settings → Audio**: Sample Rate = 48 kHz / Channels = Stereo。グローバル Desktop Audio・Mic/Aux は**いずれも無効化**してシーン側の音声入力キャプチャ 1 本に集約。
- **モニタリング**: 声変換ホスト monitor が物理ヘッドホンに直接出ているので OBS 側 Monitor は全ソース Off。Audio Monitoring Device は未設定でよい。
- **Sync Offset**: 単一ソース。映像キャプチャとのリップシンクが必要になったときだけソース側に正のオフセットを入れる。

### 5.2 P2 × OBS: VoiceMeeter ハブ経路（Windows、複数音源を混ぜる）

```
[マイク] ─▶ [声変換ホスト] ──▶ [Voicemeeter Input / AUX Input (仮想入力)]
                                        ▼
[ゲーム音 / BGM 等] ───────────────▶ [Voicemeeter mixer]
                                        │
                          ┌─────────────┼──────────────┐
                          ▼             ▼              ▼
                  [Bus B1 (仮想)]  [Bus B2 (仮想)]  [Bus A1 (物理)]
                          │             │              │
                          ▼             ▼              ▼
                ┌────────────────────────┐    [物理ヘッドホン]
                │ OBS Studio              │
                │  Audio Input Capture #1 │ ◀── Voicemeeter Out B1
                │   Monitor: Off          │
                │  Audio Input Capture #2 │ ◀── Voicemeeter Out B2 (任意)
                │   Monitor: Off          │
                │  Audio Mixer            │
                │  Output Track 1 (B1)    │
                │  Output Track 2 (B2)    │ ← multi-track 録画時
                └────────────────────────┘
                          │
                          ▼
                    [配信先 / アーカイブ]
```

- **OBS 音声入力キャプチャ ソース**:
  - 既定経路: 1 ソース = `Voicemeeter Out B1`（声変換マイク + ゲーム音を Voicemeeter で合流済み）
  - アーカイブ用 multi-track 録画する場合: 2 ソース目 = `Voicemeeter Out B2`（マイク素のみを別 Bus で送る）
- **Settings → Audio**: Sample Rate = 48 kHz。Voicemeeter 側 A1 SR と必ず一致（[VAD §3.2 / §3.3](./virtual-audio-devices.md#32-voicemeeter-banana) 仕様）。グローバル Desktop Audio は無効化（Voicemeeter 経由で B1 に集約済みのため）。
- **モニタリング**: Voicemeeter Bus A1 が物理ヘッドホンに出ているので、OBS 側 Audio Monitoring Device は基本未設定 / 全ソース Monitor Off。OBS 側で別途モニタしたいときだけ Audio Monitoring Device に**物理ヘッドホン**を選び、対象ソースだけ Monitor Only にする（**`Voicemeeter Input` 系の仮想入力は絶対に選ばない**）。
- **Sync Offset**: ソース内同期は Voicemeeter mixer 側の Patch Insert / Delay で先に詰める。OBS 側はソース間の最終調整に最小限だけ使う。
- **配信エンコーダー**: B1 を Track 1、B2 を Track 2 に割って multi-track 録画する構成は [KB Multiple Audio Track Recording Guide](https://obsproject.com/kb/multiple-audio-track-recording-guide) 範疇。

### 5.3 P3 × OBS: monitor 分離経路（Windows、低遅延モニタリング Tip）

```
[マイク] ─▶ [声変換ホスト]
                 │
                 ├─ output  ──▶ [VB-CABLE / VoiceMeeter Input] ──┐
                 │                                                 │
                 └─ monitor ──▶ [WASAPI / ASIO 物理出力]           │
                                       │                           │
                                       ▼                           ▼
                              [物理ヘッドホン]            ┌────────────────────┐
                                                          │ OBS Studio          │
                                                          │ Audio Input Capture │
                                                          │   device: 仮想ケーブル
                                                          │   Monitor: Off      │
                                                          │ Audio Monitoring    │
                                                          │   Device: 未設定    │
                                                          └────────────────────┘
```

- **OBS 音声入力キャプチャ ソース**: デバイス = `CABLE Output (VB-Audio Virtual Cable)` または `Voicemeeter Out B1`。
- **Settings → Audio**: Sample Rate = 48 kHz。声変換ホスト VC Client SR と仮想ケーブル側 SR を 3 段で一致（w-okada §5.4 の 3 デバイス SR 一致制約と整合）。
- **Audio Monitoring Device / モニタリング**: 全ソース **Monitor Off**。声変換ホスト monitor が物理デバイスに直接出ているため、OBS 側でモニタを増やすと**二重モニタ**でエコーになる。Audio Monitoring Device は触らないか、声変換ホストの monitor 先**とは別の**物理出力を割り当てる。
- **Sync Offset**: 単一の合流ソース。映像とのリップシンク時のみ使う。
- **背景**: w-okada §5.2 公式 Tip「Input, Monitor を WASAPI デバイス、output を任意にすることで遅延をかなり少なく運用することができました」を OBS 側で受け止めるレシピ。OBS 側のモニタ経路を**経路から外す**ことで、[Issue #4531](https://github.com/obsproject/obs-studio/issues/4531) のモニタ側バッファ蓄積問題からも遠ざかる。

### 5.4 P4 × OBS: macOS BlackHole + Multi-Output 経路（macOS、自分用モニタリング併用）

```
[マイク] ─▶ [声変換ホスト]
                 │
                 └─ output ──▶ [Aggregate / Multi-Output Device]
                                       │
                                       ├──▶ [Built-in Output (Top)] ──▶ [物理ヘッドホン]
                                       │
                                       └──▶ [BlackHole 2ch / 16ch] ──▶ ┐
                                                                          │
                                                                          ▼
                                                          ┌─────────────────────────┐
                                                          │ OBS Studio (macOS)        │
                                                          │ Audio Input Capture       │
                                                          │   device: BlackHole 2ch  │
                                                          │   Monitor: Off            │
                                                          │ Audio Monitoring Device:  │
                                                          │   Built-in Output         │
                                                          │   （Multi-Output 自体は選ばない）│
                                                          └─────────────────────────┘
```

- **OBS 音声入力キャプチャ ソース**: デバイス = `BlackHole 2ch`（基本）。アプリ別に独立経路を切るなら `BlackHole 16ch` で 2ch ペアごとに別ソースを立てる。
- **Settings → Audio**: Sample Rate = 48 kHz。Audio MIDI Setup で BlackHole / Built-in / Multi-Output Device を**全て 48000 Hz に揃える**（[VAD §3.4](./virtual-audio-devices.md#34-blackhole) Multi-Output Device 構成の前提）。
- **モニタリング**: 全ソース Monitor Off。Audio Monitoring Device は **Built-in Output（または別の物理ヘッドホン）**。**Multi-Output Device 自体を選ばない**（OBS が拾った音を Multi-Output 経由で再び BlackHole に流すループになる可能性、[§4.2.2](#422-モニタリング設定をどれにするか3-3-モード) 警告）。
- **Sync Offset**: 単一ソース。映像とのリップシンク時のみ。
- **背景**: macOS 30 + macOS 13+ で[§3.3 macOS Audio Capture Source](#33-音声出力キャプチャaudio-output-capture--デスクトップ音声) を使う場合、デスクトップ音声側は BlackHole を経由せず OBS が直接拾える。**声変換 output だけを BlackHole 経由で受ける**シンプルな経路として P4 を組むのが本書最終確認日時点の推奨整合。OBS 30 未満や旧 macOS では BlackHole + Multi-Output Device で**全部まとめて**経路を組む構成になる（[VAD §5.4 P4](./virtual-audio-devices.md#54-p4-macos-blackhole--multi-output-経路macos自分用モニタリング併用) と一致）。

### 5.5 パターン選択の指針（OBS 視点）

| 必要要件（OBS 側） | 選ぶパターン |
| --- | --- |
| 音声入力キャプチャ 1 ソースで配信音声が完結すれば良い | P1 |
| ゲーム音 + マイク + 声変換を 1 ソース、加えてアーカイブ用にマイク素を別 Track へ | P2（B1 + B2 の multi-track） |
| OBS 側のモニタ経路をオフにして声変換ホスト側 monitor を活かしたい（[Issue #4531](https://github.com/obsproject/obs-studio/issues/4531) 回避を含む） | P3 |
| macOS で BlackHole 経由のシングルソース + Built-in モニタ | P4 |
| アプリ別経路を 3 本以上 OBS の別ソースに渡したい（Win） | [VAD §5.5](./virtual-audio-devices.md#55-パターン選択の指針) と同じく Potato で組み、OBS 側は B1 / B2 / B3 / VAIO3 を別ソース化 |

## 6. 遅延ハンドリング

OBS Studio の音声経路で「遅延」を扱う設定軸は次の 4 つ。本書は**公式 KB / GitHub Wiki / Forum / Issues に書かれている範囲のみ**を整理し、実測値・他ツールとの遅延比較は [CLAUDE.md](../../CLAUDE.md) 方針に従い書かない。

### 6.1 Sync Offset（オーディオ同期オフセット）の適用ポリシー

- **設定箇所**: Edit → Advanced Audio Properties → "Sync Offset (ms)"（**ソース単位**、ミリ秒）。入口は [§3.6](#36-オーディオ同期オフセットsync-offset--audio-delay) / [KB Audio Mixer Guide](https://obsproject.com/kb/audio-mixer-guide)。
- **適用先**: **出力エンコード経路のみ**。Audio Monitoring 経路には適用されない（Forum 通則。KB に独立記事は無いため、本書では **Forum 通則**として扱う）。結果として、**OBS 側 Monitor を使うと「自分が聴く音」と「配信に乗る音」のリップシンクがずれる**ことを前提に設計する必要がある。
- **正のオフセットの意味（Forum 通則）**: 該当ソースを**遅らせて**出力に送る。例えばゲームキャプチャ映像が音声より遅れて見える → ゲーム音声ソースに正の Sync Offset を入れて音を遅らせ、映像とリップシンクを合わせる。
- **負のオフセットの意味**: KB / GitHub Wiki に**公式定義がない**。Forum では「他ソースを先に出すような効果は実装上得にくい」との見解が散見するが、本書では**未確認**として扱う（[§3.6](#36-オーディオ同期オフセットsync-offset--audio-delay) 未確認事項）。**負のオフセットに依存した経路設計はしない**のが安全側。
- **実測の取り方の公式記述**: KB に手順記述なし。Forum / コミュニティでは「映像と音声の同期テスト動画を流して目視 / 波形で詰める」「ヘッドホンに `Monitor Only` で出してから配信録画でズレを確認」が一般則として言及されるが、これらは**公式手順ではない**ため本書では参考扱い。
- **既知の不具合**: [Issue #11656](https://github.com/obsproject/obs-studio/issues/11656) — Advanced Audio Properties ウィンドウを再オープンすると Sync Offset 値がリセットされる事例。本書最終確認日時点で**未クローズ**。Sync Offset を詰めた後は**シーンコレクションのバックアップ**を取り、再現したら Issue で確認する。

### 6.2 OS オーディオ API とのバッファ整合（ASIO / WASAPI / CoreAudio / PA・PW）

- **ASIO 入力**: [§3.1](#31-音声入力キャプチャaudio-input-capture) / [§4.2.1](#421-ゲーム--アプリ音声をどう拾うか音声入力キャプチャ-vs-アプリケーション音声キャプチャ) で示した通り **OBS 本体ネイティブ非対応**（GPL-2.0 と Steinberg ASIO SDK 規約の非互換が公式 Forum 説明）。サードパーティプラグイン `Andersama/obs-asio` または **VoiceMeeter Insert ASIO 経由**で受ける構成になる。VoiceMeeter Banana / Potato の ASIO バッファサイズ（**256 推奨 / 512 でより安定**、[VAD §3.2 / §3.3](./virtual-audio-devices.md#32-voicemeeter-banana)）が経路全体の最小バッファ要件を決める。
- **WASAPI（Windows）**: OBS の `Audio Input Capture` ソースの裏側 API。バッファサイズや排他モード切替の **OBS UI からの直接設定 UI は無い**（Sources 側）。Windows サウンド設定の「デバイスのプロパティ → 詳細」の SR / ビット深度は OBS の SR と一致させる（[§3.5](#35-グローバル音声サンプリングレートaudio-settings--sample-rate) KB 公式手順）。
- **CoreAudio（macOS）**: OBS は OS の CoreAudio 経由でデバイスにアクセス。Multi-Output Device 構成は **drift correction を Top の Built-in 以外に有効化**することが [VAD §3.4](./virtual-audio-devices.md#34-blackhole) BlackHole FAQ の公式手順。
- **PulseAudio / PipeWire（Linux 参考）**: 本ラボのメイン環境ではないため、本書では立ち入らない（[§1.2](#12-対象-obs-バージョン) / [§1.4](#14-obs-studio-との接続パターンと本書で呼ぶ範囲)）。

### 6.3 OBS 内部の音声バッファリング

- **Max Audio Buffering**: Forum / GitHub PR 一次情報では**約 1 秒（1000 ms）が上限**として言及される。これはアプリケーション音声キャプチャ等の音声ソース側の取り回しに影響する内部上限であり、**KB 上の独立した解説記事は本書最終確認日時点で未特定**（本書では Forum 通則扱い）。
- **モニタ経路と出力経路は別バッファ**（Forum 通則）: [§3.4](#34-音声モニタリング設定audio-monitoring) の通り Sync Offset は出力側のみに適用される。長時間運用でモニタ側が膨張して映像と非同期になる事例が [Issue #4531](https://github.com/obsproject/obs-studio/issues/4531) に**未解決**で報告。OBS 側 Monitor を使う運用では、**長時間配信時に再起動で切り戻す運用**を念頭に置くか、[§5.3 P3](#53-p3--obs-monitor-分離経路windows低遅延モニタリング-tip) のように OBS 側 Monitor を使わない設計にする。
- **OBS 30 系で導入された Audio Capture / Track 数の上限拡張**: [KB Multiple Audio Track Recording Guide](https://obsproject.com/kb/multiple-audio-track-recording-guide) を参照。Track 増による録画ファイルへの負荷は本書スコープ外。

### 6.4 ベンダー公称値 / 公式ドキュメント記載値と本ラボ実測の分離ポリシー

[CLAUDE.md](../../CLAUDE.md) 方針および前段の [VAD §1.7 記述ルール](./virtual-audio-devices.md#2-評価項目) と統一する:

- **「OBS 公式 KB / GitHub Wiki / Forum / Issues に書かれている数値・推奨値」**は出典付きで明示する（例: KB Audio Sources の "set the global Sample Rate to 48 kHz"、Voicemeeter ASIO バッファ "256 推奨 / 512 でより安定"、Speex の Suppression Level 既定 "-30 dB"）。これらを本書では **公式記述**として扱う。
- **本ラボでの実測値**は本書には**書かない**。声変換ホスト × OBS × 仮想ケーブルの組合せでの実測は、後続の [experiments/](../../experiments/) 配下で個別タスクとして取り、本書 §5 のパターン番号（P1〜P4）と紐付けて記録する。
- **コミュニティ通説 / Forum 一次情報のうち、KB に独立記事が無いもの**（例: Sync Offset の適用先がモニタに作用しない件、Max Audio Buffering の約 1 秒上限）は **「Forum 通則」**として明示し、公式記述と区別する。
- **第三者ベンダーの公称遅延値**（NVIDIA Broadcast / Krisp の公称遅延等）はシリーズ第 3 弾の射程。本書では引用しない（[§1.4](#14-obs-studio-との接続パターンと本書で呼ぶ範囲) スコープ通り）。

### 6.5 P1〜P4 ごとの遅延着目点

[§5](#5-配信用途での典型構成p1p4--obs-レシピ) の各経路で「遅延を詰めるときに最初に効く設定」をまとめる:

| パターン | 第一に詰める設定 | 補助的に効く設定 |
| --- | --- | --- |
| P1 | 声変換ホストの chunk size / extra（[w-okada §5](./w-okada-voice-changer.md#5-io-構成) 側） / 仮想ケーブル SR を 48 kHz に統一（[§3.5](#35-グローバル音声サンプリングレートaudio-settings--sample-rate)） | OBS 側 Sync Offset は最後の微調整で使う |
| P2 | Voicemeeter ASIO バッファ（256/512、[VAD §3.2](./virtual-audio-devices.md#32-voicemeeter-banana)） / A1 SR と OBS / 仮想ケーブル / 声変換ホストの 4 段一致 | OBS 側 Sync Offset / Voicemeeter Patch Insert Delay |
| P3 | 声変換ホスト monitor を WASAPI / ASIO 直接で物理出力に出す（w-okada §5.2 公式 Tip） / OBS 側 Monitor は全ソース Off | 仮想ケーブルバッファ |
| P4 | Multi-Output の drift correction を Built-in 以外に有効化（[VAD §3.4](./virtual-audio-devices.md#34-blackhole) BlackHole FAQ） / Audio MIDI Setup の SR を 48 kHz で全揃え | OBS 側 Sync Offset |

「OBS 側だけで遅延を詰める」発想ではなく、**経路上のどの段が支配的か**を [§5](#5-配信用途での典型構成p1p4--obs-レシピ) のレシピで切り分けてから、最後に OBS の Sync Offset で微調整する、というのが本書の前提。

## 7. 上流ドキュメントへの反映方針

本書の成果物を、これまで「OBS 側は別タスクで埋める」「OBS の具体的接続は未確認」で止まっていた箇所に反映する。本 Phase 3 で**本書から見て参照されるべき側の更新を実施した上で**、それぞれの差分要旨を以下に残す（後から経緯を辿るための記録）。

### 7.1 voice-changer-types §2 補助カテゴリ「周辺ツール」への反映

**Before**: 「配信ソフト・通話ソフト（最終的な配信先） — 代表例: OBS Studio, Streamlabs Desktop、各種通話アプリ（Discord 等）」と**名前出しのみ**。

**After**: 名前出しの直後に本書へのリンクと「OBS Studio 本家のみ。Streamlabs Desktop 等派生版は §1.3 参照」の補足を追記する。

更新後の文面方針（[voice-changer-types §補助カテゴリ](./voice-changer-types.md#補助カテゴリ-周辺ツール)）:

> 配信ソフト・通話ソフト（最終的な配信先）
>   - 代表例: OBS Studio, Streamlabs Desktop、各種通話アプリ（Discord 等）
>   - OBS Studio（本家）の音声入力キャプチャ・モニタリング・遅延ハンドリングは [obs-studio.md](./obs-studio.md) で横断棚卸し（最終確認日 2026-05-12 / OBS Studio 32.1.2）。Streamlabs Desktop / OBS.Live 等の派生版は同 [§1.3](./obs-studio.md#13-派生版関連プロダクトの線引き) で参考扱い

### 7.2 voice-changer-types §4 評価軸「入出力構成」「エコシステム」行への反映

「入出力構成」「エコシステム」両行で本書の参照先を増やす:

- 「入出力構成」行末尾に **「配信ソフト（OBS Studio）側の経路設計は [obs-studio.md §5](./obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) の P1〜P4 × OBS レシピを参照」**を追記。
- 「エコシステム」行末尾に **「OBS Studio との接続パターン（音声入力キャプチャ / モニタリング / Sync Offset）の整理は [obs-studio.md](./obs-studio.md)」**を追記。

### 7.3 w-okada-voice-changer.md §6 配信ソフト連携への反映

[§6.2](./w-okada-voice-changer.md#62-obs--配信ソフトの直接言及) の「OBS Studio との接続パターンを名指しで説明する公式チュートリアルは見つかっていない（未確認）」の状態は変わらないが、**本ラボ側の補完が完成した旨**を §6.3 で示す:

- §6.3 冒頭の「（後続の OBS 接続調査タスクで上書き予定）」を削除し、**本書 §5 P1〜P4 × OBS レシピへの参照**に置き換える。
- §6.3 の本文（VC Client output → 仮想オーディオデバイス → OBS 音声入力キャプチャ／monitor は WASAPI / ASIO 直接）の構成自体は本書 §5 の前提と一致しているので、本文末尾に「本書 [obs-studio.md §5.3 P3](./obs-studio.md#53-p3--obs-monitor-分離経路windows低遅延モニタリング-tip) として経路図 + OBS レシピ化済み」を追記。
- 末尾の「→ ここの整合性確認・実機検証は、後続の OBS Studio との接続パターンまとめタスクと紐付ける」を、**「整合性確認は [obs-studio.md](./obs-studio.md)（最終確認日 2026-05-12 / OBS Studio 32.1.2）で完了。実機検証は experiments タスクで個別に取る」**に置き換え。

### 7.4 w-okada-voice-changer.md §9.1 未確認事項への反映

§9.1 の「**OBS Studio との具体的な接続パターン**（VC Client の output → 仮想オーディオデバイス → OBS の音声入力キャプチャ） → `TODO.md` の「OBS Studio との接続パターンまとめ」で実機検証」の項目を:

> **OBS Studio との具体的な接続パターン**（VC Client の output → 仮想オーディオデバイス → OBS の音声入力キャプチャ） → [obs-studio.md §5 P1〜P4 × OBS レシピ](./obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) で公式情報源ベースの整理は完了（最終確認日 2026-05-12）。残るのは**実機での挙動確認**で、experiments タスクとして個別に取る

に更新する。

### 7.5 experiments/w-okada-voice-changer/_template.md §6 への反映

§6 配信ソフト連携の表に **「OBS Studio 側のレシピは本書 §5 のパターンに紐付ける」**前提を入れる:

- 「経路パターン」行の参照先に **本書 [obs-studio.md §5](./obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ)** を追記（virtual-audio-devices.md §5 と並記）。
- 「配信ソフト側の音声入力キャプチャ設定（サンプリングレート / モノラル・ステレオ）」行に**本書 [§5.0 設定レシピ表](./obs-studio.md#50-p1p4--obs-設定レシピ表) の値を引用する形式**を案内（パターン番号と OBS Settings → Audio の SR を実機で記入）。
- 「monitor デバイスの繋ぎ先」行に**本書 [§4.2.2 モニタリング設定をどれにするか](./obs-studio.md#422-モニタリング設定をどれにするか3-3-モード) の判断軸**を案内（OBS 側 Audio Monitoring Device に何を選んだか / 各ソースの Monitor Off/Only/Output のどれにしたか）。

### 7.6 virtual-audio-devices.md §5 P1〜P4 への反映

各パターン末尾に **「OBS 側の設定は [obs-studio.md §5.X](./obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) 参照」**を追記する:

- §5.1 P1 末尾 → 本書 §5.1 へ
- §5.2 P2 末尾 → 本書 §5.2 へ
- §5.3 P3 末尾 → 本書 §5.3 へ
- §5.4 P4 末尾 → 本書 §5.4 へ

これで [VAD §6.5](./virtual-audio-devices.md#65-反映の境界本書で扱わない上流) で「OBS 側は次タスクのスコープ」と明示していた境界が、双方向リンクで閉じる。

### 7.7 反映の境界（本書で扱わない上流）

- **ノイズ抑制 / ゲート系プラグインの選定軸**（NVIDIA Broadcast / Krisp / RNNoise / Speex の比較） → **配信周辺ツール調査シリーズ第 3 弾**として [§8](#8-未確認事項--後続タスク) に残す。本書では voice-changer-types §2 補助カテゴリの「ノイズ抑制 / ゲート」レイヤーには触れない（[§1.4](#14-obs-studio-との接続パターンと本書で呼ぶ範囲) スコープ通り）。
- **通話アプリ Discord / Zoom 取り回し** → 同じく独立タスク候補として [§8](#8-未確認事項--後続タスク) に残す。voice-changer-types §2 補助カテゴリの「通話ソフト」側は、本書では Forum 通則レベルの言及にとどめる。
- **Streamlabs Desktop / OBS.Live 等の派生版** → [§1.3](#13-派生版関連プロダクトの線引き) で参考扱いとして固定済み。差分調査は [§8](#8-未確認事項--後続タスク) に残す。

## 8. 未確認事項 / 後続タスク

### 8.1 §3 各エントリで残った未確認事項（本書内で再掲）

[§3 OBS Studio の音声系機能エントリ](#3-obs-studio-の音声系機能エントリ) の各「未確認事項」を、後で個別に裏取りすべき粒度で集約する。実運用で困った時点で個別タスクへ昇格する。

- **§3.1 音声入力キャプチャ**: ソース側の chs 選択 UI 仕様（Mono / Stereo / マルチ）／Apple Silicon・ARM Windows での挙動差分／リサンプリングの実装位置（DSP 経路のどこで再サンプルされるか）
- **§3.2 アプリケーション音声キャプチャ**: WGC が要件とするプロセス特性網羅（UWP / Win32 / 子プロセス音声）／macOS Window・Game Capture の `Capture Audio (BETA)` 将来対応の公式ロードマップ
- **§3.3 音声出力キャプチャ**: macOS Sonoma (14.x) / Sequoia (15.x) 以降での挙動（KB は Ventura までの言及）／macOS Audio Capture Source の「特定アプリ」モードの内部実装詳細
- **§3.4 音声モニタリング**: モニタ経路バッファサイズと処理段の公式仕様（[Issue #4531](https://github.com/obsproject/obs-studio/issues/4531) 関連、未解決）／複数モニタリングデバイスへの同時出力サポート予定
- **§3.5 グローバル SR**: 88.2k / 96k / 176.4k / 192k を Settings → Audio で選択可能かの公式 UI 仕様（KB は 44.1 / 48 のみ言及）／リサンプリングアルゴリズムの公式仕様
- **§3.6 Sync Offset**: 正負の意味の公式定義（KB に独立記事なし、Forum 通則で補う状態）／ASIO・WASAPI・CoreAudio バッファ整合との関係／モニタ側にも独立した遅延補正を入れる UI / API の有無（[Issue #11656](https://github.com/obsproject/obs-studio/issues/11656) 未クローズ）
- **§3.7 音声フィルタ**: 各内蔵 Noise Suppression（RNNoise / Speex / NVIDIA NR）の実測遅延・CPU 負荷・音質比較は **配信周辺ツール調査シリーズ第 3 弾**へ分離。NVIDIA Noise Removal の対応 GPU / Broadcast SDK バージョン要件の公式網羅記述／VST 3 対応の公式ロードマップ

### 8.2 後続タスク（`TODO.md` に上げるべき項目）

本書を前提に次に着手する候補。優先度の高いものから:

- **[中] 配信周辺ツール調査シリーズ第 3 弾: ノイズ抑制 / ゲート系の棚卸し**（NVIDIA Broadcast / Krisp / RNNoise / Speex / NVIDIA Audio Effects SDK プラグイン等）。本書 §3.7 で **OBS 内蔵フィルタの列挙**までしか踏み込まないため、選定軸自体を別タスクで掘る。本書および [virtual-audio-devices.md](./virtual-audio-devices.md) と同じ「公式情報源ベースの横断棚卸し」の立て付けで書ける見込み。voice-changer-types §2 補助カテゴリの「ノイズ抑制 / ゲート」レイヤーを埋める形になる。
- **[低] 通話アプリ Discord / Zoom 固有の仮想デバイス取り回し**（[VAD §7.3](./virtual-audio-devices.md#73-後続タスクtodomd-に上げるべき項目) と同じく独立タスク候補）。w-okada §6.1 で公式言及がある領域。本書では OBS Studio 単体への接続までを扱った（[§1.4](#14-obs-studio-との接続パターンと本書で呼ぶ範囲)）ため、通話アプリ側の音声入出力デバイス制約・NSChannel 数・ノイズ抑制の重複適用などは別タスクで掘る。
- **[低] Streamlabs Desktop / OBS.Live 等派生版の差分調査**（[§1.3](#13-派生版関連プロダクトの線引き) 参照）。OBS 本家との UI / 内部音声処理パスの差分が見えた時点で個別タスク化。本書の §5 P1〜P4 レシピが派生版でそのまま当てはまるかの検証も含む。
- **[低] OBS プラグイン系の深掘り**（StreamFX / obs-vst / NVIDIA Audio Effects SDK プラグイン等）。シリーズ第 3 弾（ノイズ抑制 / ゲート系）の射程と重なる部分が大きいため、第 3 弾の中で**プラグイン経由の選択肢**として併せて扱う方針。本書では §1.3 / §3.7 で境界の明示のみ。

### 8.3 シリーズ進捗との関係

配信周辺ツール調査シリーズの全体像:

- **第 1 弾（完了）**: [virtual-audio-devices.md](./virtual-audio-devices.md) — 仮想オーディオデバイス層（VB-CABLE / VoiceMeeter / BlackHole）
- **第 2 弾（本書で完了）**: [obs-studio.md](./obs-studio.md) — 配信ソフト層（OBS Studio 本家）
- **第 3 弾（候補）**: ノイズ抑制 / ゲート系の棚卸し（[§8.2](#82-後続タスクtodomd-に上げるべき項目) [中] 項目）
- **後続候補**: 通話アプリ Discord / Zoom、Streamlabs Desktop 等派生版、OBS プラグイン

第 3 弾を `TODO.md` に起票する際は、本書 §3.7 / §4.1 の「音声フィルタ」列を出発点として、同じ立て付け（§1 範囲定義 → §2 評価項目 → §3 個別エントリ → §4 横断棚卸し → §5 配信用途の典型構成 → §6 上流反映 → §7 後続）で書ける見込み。
