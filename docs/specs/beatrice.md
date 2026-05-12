# Beatrice

> [voice-changer-types](./voice-changer-types.md) 上の位置付け: **技術アプローチ: 1.3 ニューラル変換（コンテンツ表現 + 話者条件付け系）/ 提供形態: 2.1 ローカル OSS / モデル形態: 3.1 話者依存**
>
> 本ページは [docs/plans/beatrice.md](../plans/beatrice.md) のスコープに沿って、**Project Beatrice の公式系情報源**（公式サイト [prj-beatrice.com](https://prj-beatrice.com)、GitHub Organization [`prj-beatrice`](https://github.com/prj-beatrice)、公式トレーナー [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer)）に書かれている内容を中心にまとめる。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。
> 各項目で「公式に書かれている内容」「コミュニティで一般に言われている内容」「未確認」を区別する。
> [rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) と構成を揃え、§7 で構造比較を行う前提で書いている。
>
> **進捗:** Phase 1〜3 完了（§1〜§9 を執筆）。

## 1. 概要 — 「Beatrice」が指す 4 つのレイヤ

「Beatrice」という名前は文脈によって少なくとも次の 4 つを指す。本ラボでは混同しないように分けて扱う（[rvc.md §1](./rvc.md#1-概要--rvc-が指す-3-つのレイヤ) / [so-vits-svc.md §1](./so-vits-svc.md#1-概要--so-vits-svcが指す-4-つのレイヤ) と並行な整理）。

### 1.1 アルゴリズム / モデルとしての Beatrice

- 名前: **Beatrice**（公式 VST リポジトリの説明文 [`声質変換 VST`](https://github.com/prj-beatrice/beatrice-vst)。日本語では「ベアトリーチェ」表記）。
- 主体は **Project Beatrice**（[`prj-beatrice`](https://github.com/prj-beatrice) Organization）。
- 公式トレーナー（[`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer)、後述 §1.2）の README は Beatrice を次のように紹介している（公式に書かれている内容）:
  > 「超低遅延・低負荷・低容量を特徴とする完全無料の声質変換 VST 「[Beatrice 2](https://prj-beatrice.com)」のモデル学習用ツールキットです。」
- 公式サイト [prj-beatrice.com](https://prj-beatrice.com) は Beatrice 2 を **CPU シングルスレッド動作 / 約 35 MB / 約 50 ms 遅延（**外部測定の引用**）** と紹介している。
  - 「50 ms」は公式サイト上で **外部測定の引用** として書かれているもので、本ラボの実測値ではない（[CLAUDE.md](../../CLAUDE.md) 方針との接点。実測は別途 `experiments/` 配下で扱う）。
- voice-changer-types §1.3 で挙げた「**コンテンツ表現 + 話者条件付け系**」に該当する（**Phase 1 で確定**。根拠は §2.1 / §2.2 で公式トレーナー README から具体的なモジュール構成（PhoneExtractor / PitchEstimator / WaveGenerator）を引いて示す）。
  - 暫定置きだった voice-changer-types §1.3 の代表例記述はこれを反映して **暫定表記を外す**（[voice-changer-types §1.3](./voice-changer-types.md#13-ニューラル変換-neural-voice-conversion) を本書 §2 と整合させる予定）。
- RVC / so-vits-svc との位置関係:
  - [RVC](./rvc.md) が **外部 faiss index に対する top1 検索で特徴量を学習データ側に置き換える**設計だったのに対し、Beatrice は **コンテンツ抽出器内部で vector quantization（kNN-VC を参考にしたものと公式 README が明言）** を行うが、外部の retrieval index は持たない（[trainer README](https://huggingface.co/fierce-cats/beatrice-trainer)。詳細 §2.2、対比は §7）。
  - [so-vits-svc](./so-vits-svc.md) が SoftVC（ContentVec / HuBERT 系）+ VITS デコーダ + NSF-HiFiGAN という構成だったのに対し、Beatrice 2 は **PhoneExtractor + PitchEstimator + WaveGenerator** という 3 モジュール構成（§2.1）。「VITS ベース」を名乗っていない点も RVC / so-vits-svc との違い（公式 README にそうした表現は無い）。

### 1.2 公式系リポジトリ / 配布物としての Beatrice

「公式」とみなす配布物は次の 4 種類。これらはそれぞれ役割と保管場所が異なり、ライセンス・配布条件も別々（[§5](#5-配布形態とライセンス) で詳述）。

- **公式 VST 本体**: 配布バイナリ。[公式サイト](https://prj-beatrice.com)から配布。「Beatrice 2.0.0-rc.1」が公式サイト確認時点の最新表記。
- **公式 VST のソースコード**: [`prj-beatrice/beatrice-vst`](https://github.com/prj-beatrice/beatrice-vst)（MIT License）。「Beatrice 2 の公式 VST です。」とだけ書かれた最小限の README で、アルゴリズム / モデル仕様の説明は **このリポジトリには無い**。技術仕様はトレーナー側（次項）に集約されている。
- **公式トレーナー (Beatrice 2)**: [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer)（MIT License、リポジトリは Hugging Face）。公式 VST が読むモデルを学習するためのツールキットで、**モジュール構成・損失関数・学習データセット**まで含めて公式に書かれている唯一の場所が現状ここ。
- **公式モデル配布リスト**: [prj-beatrice.notion.site の Notion ページ](https://prj-beatrice.notion.site/246fb3c9fba480119c95ec07e205f061)（公式サイトからリンク。"モデル配布リスト (試験運用)" として案内）。

そのほか「Beatrice」と名乗る派生クライアントが存在する（例: [aq2r/beatrice-client](https://github.com/aq2r/beatrice-client)、[w-okada/beatrice-trainer-colab](https://github.com/w-okada/beatrice-trainer-colab) など）が、これらは **公式の周辺ツール / コミュニティ実装**で、本書では **公式系の 4 種類**（上記）に限定して扱う。

### 1.3 配布チェックポイント / キャラクターエディションとしての Beatrice

公式サイトで配布されているキャラクター入りエディションは現時点で 3 種類（**個別に EULA（使用許諾）ページがあり、それぞれ独立にライセンスを判断する必要がある**点が重要。詳細 §5.3）:

- **つくよみちゃんエディション**
- **刻鳴時雨エディション**
- **OLUNE エディション**

これらは「公式サイトから配布される、特定のキャラクター声に変換するためのモデル」。RVC / so-vits-svc では「公式リポジトリは話者特化チェックポイントを配布しない」のが原則だが、**Beatrice はキャラクター入りのチェックポイントを公式自身が配布している**点が運用面の大きな違い（§7 で再掲）。

加えて、後述する **Beatrice JVS Corpus Edition** という別系統の配布物が存在する。これは公式サイトではなく **w-okada/voice-changer リポジトリ経由で案内されている v1 系のモデル** で、ライセンスもキャラクターエディションとは独立（§1.4 と §5.4 で詳述）。

本書で「Beatrice モデル / Beatrice チェックポイント」と書いた場合は、原則として **公式またはユーザーがトレーナーで作った、Beatrice 形式のモデル**を指す。Beatrice は **独自のモデル形式**を持ち、`.pth` や `.onnx` などの一般形式とは互換性が無いことが [w-okada/voice-changer #1523 ディスカッション](https://github.com/w-okada/voice-changer/discussions/1523) で言及されている（「Beatrice works with Beatrice voices. They are not the same as pth or onnx voices」）。**公式に「Beatrice 形式」の仕様文書が公開されているかは未確認**（§9 で後追い）。

### 1.4 「Beatrice 1」と「Beatrice 2」というバージョンの呼び方

Beatrice には **大きな世代差** があり、本書では明示的に書き分ける。

- **Beatrice 1（v1, 1.x 系）**:
  - **本ラボの spec で参照できる主な v1 物**は **Beatrice API 1.1.0 JVS Corpus Edition**（w-okada/voice-changer リポジトリ内 [`server/voice_changer/Beatrice/README.md`](https://github.com/w-okada/voice-changer/blob/master/server/voice_changer/Beatrice/) の表題より、Copyright 2023 Project Beatrice 表記）。
  - [w-okada/voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) で「Beatrice v1 は Windows のみ」と表に書かれているのは、この v1 系を指す。
  - 公式サイト・公式 GitHub には現時点で **v1 のアーキテクチャを語る公式 README は見当たらない**（v1 時代の URL や README は v2 への移行で整理されている可能性が高い。**未確認**、§9 で後追い）。
  - 本書での v1 の扱いは「**w-okada が同梱している `Beatrice API 1.1.0 JVS Corpus Edition`**」を起点に書き、内部実装の詳細には踏み込まない。
- **Beatrice 2（v2, 2.x 系）**:
  - 公式サイト・公式 VST リポジトリ・公式トレーナーが対象としているのはこちら。本書の §2 / §3 / §4 で「Beatrice」と書いたら、特に断らない限り **Beatrice 2** を指す。
  - 公式トレーナーは **v2 専用**で、「Beatrice 2.0.0-rc.0 をリリースしました」「新しい Trainer で生成したモデルは、古いバージョンの公式 VST、VCClient、beatrice-client で動作しません」と README が明記しており、**v1 と v2 はモデル互換性が無い**（[trainer README](https://huggingface.co/fierce-cats/beatrice-trainer)）。
  - [w-okada/voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) で v.2 系のサポート対象として挙がっているのも Beatrice 2。

本書で「Beatrice」と書いたときは、特に断らない限り **公式サイト + 公式 VST + 公式トレーナーの最新（Beatrice 2 系）**を指す。v1 固有の話は **明示的に「Beatrice 1 / v1」と書き分ける**。

## 2. アーキテクチャ概観

公式情報源の中で **モジュール構成まで踏み込んで書かれているのは [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer) の README** で、`prj-beatrice/beatrice-vst` の README は配布告知レベル、公式サイトはユーザー向け紹介レベルに留まる。本節は **trainer README に書かれている v2 のモジュール構成**を中心に整理する。

### 2.1 3 モジュール + 識別器構成（Beatrice 2、公式トレーナー README で確認できる範囲）

[trainer README](https://huggingface.co/fierce-cats/beatrice-trainer) を本ラボの理解で図にすると以下になる（[rvc.md §2.1](./rvc.md#21-3-段構成公式-readme-で確認できる範囲) / [so-vits-svc.md §2.1](./so-vits-svc.md#21-4-段構成公式-readme-で確認できる範囲) と並行）。

```
入力波形
   │
   ▼
[A] PhoneExtractor      ── 入力からコンテンツ（音素的特徴）を抽出
   │       self-attention を導入、GRU を削除
   │       出力に vector quantization（kNN-VC 参考）
   │       学習時は出力にノイズ拡張
   │
[B] PitchEstimator      ── F0 推定
   │       v2.0.0-rc.0 で出力上限を A5 付近 → F6 付近に引き上げ
   │       v2.0.0-rc.0 で有声/無声予測を廃止
   │       学習データに VocalSet（歌唱）を追加
   │
   ▼  (PhoneExtractor 出力 + F0)
[C] WaveGenerator       ── 波形合成（Vocoder 兼 Decoder）
   │       cross-attention で話者性を注入（v2 で追加）
   │       FIRNet 系 post-filter を踏襲
   │       損失計算に D4C
   │       活性化に SiLU（EVA-GAN 参考）
   ▼
出力波形

学習時のみ:
[D] Discriminator       ── DiscriminatorP（HiFi-GAN 系）+ DiscriminatorR（UnivNet 系）
```

公式トレーナー README で明示的に確認できる根拠（公式に書かれている内容）:

- **PhoneExtractor の構造変更**: 「アーキテクチャに self-attention の追加や GRU の削除などの変更」「kNN-VC に類似した vector quantization」「学習時の出力へのノイズ augmentation」を行う、と README が明言。
- **PitchEstimator の v2.0.0-rc.0 での変更**: 「出力値の上限を A5 付近から F6 付近に引き上げました」「有声/無声の予測を行わないように変更」、学習データに **VocalSet**（歌唱コーパス）を追加。
- **WaveGenerator の構造**: 「cross-attention によって話者性を注入する構造を追加」「FIRNet post-filter 構造を踏襲」、「D4C」を損失計算に用いる、活性化関数に **SiLU**（EVA-GAN 参考）。
- **識別器構成**: **DiscriminatorP**（HiFi-GAN 系の multi-period discriminator 派生）と **DiscriminatorR**（UnivNet 系 multi-resolution discriminator 派生）の 2 系統。

ここから、Beatrice 2 が **voice-changer-types §1.3 のうち「コンテンツ表現 + 話者条件付け系」に分類できる**ことが裏取りできる（**Phase 1 確定事項**）:

- 「コンテンツ抽出（PhoneExtractor）」「F0（PitchEstimator）」「波形合成 + 話者条件（WaveGenerator with cross-attention）」と段が分かれており、so-vits-svc（SoftVC + VITS + NSF-HiFiGAN）と類似のレイヤ分割になっている。
- **kNN-VC 系の vector quantization が PhoneExtractor の出力側に入る**点は RVC の Retrieval（外部 faiss index）とは別物。Beatrice の VQ は **コンテンツ表現を離散化するためのもの**で、「学習データ側の特徴量に置き換える」目的の外部 retrieval ではない（§7 で対比）。

未確認（**Phase 1 では確認できなかった**こと）:

- 「Beatrice 2 のアーキテクチャ全体図」を 1 枚で説明した**論文 / プレプリント / 公式技術ブログ**は本 Phase で発見できていない。trainer README の文面以上の詳細（各モジュールの層数 / パラメータ数 / 中間次元など）は未確認（§9 で後追い）。
- VITS 系を踏襲しているかどうか公式に名指しの記述は無い。RVC / so-vits-svc が「VITS based」を明言しているのと対照的（本書では「VITS ベース」とは書かない）。

### 2.2 Beatrice 1 と Beatrice 2 の差分

Phase 1 で確認できた範囲では:

- **モデル形式は非互換**（[trainer README](https://huggingface.co/fierce-cats/beatrice-trainer)。「新しい Trainer で生成したモデルは、古いバージョンの公式 VST、VCClient、beatrice-client で動作しません」）。trainer は v2 専用。
- **対応プラットフォームの公式表記**:
  - **Beatrice 2（公式 VST バイナリ）**: 公式サイトに「OS: Windows® 10/11」「CPU: Intel® Core™ series 4th generation or later / N100」と明記（**Windows のみ・CPU のみ**）。
  - **Beatrice 1**: 公式サイトに現役の v1 配布記述は見当たらず、本ラボで参照可能な v1 物は w-okada/voice-changer 同梱の Beatrice API 1.1.0 JVS Corpus Edition のみ。w-okada/voice-changer §3.1 の表で「Beatrice v1 は Windows のみ」とされているのは、v1 ランタイム側の制約（モデルではなく公式 VST / API バイナリの提供 OS）に由来する、と本ラボでは整理する（**ホスト側の制約ではなく、モデル / API 側の制約**。§6 で再掲予定）。
- **学習データ**: Beatrice 2 は **ReazonSpeech / VocalSet / DNS Challenge / LibriTTS-R** を組み合わせて事前学習している（公式サイト / trainer README）。v1 は本ラボで確認可能な範囲では **JVS Corpus / LibriTTS-R / LibriTTS / DNS Challenge** ベース（w-okada リポジトリ内 README、§5.4）。**学習素材レベルで世代差がある**。
- **歌唱への対応**: Beatrice 2 の v2.0.0-rc.0 以降は **PitchEstimator のピッチ上限引き上げと VocalSet 追加**で歌唱を扱いやすくする方向で更新が入っている（trainer README）。v1 の歌唱対応の公式記述は未確認。

### 2.3 入出力と動作モデルの位置関係（公式 VST としての形）

- **配布形態は VST（プラグイン）**。`prj-beatrice/beatrice-vst` リポジトリ名のとおり、Beatrice 2 公式は **VST / VST3 プラグインとしてホスト DAW / VST ホストから呼ばれる**ことを前提に作られている。
- 配信用途では w-okada/voice-changer（VCClient）から呼び出される運用が中心で、その場合は [w-okada-voice-changer §1.4](./w-okada-voice-changer.md#14-ホストの責任分界モデルではない部分) のホスト責任分界がそのまま適用される（§6 で詳細化）。
- **GPU は要件に出てこない**: 公式サイトに「CPU シングルスレッド動作 / 約 35 MB」と書かれており、推論には GPU は前提とされていない。RVC / so-vits-svc が GPU 前提で語られるのと対照的（§7 で再掲）。

## 3. 学習プロセスの大枠

本節は公式トレーナー [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer) の README / `assets/README.md` / `assets/default_config.json`、および [公式サイト Q&A](https://prj-beatrice.com) を一次情報源とする。**Beatrice 2 専用**で、v1 のトレーナーは本ラボでは公式所在を確認できていない（§1.4 / §9）。

### 3.1 前提環境と GPU 要件（公式 README に明記）

- **推論には GPU 不要、学習には GPU 必要**（trainer README "Prerequisites" 節）。「既存の学習済みモデルを用いて声質の変換を行うだけであれば GPU を必要としません」「新たなモデルの作成を効率良く行うためには GPU が必要」と公式 README に明記。RVC ([rvc.md §3.1](./rvc.md#31-必要な学習データ量エポック数faq-ベース)) / so-vits-svc ([so-vits-svc.md §3.1](./so-vits-svc.md#31-必要な学習データの形式公式-readme-dataset-preparation)) と違い、**推論を GPU 前提で語っていない**点が大きい違い（§7 で再掲）。
- **VRAM**: デフォルト設定で約 9 GB（trainer README）。
- **学習時間の参照値**: GeForce RTX 4090 で約 40 分で完了する想定（trainer README）。**本ラボでの実測値ではない**。
- **対応 OS**: README は Linux / Windows 両方の手順を併記し、Windows では `.venv\Scripts\activate` を使う旨が明記。GPU が用意できない場合の代替として [`w-okada/beatrice-trainer-colab`](https://github.com/w-okada/beatrice-trainer-colab)（**コミュニティ実装。公式のフォーク**）が公式 README からリンクされている。**トレーナー自体は Windows-only ではない**（§6 / §1.4 で v1 / v2 の Windows のみ制約と切り分け）。
- パッケージマネージャは v2.0.0-rc.0 で **Poetry → uv** に変更（trainer README リリースノート）。`uv sync --extra cu128` で CUDA 12.8 ビルドの PyTorch を含む依存が入る。

### 3.2 学習データの配置（公式 README "Prepare Your Training Data"）

公式 README に図示されている配置規約は次のとおり:

- 学習データ用ディレクトリの**直下に各話者のディレクトリを作る**必要がある。
- 各話者ディレクトリ**内部の構造・ファイル名は自由**で、サブディレクトリ内の音声ファイルも再帰的に使用される。
- **1 話者のみで学習する場合でも、その 1 話者のディレクトリを作る必要がある**（直下に音声ファイルを置くのは公式 README の「Wrong.」例）。
- 対応フォーマットは **WAV / FLAC / MP3 など**（README で WAV / FLAC / MP3 が明示）。
- **モノラル制約**: 過去のリリースノート（2024-10-20 / 2.0.0-beta.2）で「学習データにモノラルでない音声ファイルが含まれる場合にエラーが発生する問題を修正しました」とあり、現行では**ステレオ素材も受け付ける**ようになっている（修正前はモノラル制約があった、と読み取れる）。

so-vits-svc が `dataset_raw/<speaker>/*.wav` + 44.1 kHz / モノラル制約を README に明記している（[so-vits-svc.md §3.1](./so-vits-svc.md#31-必要な学習データの形式公式-readme-dataset-preparation)）のと比べると、**Beatrice 側の制約はだいぶ緩い**（任意のサンプリングレート / 任意のフォーマット / 任意の話者数 / ネストディレクトリ可）。

### 3.3 事前学習チェックポイントと学習素材の使い分け

trainer リポジトリの `assets/default_config.json` で参照されている事前学習物は次の 3 種類:

| 設定キー | 役割 | デフォルト値 |
| --- | --- | --- |
| `phone_extractor_file` | PhoneExtractor の事前学習重み | `assets/pretrained/122_checkpoint_03000000.pt` |
| `pitch_estimator_file` | PitchEstimator の事前学習重み | `assets/pretrained/104_3_checkpoint_00300000.pt` |
| `pretrained_file` | 学習開始時のフル状態（WaveGenerator など含む） | `assets/pretrained/151_checkpoint_libritts_r_200_02750000.pt.gz` |

**学習素材の使い分け**は、trainer の `assets/README.md` と公式サイト Q&A「権利侵害の恐れのあるデータを学習に使用していませんか？」で明確に整理されている（公式に書かれている内容）:

| データセット | 使用される部分 | ライセンス |
| --- | --- | --- |
| [**ReazonSpeech**](https://research.reazon.jp/projects/ReazonSpeech/index.html) | **「ユーザが喋った内容を認識する部分」のみ**（= PhoneExtractor 系） | reazon-research/reazonspeech の規約 |
| [**VocalSet**](https://zenodo.org/records/1193957)（2.0.0-rc.0 以降） | **「ユーザが喋った内容を認識する部分」のみ**（= PitchEstimator の歌唱対応） | 各データセット規約 |
| [**DNS Challenge**](https://github.com/microsoft/DNS-Challenge)（ノイズ部） | **入力ノイズへの頑健化**（= 学習時 augmentation の素材） | CC0 / CC BY / CC BY-SA（[trainer assets/README.md](https://huggingface.co/fierce-cats/beatrice-trainer/blob/main/assets/README.md)） |
| [**LibriTTS-R**](https://www.openslr.org/141/) | **「目標話者の声質で音声を合成する部分」の事前学習**（= WaveGenerator） | CC BY 4.0 |
| [**Room Impulse Response Generator**](https://github.com/audiolabs/rir-generator) で生成した IR | 学習時のリバーブ augmentation 素材 | 元プロジェクト規約 |
| 各目標話者の音声データ | **「目標話者の声質で音声を合成する部分」の学習**（= ユーザが用意するデータ） | ユーザ責任 |

**重要な公式の整理**（Q&A 引用）:

> 「ユーザがどんな声を入力しても発話内容の認識が可能となるよう、『ユーザが喋った内容を認識する部分』の学習のみにこのデータを使用しています。合成部分では使用していないため、入力音声がこのデータに含まれる話者の声質に変換されることはありません。」

→ **ReazonSpeech / VocalSet に含まれる話者の声には**、ユーザの学習データを使ったとしても**変換されない**設計であることが公式に明言されている。これは「ベース事前学習に含まれる話者の特徴が変換結果に漏れるリスク」を構造的に下げる設計上の判断（コンテンツ抽出と合成のデータを分離）であり、[so-vits-svc.md §5.7](./so-vits-svc.md#57-歌声素材という性質に起因する追加リスクrvc-との差分の核心) で扱った「ベース事前学習素材が結果に漏れる問題」を Beatrice 側はこの形で扱っていることになる（§7 で対比）。

### 3.4 学習時の Data Augmentation

`assets/default_config.json` から確認できる augmentation 設定（公式に書かれている内容）:

- **ノイズ混合**: SNR を `[20, 25, 30, 35, 40, 45]` dB の候補から選択し、§3.3 の DNS Challenge ノイズを混合（`augmentation_snr_candidates`）。
- **フォルマントシフト**: 確率 0.5 で `[-3, +3]` semitone の範囲でシフト（`augmentation_formant_shift_probability` / `_semitone_min` / `_max`）。**v2.0.0-rc.0 のリリースノートで追加された augmentation**（trainer README リリースノート）。
- **リバーブ**: 確率 0.5 で IR 畳み込み（`augmentation_reverb_probability`）。
- **LPF**: 確率 0.2 で `[2k, 3k, 4k, 6k]` Hz のいずれかでカットオフ（`augmentation_lpf_probability` / `_cutoff_freq_candidates`）。

**注意**: ここで言う**「フォルマントシフト」は学習時の augmentation** で、§4 で扱う **推論時の formant パラメータ**とは別物。学習時の augmentation は「話者類似性を上げる」目的で trainer README に書かれており、推論時のフォルマント調整 UI はそれを土台にして表に出ているものと推測される（公式に直接の対応関係の記述は無く、本ラボの整理）。

### 3.5 学習コマンド・再開・出力（公式 README "Getting Started" / "Detailed Usage"）

- **基本コマンド**: `python3 beatrice_trainer -d <data_dir> -o <out_dir>`。
- **コンフィグ指定**: `assets/default_config.json` を別の場所にコピーして編集し `-c <your_config.json>` で渡す。**`default_config.json` を直接編集すると壊れる**と README が明記。コンフィグ内に `data_dir` / `out_dir` を書けば `-d` / `-o` を省略可能。
- **再開**: 学習中断時 `checkpoint_latest.pt.gz` が出力ディレクトリにあれば `-r` で再開。
- **デフォルトハイパーパラメータ**（`default_config.json` 抜粋）:
  - `n_steps: 10000`（warmup 5000）— so-vits-svc / RVC の十数〜数十万ステップと比べると桁が違って短い。
  - `batch_size: 8`、Adam 学習率 `5e-5`、`learning_rate_decay: 0.999999`。
  - **サンプリングレート**: `in_sample_rate: 16000`、`out_sample_rate: 24000`。**入力 16 kHz / 出力 24 kHz**で固定されており、so-vits-svc ([so-vits-svc.md §3.1](./so-vits-svc.md#31-必要な学習データの形式公式-readme-dataset-preparation)) の 44.1 kHz / RVC の 32k / 40k / 48k 選択とは異なる固定値運用（§7 で対比）。
- **TensorBoard**: `tensorboard --logdir <out_dir>` で観察可能。ただし v2.0.0-rc.0 で **TensorBoard への数値記録はデフォルト無効** になった（「損失関数の値などによって品質が評価できると誤解されることを避けるため」と trainer README に明記）。`record_metrics: false` がデフォルト。
- **出力ファイル**:
  - `paraphernalia_(data_dir_name)_(step)/` — ストリーム変換に必要なファイル一式（後述 §3.6）。
  - `checkpoint_(data_dir_name)_(step).pt.gz` — 学習途中チェックポイント（圧縮保存。v2.0.0-rc.0 で圧縮形式化）。
  - `checkpoint_latest.pt.gz` — 最新チェックポイントのコピー。
  - `events.out.tfevents.*` — TensorBoard 用イベント。

### 3.6 配布形態としての成果物（paraphernalia）

学習が正常完了すると **`paraphernalia_(data_dir_name)_(step)/`** が出力され、これを **公式 VST / VCClient / beatrice-client から読み込む**ことでリアルタイム変換が可能になる（trainer README "After Training"）。

- ディレクトリ内には `beatrice_paraphernalia_*.toml` があり、VST / VCClient / beatrice-client 上での **表示名・description・portrait 画像**などをユーザが編集可能（trainer README "Customize Paraphernalia"）。
- `model.version` は**変更してはいけない**（モデルフォーマットのバージョン識別子）。
- portrait に設定する画像は PNG 形式かつ正方形、と明記。
- README は「このリポジトリを用いて生成したモデルの配布を歓迎します」と明示しており、**ユーザが trainer で作ったモデルの再配布は公式に推奨**（ただし学習素材データの規約は別、§5.5 参照）。

## 4. 推論パラメータ

公式の推論ライブラリ（[`prj-beatrice/beatrice-vst`](https://github.com/prj-beatrice/beatrice-vst) 内）には API ドキュメント / パラメータ列挙ドキュメントは現時点で見当たらず、**推論パラメータの一次情報源は (a) 公式 VST 本体の UI / 同梱 PDF README**、**(b) 公式サイト Q&A の言及**、**(c) 公式 / 派生クライアント側（VCClient / beatrice-client）の UI 露出とリリースノート**の 3 つに分かれる。本節は **公式が「同じ推論ライブラリを使う」と保証している範囲**（後述 4.1）を前提に、3 種類のクライアントを横断して整理する。

### 4.1 公式 VST / VCClient / beatrice-client は同じ推論ライブラリ（公式 Q&A の明言）

公式サイト Q&A「スタンドアロンで動作しますか？」より（公式に書かれている内容）:

> 「公式 VST の代わりに [beatrice-client](https://github.com/aq2r/beatrice-client) または [VCClient](https://github.com/w-okada/voice-changer) を使用することで、VST ホストアプリケーションを介さずに動作させることができます。**これらのソフトウェアは公式 VST と同じ推論ライブラリを使用しており、単体で声の変換が可能です。**」
> 「※ 遅延の長さは各ソフトウェアの実装に依存します。」「※ 最新モデルへの対応が公式 VST より遅れる場合があります。」

ここから本ラボの整理:

- **モデル本来の挙動（声質変換そのもの）はクライアント横断で同一**と公式に保証されている。VCClient / beatrice-client 経由で出る変換音と公式 VST の変換音は、原理的には**同じ推論コードの出力**。
- **遅延・対応モデル世代はクライアント実装側に依存**。VCClient で「Beatrice v1 が Windows のみ」と表記されているのは推論ライブラリの提供 OS 起因であり、これは公式 VST バイナリと共有の制約（§6 で再掲）。
- したがって本節で扱うパラメータは、原則として **Beatrice 推論ライブラリのパラメータ**として書ける（**どのクライアントから触っても同じ意味**）。クライアント固有の UI 露出は §4.3 / §4.4 で別途扱う。

### 4.2 Beatrice 2 固有の前提（公式 Q&A・モデル構造から読み取れる挙動）

推論パラメータを読み解く前に、Beatrice 2 の **モデル側で決まっている挙動** を確認しておく（公式に書かれている内容）。これは RVC / so-vits-svc とは違う Beatrice 固有の前提で、パラメータの意味付けに直結する。

- **入力ピッチを「正確に」反映する**: 公式サイト Q&A「Beatrice 2 は、Beatrice 1 とどう違いますか？」より:
  > 「単純なピッチシフト以上にピッチを変化させないため、喋り方の癖やイントネーションを保持した変換や、歌声の変換を行うことができます。」

  → モデルが**入力 F0 をそのまま使う**（PitchEstimator が推定した F0 を WaveGenerator に渡す）設計で、**話者埋め込みでピッチが書き換わらない**ことを公式が明言。これは [rvc.md §2.4](./rvc.md#24-リアルタイムのための工夫として-readme-に挙がっているもの) で扱う RVC の F0 抽出と通じる「入力ピッチを尊重する」方向の設計で、so-vits-svc の各種 F0 補正（[so-vits-svc.md §4.2](./so-vits-svc.md#42-f0-抽出方式の整理)）よりはストレートな扱い。
- **PhoneExtractor の出力に内部 VQ がかかる**: §2.1 で述べたとおり、kNN-VC 系の vector quantization が PhoneExtractor の出力に入る。これは**推論時に追加のパラメータを露出しない**（VQ のコードブックは学習時に固定され、推論時はそのまま使われる）。RVC の `INDEX`（[rvc.md §4.3](./rvc.md#43-w-okadavoice-changer-ui-露出との対応表)）のような外部 retrieval index は **存在しない**ため、対応する UI パラメータも無い。
- **F0 抽出器は内蔵 PitchEstimator のみ**: trainer README / 公式 VST 同様、**F0 抽出方式の選択肢は存在しない**（RVC の dio / harvest / crepe / rmvpe 切替や so-vits-svc の `--f0_predictor` 切替は Beatrice には無い）。学習時に PitchEstimator が一体学習されている設計のため、抽出方式は**モデルに内包されている**（§6 / §7 で対比）。

### 4.3 推論時に UI 露出されているパラメータ

本ラボで一次情報源として確認できた範囲は次のとおり。**Beatrice 1 の `README.pdf`（公式サイトから配布）/ Beatrice 2 の公式 VST 同梱 UI の一次確認は本ラボでは未実施**で、ここでの記述は VCClient リリースノート（[w-okada §3.3](./w-okada-voice-changer.md#33-モデル別の補足リリースノートから読み取れる範囲)）と公式サイト記述から組み立てたもの（§9 で確認タスク化）。

| パラメータ | 出どころ | 意味（本ラボの理解） |
| --- | --- | --- |
| **pitch（ピッチシフト量）** | VCClient リリースノート v.2.0.73-beta「beatrice v2 の pitch, formant が反映されないバグを修正」より UI 露出を確認 | 推論時に入力ピッチをユーザ指定 semitone 数シフトする。公式 Q&A の「単純なピッチシフト以上にピッチを変化させない」のうち**「単純なピッチシフト」分**にあたるユーザ操作。**話者埋め込みで決まる絶対音域への移動とは別** |
| **formant（フォルマントシフト量）** | 同上 | フォルマント周波数のシフト。学習時 augmentation の `augmentation_formant_shift_*`（§3.4）と同じメカニズムが推論時にも露出していると推測。Beatrice 2 で WaveGenerator に cross-attention で話者性を注入する構造に合わせて挙動が再設計されている可能性があるが、**公式 README で内部実装を語った記述は未確認** |
| **オートピッチシフト** | VCClient リリースノート v.2.0.76-beta「Beatrice: オートピッチシフト」 | 入力話者と目標話者の声域差を**自動で**推定して pitch シフト量を決める機能。手動 pitch 設定の自動化版にあたると本ラボでは整理（**公式 VST / Beatrice 公式サイトに「オートピッチシフト」の表記があるかは未確認**。VCClient 表記としてのみ確認） |
| **話者マージ / Voice Morphing Mode** | VCClient リリースノート v.2.0.76-beta「話者マージの実装」/ 公式 VST 2.0.0-beta.3「Voice Morphing Mode 等の機能追加」/ 2.0.0-rc.1「Voice Morphing Mode を 2.0.0-rc.0 のモデルに対応」 | **複数の目標話者モデルの間で話者性を混合**して中間的な声質を生成する機能。公式 VST 側の呼称は **Voice Morphing Mode**、VCClient 側の呼称は **話者マージ** で、**同じ機能を指していると本ラボでは整理**（§9 で原文確認タスク化）。§2.1 で述べた WaveGenerator の cross-attention 話者注入と整合的（複数モデルの話者埋め込みを線形補間できる構造） |

公式サイトでの **Voice Morphing Mode** の段階的展開は次のとおり（公式サイト「新バージョン情報」の各リリース説明より）:

1. **2.0.0-beta.3**: Voice Morphing Mode 等の機能追加
2. **2.0.0-rc.0**: 品質向上、ピッチの上限引き上げ、推論ライブラリの最適化による負荷軽減、GUI の改善、**ピッチ推定の範囲設定などの機能追加**
3. **2.0.0-rc.1**: Voice Morphing Mode を 2.0.0-rc.0 のモデルに対応

→ **「ピッチ推定の範囲設定」は 2.0.0-rc.0 で公式 VST 側にも UI として追加されている**（PitchEstimator の出力範囲を絞る UI パラメータ。trainer 側で「PitchEstimator の出力上限を F6 付近に引き上げ」とあるのを推論時に絞り直す UI と思われるが、**公式 README での詳細記述は未確認**）。VCClient 側で同等のパラメータが UI 露出しているかは未確認（§9）。

### 4.4 w-okada/voice-changer UI 露出との対応表

[w-okada-voice-changer §4.1〜4.2](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) で確認した VCClient の共通 UI 上のパラメータと、§4.3 の Beatrice 固有パラメータを 1 つの表に統合する。**「ホスト側で吸収される共通パラメータ」と「モデル固有パラメータ」を明確に切り分ける**のがこの表の目的（[rvc.md §4.3](./rvc.md#43-w-okadavoice-changer-ui-露出との対応表) / [so-vits-svc.md §4.3](./so-vits-svc.md#43-w-okadavoice-changer-ui-露出との対応表) に対応）。

| VCClient UI 名 | 担当 | Beatrice 側で対応するもの |
| --- | --- | --- |
| Echo / Sup1 / Sup2 | ホスト（Client device mode のブラウザ機能） | 該当なし（推論前のブラウザ側ノイズ抑制） |
| S. Thresh (Noise Gate) | ホスト | 該当なし（推論前のゲート処理） |
| GAIN in / out | ホスト | 該当なし（モデル入出力の音量正規化はホスト責任） |
| **TUNE / pitch** | **モデル（Beatrice）** | §4.3 の **pitch**。半音単位の入力ピッチシフト |
| **formant** | **モデル（Beatrice）** | §4.3 の **formant** |
| **オートピッチシフト**（VCClient v.2.0.76-beta〜） | **モデル（Beatrice）** | §4.3 の **オートピッチシフト**。pitch の自動値設定。手動 pitch と排他か併用かは未確認 |
| **話者マージ**（VCClient v.2.0.76-beta〜） | **モデル（Beatrice）** | §4.3 の **Voice Morphing Mode** |
| CHUNK (Input Chunk Num) | ホスト | 入力切り出し長。Beatrice の 16 kHz / 24 kHz サンプリングレート（§3.5）と、VCClient 側 CHUNK 設定の整合性は **未確認**（§9） |
| EXTRA (Extra Data Length) | ホスト | 過去音声混入量。Beatrice の WaveGenerator 側がストリーム前提に作られているため、EXTRA を増やしても**モデル内部で文脈が積み上がるわけではない**（ホストが推論呼出ごとに渡す入力を伸ばすだけ）と本ラボでは整理（**公式 README に直接の記述は無く、未確認**） |
| F0 Det (F0 Extractor) | RVC のみ | **Beatrice には存在しない**。内蔵 PitchEstimator が常に使われる（§4.2） |
| INDEX | RVC のみ | **Beatrice には存在しない**。外部 retrieval index を持たない（§4.2 / §2.2） |

**確定的に言えること**:

- **F0 抽出方式・INDEX という UI 概念が Beatrice には登場しない**。これは RVC を触ったユーザが Beatrice に移ったときに最初に気づく UI 差分（§7 で対比）。
- **オートピッチシフト・話者マージは Beatrice 系列で初出のパラメータ**で、RVC / so-vits-svc には対応する UI が無い（so-vits-svc に話者融合機能はあるが、これはバッチ推論時の `spk_mix_dict` / `--use_spk_mix` で、リアルタイム UI 上に露出するものではない。[so-vits-svc.md §4.1 話者融合 / Vocoder 増強](./so-vits-svc.md#話者融合--vocoder-増強)）。
- **CHUNK / EXTRA / GAIN / S. Thresh はホスト側の責任**で、モデル本来の挙動を変えるパラメータではない（§6 で詳細整理）。

**未確認**（§9 で起票）:

- 公式 VST 同梱 UI の正確なパラメータ列（VCClient 経由ではない一次情報）。
- 「**ピッチ推定の範囲設定**」（公式 VST 2.0.0-rc.0 で追加）と VCClient UI の対応関係。
- オートピッチシフトと手動 pitch の併用挙動。
- formant パラメータが学習時 augmentation の formant_shift とどう内部接続しているか。

## 5. 配布形態とライセンス

**「リポジトリ本体のライセンス」と「配布されるモデルのライセンス」は独立に判断する**。これは [rvc.md §5](./rvc.md#5-配布形態とライセンス) / [so-vits-svc.md §5](./so-vits-svc.md#5-配布形態とライセンス) と同じ考え方だが、Beatrice は **公式自身がキャラクター入りモデルを配布している** のが特徴で、エディションごとに使用許諾が分かれている点が他の 2 系統と異なる。

### 5.1 公式 VST 本体（バイナリ配布）

- 配布元: [公式サイト prj-beatrice.com](https://prj-beatrice.com)。
- 配布形態: VST / VST3 プラグイン（Windows のみ）。
- **「完全無料」と公式トレーナー README で表現されている**（"完全無料の声質変換 VST"）。
- VST バイナリそのものの利用規約（商用配信での扱いを含む）は、本ラボの確認範囲では **公式サイト上で 1 ファイルに統合された EULA としては見当たらず、各キャラクターエディションの EULA とは別物**。**未確認**（§9 で後追い）。

### 5.2 公式 VST のソースコード（`prj-beatrice/beatrice-vst`）

- ライセンス: **MIT License**（GitHub リポジトリの LICENSE ファイルおよびリポジトリページのバッジで確認）。
- 言語構成は C++ 91.4% / C 6.5% / CMake 1.7%（GitHub リポジトリページの言語サマリ）。
- README は「Beatrice 2 の公式 VST です。」とだけ書かれた最小限の内容で、ビルド手順や仕様の説明は無い。
- **MIT であるのはあくまで VST のラッパー（C++ 実装）部分**で、学習済みモデルの重みは含まれない。**実用上 VST を動かすには別途モデルファイル（公式 VST バイナリ同梱 or キャラクターエディションをダウンロード）が必要**であり、その部分のライセンスは別（§5.3 以降）。

### 5.3 公式キャラクターエディション（公式サイト配布）

公式サイトで配布されている Beatrice 2 のキャラクター入りエディションは現時点で 3 種類:

| エディション | 配布元 | 使用許諾の所在 |
| --- | --- | --- |
| **つくよみちゃんエディション** | [公式サイト](https://prj-beatrice.com) | 公式サイト内「つくよみちゃんエディション使用許諾・ダウンロード」ページ（個別 EULA） |
| **刻鳴時雨エディション** | 同上 | 公式サイト内「刻鳴時雨エディション使用許諾・ダウンロード」ページ（個別 EULA） |
| **OLUNE エディション** | 同上 | 公式サイト内「OLUNE エディション使用許諾・ダウンロード」ページ（個別 EULA） |

重要な観点（公式サイトから読み取れる範囲）:

- 各エディションは **独立した EULA ページが用意されており、ダウンロード前に同意が必要な形**になっている。
- **個別 EULA の本文（商用配信での扱い、収益化、クレジット要件、二次配布の可否など）は本書には書かない**。利用時は必ず**各エディションの EULA ページ本文を一次情報として確認**する（[CLAUDE.md](../../CLAUDE.md) 方針）。
- 「Beatrice 公式が出しているから自由に使える」と読み取らない。**キャラクター声には各キャラの権利元（つくよみちゃん / 刻鳴時雨 / OLUNE）の利用条件があり、Project Beatrice の VST 規約とは別レイヤ**。
- 上記 3 種以外の配布物については **[公式モデル配布リスト Notion ページ](https://prj-beatrice.notion.site/246fb3c9fba480119c95ec07e205f061)**（公式サイトから「モデル配布リスト (試験運用)」としてリンクされている）を一次情報源とする。各モデルのライセンスはリスト先のページに従う。

### 5.4 Beatrice JVS Corpus Edition（v1 系、w-okada/voice-changer 経由）

公式サイト側ではなく **w-okada/voice-changer リポジトリ内で配布が案内されている v1 系のモデル** で、§5.3 のキャラクターエディションとは別物。w-okada/voice-changer の [LICENSE-NOTICE](https://github.com/w-okada/voice-changer/blob/master/LICENSE-NOTICE) も「Beatrice JVS Corpus Edition のライセンスについてはこちらを確認してください」として、リポジトリ内 [`server/voice_changer/Beatrice/README.md`](https://github.com/w-okada/voice-changer/blob/master/server/voice_changer/Beatrice/) を指している。

w-okada リポジトリ同梱 README の主な記載（公式に書かれている内容）:

- 表題: **Beatrice API (1.1.0 JVS Corpus Edition)**
- 著作権表示: **Copyright 2023 Project Beatrice** ([prj-beatrice.com](https://prj-beatrice.com))。
- 利用制限:
  > 「営利目的の使用を禁ずる。(COMMERCIAL USE IS PROHIBITED.)」
  - 商用利用の基準は **JVS Corpus の規約に準ずる**と書かれている（後述）。
  - 「著作権法で許される範囲を超える利用」は **Project Beatrice の事前許諾が必要**と書かれている。
- 同梱 OSS の出典: PocketFFT / fmath / NumPy（BSD-3-Clause）、Python（PSF License）の表示あり。
- 学習に使われたデータセット:
  - **JVS Corpus**: 独自ライセンス（**「営利目的の使用を禁ずる」の根拠**）
  - **LibriTTS-R / LibriTTS**: CC BY 4.0
  - **DNS Challenge** 関連: CC BY 4.0（Audioset、Freesound CC0 由来）/ Apache 2.0（OpenSLR26 / OpenSLR28）

本ラボの整理:

- **JVS Corpus Edition は配信用途で扱う際は「営利目的の使用」に該当するかどうかを別途判断**する必要がある（配信の収益化・スポンサー案件・有償配信などは商用利用に該当する可能性が高い）。**配信での利用可否は本書では断定せず、JVS Corpus の規約と Project Beatrice の事前許諾要件を一次情報として再確認**する。
- これは **§5.3 の Beatrice 2 公式キャラクターエディション**とは **別の規約セット**。v1 系の JVS Corpus Edition は **v1 の話**であり、Beatrice 2 全体に同じ制約がかかるわけではない。
- w-okada/voice-changer の v.1 系で「Beatrice v1」が「Windows のみ」として扱われているのは、この **1.1.0 JVS Corpus Edition の Windows バイナリ提供**が起点。

### 5.5 公式トレーナー（`fierce-cats/beatrice-trainer`）

- ライセンス: **MIT License**（[trainer README](https://huggingface.co/fierce-cats/beatrice-trainer) に明記: 「このリポジトリ内のソースコードおよび学習済みモデルは MIT License のもとで公開されています。」）。
- **「ソースコードおよび学習済みモデル」**が MIT で公開されている、と明言されている点が重要。これは **トレーナーが内部で使う事前学習チェックポイント**（PhoneExtractor / PitchEstimator / WaveGenerator の事前学習重み）に対するライセンス表明で、§5.3 のキャラクターエディションや §5.4 の JVS Corpus Edition とはまた別レイヤ。
- ただし **学習に使われた素材データセット**は MIT ではなく各データセットの規約に従う:
  - **ReazonSpeech**（[reazon-research/reazonspeech](https://github.com/reazon-research/reazonspeech)、放送音源由来。ライセンスは本書では追わず必要時に確認）
  - **VocalSet**（歌唱コーパス）
  - **DNS Challenge** 関連（Audioset / Freesound 由来など、利用条件は混在）
  - **LibriTTS-R**（CC BY 4.0）
- これら素材データセットの規約が **派生モデル（=学習結果）にどこまで伝播するか**は、各データセット規約に依存。**ユーザーが trainer を使って自分のデータで作ったモデルの再配布規約は、ユーザー側の責任で判断**する。本書では一律の判断は書かない。

### 5.6 配布形態とライセンスのレイヤ整理（まとめ）

| レイヤ | 配布元 | ライセンス / 規約 | 商用配信での扱いの目安（本書では断定しない） |
| --- | --- | --- | --- |
| 公式 VST バイナリ | [prj-beatrice.com](https://prj-beatrice.com) | 「完全無料」表記。統合 EULA の所在は **未確認** | 公式サイト記述を一次情報として確認 |
| 公式 VST ソース | [`prj-beatrice/beatrice-vst`](https://github.com/prj-beatrice/beatrice-vst) | **MIT License** | コードのライセンスのみ。モデル別 |
| 公式トレーナー | [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer) | **MIT License**（ソース + 事前学習モデル） | 素材データセット規約は別 |
| Beatrice 2 つくよみちゃん / 刻鳴時雨 / OLUNE エディション | 公式サイト | エディションごとの **個別 EULA** | 各 EULA ページを一次情報として確認 |
| Beatrice JVS Corpus Edition（v1） | w-okada/voice-changer 同梱 README | **営利目的禁止**（JVS Corpus 規約準拠）、許諾範囲超は **Project Beatrice の事前許諾** | 配信収益化・有償配信は商用利用に該当する可能性。要事前確認 |
| ユーザーが trainer で作ったモデル | ユーザー側 | 学習データの規約に従う | 学習データ規約 + 配布先規約で個別判断 |

**運用ルール（本ラボ）:**

- 「Beatrice なら配信で自由に使える」と書かない / 提案しない。**必ずどのレイヤのライセンスを指しているか**を切り分ける。
- キャラクター入りエディションを使う場合は、**配信開始前に該当 EULA を読む**ことを README で促す。
- 第三者の声を許諾なくクローンするチェックポイント（公式配布リスト外で出回るもの）は **[CLAUDE.md](../../CLAUDE.md) の方針により取得手順・リンクを本ラボでは案内しない**。

## 6. w-okada/voice-changer 経由で触る場合の責任分界

[w-okada-voice-changer.md](./w-okada-voice-changer.md) を VCClient のホスト側仕様として、本書を Beatrice モデル / 推論ライブラリ側の仕様として、両者の責任分界を整理する。**§4.1 で見たとおり、公式 VST / VCClient / beatrice-client は同じ推論ライブラリを使う**と公式 Q&A が明言しているため、ここでの「モデル側」は **「Beatrice 推論ライブラリ + paraphernalia モデル」**を指し、**どのクライアントから呼んでも同じ**。

### 6.1 責任分界マップ

[rvc.md §6.1](./rvc.md#61-責任分界マップ) / [so-vits-svc.md §6.1](./so-vits-svc.md#61-責任分界マップ) と並行な形で整理する。

| 領域 | ホスト（VCClient）側 | モデル / 推論ライブラリ（Beatrice）側 |
| --- | --- | --- |
| 入力 I/O | device mode の選択（client / server）、入力デバイス選択、サンプリングレート整合性、リサンプリング | 推論ライブラリは **16 kHz 入力 / 24 kHz 出力**で動く（§3.5）。ホストはここに合わせるリサンプリングを担う |
| 出力 I/O | output / monitor の 3 デバイス分離（[w-okada §5.2](./w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537)） | 24 kHz の波形を返すのみ |
| 前段ノイズ処理 | Echo / Sup1 / Sup2（Client device mode のブラウザ機能）、S. Thresh（Noise Gate）、GAIN in | モデル本体はノイズに対して **学習時 augmentation で頑健化済み**（§3.4）。ホスト側ゲートでさらに前処理する形 |
| 後段音量処理 | GAIN out | モデルが「loudness loss」（trainer リリースノート 2025-08-31）で学習されており、**入力音量を一定範囲で受け取る前提**。ホスト側の GAIN in が極端だと品質に影響する可能性あり（未検証） |
| バッファリング | CHUNK / EXTRA、バッファ可視化、ショートカットキー | 推論ライブラリ自体はストリーム前提（StreamVC アイデアを参考と trainer README "Reference" に明記）。チャンク境界で内部状態を保持する設計と想定（**詳細は未確認**） |
| F0 抽出 | （切替 UI 無し） | **モデル内蔵 PitchEstimator** が常に使われる（§4.2） |
| 話者埋め込み | モデル選択 UI（モデルスロット） | paraphernalia に含まれる話者埋め込みを WaveGenerator の cross-attention に注入（§2.1） |
| pitch / formant | UI スライダー露出（[w-okada §4.2 Beatrice 系](./w-okada-voice-changer.md#42-モデル固有のパラメータ)） | 推論ライブラリのパラメータとして受理（§4.3） |
| オートピッチシフト / 話者マージ | UI スイッチ / スライダー露出 | 推論ライブラリの機能（§4.3） |
| モデル管理 | モデルスロット UI、paraphernalia ディレクトリの読み込み | paraphernalia 内 `model.version` でフォーマット世代を識別。**v1 / v2 のフォーマットは非互換**（§1.4） |
| ライセンス / 配布 | VCClient 本体は MIT（[w-okada §7.1](./w-okada-voice-changer.md#71-リポジトリ本体)） | paraphernalia 単位で個別のライセンス（§5）。VCClient はモデルのライセンスには関与しない |

### 6.2 「Beatrice v1 が Windows のみ」の起点 — モデル / 推論ライブラリ側の制約

VCClient の README で **「Beatrice v1 は Windows のみ」** と表に書かれている（[w-okada §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より)）が、これは**ホスト側の制約ではなく、Beatrice 1 系の推論バイナリ（Beatrice API 1.1.0 JVS Corpus Edition）の提供 OS が Windows のみであることが起点**と本ラボでは整理する。

- VCClient 自体は Mac 版 (`vcclient_mac_xxx.zip`) / Linux（リポジトリクローン）/ Colab Notebook を持っており（[w-okada §2.4](./w-okada-voice-changer.md#24-配布形態とエディション)）、**ホストとしては複数 OS で動く**。
- ただし、Beatrice 1 系を VCClient から呼ぶには **Beatrice 1 系の推論バイナリ**が必要で、そのバイナリは **w-okada/voice-changer 同梱 README（`server/voice_changer/Beatrice/`）に Windows 版のみ案内されている**（§5.4）。
- Beatrice 2 系の推論ライブラリは **公式 VST バイナリ自体が「OS: Windows® 10/11」と公式サイトで明記**（[§2.3](#23-入出力と動作モデルの位置関係公式-vst-としての形)）。VCClient の v.2 系で Beatrice v2 を扱えるかどうかは Mac / Linux ビルドにおいて未確認（**ホスト側 OS と推論ライブラリ側 OS のクロス対応表は本ラボでは未整理**。§9 で起票）。
- **公式トレーナー（`fierce-cats/beatrice-trainer`）は Linux / Windows / Colab で動作**（§3.1）。**学習は OS 制約が緩く、推論バイナリが Windows のみ**という非対称構造。

→ **VCClient の Beatrice v1 / v2 サポート OS は推論ライブラリ側の都合**で決まっており、ホスト機能（device mode / monitor 出力 / GAIN 等）の OS 対応とは別問題、というのが本ラボの結論。

### 6.3 「同じ UI 名でも担当が違う」紛らわしい点

[rvc.md §6.2](./rvc.md#62-同じ-ui-名でも担当が違う紛らわしい点) / [so-vits-svc.md §6.2](./so-vits-svc.md#62-同じ-ui-名でも担当が違う紛らわしい点) と同じ書式で、Beatrice 固有の紛らわしさを整理する。

- **TUNE / pitch**: VCClient の共通 UI 上では RVC でも Beatrice でも同じ位置に出る半音シフトだが、内部処理は別物。RVC は **選択した F0 抽出器の結果に対するシフト**だが、Beatrice は **PitchEstimator が出した F0 に対するシフト**で、F0 抽出器選択 UI が存在しない（§4.2 / §4.4）。
- **formant**: RVC / so-vits-svc 系での formant 操作と Beatrice の formant は **モデル構造が違うため挙動が違う可能性**がある。Beatrice では学習時 augmentation で formant shift が組み込まれており（§3.4）、推論時の formant パラメータはこの augmentation を逆向きに展開する形になっていると推測されるが、公式 README で内部実装を語った記述は無い（§4.3 / §9）。
- **チャンク（CHUNK）**: VCClient 共通 UI 上の CHUNK は**ホスト側のバッファ長**で、Beatrice 内部の処理単位とは独立。Beatrice 推論ライブラリは StreamVC 系のストリーム前提アーキテクチャ（§2.1）だが、**「CHUNK を変えるとモデル内部のコンテキスト長も変わる」わけではない**（CHUNK を変えると 1 回の推論呼出に渡す音声長が変わるだけ）。
- **「話者マージ」と「Voice Morphing Mode」**: §4.3 のとおり、**VCClient 側呼称と公式 VST 側呼称が違う同じ機能**だと本ラボでは整理。これは Beatrice 固有の混乱要素で、ユーザが情報を探すときに「話者マージ」と「Voice Morphing Mode」を別物として扱わないこと（§9 で原文裏取りタスク化）。

### 6.4 本ラボでこの分界を意識する場面

- **遅延の切り分け**: 公式が言う「外部測定 50 ms」（§1.1）は **VST 本体のレイテンシ**で、VCClient 経由の場合は VCClient のバッファ（CHUNK / EXTRA / 仮想オーディオ経路）が上に乗る。本ラボで遅延を計測する場合は **公式 VST 直 / VCClient 経由**で別ログを取り、ホスト側の上乗せ分を切り分ける（**実測は `experiments/` 配下、後続タスク**）。
- **品質の切り分け**: 同じ paraphernalia モデルを公式 VST と VCClient で読んで音が違う場合は、**前処理（Noise Gate / GAIN / Echo / Sup）の有無**を最初に疑う。**モデル本体の出力は理屈上一致する**はず（§4.1）。
- **OS 対応の事前確認**: Mac / Linux で Beatrice を試す前に、**(a) VCClient 側ビルドが Beatrice v1 / v2 を有効化しているか**、**(b) 公式 VST バイナリの OS 表記**、**(c) 公式トレーナー（Linux / Colab で動く）でモデルを作る方の経路で代替可能か**、の 3 点を確認する（§6.2 の非対称性）。
- **RVC からの移行**: F0 抽出方式 / INDEX という UI 概念が**消える**（§4.4）。RVC で詰めていた「rmvpe vs harvest」「INDEX 比率」のような調整軸がなくなり、代わりに **オートピッチシフト / 話者マージ / Voice Morphing** という Beatrice 固有の軸が増える。**チューニングの考え方が変わる**ことを意識する。

## 7. RVC / so-vits-svc との対比

§1〜§6 で個別に触れた [RVC](./rvc.md) / [so-vits-svc](./so-vits-svc.md) との差異を、**構造・入出力・学習・パラメータ・配布・ライセンス・運用感** の 7 軸で三系統並列に整理する。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**voice-changer-types** 上は三者とも §1.3 ニューラル変換 / §2.1 ローカル OSS / §3.1 話者依存型に分類されるが（[voice-changer-types §1.3](./voice-changer-types.md#13-ニューラル変換-neural-voice-conversion) / [§3.1](./voice-changer-types.md#31-話者依存型)）、**同じカテゴリの中での構造的差異** を浮かび上がらせるのが本節の目的（[so-vits-svc.md §7](./so-vits-svc.md#7-rvc-との対比) の二項対比を三系統対比に拡張する位置付け）。

### 7.1 構造レベルの違い — Retrieval / コンテンツ表現+話者条件付け / コンテンツ表現+内部 VQ+話者条件付け

三者とも「コンテンツ特徴量 + F0 + 話者性」という大枠は共有しているが、**話者性を出力に与える方法**と **コンテンツ表現の離散化／参照の有無** が根本的に違う。

```
RVC（Retrieval ベース）:
入力 → HuBERT → [faiss top1 で学習データ側の特徴量に置換] → VITS デコーダ → 出力
              （話者性は "置き換える特徴量プール" 自体に焼き込まれている）

so-vits-svc（コンテンツ表現+話者条件付け）:
入力 → SoftVC 系エンコーダ → [話者埋め込み + F0 を条件として連結] → VITS デコーダ → NSF-HiFiGAN → 出力
                          （話者性は埋め込みベクトルとして "条件付け" で与える）

Beatrice 2（コンテンツ表現+内部 VQ+話者条件付け）:
入力 → PhoneExtractor [出力に kNN-VC 系 vector quantization]
       PitchEstimator [F0 推定]
       → WaveGenerator [cross-attention で話者性を注入] → 出力
       （話者性は WaveGenerator の cross-attention に注入する話者埋め込み、
         retrieval index は持たない。コンテンツ表現は学習時に決めた VQ コードブックで離散化）
```

| 観点 | RVC | so-vits-svc | Beatrice 2 |
| --- | --- | --- | --- |
| 話者性の付与方式 | **Retrieval（faiss top1 近傍検索）** で学習データ側の HuBERT 特徴量に置換 | **話者埋め込みベクトル**を VITS デコーダの条件入力に連結 | **話者埋め込み**を WaveGenerator に **cross-attention で注入**（§2.1） |
| コンテンツ表現の離散化 | なし（HuBERT 連続特徴量を直接使う） | なし（連続表現を条件入力に渡す） | **PhoneExtractor 出力に内部 VQ**（kNN-VC 参考、§2.1）。外部 retrieval index は持たない |
| コンテンツ抽出器 | **`hubert_base.pt` 固定**（v1 = 9 層 256 次元 / v2 = 12 層 768 次元） | **`speech_encoder` で切替可能**（ContentVec / HuBERT-Soft / Whisper-PPG / WavLM 等） | **PhoneExtractor 固定**（trainer が事前学習重みを配る） |
| F0 抽出器の選択 | 4 種（pm / harvest / crepe / rmvpe） | **6 種**（pm / dio / harvest / crepe / rmvpe / fcpe） | **選択肢なし**。内蔵 PitchEstimator が常に使われる（§4.2） |
| Vocoder | HiFi-GAN 系 | **NSF-HiFiGAN**（別配布） | **WaveGenerator**（FIRNet 系 post-filter 踏襲、SiLU、損失に D4C） |
| 識別器 | HiFi-GAN multi-period（v2 で 3 段追加） | NSF-HiFiGAN 同梱 | **DiscriminatorP**（HiFi-GAN 系）+ **DiscriminatorR**（UnivNet 系）の 2 系統（§2.1） |
| 「VITS ベース」表記の有無 | 公式 README で VITS ベース明言 | 公式 README で VITS ベース明言 | **公式 README にそうした表記は無い**（§2.1 — 本書も「VITS ベース」とは書かない） |
| 後段補正 | なし | **Shallow Diffusion**（任意） | **なし**（cross-attention 注入が話者性付与の主構造） |

含意:

- **Beatrice 2 は「VITS ベース」を名乗っていない** 点が RVC / so-vits-svc と決定的に違う。trainer README は StreamVC / kNN-VC / FIRNet / UnivNet / EVA-GAN を参考に挙げており（"Reference" 節）、**VITS 系の系譜とは別**にデザインされている。
- **「内部 VQ」と「外部 Retrieval」は別物**。RVC は **学習データ側の HuBERT 特徴量プール**を実行時に参照するため、配布チェックポイントに **`.index` ファイル**が同梱される（[rvc.md §3.6](./rvc.md#36-学習成果物配布形態)）。Beatrice 2 の VQ は **学習時にコードブックを固定**し、推論時に追加のテーブルや index を読まない（§4.2）。
- **「コンテンツ抽出器の差し替え」は Beatrice ではユーザに開かれていない**（so-vits-svc の `speech_encoder` 切替に相当する自由度は無い）。代わりに **paraphernalia 単位でモデル全体が差し替わる**前提（§3.6）。

### 7.2 入出力構成の違い

| 観点 | RVC | so-vits-svc | Beatrice 2 |
| --- | --- | --- | --- |
| 出力サンプリングレート | **モデル別に選択可**（v1: 32k / 40k / 48k、v2: 32k / 48k） | **44.1 kHz 固定** | **24 kHz 固定**（学習時 in=16 kHz / out=24 kHz、§3.5） |
| 入力サンプリングレート | モデルの SR と揃える（FAQ Q18） | 任意（`resample.py` で 44.1 kHz に統一） | **16 kHz に内部で揃える前提**（trainer 設定） |
| 推論時の GPU 要件 | **GPU 前提**（FAQ Q8 が 4GB / fp16 / fp32 の 3 プロファイルを明示） | **GPU 前提**（公式に CPU 推論ガイドなし） | **GPU 不要**（trainer README "Prerequisites" / 公式サイト「CPU シングルスレッド動作」、§3.1） |
| 学習時の GPU 要件 | GPU 必須 | GPU 必須 | **GPU 必須**（VRAM 約 9 GB、RTX 4090 で約 40 分の参考値、§3.1） |
| 配布バイナリの OS | クロスプラットフォーム（Python / PyTorch ベース） | クロスプラットフォーム（同上） | **公式 VST は Windows のみ**（公式サイト「OS: Windows® 10/11」明記、§2.3）。**v1 推論バイナリも Windows のみ**（§6.2） |
| 動作形態 | スクリプト + WebUI、`realtime-gui` 同梱 | スクリプト中心（リアルタイム GUI 同梱なし、§1.3） | **VST / VST3 プラグインとして公式配布**（§2.3） |
| リアルタイム動作の公式主張 | **公式 README に "end-to-end 170 ms / ASIO 90 ms" を明示** | **明示的記述なし**。w-okada/voice-changer に委ねる立て付け | **「超低遅延」を公式 trainer README が明言**。公式サイトに「約 50 ms 遅延（外部測定の引用）」「約 35 MB」「CPU シングルスレッド」を併記（§1.1） |
| 公式の軽量性主張 | FAQ Q8 で 4GB 級 GPU 想定 | 明示記述なし | **「超低遅延・低負荷・低容量を特徴とする完全無料の声質変換 VST」**と trainer README が明言（§1.1） |

含意:

- **Beatrice の最大の差別化点は「推論に GPU が要らない」こと**。RVC / so-vits-svc が VRAM プロファイル前提で動くのに対し、Beatrice 2 は **CPU シングルスレッドで動かす設計**で、配信機のリソース配分が根本的に違う。「配信向け軽量を謳う系統」という一般評価は、公式 README / 公式サイトのこの主張で裏取れる（[plan](../plans/beatrice.md) の検証ポイント）。
- **出力 24 kHz 固定**は、RVC の 32〜48k / so-vits-svc の 44.1 kHz と比べて低い。配信用途では十分だが、歌唱の高域収録など 44.1 kHz 以上を前提とする素材を扱う場合は、ホスト側のリサンプル品質に依存する。
- **OS 非対称性**: 公式 trainer は Linux / Windows / Colab で動く一方、**公式 VST バイナリ・v1 推論バイナリは Windows のみ**（§6.2）。RVC / so-vits-svc が Python ベースで OS を選ばないのに対し、Beatrice は **学習は緩く、推論は厳しい**という非対称構造（§6.2）。

### 7.3 学習プロセスの違い

| ステップ | RVC | so-vits-svc | Beatrice 2 |
| --- | --- | --- | --- |
| 前処理の粒度 | **WebUI で一括**（無音分割 → 16 kHz リサンプル → HuBERT 抽出 → F0 抽出 → faiss index 構築） | **CLI 3 スクリプト分割**（`resample.py` → `preprocess_flist_config.py` → `preprocess_hubert_f0.py`） | **`python3 beatrice_trainer -d <data_dir> -o <out_dir>` の 1 コマンド**（§3.5）。前処理ステップをユーザに見せない |
| 学習データの粒度 | WebUI が無音分割（`max_sil_kept=5s`） | ユーザ側で 5〜15 秒に切ってから投入 | **ユーザの分割は任意**。ネストディレクトリ可、各話者ディレクトリ必須、対応フォーマットは WAV / FLAC / MP3（§3.2） |
| サンプリングレート要件 | モデルの SR と揃える | 任意（`resample.py` で揃える） | **任意**。trainer 内部で 16 kHz 入力 / 24 kHz 出力に揃える |
| モノラル制約 | あり | あり | **過去のリリースノートでステレオ対応を修正**（§3.2）。現行は緩い |
| 必要な学習データ量の目安 | FAQ Q10 が **「10〜50 分」**と明示 | **README に合計時間の明示なし**（1 ファイル 5〜15 秒の規定のみ、未確認） | **README に合計時間の明示なし**（§3 — 公式サイト Q&A 含めて目安は未記述。§9 で起票） |
| デフォルト学習ステップ数 | 公式 FAQ 数値の明示なし（エポック / バッチ運用） | 同上 | **`n_steps: 10000`（warmup 5000）**。**so-vits-svc / RVC の十数〜数十万ステップと桁が違って短い**（§3.5） |
| 配布された事前学習物の活用 | `hubert_base.pt` + `rmvpe.pt` + `pretrained{,_v2}/` 等 | ContentVec / Whisper-PPG / WavLM / NSF-HiFiGAN / RMVPE / FCPE 等を個別取得 | **trainer リポジトリ内に 3 種類の事前学習物**（PhoneExtractor / PitchEstimator / WaveGenerator、§3.3）を **一式同梱**。MIT License で配布 |
| 学習素材の使い分けの公式整理 | VCTK 由来 base を「著作権懸念なし」と公式が主張（[rvc.md §5.3](./rvc.md#53-事前学習モデルの学習素材ベースモデルが何で学習されたか)） | コンテンツ抽出器・Vocoder・base モデルは別配布で個別ライセンス | **「コンテンツ認識用」（ReazonSpeech / VocalSet）と「声質合成用」（LibriTTS-R）を構造的に分離**（§3.3）。「ReazonSpeech に含まれる話者の声に変換されることはない」と公式 Q&A が明言 |
| Data Augmentation の公式記述 | training_tips に断片的 | 公式記述薄い | **`default_config.json` に列挙**（ノイズ混合 / フォルマントシフト / リバーブ / LPF、§3.4）。**augmentation の formant_shift は学習時で、推論時 formant パラメータとは別物**（§4.3） |
| 配布形態 | **`.pth` + 任意 `.index`** の最大 2 ファイル | main G + config + 任意 cluster + 任意 diffusion ×2 の最大 5〜6 ファイル | **`paraphernalia_*/` ディレクトリ**（モデル本体 + `.toml` メタデータ + portrait 画像、§3.6） |

含意:

- **Beatrice のデフォルト学習ステップ数（10,000 step）は RVC / so-vits-svc と桁が違って短い**。これは事前学習物が十分に強い（LibriTTS-R で WaveGenerator が事前学習済み）前提で、**話者特化部分のみ追い学習する設計**であることを示唆する。**「RTX 4090 で約 40 分」**という参考値（§3.1）はこの短さの裏付け。
- **学習素材の責務分離**（ReazonSpeech / VocalSet = 認識用、LibriTTS-R = 合成用）は、so-vits-svc の歌唱コーパス学習で発生しがちな「ベース事前学習素材の話者性が結果に漏れるリスク」（[so-vits-svc.md §5.7](./so-vits-svc.md#57-歌声素材という性質に起因する追加リスクrvc-との差分の核心)）を **構造的に下げる設計**。公式 Q&A の「変換されることはない」明言が裏付け（§3.3）。
- **paraphernalia という配布単位**は Beatrice 独自。表示名・description・portrait 画像が `.toml` で編集できる（§3.6）ため、**配布時のメタデータ管理が公式に組み込まれている**。RVC の `.pth` / so-vits-svc の `main G + config` には無い概念。

### 7.4 推論パラメータの違い — 「同じ UI 名で違う処理」を中心に

[§6.3](#63-同じ-ui-名でも担当が違う紛らわしい点) で個別に触れた紛らわしいポイントを、三系統 1 表で再整理する（[so-vits-svc.md §7.4](./so-vits-svc.md#74-推論パラメータの違い--同じ-ui-名で違う処理を中心に) の二項対比を三項に拡張）。

| w-okada UI 名 / 役割 | RVC | so-vits-svc | Beatrice 2 |
| --- | --- | --- | --- |
| **INDEX** | `index_rate`（faiss top1 retrieval の寄せ比率） | `cluster_infer_ratio`（K-means or Feature Retrieval の寄せ比率） | **対応概念なし**。外部 retrieval index を持たない（§4.2） |
| **TUNE / pitch** | `f0_up_key`（半音単位ピッチシフト、選択した F0 抽出器の結果に対して適用） | `--trans`（半音単位ピッチシフト） | **`pitch`**（半音単位、PitchEstimator が出した F0 に対して適用、§4.3） |
| **F0 Det** | 4 種選択（pm / harvest / crepe full・tiny / rmvpe） | **6 種選択**（pm / dio / harvest / crepe / rmvpe / fcpe） | **選択不可**。内蔵 PitchEstimator のみ（§4.2） |
| **formant** | （主要 UI には露出薄。`x_pad` 等で側面的に影響） | （主要 UI には露出薄。`-lea` が音量包絡寄せで近い役割） | **`formant`**（§4.3）。学習時 augmentation の `augmentation_formant_shift_*`（§3.4）と内部接続している可能性が高いが公式記述なし |
| **オートピッチシフト** | 対応 UI なし | 対応 UI なし（`-a` / `--auto_predict_f0` は別概念で歌声では off 推奨） | **Beatrice 固有**。入力話者と目標話者の声域差から pitch を自動推定（§4.3） |
| **話者マージ / Voice Morphing Mode** | 対応 UI なし | 静的話者融合（`spk_mix_dict`）/ 動的（`-usm`）あるがリアルタイム UI 露出なし | **Beatrice 固有**。WaveGenerator の cross-attention 話者注入を複数モデル間で線形補間（§4.3。公式 VST 呼称は **Voice Morphing Mode**、VCClient 呼称は **話者マージ** — 同一機能と本ラボでは整理） |
| GAIN（in/out） | ホスト側、`rms_mix_rate` とは独立 | ホスト側、`-lea` とも独立 | **ホスト側**。Beatrice 2 は **loudness loss** で学習されており（trainer リリースノート 2025-08-31）、**入力音量を一定範囲で受け取る前提**（§6.1） |
| CHUNK / EXTRA | ホスト側（リアルタイム用バッファ管理） | ホスト側（同上） | **ホスト側**。Beatrice 推論ライブラリは StreamVC アイデアを参考にしたストリーム前提だが、**CHUNK / EXTRA を変えてもモデル内部のコンテキスト長は変わらない**（§6.3） |

Beatrice 固有で **RVC / so-vits-svc にも対応するスイッチが無い** もの:

- **オートピッチシフト**（§4.3）— pitch の自動値設定。RVC / so-vits-svc の手動 TUNE には対応概念が無い
- **話者マージ / Voice Morphing Mode**（§4.3）— **リアルタイム UI 上での**話者線形補間。so-vits-svc に `spk_mix_dict` はあるがリアルタイム UI 上に露出するものではない
- **ピッチ推定の範囲設定**（公式 VST 2.0.0-rc.0 で追加、§4.3）— PitchEstimator の出力範囲を絞る UI パラメータ

RVC / so-vits-svc 固有で **Beatrice には対応するスイッチが無い** もの:

- **F0 抽出方式の選択**（pm / harvest / crepe / rmvpe / dio / fcpe）— Beatrice は内蔵 PitchEstimator のみ（§4.2）
- **INDEX / cluster / Feature Retrieval**（RVC `index_rate` / so-vits-svc `cluster_infer_ratio`）— Beatrice は外部 retrieval index を持たない（§4.2）
- **コンテンツ抽出器の差し替え**（so-vits-svc `speech_encoder`）— Beatrice は PhoneExtractor 固定（§7.1）
- **Shallow Diffusion**（so-vits-svc 任意）— Beatrice に後段補正の概念は無い（§7.1）
- **`protect`（子音保護、RVC）** / **`rms_mix_rate`（RVC）** / **`-lea`（so-vits-svc loudness envelope adjustment）** — 直接対応は無し（Beatrice は loudness loss を学習時に組み込み済み）

含意:

- **RVC からの移行で消える UI 概念**: **F0 抽出方式の選択**と **INDEX**。これは [§6.4 RVC からの移行](#64-本ラボでこの分界を意識する場面) の通り、チューニング軸そのものが変わる。
- **so-vits-svc からの移行で消える UI 概念**: **コンテンツ抽出器の選択**と **Shallow Diffusion**、それから **`-lea` / `-ns` / `-eh` 等の多数の細かい補正パラメータ**。Beatrice では **モデル選択（paraphernalia）+ pitch / formant / 話者マージ**の 3 軸前後でだいたい収まる。
- **Beatrice 固有の追加軸**は **オートピッチシフトと話者マージ**。両者とも **モデル側の埋め込み構造**に直結する機能で、ホスト側で再現することはできない。

### 7.5 配布形態の違い — 「公式が話者特化モデルを配布するか」が最大の分岐

| 観点 | RVC | so-vits-svc | Beatrice |
| --- | --- | --- | --- |
| 公式配布の話者特化モデル | **VCTK 由来 base model**（Hugging Face、[rvc.md §5.2](./rvc.md#52-事前学習モデルの配布)） | **存在しない**（部品のみ配布） | **存在する**。公式サイトで **キャラクター入りエディションを 3 種**（つくよみちゃん / 刻鳴時雨 / OLUNE）配布。**公式モデル配布リスト Notion ページ**もあり（§1.3 / §5.3） |
| 公式配布の事前学習部品 | `hubert_base.pt` / `rmvpe.pt` / `pretrained{,_v2}/` | ContentVec / HuBERT-Soft / Whisper-PPG / WavLM / NSF-HiFiGAN / RMVPE / FCPE 等多数 | **PhoneExtractor / PitchEstimator / WaveGenerator の事前学習重み**を trainer リポジトリ内に **一式同梱**（§3.3、MIT で配布） |
| 配布元の数 | RVC-Project Hugging Face | 部品ごとに別ホスト | **公式サイト + 公式 GitHub Organization + Hugging Face**（trainer）+ **w-okada/voice-changer（v1 JVS Corpus Edition）** の 4 系統 |
| 配布物のファイル単位 | `.pth` + 任意 `.index` | main G + config + 任意 cluster + 任意 diffusion ×2（最大 5〜6 ファイル） | **paraphernalia ディレクトリ**（モデル + `.toml` メタデータ + portrait 画像）（§3.6） |
| キャラクター入りモデルの公式取り扱い | **公式リポジトリは話者特化を配布しない原則**。キャラ声はコミュニティ配布 | **同上**。コミュニティ配布（歌声寄り）に依存 | **公式自身がキャラ入りエディションを配布**し、**個別 EULA ページを各エディションに用意**（§5.3）。**運用面で他 2 系統と決定的に違う** |
| モデル形式 | `.pth`（汎用 PyTorch 形式） | `.pth` + JSON | **独自形式**（[w-okada #1523 ディスカッション](https://github.com/w-okada/voice-changer/discussions/1523)：「Beatrice works with Beatrice voices. They are not the same as pth or onnx voices」、§1.3） |
| Vocoder の同梱 | コード内蔵（HiFi-GAN 系） | NSF-HiFiGAN は別配布（openvpi/vocoders） | **WaveGenerator は paraphernalia に含まれる**（モデル本体の一部） |

含意:

- **「公式自身がキャラクター入りモデルを配布する」のは三系統で Beatrice だけ**。これは [plan](../plans/beatrice.md) の主要観察点の 1 つで、**ライセンス判断の出発点が違う**（RVC / so-vits-svc は「コミュニティ配布をどう扱うか」、Beatrice は **「公式 EULA をどう読むか」が先頭に来る**、§5.3）。
- **モデル形式が独自**で、**`.pth` / `.onnx` と互換性が無い**（§1.3）。RVC / so-vits-svc のような「`.pth` を直接覗いてレイヤ構造を確認する」運用は Beatrice では取りにくい（**仕様文書が公式に公開されているかは未確認**、§9）。
- **paraphernalia という配布パッケージ単位**で、**表示メタデータ・portrait・description が `.toml` で編集可能**（§3.6）。これは VST / VCClient で UI に出ることを前提にした設計で、RVC / so-vits-svc には対応概念がない。

### 7.6 ライセンスと規約の違い

| 観点 | RVC | so-vits-svc | Beatrice |
| --- | --- | --- | --- |
| コード本体のライセンス | **MIT**（[rvc.md §5.1](./rvc.md#51-リポジトリ本体のライセンス)） | **AGPL-3.0** | **MIT**（公式 VST ソース [`prj-beatrice/beatrice-vst`](https://github.com/prj-beatrice/beatrice-vst) / 公式トレーナー [`fierce-cats/beatrice-trainer`](https://huggingface.co/fierce-cats/beatrice-trainer) 両方、§5.2 / §5.5） |
| ネットワークサービス組み込み時のソース開示義務 | なし | **あり**（AGPL） | なし（MIT） |
| 公式の利用目的明文化 | 商用利用への明示的制限なし | **README で「学術目的限定 / 配信投稿時の入力素材明示義務 / 違法・宗教・政治目的禁止」を明文化** | **「完全無料の声質変換 VST」と公式 trainer README が明言**。統合 EULA の所在は **未確認**（§5.1）。**キャラクター入りエディションは個別 EULA**（§5.3）、**v1 JVS Corpus Edition は営利目的禁止**（§5.4） |
| 実在人物利用に関する公式スタンス | 明示的な記述なし | 「実在人物への適用は開発者の本来の意図から外れる」と明言 | **明示的な記述は本ラボの確認範囲では見当たらない**（§9 で起票候補） |
| 公式 base / 公式話者モデルの素材ライセンス | VCTK 由来で「著作権懸念なし」と公式主張 | 公式 base なし。部品は個別ライセンス | **trainer の事前学習重みは MIT**（§5.5）。素材は **ReazonSpeech / VocalSet / DNS Challenge / LibriTTS-R** で、**「コンテンツ認識用」と「声質合成用」が公式 Q&A で構造的に分離**（§3.3） |
| コミュニティ配布チェックポイントの学習素材ジャンル | 主に話し声 | 主に歌声（楽曲権利 + 編曲権 + 実演家権が絡む比率が高い） | **公式キャラエディションが主軸**（コミュニティ配布チェックポイントは公式 Notion 配布リスト経由が前提、§5.3） |
| リポジトリ管理状態 | アクティブ | **2023-11-11 にアーカイブ済み** | **アクティブ**（公式 trainer / 公式 VST 両方） |
| 配信用途での判断レイヤ数 | コード（MIT）+ 配布チェックポイント | コード（AGPL）+ 規約（学術目的）+ 配布チェックポイント + 歌唱権利 | **コード（MIT）+ 公式 VST バイナリ「完全無料」+ キャラエディション個別 EULA + v1 JVS Corpus Edition 営利禁止 + ユーザ作成モデルの素材規約** の最大 5 段（§5.6） |

含意:

- **コード本体のライセンスでは Beatrice と RVC が並ぶ（MIT）**が、**Beatrice はモデル配布レイヤで EULA が積層する**（公式キャラエディション / JVS Corpus Edition）点が独特。RVC のようにコード + 配布チェックポイントの 2 段ではなく、**最大 5 段で判断する**必要がある（§5.6）。
- **AGPL-3.0 の伝播範囲を気にしなくてよい**のは Beatrice / RVC の 2 系統。w-okada/voice-changer 経由で複数モデルを混在ロードする場合の AGPL 伝播論点（[so-vits-svc.md §5.1](./so-vits-svc.md#51-リポジトリ本体のライセンス)）は **Beatrice 単独利用時には発生しない**。
- **v1 JVS Corpus Edition の「営利目的禁止」が配信収益化の論点**（§5.4）。**v2 系のキャラエディションは個別 EULA**で、v1 系の制約を v2 系全体に拡張して読んではいけない。

### 7.7 運用感の違い — 配信用途での "重さ" の差

[so-vits-svc.md §7.7](./so-vits-svc.md#77-運用感の違い--配信用途での-重さ-の差) の二項対比を三項に拡張する。実測ではなく構造から導かれる **予想される運用感**（コミュニティで一般に言われている範囲を含む）として書く。

| 観点 | RVC | so-vits-svc | Beatrice |
| --- | --- | --- | --- |
| 初回セットアップの手数 | 中（HF から base 一式 + 自前 ckpt） | **大**（多元的な部品取得 + 自前学習または配布物の完全性チェック） | **小**（公式 VST バイナリ + 公式キャラエディション）/ **中**（VCClient + paraphernalia の場合） |
| GPU の必要性（推論時） | **必須** | **必須** | **不要**（CPU シングルスレッド、§7.2） |
| モデル差し替え時の構成管理 | 軽（`.pth` + 任意 `.index`） | **重**（最大 5〜6 ファイルのセット管理） | **中**（paraphernalia ディレクトリ単位、`.toml` メタデータ含む） |
| 推論パラメータの試行錯誤コスト | 中（7 個程度、公式ガイドあり） | **大**（20 個超、公式ガイドが薄いものあり） | **小**（pitch / formant / オートピッチシフト / 話者マージ 程度。F0 抽出器・INDEX が無い分軸が減る） |
| 「歌声 → 話し声」転用時の挙動 | 元から話し声中心、転用ストレス低 | 公式が "Singing" を強調しており、話し声転用は `-a` 等のスイッチ理解が必要 | **歌声・話し声ともサポート**（v2.0.0-rc.0 で VocalSet 追加 + PitchEstimator のピッチ上限引き上げ、§2.2） |
| ライセンス判断の負荷 | 軽（MIT + 配布物個別チェック） | **重**（AGPL + 学術目的規約 + 歌唱権利 + 配布物個別チェック） | **中**（MIT + 公式キャラエディション個別 EULA、§5.6）。v1 JVS Corpus Edition を選ぶ場合は **重**（営利禁止） |
| 公式の改善継続性 | 公式リポジトリはアクティブ | **アーカイブ済み**（4.1-Stable で凍結） | **アクティブ**（公式 trainer は 2025-08-31 リリースノートが trainer README に確認できる） |
| 配信用途での参考実装 | 公式リポジトリに `realtime-gui` 同梱、w-okada/voice-changer もサポート | w-okada/voice-changer 経由が事実上の標準 | **公式 VST 本体がリアルタイム実装**（VST ホスト経由）。w-okada/voice-changer 経由は **同じ推論ライブラリを共有**と公式が明言（§4.1） |
| OS 制約 | クロスプラットフォーム | クロスプラットフォーム | **公式 VST バイナリは Windows のみ**（§2.3）。trainer は Linux / Windows / Colab 可（§3.1） |

→ **本ラボの立て付け**: 三系統の中で **Beatrice は「配信機の GPU 予算を空けたい / セットアップを軽くしたい」場面に第一候補**。RVC は「自前学習で話し声特化を作る」流れに馴染み、so-vits-svc は「歌声特化 / コンテンツ抽出器を差し替えたい」場面の選択肢。Beatrice の独自利点（CPU 推論・公式キャラエディション・公式 VST）と独自制約（Windows のみ・モデル形式独自・モデル形式の仕様文書未確認）を把握した上で選ぶ。

### 7.8 1 枚早見表（三系統）

| 軸 | RVC | so-vits-svc | Beatrice 2 |
| --- | --- | --- | --- |
| 話者性の与え方 | Retrieval（faiss top1） | 話者埋め込み（条件付け） | **話者埋め込み（cross-attention 注入）+ 内部 VQ** |
| コンテンツ抽出器 | `hubert_base.pt` 固定 | `speech_encoder` で切替可 | **PhoneExtractor 固定** |
| 外部 retrieval index | あり（`.index`） | あり（cluster / Feature Retrieval） | **なし** |
| 1 ckpt の話者数 | 1 | 複数（`n_speakers` 席） | 1（**Voice Morphing で複数モデル間補間は可能**） |
| 入力 / 出力 SR | 32k / 40k / 48k | 入力任意 / 出力 44.1 kHz 固定 | **入力 16 kHz / 出力 24 kHz 固定** |
| 後段補正 | なし | Shallow Diffusion（任意） | **なし** |
| 推論パラメータ数 | ~7 | ~20+ | **~5**（pitch / formant / オートピッチシフト / 話者マージ / ピッチ推定範囲） |
| 配布物ファイル単位 | `.pth` + 任意 `.index` | 1〜6 ファイル | **paraphernalia ディレクトリ** |
| 公式話者特化モデル | あり（VCTK base） | なし | **あり（キャラエディション 3 種 + Notion 配布リスト）** |
| コード本体ライセンス | **MIT** | **AGPL-3.0** | **MIT**（VST ソース / トレーナー両方） |
| モデル配布のライセンス | コミュニティ配布が中心 | コミュニティ配布（歌唱権利あり） | **公式キャラ個別 EULA + v1 JVS Corpus Edition 営利禁止** |
| 公式の利用目的 | 制限明示なし | **学術目的限定** | 「完全無料」表記。実在人物への明示スタンスは未確認 |
| 学習素材ジャンル | 主に話し声 | 主に歌声 | **話し声 + 歌声（v2.0.0-rc.0 で歌唱対応強化）** |
| 公式リポジトリ状態 | アクティブ | **アーカイブ済み (2023-11-11)** | **アクティブ** |
| F0 抽出選択肢 | 4 種 | 6 種 | **選択不可（内蔵 PitchEstimator）** |
| 推論時 GPU 要件 | 必須 | 必須 | **不要（CPU シングルスレッド）** |
| OS 制約 | クロスプラットフォーム | クロスプラットフォーム | **公式 VST バイナリは Windows のみ** |
| 動作形態 | スクリプト + WebUI / `realtime-gui` 同梱 | スクリプト中心 | **VST / VST3 プラグイン** |
| リアルタイム公式主張 | end-to-end 170 ms / ASIO 90 ms | なし | **超低遅延・低負荷・低容量。約 50 ms（外部測定引用）/ 約 35 MB** |

## 8. voice-changer-types §4 評価軸への暫定マッピング

[voice-changer-types §4](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) の評価軸に、**Beatrice（モデル/アルゴリズムとしての立場）** の暫定マッピングを置く。Beatrice 2 は **公式 VST がリアルタイム実装そのもの**である点で RVC / so-vits-svc と立て付けが少し違うが、w-okada/voice-changer 経由で扱う場合の IO 構成・エコシステム面はホスト側との責任分界（§6）をそのまま反映する。実測値は本ドキュメントには書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。

| 評価軸 | Beatrice（モデル/アルゴリズム）としての暫定マッピング | 出どころ / 補足 |
| --- | --- | --- |
| レイテンシ | 公式サイトに **「約 50 ms 遅延（外部測定の引用）」**と明記されている（§1.1）。「**超低遅延**を特徴とする」と公式 trainer README が明言。**本ラボでは未計測**で、配信用途では実際の値はホスト側のチャンク化遅延（CHUNK / EXTRA）と合算される。**VCClient 経由か公式 VST 直か**で前段バッファ量が変わる（§6.4） | §1.1 / §2.3 / §6.4 |
| 音質 | モデル単体としての音質は **paraphernalia（PhoneExtractor + PitchEstimator + WaveGenerator + 話者埋め込み）固定** + **推論時の pitch / formant / オートピッチシフト / 話者マージ** で決まる。**コンテンツ抽出器や Vocoder の差し替え軸はない**（§7.1）。**学習素材のジャンル**（話し声 / 歌声）は paraphernalia 単位で決まる（v2.0.0-rc.0 以降は歌唱対応強化、§2.2）。**実測の自然さ・破綻のしにくさは本書では扱わない** | §2.1 / §2.2 / §4.3 |
| 必要 GPU 性能 | **推論時 GPU 不要**（公式 trainer README "Prerequisites" / 公式サイト「CPU シングルスレッド動作」、§3.1 / §7.2）。**学習時は GPU 必須**（VRAM 約 9 GB、RTX 4090 で約 40 分の参考値、§3.1）。GPU が用意できない場合は [`w-okada/beatrice-trainer-colab`](https://github.com/w-okada/beatrice-trainer-colab) が公式 README からリンクされている | §3.1 / §7.2 |
| CPU 負荷 | **「CPU シングルスレッド動作」と公式サイトが明言**（§1.1）。「**低負荷**」と公式 trainer README にも明記。**本書では未計測**で、配信ソフト併走時の余裕度は実機で要確認 | §1.1 / §7.2 |
| 入出力構成 | **モデル単体は VST / VST3 プラグインとして配布**（§2.3）— RVC / so-vits-svc のような「単体スクリプト」ではない。公式 VST 自体が VST ホスト経由でリアルタイム IO を持つ。VCClient 経由の場合は **同じ推論ライブラリを公式 VST と共有**と公式 Q&A が明言（§4.1）し、IO 構成は w-okada/voice-changer のホスト側責任（§6） | §2.3 / §4.1 / §6.1 |
| モデル形態 | voice-changer-types **§3.1 話者依存型**。1 paraphernalia = 1 話者だが、**話者マージ / Voice Morphing Mode で複数モデル間補間が可能**（§4.3）。新しい声を増やすには学習が必要だが、**事前学習物が強い**（LibriTTS-R で WaveGenerator が事前学習済み）ため、デフォルトで **10,000 step / RTX 4090 約 40 分**と学習コストが軽い（§3.5 / §7.3） | §1.3 / §3.5 / §3.6 / §4.3 |
| カスタマイズ性 | **学習側**: trainer の `default_config.json` で **augmentation（ノイズ / フォルマント / リバーブ / LPF）**・**学習ステップ数**・**事前学習物の差し替え**を編集可能（§3.4 / §3.5）。**コンテンツ抽出器の差し替え軸はない**（§7.1）。**推論側**: pitch / formant / オートピッチシフト / 話者マージ / ピッチ推定範囲設定の 5 個前後（§4.3）。**RVC（~7 個）と so-vits-svc（~20 個）の中間より軽い**（§7.4）。**Voice Morphing / オートピッチシフトは Beatrice 固有**の調整軸 | §3.4 / §3.5 / §4.3 / §7.4 |
| 配信での利用可否 | **コード本体（公式 VST ソース・公式トレーナー）は MIT**（§5.2 / §5.5）。**公式 VST バイナリは「完全無料」**と trainer README が明言（§5.1）。**統合 EULA の所在は未確認**（§9）。**キャラクター入りエディション（つくよみちゃん / 刻鳴時雨 / OLUNE）は個別 EULA**（§5.3）。**v1 JVS Corpus Edition は営利目的禁止**（§5.4）。**実在人物への明示スタンスは未確認**。本ラボでは [CLAUDE.md](../../CLAUDE.md) 方針により**第三者の声を許諾なく再現する用途には誘導しない**、特定チェックポイントの取得導線は記載しない | §5.1 / §5.2 / §5.3 / §5.4 / §5.5 / §5.6 |
| エコシステム | 公式 Project Beatrice が **アクティブ**（公式 trainer / 公式 VST / 公式サイト / 公式 Notion 配布リスト、§1.2）。**公式自身がキャラクター入りエディションを配布する**点が RVC / so-vits-svc と独自（§7.5）。配信向け対応は **(a) 公式 VST 直 / (b) VCClient（w-okada/voice-changer）/ (c) beatrice-client（[aq2r/beatrice-client](https://github.com/aq2r/beatrice-client)）** の 3 系統で、いずれも同じ推論ライブラリを使う（§4.1）。**w-okada/voice-changer v.1 / v.2 系両方で Beatrice 系をサポート**（[w-okada §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より)） | §1.2 / §4.1 / §6 |
| コスト | **コード本体（MIT）・公式 VST バイナリ・公式トレーナー・キャラエディション**いずれも「完全無料」表記（§5.1）。**推論に GPU が要らない**ため、配信機を新規購入する場合の総額が三系統で最も低い見込み（§7.2）。**自前モデル学習を行う場合のみ GPU が要る**が、Colab Notebook ルートが公式から案内されている（§3.1）。クラウド利用料は不要 | §5.1 / §5.2 / §3.1 / §7.7 |

モデル/アルゴリズム単体で値が出せる評価軸は **モデル形態（§3.1 話者依存 + Voice Morphing で補間可）/ カスタマイズ性（学習・推論パラメータの自由度は中程度。コンテンツ抽出器差し替え軸は無し）/ 配信での利用可否（コード MIT + 公式 VST 完全無料 + キャラエディション個別 EULA + v1 JVS Corpus Edition 営利禁止 + 素材規約）/ コスト（OSS、推論 GPU 不要）** の 4 つで、**実機計測で値が確定する** のは **レイテンシ・音質・CPU 負荷**。**必要 GPU 性能**は推論時に「不要」と公式が明言している点が三系統で唯一（§7.2）。w-okada/voice-changer 側の評価軸マッピング（[w-okada §8](./w-okada-voice-changer.md#8-voice-changer-types-§4-評価軸への暫定マッピング)）と組み合わせて、**ホスト × モデル**の二段でようやく voice-changer-types §4 の表が埋まる、という構造は [rvc.md §7](./rvc.md#7-voice-changer-types-§4-評価軸への暫定マッピング) / [so-vits-svc.md §8](./so-vits-svc.md#8-voice-changer-types-§4-評価軸への暫定マッピング) と同じ。

**RVC / so-vits-svc との対比視点での要点**（§7 のサマリを評価軸ごとに再投影）:

- レイテンシ: **公式が「約 50 ms（外部測定引用）」を明示**しており、RVC（170 ms / 90 ms 明示）と比べても短く、so-vits-svc（数値明示なし）よりは比較可能。**実測ではないが公式情報源で軽量性が裏取れる**唯一の系統
- 必要 GPU 性能 / CPU 負荷: **推論 GPU 不要は三系統で Beatrice のみ**。配信機のリソース配分が根本的に違う
- 入出力構成: **VST プラグインとして配布**される唯一の系統。DAW / VST ホスト経由のセットアップが可能
- カスタマイズ性: 推論パラメータ数は **so-vits-svc（~20）> RVC（~7）> Beatrice（~5）**。**「軸が少ない = 試行錯誤コストが低い」**という方向で軽い
- 配信での利用可否: **MIT + 公式 VST 完全無料 + キャラエディション個別 EULA** という構造は **RVC（MIT + コミュニティ配布）** と **so-vits-svc（AGPL + 学術目的 + コミュニティ配布）** のどちらでもない第三のパターン
- エコシステム: **公式が話者特化モデルを直接配布する**唯一の系統（§7.5）
- コスト: 推論 GPU 不要 + 公式キャラエディション「完全無料」表記で、**新規参入コストが三系統で最も低い**

## 9. 未確認事項 / 後続タスク

本書 §1〜§8 を通して残った「未確認」マーカーを、**(A) 既存 TODO で吸収するもの / (B) 新規起票するもの / (C) 当面深追いしないもの** の 3 区分で整理する（[rvc.md §8](./rvc.md#8-未確認事項--後続タスク) / [so-vits-svc.md §9](./so-vits-svc.md#9-未確認事項--後続タスク) と並行な構成）。

### 9.1 既存タスクで吸収する未確認事項

[`TODO.md`](../../TODO.md) に既にある後続タスクで自然に拾えるもの。本書では結論を出さずに引き継ぐ。

- **公式 VST 同梱 UI のパラメータ列（一次情報）**（§4.3）— 「ピッチ推定の範囲設定」（公式 VST 2.0.0-rc.0 で追加）と VCClient UI の対応関係、オートピッチシフトと手動 pitch の併用挙動、formant パラメータと学習時 augmentation の formant_shift の内部接続関係 → `TODO.md` の **「w-okada/voice-changer の実測タスク用 `experiments/` テンプレート整備」** で UI 確認と併せて拾う
- **w-okada UI 上で Beatrice 選択時の CHUNK / EXTRA と Beatrice 内部処理単位の関係**（§4.4 / §6.3）— CHUNK 変更時に推論呼出長が変わるだけで内部コンテキストが伸びるわけではない、という本ラボの整理（公式 README 上の直接記述は無い）の実機裏取り → 同上の `experiments/` テンプレ整備で扱う
- **VCClient の Beatrice v1 / v2 サポート OS のクロス対応表**（§6.2）— ホスト側 OS（Mac / Linux / Colab）と推論ライブラリ側 OS（Beatrice v1 / v2 = Windows のみ）の組み合わせで実際に動く範囲の確認 → 同上
- **キャラクター入りエディション（つくよみちゃん / 刻鳴時雨 / OLUNE）の個別 EULA 本文の読み込み**（§5.3）— **配信収益化 / クレジット要件 / 二次配布の可否**を一次情報として確認 → `TODO.md` の **「w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認とキャラクター音声利用条件（つくよみちゃん / あみたろ / 琴葉茜 等）の整理」** で **Beatrice 系キャラエディションも対象に拡張する**形で扱う（つくよみちゃんは [w-okada §7.2](./w-okada-voice-changer.md#72-同梱-参照されるモデルの利用条件) でも触れられており、整理を本ラボで集約する利点が大きい）
- **公式モデル配布リスト Notion ページ掲載モデルそれぞれのライセンス**（§5.3）— 公式キャラ 3 種以外で配布されているモデルのライセンス整理 → 同 LICENSE 整理タスクで扱う

### 9.2 本タスクの follow-up として新規起票するもの

本書範囲では結論が出ず、かつ既存タスクでは吸収しきれない独立タスクは **現時点では起票しない**。理由:

- 公式 VST 同梱 PDF README / UI スクリーンショットの一次確認は **w-okada 実測テンプレ整備の上に重ねる**形が自然で、先に独立 TODO に立てると RVC / so-vits-svc 用テンプレと重複する
- Beatrice 1 のアーキテクチャを語る公式 README / 公式技術ブログの所在追加調査（§1.4 / §2.2）は、本ラボの配信用途では **Beatrice 2 で完結する**ため当面深追い不要（§9.3）
- Beatrice 2 の論文 / プレプリント / 公式技術ブログ（§2.1）が出てきた場合は trainer README より詳しい記述が得られる可能性があるが、**新規発見ベースで取り込む**形でよく、独立 TODO 化は不要

→ **新規 TODO 起票は 0 件**。実機検証段階・新規発見時に必要になった時点で改めて TODO 化する（[rvc.md §8.2](./rvc.md#82-本タスクの-follow-up-として新規起票するもの) / [so-vits-svc.md §9.2](./so-vits-svc.md#92-本タスクの-follow-up-として新規起票するもの) と同じ判断）。

### 9.3 当面は深追いしない領域

本ラボのスコープでは現時点で踏み込む必要がなく、必要になった時点で再開するもの（いずれも公式 README / 公式サイトの範囲を越えてコード読解または派生フォーク調査が要る項目）。

- **Beatrice の独自モデル形式の仕様文書**（§1.3）— `.pth` / `.onnx` と互換性が無いことは確認できたが、**公式の仕様文書が公開されているかは未確認**。配信用途では paraphernalia 単位で読めれば足り、仕様文書を読まないと触れない場面は無い
- **Beatrice 1 のアーキテクチャを語る公式 README / 公式技術ブログ**（§1.4 / §2.2）— v1 は本ラボでは w-okada/voice-changer 同梱の JVS Corpus Edition を起点に整理する方針で、内部実装の詳細には踏み込まない
- **Beatrice 2 の論文 / プレプリント**（§2.1）— trainer README より詳しい記述（モジュールの層数 / パラメータ数 / 中間次元）は無い。**新規発見ベースで取り込む**
- **w-okada/voice-changer 同梱の v1 系 API が公式サイトの v1 配布物と同一物か**（§1.4 / §5.4）— v1 系は本ラボでは JVS Corpus Edition のみ参照する方針で、公式サイト側の v1 配布の所在まで遡る必要は当面なし
- **VST バイナリの統合 EULA の所在**（§5.1）— 「完全無料」表記までは確認済み、配信運用は **キャラエディション個別 EULA を一次情報**として進める方針で当面足りる
- **派生クライアント実装の個別深掘り**（[`aq2r/beatrice-client`](https://github.com/aq2r/beatrice-client) / [`w-okada/beatrice-trainer-colab`](https://github.com/w-okada/beatrice-trainer-colab) など）— plan の「含めない」セクションに記載済み（[plan](../plans/beatrice.md)）。**公式系の 4 種類**（§1.2）に限定して本書は構成している
- **WaveGenerator の cross-attention 話者注入と話者マージ / Voice Morphing の内部接続**（§4.3 / §6.3）— 「複数モデルの話者埋め込みを線形補間できる構造」までは本ラボで整理可能だが、**重み混合のアルゴリズム詳細**はコード読解レベル。実機での挙動把握で十分
