# VCClient と Beatrice の違い

> [voice-changer-types](./voice-changer-types.md) 上の位置付けは両者で**階層が違う**ため、本ページは「比較対象が違う」ことを解きほぐすことに集中する。
>
> 個別の詳細は [w-okada-voice-changer.md](./w-okada-voice-changer.md) / [beatrice.md](./beatrice.md) を参照。本ページは既存 spec の引用とリンクで構成し、新規調査は含まない（[CLAUDE.md](../../CLAUDE.md) 方針）。実測値・断定的性能評価は書かない。
>
> **想定読者:** [overview.md](./overview.md) / [README.md](./README.md) などから入って、「VCClient」と「Beatrice」が同列に並ぶように見えて違いが分からない、と感じた人。

## 1. そもそも比較対象が違う

**VCClient と Beatrice は階層が違う**。並べて比較できる関係ではない。

| | **VCClient（w-okada/voice-changer）** | **Beatrice** |
| --- | --- | --- |
| 一言で | リアルタイム声変換の **実行ホスト** | 声変換 **アルゴリズム / モデル** |
| 何が中にあるか | マイク入力 / 出力 / monitor の IO 配線 / モデル切替 UI / 前処理・後処理 | コンテンツ抽出 + F0 推定 + 波形合成のニューラルネット本体 |
| [voice-changer-types](./voice-changer-types.md) 上の位置 | **§1.4 ハイブリッド / §2.1 ローカル OSS**（モデル形態はロードするモデル依存） | **§1.3 ニューラル変換（コンテンツ表現 + 話者条件付け系）/ §2.1 ローカル OSS / §3.1 話者依存** |
| 単体で何ができるか | **モデルを載せないと何もしない**（ホストだけ） | **何かしらのホストから呼ばれて初めて動く**（公式 VST 単体・VCClient 経由・派生クライアント経由のどれか） |

**1 行イメージ:** **「VCClient は土俵、Beatrice は出場するレスラーの 1 人」**。VCClient という土俵の上には RVC / so-vits-svc / MMVC / DDSP-SVC などの他のレスラーも上がれる（§2 参照）。逆に Beatrice は VCClient 以外の土俵（**公式 VST 単体**、**派生クライアント**）にも上がれる（§4 参照）。

## 2. VCClient（w-okada/voice-changer） = 実行ホスト

> 詳細は [w-okada-voice-changer.md §1〜§5](./w-okada-voice-changer.md)。

### 2.1 何をするソフトか

[w-okada-voice-changer.md §1](./w-okada-voice-changer.md#1-概要) より、公式 README の表現は **「AI を用いてリアルタイム音声変換を行うソフトウェア」**。本ラボでは**実行ホスト**として整理している。具体的にホスト側が担うのは:

- **入出力 IO の配線**（[§5](./w-okada-voice-changer.md#5-io構成)）
  - Client device mode（ブラウザ getUserMedia 経由）と Server device mode（OS デバイス直接）の 2 系統
  - Server device mode では **input / output / monitor の 3 デバイス分離**（v.1.5.3.7〜）と WASAPI / ASIO への monitor 直接出力で低遅延運用ができる
- **モデルの切替 UI**（[§3](./w-okada-voice-changer.md#3-対応モデル一覧と切替の仕組み)）— モデルスロット UI から複数モデルを差し替え
- **共通の前処理・後処理**（[§4](./w-okada-voice-changer.md#4-前処理後処理として提供されているもの)）— Echo / Sup1 / Sup2 / Noise Gate / GAIN / TUNE / CHUNK / EXTRA
- **配信ソフトへの繋ぎ目**（[§6](./w-okada-voice-changer.md#6-配信ソフトobs等との接続パターンの公式言及)）— 仮想オーディオデバイス経由で OBS / Discord / Zoom に流す

### 2.2 内蔵していないもの

- **声変換アルゴリズム本体**（PhoneExtractor / WaveGenerator のような実装はホスト側には無い）
- **モデルの重み**（ユーザーが配布元から入手してモデルスロットに読み込む。[§7.3](./w-okada-voice-changer.md#73-本ラボで扱う際の注意点実運用観点) 参照）

### 2.3 ロードできるモデル

[w-okada-voice-changer.md §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) の表より:

| モデル | v.2 | v.1 (legacy) |
| --- | --- | --- |
| RVC (v.2 / v.1) | ✅ | ✅ |
| **Beatrice v2** | **✅** | — |
| **Beatrice v1** | — | **✅ (Windows のみ)** |
| MMVC | — | ✅ |
| so-vits-svc | — | ✅ |
| DDSP-SVC | — | ✅ |

→ Beatrice は VCClient がロードできる **複数モデルの 1 つ**であり、専用のホストではない。

## 3. Beatrice = 声変換アルゴリズム / モデル

> 詳細は [beatrice.md §1〜§3](./beatrice.md)。

### 3.1 「Beatrice」が指す 4 つのレイヤ（超要約）

[beatrice.md §1.1〜§1.4](./beatrice.md#1-概要--beatriceが指す-4-つのレイヤ) で 4 レイヤに分けて整理されている。本ページでは**超要約**のみ:

| レイヤ | 何 | 配布元 |
| --- | --- | --- |
| **アルゴリズム / モデル** | Project Beatrice が開発した声変換アルゴリズム本体。PhoneExtractor + PitchEstimator + WaveGenerator の 3 モジュール（[beatrice.md §2.1](./beatrice.md#21-3-モジュール--識別器構成beatrice-2公式トレーナー-readme-で確認できる範囲)） | — |
| **公式系リポジトリ** | 公式 VST バイナリ / 公式 VST ソース / 公式トレーナー / 公式モデル配布リスト | [prj-beatrice.com](https://prj-beatrice.com) / [`prj-beatrice/beatrice-vst`](https://github.com/prj-beatrice/beatrice-vst) / [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer) |
| **配布チェックポイント** | キャラクターエディション（つくよみちゃん / 刻鳴時雨 / OLUNE）、Beatrice JVS Corpus Edition（v1 系）など | 公式サイト / w-okada/voice-changer 同梱 |
| **バージョン** | Beatrice 1（v1）と Beatrice 2（v2）。**モデル形式は非互換** | — |

### 3.2 配布形態の特徴 — VST プラグイン

[beatrice.md §2.3](./beatrice.md#23-入出力と動作モデルの位置関係公式-vst-としての形) より、**Beatrice 2 公式の配布形態は VST / VST3 プラグイン**で、**DAW / VST ホストから呼ばれる前提**で作られている。リポジトリ名も `beatrice-vst`。

これが VCClient との関係に効く:

- **DAW / VST ホストでも動かせる**（公式 VST 単体経路、§4 A）
- **VCClient からも呼べる**（[beatrice.md §4.1](./beatrice.md#41-公式-vst--vcclient--beatrice-client-は同じ推論ライブラリ公式-q-の明言) の公式 Q&A で「公式 VST / VCClient / beatrice-client は**同じ推論ライブラリ**を使う」と明言）

### 3.3 公式が標榜する特徴（数値の根拠は引用で）

[beatrice.md §1.1](./beatrice.md#11-アルゴリズム--モデルとしての-beatrice) より、公式サイト [prj-beatrice.com](https://prj-beatrice.com) は Beatrice 2 を:

- **CPU シングルスレッド動作 / 約 35 MB / 約 50 ms 遅延**（**50 ms は公式サイト上で「外部測定の引用」として書かれているもの**で本ラボの実測値ではない）
- 対応 OS: **Windows® 10/11**、CPU: Intel® Core™ 4th gen 以降 / N100

と紹介している。RVC / so-vits-svc が GPU 前提で語られるのと対照的（[beatrice.md §2.3](./beatrice.md#23-入出力と動作モデルの位置関係公式-vst-としての形) / §7）。

## 4. 3 つの使い方パターン（同じ Beatrice を使っても起動経路が違う）

[beatrice.md §4.1](./beatrice.md#41-公式-vst--vcclient--beatrice-client-は同じ推論ライブラリ公式-q-の明言) で公式 Q&A が明言しているとおり、**3 経路はどれも同じ推論ライブラリを呼ぶ**。つまり**変換音そのものは原理的に同じ**で、違うのは**ホストの責任分界**と**運用上できることの範囲**。

| 経路 | ホスト | モデル | 何が違うか |
| --- | --- | --- | --- |
| **A) 公式 VST 単体** | DAW / VST ホスト | Beatrice 公式モデル | Beatrice **だけ**を使う最も素直な経路。**IO は DAW / VST ホスト側の責任**。GUI も公式 VST の Voice Morphing Mode 等が UI 露出 |
| **B) VCClient + Beatrice モデルロード** | **VCClient** | Beatrice モデル | **本ラボの配信用途で扱う主流経路**。RVC など他モデルとも切り替えられる。VCClient の **3 デバイス分離 / monitor 直接 WASAPI / 共通 UI（GAIN / CHUNK / EXTRA / Noise Gate）** が使える |
| **C) 派生クライアント** | [`aq2r/beatrice-client`](https://github.com/aq2r/beatrice-client) 等 | Beatrice モデル | 公式 Q&A でも名前が挙がる派生実装。**本ラボでは深追いしない**（[beatrice.md §1.2](./beatrice.md#12-公式系リポジトリ--配布物としての-beatrice) で言及まで） |

### ホストの責任分界の違い

経路ごとに**「同じ Beatrice モデル」を動かしても、その周りで誰が何を担当するか**が変わる。

| 項目 | A) 公式 VST 単体 | B) VCClient + Beatrice | C) 派生クライアント |
| --- | --- | --- | --- |
| マイク入力デバイス選択 | DAW / VST ホスト | VCClient（[§5](./w-okada-voice-changer.md#5-io構成)） | 派生クライアント側 |
| 出力デバイス / monitor 分離 | DAW / VST ホスト | **VCClient（3 デバイス分離 + WASAPI / ASIO 直接）** | 派生クライアント側 |
| ノイズゲート / GAIN / TUNE | DAW / VST ホストや併用プラグイン | **VCClient 共通 UI** | 派生クライアント側 |
| Beatrice 固有パラメータ（pitch / formant / オートピッチシフト / 話者マージ） | 公式 VST の UI に露出（[beatrice.md §4.3](./beatrice.md#43-推論時に-ui-露出されているパラメータ)） | **VCClient の UI に露出**（同じ意味のパラメータ。[beatrice.md §4.4](./beatrice.md#44-w-okadavoice-changer-ui-露出との対応表)） | 派生クライアント側 UI |
| 他モデル（RVC など）への切替 | **不可**（Beatrice 専用ホスト） | **可**（モデルスロット UI） | クライアントによる |

→ どの経路でも**Beatrice の音そのものは同じ**だが、**IO の柔軟性と他モデル切替の自由度**は B) VCClient 経路が一番広い。

## 5. 用語の整理

混乱しやすい用語の対応表。

| 表記 | 指すもの |
| --- | --- |
| **VCClient** / **VC Client** / **w-okada/voice-changer** | すべて同じ**実行ホスト**。リポジトリ名は `voice-changer`、現行プロダクト名は VCClient ([w-okada-voice-changer.md §1](./w-okada-voice-changer.md#1-概要)) |
| **Beatrice** | Project Beatrice 製の**声変換アルゴリズム / モデル名**。公式 VST 名としても使われる |
| **Beatrice v1 / Beatrice 1 / Beatrice 1.x** | v1 系。本ラボで参照可能なのは w-okada 同梱の **Beatrice API 1.1.0 JVS Corpus Edition**。**営利目的禁止**（[beatrice.md §5.4](./beatrice.md#54-beatrice-jvs-corpus-editionv1-系w-okadavoice-changer-経由)） |
| **Beatrice v2 / Beatrice 2 / Beatrice 2.x** | 公式サイト・公式 VST・公式トレーナーが対象とする現行。v1 とモデル形式非互換 |
| **Beatrice JVS Corpus Edition** | v1 系のモデル。w-okada/voice-changer 経由で案内されるもの。JVS Corpus 規約準拠で **営利目的禁止**（[beatrice.md §5.4](./beatrice.md#54-beatrice-jvs-corpus-editionv1-系w-okadavoice-changer-経由)） |
| **キャラクターエディション** | Beatrice 2 公式サイト配布のキャラ入りモデル（つくよみちゃん / 刻鳴時雨 / OLUNE）。**それぞれ個別 EULA**（[beatrice.md §5.3](./beatrice.md#53-公式キャラクターエディション公式サイト配布)） |
| **VST / VST3** | プラグイン形式の規格。DAW / VST ホスト（Reaper, Cubase, FL Studio など）が読み込んで使う |
| **beatrice-client** | `aq2r/beatrice-client`。Beatrice を呼ぶ**派生クライアント**。VCClient と並ぶ「公式 VST 以外の動かし方」の選択肢 |
| **モデルスロット** | VCClient の UI 上で複数モデルを差し替える仕組み（[w-okada-voice-changer.md §3.2](./w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理)） |

## 6. どう選ぶか

「Beatrice を使いたい」と思ったときに **VCClient を入れるべきか公式 VST だけで済むか** を判断するための実用ガイド。

### 6.1 こういうときは公式 VST 単体（経路 A）

- **Beatrice だけ** 使いたい（他のモデルに切り替える予定が無い）
- DAW / VST ホストを既に使っている、または用意できる
- 配布物の軽さを最大限活かしたい（公式サイトが標榜する **CPU シングルスレッド / 約 35 MB**）

### 6.2 こういうときは VCClient + Beatrice（経路 B）

- **他のモデル（RVC など）も切り替えて試したい**（→ モデルスロット UI でロード切替）
- 配信用途で **input / output / monitor の 3 デバイス分離** や **WASAPI / ASIO への monitor 直接出力** が欲しい（[w-okada-voice-changer.md §5.2](./w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537)）
- ノイズゲート / GAIN / CHUNK / EXTRA など**ホスト共通 UI** から触れる前処理を活用したい
- 仮想オーディオデバイス経由で OBS / Discord / Zoom に流す経路を本ラボの典型構成（[virtual-audio-devices.md §5](./virtual-audio-devices.md#5-配信用途での典型構成) / [obs-studio.md §5](./obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ)）に乗せたい

**Windows 10/11 で経路 B を実際に組むときの手順書** → [install-vcclient-beatrice-windows.md](./install-vcclient-beatrice-windows.md)（VCClient + Beatrice 2 + VB-CABLE + VoiceMeeter Banana + OBS Studio + ノイズ抑制（選択肢提示）+ Discord・Zoom（汎用チェックリスト）を 1 本のチュートリアルにまとめたもの）。

### 6.3 ライセンスの所在に注意

**経路によって読むべき規約が変わる**（[beatrice.md §5](./beatrice.md#5-配布形態とライセンス) / [w-okada-voice-changer.md §7](./w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点)）。

| 使うもの | 読むべき規約 |
| --- | --- |
| 公式 VST バイナリ | 公式サイト記述（統合 EULA の所在は **未確認**。[beatrice.md §5.1](./beatrice.md#51-公式-vst-本体バイナリ配布)） |
| 公式 VST ソース | **MIT License**（コードのみ） |
| 公式トレーナー / 事前学習モデル | **MIT License**（ただし学習素材データセットの規約は別） |
| キャラクターエディション（つくよみちゃん / 刻鳴時雨 / OLUNE） | **各エディションの個別 EULA**（[beatrice.md §5.3](./beatrice.md#53-公式キャラクターエディション公式サイト配布)） |
| Beatrice JVS Corpus Edition（v1） | **営利目的禁止**（JVS Corpus 規約準拠）。許諾範囲超は Project Beatrice の事前許諾 |
| VCClient 本体 | **MIT License**（[w-okada-voice-changer.md §7.1](./w-okada-voice-changer.md#71-リポジトリ本体)） |

**本ラボの方針:** 「Beatrice なら配信で自由に使える」と書かない / 提案しない。**どのレイヤのライセンスを指しているか**を常に切り分ける（[CLAUDE.md](../../CLAUDE.md) 方針）。配信で収益化を伴う使い方をする場合は、**該当エディションの EULA を一次情報として確認**する。

## 7. 次に読むもの

- **VCClient 側を深掘り** → [w-okada-voice-changer.md](./w-okada-voice-changer.md)
- **Beatrice 側を深掘り** → [beatrice.md](./beatrice.md)
- **入門ページ（提供形態主軸 3 タイプ）** → [overview.md](./overview.md)
- **分類軸の見取り図（3 軸クロスマトリクス）** → [voice-changer-types.md](./voice-changer-types.md)
- **配信ソフトへの繋ぎ方** → [virtual-audio-devices.md](./virtual-audio-devices.md) → [obs-studio.md](./obs-studio.md)
- **Windows で経路 B を実機セットアップする手順** → [install-vcclient-beatrice-windows.md](./install-vcclient-beatrice-windows.md)
- **フォルダ全体の目次** → [README.md](./README.md)
