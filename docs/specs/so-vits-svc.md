# so-vits-svc (SoftVC VITS Singing Voice Conversion)

> [voice-changer-types](./voice-changer-types.md) 上の位置付け: **技術アプローチ: 1.3 ニューラル変換（コンテンツ表現 + 話者条件付け系）/ 提供形態: 2.1 ローカル OSS / モデル形態: 3.1 話者依存**
>
> 本ページは [docs/plans/so-vits-svc.md](../plans/so-vits-svc.md) のスコープに沿って、**公式系リポジトリ（[svc-develop-team/so-vits-svc](https://github.com/svc-develop-team/so-vits-svc)、デフォルトブランチ `4.1-Stable`、2023-11-11 にアーカイブ済み）の README で述べられている内容**を中心にまとめる。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。
> 各項目で「公式に書かれている内容」「コミュニティで一般に言われている内容」「未確認」を区別する。
> [rvc.md](./rvc.md) と構成を揃え、§7 で構造比較を行う前提で書いている。
>
> **進捗:** Phase 1〜3 完了。

## 1. 概要 — 「so-vits-svc」が指す 4 つのレイヤ

「so-vits-svc」という名前は文脈によって少なくとも次の 4 つを指す。本ラボでは混同しないように分けて扱う（[rvc.md §1](./rvc.md#1-概要--rvc-が指す-3-つのレイヤ) と並行な整理）。

### 1.1 アルゴリズムとしての so-vits-svc

- 正式名称: **SoftVC VITS Singing Voice Conversion**（公式リポジトリのリポジトリ説明文より）。
- **SoftVC 系のコンテンツ表現抽出器**（後述の通り ContentVec / HuBERT 系などにバージョンと設定で切替）で入力波形から話者非依存の音声特徴を取り出し、**話者埋め込み**と **F0** を条件として **VITS ベースのデコーダ** に渡し、**NSF-HiFiGAN** で波形を生成する系統（詳細 §2）。
- 公式 README（英語）の説明:
  > 「The singing voice conversion model uses SoftVC content encoder to extract speech features from the source audio.」
  > 「Feature vectors are directly fed into VITS without the need for conversion to a text-based intermediate representation.」
  > 「The pitch and intonations of the original audio are preserved.」
  > 「The vocoder is replaced with NSF HiFiGAN to solve the problem of sound interruption.」
- voice-changer-types §1.3 で挙げた「**コンテンツ表現 + 話者条件付け系**」の代表例にあたる。[RVC](./rvc.md) が Retrieval（faiss kNN）で「学習データ側の特徴量に置き換える」設計だったのに対し、so-vits-svc は **コンテンツ表現 + 話者埋め込み + F0** を直接 VITS デコーダに与える素直な条件付け生成という構造の違いがある（詳細 §7 で対比）。
- 公式は **"Singing" Voice Conversion** を強調しており、README に明確に書かれている:
  > 「This project differs fundamentally from VITS… it focuses on Singing Voice Conversion rather than Text-to-Speech. TTS is not supported, and VITS is incapable of performing SVC tasks.」
  - とはいえ実運用としては話し声（配信用途）にも転用されている（[w-okada-voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) で v.1 系のサポート対象として so-vits-svc が挙がっている）。
  - **「歌声」前提で設計されていることが、学習データや配布チェックポイントの権利関係の論点を RVC とは違う方向に引っ張る**点は §5 で再掲する。

### 1.2 公式系リポジトリとしての so-vits-svc

- 本ラボが「公式」とみなすのは **[`svc-develop-team/so-vits-svc`](https://github.com/svc-develop-team/so-vits-svc)**（GitHub Organization `svc-develop-team` 配下）。
- **重要な前提**: 公式 README に「the author deleted the original repository」（**原作者は元のリポジトリを削除済み**）との記載があり、現在の `svc-develop-team/so-vits-svc` は **コミュニティによる再構成 / 継続開発**という立て付け。`svc-develop-team` という Organization 名そのものがコミュニティ団体名であり、**個人作者の公式リポジトリではなく、複数コントリビュータによる公式系**である点を本書では強調しておく。
- 同リポジトリは **2023-11-11 にアーカイブ済み**（GitHub 上で read-only 化）。**新規 commit・新規 issue は受け付けない**状態で、以降の機能追加は派生フォーク（§1.3）側に移っている。本書が記述する「so-vits-svc 公式」の挙動はすべて **アーカイブ時点（2023-11-11、`4.1-Stable` ブランチ）**の状態を指す。
- デフォルトブランチは **`4.1-Stable`**。それ以前のメジャーバージョン（3.0 / 4.0）に対応するブランチが履歴に残っていることが README から読み取れる（4.1-Stable の "Compatibility with 4.0" 節）。本書で「公式」と書くときは、特に断らない限り **`svc-develop-team/so-vits-svc` の `4.1-Stable` ブランチ**を指す。
- リポジトリの中身は **学習スクリプト + 推論スクリプト + 設定ファイル + ドキュメント**で、リアルタイム配信用の GUI は同梱されていない。リアルタイム配信用途では公式 README が **"Related Projects" として外部の `voice-changer` (w-okada) を「A client supports real-time conversion」**として紹介している（§1.3）。

### 1.3 派生フォークとの関係

公式 README の **"Related Projects" / "✨ A studio / A fork / A client"** で名指しされているのは次の 3 つ:

- **MoeVoiceStudio** — 「A studio that contains visible f0 editor, speaker mix timeline editor」（GUI 付きのスタジオ的派生）
- **so-vits-svc-fork（`voicepaw/so-vits-svc-fork`、もとは `34j` 個人）** — 「A fork with a greatly improved user interface」。本家がアーカイブされた後も active な派生として一般に言及される
- **voice-changer（`w-okada/voice-changer`）** — 「A client supports real-time conversion」。本ラボの [w-okada-voice-changer.md](./w-okada-voice-changer.md) で別途整理しており、so-vits-svc を **ロード対象モデルの 1 つ**として扱う立場（[w-okada-voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) のサポート表で v.1 系の対応モデルとして名指し）

これら以外にも **DDSP-SVC**（DSP × ニューラル）、**Diff-SVC**（拡散モデル系）などが歌声変換系で名前が挙がるが、これらは so-vits-svc の派生フォークというより **別系統のプロジェクト**で、voice-changer-types では §1.3 の別サブカテゴリに置く（[voice-changer-types §1.3](./voice-changer-types.md#13-ニューラル変換-neural-voice-conversion)）。本書では深掘りしない（プラン側スコープ外）。

本ラボでの取り扱い:

- 「so-vits-svc」と書いたときは **`svc-develop-team/so-vits-svc` の 4.1-Stable** を指す
- so-vits-svc-fork / MoeVoiceStudio などの派生は、`svc-develop-team` 系と**コードや設定ファイル形式に互換性がある可能性は高いが、本書では別物として扱う**（個別の機能追加・UI 変更は派生側に依存）
- w-okada/voice-changer 経由で so-vits-svc モデルをロードする場合、ホスト側がどの so-vits-svc 系のコードを参照しているか（4.0 / 4.1 / 派生フォーク互換）は [w-okada-voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) と本書の対応はまだ取れておらず **未確認**（§9.1 で実機確認タスクに引き継ぐ）

### 1.4 配布チェックポイントとしての so-vits-svc

- ここで言う「チェックポイント」は **ユーザー（または第三者）が `svc-develop-team/so-vits-svc` 系のコードで学習させた話者特化の `.pth` ファイル + 必要に応じて K-means クラスタリングモデル / shallow diffusion モデル**を指す（詳細 §5）。
- **公式リポジトリは「特定話者に変換するためのチェックポイントを配布していない」**。配布されているのは **コンテンツ表現抽出器（ContentVec / HuBERT 系）/ Vocoder（NSF-HiFiGAN）/ F0 抽出モデル（RMVPE / FCPE）** などの**部品**で、これらを揃えた上でユーザーが自分の学習素材を使ってターゲット話者の `.pth` を作る、というのが公式の前提（§5.2）。
- 配信界隈・歌声変換界隈で「so-vits-svc モデル」と言う場合、ほとんどが **コミュニティ（個人・サークル）が学習させて配布しているチェックポイント**を指す。これらの利用条件は **公式リポジトリのライセンス（AGPL-3.0、§5.1）とは独立に**、配布者の規約・学習素材の権利関係で判断する（[CLAUDE.md](../../CLAUDE.md) 方針との接点。§5.4 で再掲）。
- so-vits-svc は **歌声を前提に設計されており**、配布チェックポイントの学習素材も **歌声素材**であることが多い。歌唱録音は楽曲権利・実演家権利が絡みやすく、**RVC 側の話し声中心のチェックポイント以上に権利関係が複雑化しやすい**という性質を持つ（§5.7）。

### 1.5 「3.0 / 4.0 / 4.1」というバージョンの呼び方

- 公式リポジトリには 3.0 / 4.0 / 4.1-Stable の各メジャーバージョンに対応するブランチが履歴に残っており、**`4.1-Stable` が（アーカイブ時点での）デフォルトかつ最新**。
- **3.0 → 4.0 は非互換**: 公式 4.0 README に「the data set needs to be fully pre-processed again」と明記。サンプリングレートも 4.0 で **44.1 kHz に統一**された（§2 で再掲）。
- **4.0 → 4.1-Stable は互換性がある**: 4.1-Stable の README は「Feature input is changed to the 12th Layer of ContentVec Transformer output, And compatible with 4.0 branches」と明記し、`config.json` の `speech_encoder` を `vec256l9` に切り替えれば 4.0 系モデルを 4.1-Stable のコードで動かせると説明（§2.3）。
- 本書では特に断らない限り **「so-vits-svc」=「`svc-develop-team/so-vits-svc` の `4.1-Stable` ブランチ」**を指し、3.0 / 4.0 個別の挙動を書くときは明示的にバージョンを書き分ける。

## 2. アーキテクチャ概観

### 2.1 4 段構成（公式 README で確認できる範囲）

公式 README（英語版・中国語版）で言及されている要素を、本ラボの理解で 4 段に整理する（[rvc.md §2.1](./rvc.md#21-3-段構成公式-readme-で確認できる範囲) と並行）。

```
入力波形
   │
   ▼
[1] コンテンツ表現抽出  ── SoftVC 系コンテンツエンコーダ
   │       4.0 既定: ContentVec 9 層目（vec256l9, 256 次元）
   │       4.1 既定: ContentVec 12 層目（vec768l12, 768 次元）
   │       他に hubertsoft / whisper-ppg / wavlmbase+ 等の選択肢（§2.4）
   ▼
[2] 話者埋め込み + F0 条件付け
   │       話者は学習済みチェックポイント内で n_speakers 単位で持つ
   │       F0 抽出方式は推論時に crepe / pm / dio / harvest / rmvpe / fcpe から選択
   │       オプション: K-means クラスタ / RVC 由来の特徴検索（§2.4）
   │       オプション: loudness（音量）埋め込み（§2.4）
   ▼
[3] VITS ベースのデコーダ
   │       「VITS ベース」と明記。テキスト中間表現には変換しない
   │       4.0 で 44.1 kHz に統一済み
   ▼
[4] Vocoder
   │       NSF-HiFiGAN（公式が "音切れ対策" として明示的に置き換え）
   │       オプション: shallow diffusion による後段補正（§2.4）
   ▼
出力波形
```

公式に明示的に確認できる根拠（**公式に書かれている内容**）:

- **SoftVC コンテンツエンコーダ**: 「The singing voice conversion model uses SoftVC content encoder to extract speech features from the source audio.」（README）
- **テキスト中間表現を介さない**: 「Feature vectors are directly fed into VITS without the need for conversion to a text-based intermediate representation.」（README）
- **ピッチ保持**: 「The pitch and intonations of the original audio are preserved.」（README）
- **NSF-HiFiGAN による Vocoder 置換**: 「The vocoder is replaced with NSF HiFiGAN to solve the problem of sound interruption.」（README）
- **VITS との明確な切り分け**: 「This project differs fundamentally from VITS… TTS is not supported, and VITS is incapable of performing SVC tasks.」（README）
- **44.1 kHz 統一**: 「The sampling rate is unified to use 44100Hz.」（4.0 README）

**「VITS ベース」と書かれている部分は、RVC が「VITS based」と書いているのと同じく、エンコーダ／デュレーション／フローを含む生成型モデルとして扱う、というレベルで本ラボでは扱う**。VITS のどの部分を継承／差し替えているかのコード読解レベルの裏取りは本書のスコープ外（**未確認**、§9.3 で深追いしない領域として明記）。RVC とは「VITS ベース」という共通点はあるが、**入力側で Retrieval を挟むか、コンテンツ + 話者 + F0 を直接条件として与えるかが違う**（詳細 §7）。

### 2.2 SoftVC 系コンテンツ表現抽出器の選択肢

「SoftVC コンテンツエンコーダ」と一般化されているが、**実体は複数のコンテンツ表現抽出モデルから選んで使う**。公式 README で `config.json` の `speech_encoder` フィールドに指定できる値として列挙されているのは以下:

| `speech_encoder` 値 | 概略 | 補足 |
| --- | --- | --- |
| `vec256l9` | **ContentVec の 9 層目**、256 次元 | 4.0 系の既定。後方互換のために 4.1 でも指定可能（§2.3） |
| `vec768l12` | **ContentVec の 12 層目**、768 次元 | **4.1-Stable の既定** / 推奨（公式 README で "recommended" 表記） |
| `hubertsoft` | HuBERT-Soft 系統 | "SoftVC" の名前のもとになった系統（HuBERT Soft 論文ベース） |
| `whisper-ppg` | OpenAI Whisper の中間表現を流用（PPG: Phonetic PosteriorGram） | 4.1 で追加 |
| `whisper-ppg-large` | 上の large 版 | 同上 |
| `cnhubertlarge` | 中国語向け HuBERT large | — |
| `dphubert` | Distilled HuBERT 系 | — |
| `wavlmbase+` | WavLM ベース | — |

加えて ONNX 推論用の派生として **`vec256l9-onnx` / `vec256l12-onnx` / `vec768l9-onnx` / `vec768l12-onnx` / `hubertsoft-onnx`** が列挙されている。

公式 README が直接書いている "推奨" 級の表現は:

- **`vec768l12` を 4.1-Stable の既定**として扱っている（README 引用: "Feature input is changed to the 12th Layer of ContentVec Transformer output"）
- **`vec256l9` は 4.0 互換のために残されている**位置付け（README "Compatibility with 4.0" 節）

重要な観察:

- **so-vits-svc 4.1 は ContentVec を中心としつつ、Whisper-PPG / WavLM / HuBERT 派生まで「コンテンツ表現抽出器を入れ替えられる」設計**になっている。これは [RVC](./rvc.md) が **`hubert_base.pt` 一択**で v1/v2 の差が層番号と次元数だけだったのに対し、**抽出器そのもののモデルを切り替えられる**という拡張性の違い（§7.1 で対比）。
- 一方で、**実用上どの抽出器がどんな声質・歌声に向くかの公式ガイドは README に書かれていない**（**未確認**。コミュニティの経験談ベースの選択にとどまる）。本書では「公式は vec768l12 を 4.1 の既定として推している」までで止め、個別の使い分けは扱わない。

### 2.3 4.0 / 4.1-Stable の差分

#### 構造的な差分

公式 README で明示的に書かれている差分は次のとおり:

> 「Feature input is changed to the 12th Layer of ContentVec Transformer output, And compatible with 4.0 branches.」（4.1-Stable README）

| 項目 | 4.0 既定 | 4.1-Stable 既定 |
| --- | --- | --- |
| コンテンツ特徴量 | ContentVec 9 層目（`vec256l9`） | ContentVec 12 層目（`vec768l12`） |
| 特徴量次元 | 256 | 768 |
| 互換性 | — | `config.json` の `speech_encoder` を `vec256l9` に切替えれば 4.0 モデル流用可 |

互換性スイッチの具体的な書き方は中国語 README に例示されている:

```json
"model": {
  "ssl_dim": 256,
  "n_speakers": 200,
  "speech_encoder":"vec256l9"
}
```

#### 4.1-Stable で追加された機能（公式 README 列挙ベース）

公式 README が "4.1-Stable" 向けに列挙している追加機能:

- **Shallow Diffusion（浅扩散）** — 「Update the shallow diffusion, you can use the shallow diffusion model to improve the sound quality.」「can solve some electrical sound problems after use」。**任意の後段補正**として、別途 `train_diff.py` で diffusion モデルを学習する形（§2.4）。
- **Whisper-PPG エンコーダのサポート** — `whisper-ppg` / `whisper-ppg-large` を `speech_encoder` として選べる
- **Static / Dynamic Sound Fusion**（話者音色のスタティック / ダイナミック融合）— 複数話者の埋め込みをスタジオ的に時系列でブレンドできる（公式 README で "speaker mix timeline" として MoeVoiceStudio 側にも言及あり）
- **Loudness Embedding（音量埋め込み）** — 「After enabling loudness embedding, the trained model will match the loudness of the input source」（§2.4）
- **RVC 由来の Feature Retrieval（特徴検索）** — 「the timbre leakage can be reduced, the enunciation is slightly better than clustering」。**4.0 で既にあった K-means クラスタリングと並ぶ "音色漏れ低減" の選択肢**として 4.1 で追加（§2.4）

#### 3.0 → 4.0 → 4.1 の互換性まとめ

| 移行 | 互換性 | 出典 |
| --- | --- | --- |
| 3.0 → 4.0 | **非互換**（学習データの再前処理が必要） | 4.0 README: "the data set needs to be fully pre-processed again" |
| 4.0 → 4.1-Stable | **互換**（`speech_encoder=vec256l9` 指定で 4.0 モデルを 4.1 コードで動かせる） | 4.1-Stable README: "compatible with 4.0 branches" |

→ 本ラボの方針: **本書で「so-vits-svc」と書いたら 4.1-Stable**、必要に応じて 4.0 を明示。3.0 系には基本的に踏み込まない。

### 2.4 オプション機能（音色漏れ対策・後段補正・音量制御）

公式 README で **任意機能**として列挙されているもの。すべて推論時に on/off を切り替えられる前提で、モデル単体の最小構成（§2.1）には含まれない。

#### K-means クラスタリング（cluster）

- 目的: **音色漏れ（timbre leakage）の低減**。入力話者の音色が出力に残るのを抑える。
- 仕組み（公式中国語 README より要約）: 学習済みデータの特徴量を **K-means** でクラスタリングし、推論時に **クラスタ中心への寄せ比率（`cluster_infer_ratio`、0〜1）**で混合する。
- 公式の説明文（英語 README）: 「The clustering scheme implemented in this model aims to reduce timbre leakage and enhance the similarity of the trained model to the target's timbre」
- トレードオフ: **クラスタ中心に寄せると音色は揃うが滑舌は落ちる**、というのが公式・コミュニティ共通の理解。0 にすれば実質無効化、1 にすればクラスタ中心固定。
- **学習側で `cluster/train_cluster.py` を別途回す必要がある**（4.0 系から存在）。

#### Feature Retrieval（特徴検索、4.1-Stable で追加）

- 目的: K-means クラスタと同じく**音色漏れ低減**。
- 仕組み: **RVC の faiss top1 retrieval を so-vits-svc 側に取り込んだもの**。公式 README にも「Feature retrieval from RVC」と明記。
- クラスタとの位置付け: 公式 README は「the enunciation is slightly better than clustering」「will reduce the inference speed」と評している。**滑舌が落ちにくい代わりに推論が遅くなる**という整理。
- 排他か併用かは README の文面では明確でない（**未確認**。コード読解レベル）。本書では「同じ目的の代替手段」として扱う。

#### Shallow Diffusion（浅扩散、4.1-Stable で更新）

- 目的: **音質向上 / "電気音 (electrical sound) 問題" の解消**（公式 README）。
- 仕組み: **VITS デコーダ + NSF-HiFiGAN の出力**に対して **浅い拡散モデルで後段補正**をかける（中国語 README に概念図あり）。
- 学習: 別途 `train_diff.py` で diffusion モデルを学習する必要があり、**前処理段階で `--use_diff` フラグを付けて素材を準備**する。
- 既定状態: 公式の表現として「disabled by default」（推論時の既定では無効）。
- 本書での扱い: **任意機能**で、後続の実機検証段で個別タスク化する。Phase 1 ではここまで。

#### Loudness Embedding（音量埋め込み、4.1-Stable）

- 目的: **入力音声の音量変化を出力にも反映する**（学習時データの音量に固定されるのを防ぐ）。
- 学習側スイッチ: `--vol_aug` を付けて前処理。
- 公式の表現: 「After enabling loudness embedding, the trained model will match the loudness of the input source rather than the loudness of the training set」
- これは [RVC](./rvc.md) の `rms_mix_rate`（入出力 RMS のブレンド比率）と**狙いは近いが実装レイヤが違う**（RVC は推論時の音量整形、so-vits-svc は学習時に音量条件を埋め込む形）。詳細対比は §7.4 で扱う。

### 2.5 F0 抽出方式の選択肢（推論時、§4 で詳細整理予定）

公式 README で **F0 predictor / F0 抽出方式**として列挙されている選択肢は次の 6 種類:

- `crepe`
- `pm`（parselmouth = Praat ベース）
- `dio`（pyworld の DIO）
- `harvest`（pyworld の Harvest）
- `rmvpe`（InterSpeech 2023 の RMVPE）
- `fcpe`

[RVC](./rvc.md#42-f0-抽出方式の整理) の main パイプラインで露出している `pm` / `harvest` / `crepe` / `rmvpe` の 4 つに加え、**`dio` 単独の選択肢**と **`fcpe`（Fast Context-base Pitch Estimation）** がリストに含まれている点が特徴。

- **`dio` 単独の選択肢が公式に存在する**ことは、[w-okada-voice-changer §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) で UI 露出されている `dio` がどこ由来か、という [rvc.md §4.2](./rvc.md#42-f0-抽出方式の整理) の未確認事項に **so-vits-svc 側経由で繋がっている可能性**を示唆する（w-okada が so-vits-svc 由来の `dio` 分岐をホスト側にコピーしている可能性。**未確認**で §9.1 の実機確認に引き継ぐ）。
- **`fcpe` は RVC 公式 README には現時点で見つかっていない**。本書では「so-vits-svc 側の追加選択肢」として扱う。

詳細な UI 露出対応表（w-okada UI → so-vits-svc 内部）は Phase 2 の §4 で書く。

### 2.6 「リアルタイム」のための工夫として README に挙がっているもの

公式 README には **so-vits-svc 本体がリアルタイム動作を強く主張する記述はない**（RVC 公式 README が「end-to-end 170 ms」「ASIO で 90 ms」と数値を明示しているのと対照的）。

そのかわり、リアルタイム配信用途は **外部 "Related Projects" として `w-okada/voice-changer` に委ねる**位置付けになっている（公式 README "Related Projects" に「A client supports real-time conversion」と明記。§1.3）。

- → **so-vits-svc 単体は「歌声変換のオフライン推論を含むフレームワーク」**として読むのが妥当で、リアルタイム配信用途の遅延・チャンク化・device mode 周りは [w-okada-voice-changer](./w-okada-voice-changer.md) 側の責務（責任分界は §6 で整理）。
- 本書で「so-vits-svc の遅延」を語るのは Phase 1 のスコープ外。実測値も書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。

## 3. 学習プロセスの大枠

本節は **公式 README（`4.1-Stable` ブランチ）の "Dataset preparation" / "Preprocessing" / "Training" / "Required pretrained models" 節で確認できる範囲**を整理する。コードレベル（学習ループの実装詳細）には踏み込まない（[rvc.md §3](./rvc.md#3-学習プロセスの大枠) と並行）。

### 3.1 必要な学習データの形式（公式 README "Dataset preparation"）

公式 README は学習素材の置き場所を **`dataset_raw/<speaker_name>/*.wav`** の固定構造として定義する:

```
dataset_raw
├───speaker0
│   ├───xxx1-xxx1.wav
│   └───Lxx-0xx8.wav
└───speaker1
    ├───xx2-0xxx2.wav
    └───xxx7-xxx007.wav
```

- **ファイル形式は WAV 固定**。「the file type must be `WAV`」と明記（README）。
- 音声長の目安は **「5 秒〜15 秒、多少長くても可」**（README "audio should be 5s - 15s ... slightly longer times are acceptable"）。**1 ファイルあたりの長さ**の規定で、データセット全体の合計時間ではない点に注意（合計時間の推奨値は README にない。**未確認**）。
- ディレクトリ名（`speaker0` / `speaker1` …）がそのまま **話者 ID（推論時の `-s | --spk_list`）**になる。話者 1 人だけの学習でもディレクトリで階層を作る必要がある。
- so-vits-svc は **複数話者を 1 つのチェックポイントに同梱できる**（`config.json` の `n_speakers` で席を確保。§2.1）。多話者構造は voice-changer-types §3.2 の "多話者" 側に近いが、本書では「話者は学習データに固定」という意味で §3.1 話者依存に分類している（複数席を持つことと、新規話者を後から増やせることは別）。

サンプリングレートに関する制約:

- 学習素材は **任意のサンプリングレートで投入可能**（次節 `resample.py` で 44.1 kHz に統一される）。
- **モデルの出力サンプリングレートは 44.1 kHz 固定**（4.0 で統一済み、§2.1 / §1.5）。

### 3.2 前処理パイプライン（README "Preprocessing" 節）

公式 README は前処理を **3 ステップ**に分けて記述している。各ステップが独立したスクリプトとして提供されている点が特徴（[rvc.md §3.2](./rvc.md#32-前処理パイプラインtraining_tips-に書かれている範囲) は WebUI 一括処理だったのに対し、so-vits-svc は CLI スクリプトを順番に実行する形）。

#### Step 1: リサンプリング — `python resample.py`

- **全 wav を 44.1 kHz / モノラルに統一**して `dataset/44k/<speaker>/*.wav` に出力する。
- 既定で **loudness normalization（音量正規化）**を行う。off にする場合は `--skip_loudnorm` を付ける。
- 音量正規化を **off にすべき場合**: §3.4 の **`--vol_aug` で loudness embedding を有効化する場合**（公式 README "If you want to enable loudness embedding, add `--vol_aug` ... resample.py should use `--skip_loudnorm`"）。loudness embedding が「入力音量を出力に反映する」機能であるため、学習素材を正規化してしまうと埋め込みが意味を持たない、という整合。

#### Step 2: 設定ファイル生成と話者リスト確定 — `python preprocess_flist_config.py --speech_encoder vec768l12`

- `dataset/44k` 配下のディレクトリ名から **話者リスト**を確定し、**train / val のファイルリスト**と **`configs/config.json`** を自動生成する。
- **`--speech_encoder` の指定**: §2.2 で列挙したコンテンツ表現抽出器のうち、このチェックポイントで使うものを 1 つ選ぶ（`vec256l9` / `vec768l12` / `hubertsoft` / `whisper-ppg` / `whisper-ppg-large` / `cnhubertlarge` / `dphubert` / `wavlmbase+`）。**ここで指定したエンコーダが学習・推論の両方で固定される**。
- オプションフラグ:
  - `--vol_aug` — **loudness embedding を有効化**（§3.4）
  - 関連: shallow diffusion を使う場合は次の Step 3 側で `--use_diff` を付ける

#### Step 3: HuBERT 特徴量と F0 の事前抽出 — `python preprocess_hubert_f0.py --f0_predictor dio`

- 全 wav について **コンテンツ表現抽出器の出力**と **F0** を事前計算してディスクに保存する（学習時に毎エポック再計算しなくて良くするための前処理）。
- **`--f0_predictor` の指定**: ここで指定した F0 抽出方式が **学習時の F0 として焼き付けられる**。選択肢は **`crepe` / `pm` / `dio` / `harvest` / `rmvpe` / `fcpe`** の 6 種類（§2.5 で列挙したものと同じ）。
- 既定値: README 例は `dio` だが、推論時 `inference_main.py` の `-f0p` 既定は `pm`、Phase 2 で別途確認したスクリプト引数の既定は実装側に依存（**未確認**）。本ラボでは「学習時の f0_predictor と推論時の f0_predictor は独立に指定できる」という事実だけ押さえる。
- オプションフラグ:
  - `--use_diff` — **shallow diffusion 用の追加前処理**（メル スペクトログラム関係の事前計算）。**Step 1 で `--vol_aug` を使った場合は同時にここでも `--use_diff` 等の整合を取る**運用が README に示されている。
  - `--num_processes 8` — 並列数（速度のみ。学習結果には影響しない）

> 前処理後のディレクトリ構成（**README からは命名規約のすべては明示されていない**。**未確認**: コードレベルでの確定が必要だが本ラボでは深追いしない）。

#### RVC との前処理比較

[rvc.md §3.2](./rvc.md#32-前処理パイプラインtraining_tips-に書かれている範囲) の RVC 前処理（FFmpeg 読込み → denoise → 無音分割 → 16 kHz リサンプル → HuBERT 抽出 → F0 抽出 → faiss index）と比較すると:

- **無音分割を so-vits-svc は前処理で行わない**: RVC は `max_sil_kept=5s` で自動分割するが、so-vits-svc は **ユーザー側で 5〜15 秒のクリップに切ってから `dataset_raw` に置く**前提（README "audio should be 5s - 15s"）。
- **denoise（`scipy.signal.filtfilt`）は so-vits-svc にない**: RVC が前処理で行う平滑化に相当する処理は README で明示されていない（**未確認**: 実装内に隠れている可能性）。
- **コンテンツ抽出器を選ぶフロー**は so-vits-svc 固有（RVC は `hubert_base.pt` 固定）。`--speech_encoder` のスイッチが前処理段階で要求される。

### 3.3 学習コマンド（README "Training" 節）

公式 README は **3 種類の学習スクリプト**を分けて提供している。

#### Main model: `python train.py -c configs/config.json -m 44k`

- so-vits-svc 本体（コンテンツ表現 + 話者埋め込み + F0 → VITS デコーダ）の学習。
- `-c` で `preprocess_flist_config.py` が生成した設定ファイルを指定、`-m` で出力ディレクトリ名（`logs/44k/` 配下に G/D ckpt が保存される）を指定。
- 事前学習部品としてダウンロードしておく必要があるもの: コンテンツ抽出器の重み（`vec768l12` なら ContentVec、`hubertsoft` なら HuBERT-Soft）、NSF-HiFiGAN Vocoder。詳細は §5.2。

#### Diffusion model（任意）: `python train_diff.py -c configs/diffusion.yaml`

- §2.4 で扱った **shallow diffusion** の後段補正モデルを学習する。
- Main model（`train.py`）の重みを **入力ソース**として、追加で diffusion 部分だけを別途学習する形（README の説明は概要レベル。コード読解は本書スコープ外）。
- 学習素材は同じ `dataset_raw` で、Step 3 で `--use_diff` 付き前処理が完了している必要がある。
- diffusion を使うかどうかは推論時にも独立に切り替えられる（§4 の `-shd` / `-od`）。

#### Cluster model（任意）: `python cluster/train_cluster.py`

- §2.4 の **K-means クラスタリング**用モデルを別途学習する。
- 「音色漏れ低減」目的の任意機能で、Main model の学習とは独立。推論時に `-cm <path>` で読み込み `-cr <ratio>` で混合比率を指定する（§4.1）。
- §2.4 の **Feature Retrieval（faiss 由来）**を使う場合も、学習データ側の特徴量に対して別途 index を構築する必要がある（README は cluster と並列の選択肢として位置付け、コマンドの明示はあまり詳しくない。**未確認**: 公式 README に Feature Retrieval 用の専用スクリプトコマンドが明示されているかどうかは要再確認）。

#### 学習中の保存・再開

- Main model の途中チェックポイントは `logs/44k/G_<step>.pth` / `D_<step>.pth` に保存される（README の例示パス）。
- 推論には **G 側の ckpt**を `inference_main.py` の `-m` に渡す（D 側は識別器なので推論時には使わない）。
- RVC のような **ckpt 抽出ステップ（FAQ Q13 の "weights/{exp}.pth" への変換）は so-vits-svc では明示的に分離されていない**: `train.py` が出力するファイルをそのまま `inference_main.py` に渡せる（**未確認**: メタデータ整合は実装側で吸収されている前提）。

### 3.4 任意機能を学習時に有効化するフラグ

§2.4 の任意機能を **学習時に "焼き付ける" かどうか**で挙動が変わる:

| 任意機能 | 学習時スイッチ | 推論時スイッチ | 効く範囲 |
| --- | --- | --- | --- |
| K-means クラスタ | `cluster/train_cluster.py` を別途実行 | `-cm <path>` + `-cr <ratio>` | Main model 学習自体には影響しない（後付け可能） |
| Feature Retrieval（4.1） | 学習データ側で index 構築（具体スクリプトは README で明示薄、**未確認**） | `-cm <path>` + `-cr <ratio>` + `-fr` | 同上（cluster と同じスロットを共有、`-fr` で切替） |
| Shallow Diffusion（4.1） | `preprocess_hubert_f0.py --use_diff` + `train_diff.py` | `-shd` または `-od` + `-dm <path>` + `-dc <path>` + `-ks <step>` | **diffusion モデルを学習しないと推論時にも使えない** |
| Loudness Embedding（4.1） | `preprocess_flist_config.py --vol_aug` + `resample.py --skip_loudnorm` | （学習時に埋め込まれるため推論時の専用スイッチはない。`-lea` は別の "出力側" 音量整形） | **学習時に有効化しないと後から付け足せない** |

特に **Loudness Embedding は学習時にしか有効化できない**点が注意。後から「音量を入力に追従させたい」と思っても、`--vol_aug` 付きで再学習が必要。

### 3.5 配布形態としての成果物

学習完了後にユーザが手にするのは、**最小構成**で:

- `logs/44k/G_<step>.pth` — 話者特化モデル本体（コンテンツ抽出器の出力 → VITS → NSF-HiFiGAN まで）。これ単独で推論可能。
- `logs/44k/config.json` — `preprocess_flist_config.py` が生成した設定。`speech_encoder` / `n_speakers` / `ssl_dim` 等が固定されている（モデル互換の鍵）。

任意で追加されるもの:

- `logs/44k/<cluster_or_retrieval>.pt` などのクラスタ / Retrieval index ファイル（cluster / feature retrieval を使う場合）
- `logs/44k/diffusion/model_<step>.pt` + `logs/44k/diffusion/config.yaml`（shallow diffusion を使う場合）

→ **配布形態は最大で 5〜6 ファイル**（main G + config + cluster + diffusion model + diffusion config）。RVC の「`.pth` + `.index` の 2 ファイル」（[rvc.md §3.6](./rvc.md#36-配布形態としての成果物)）と比べて構成要素が多く、**コミュニティ配布チェックポイントの "セット" が揃っているか**を毎回チェックする必要がある（§5.4 で再掲）。

> 本節で踏み込まなかった点（**未確認** として §9 に引き継ぐ）:
>
> - **データセット全体の推奨合計時間**（README は 1 ファイル長 5〜15 秒の指定のみ。RVC FAQ Q10 のような "10〜50 分推奨" に相当する記述は確認できていない）
> - **Feature Retrieval（4.1）用の index 構築コマンドの正確な手順**（README での明示が薄い）
> - **前処理後のディレクトリ命名規約**（speech_encoder ごとに次元が違うため、抽出済み特徴量の保存パスが分岐するはず）
> - **`train.py` の ckpt をそのまま推論に渡せるかの正確な互換性**（メタデータ整合）

## 4. 推論パラメータ（w-okada UI との対応表）

### 4.1 公式の推論スクリプトで受け取るパラメータ

[`inference_main.py`](https://github.com/svc-develop-team/so-vits-svc/blob/4.1-Stable/inference_main.py) の argparse 定義から確認した、**推論時のパラメータ全リスト**（4.1-Stable）。RVC（[rvc.md §4.1](./rvc.md#41-公式の推論パイプラインで受け取るパラメータ)）と比べると **パラメータ数が約 2 倍**で、so-vits-svc の任意機能の多さがそのまま CLI 引数の多さに反映されている。

#### 必須引数（モデルと素材の指定）

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-m` | `--model_path` | `logs/44k/G_37600.pth` | **モデル（G 側 ckpt）のパス** |
| `-c` | `--config_path` | `logs/44k/config.json` | **設定ファイル**のパス（`speech_encoder` / `n_speakers` 等を解決） |
| `-n` | `--clean_names` | `["君の知らない物語-src.wav"]` | `raw/` 配下の **入力 wav ファイル名リスト**（`nargs='+'`） |
| `-t` | `--trans` | `[0]` | **ピッチシフト（半音単位）**。`-n` と同数を nargs で指定 |
| `-s` | `--spk_list` | `['buyizi']` | **変換ターゲット話者名**（学習時の `dataset_raw/<name>` 由来）。`nargs='+'` |

→ `(-n, -t, -s)` を **同数並べて一度に複数ファイルを変換**できる設計。配信向けではなく **ファイル変換 CLI** であることが見て取れる（リアルタイム推論は §2.6 の通り w-okada 側に委ねる立て付け）。

#### 音声切り出し / 結合関連

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-cl` | `--clip` | `0`（自動分割） | **入力 wav の強制切片長（秒）**。0 で自動分割 |
| `-sd` | `--slice_db` | `-40` | **無音判定の dB 閾値**。README コメント: 「嘈杂的音频可以-30，干声保留呼吸可以-50」（騒がしい素材は -30、ブレス保持したいクリーン素材は -50） |
| `-lg` | `--linear_gradient` | `0` | **隣接スライス間のクロスフェード長（秒）**。0 で単純結合 |
| `-lgr` | `--linear_gradient_retain` | `0.75` | クロスフェード長のうち実際に残す比率（0〜1） |
| `-p` | `--pad_seconds` | `0.5` | 推論時に各クリップの前後に **付加する pad 長（秒）**（境界アーティファクト緩和） |

→ **so-vits-svc 本家の推論はオフラインのファイル分割推論**で、リアルタイム化するためのチャンク管理（w-okada UI の **CHUNK / EXTRA**, [w-okada-voice-changer §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)）とは別レイヤ。`-lg` / `-lgr` は **オフライン分割後の縫合**用のパラメータで、リアルタイムのオーバーラップ・アド処理とは目的が異なる。

#### F0 抽出と音量整形

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-f0p` | `--f0_predictor` | `pm` | **F0 抽出方式**。選択肢: `crepe` / `pm` / `dio` / `harvest` / `rmvpe` / `fcpe`（§2.5） |
| `-a` | `--auto_predict_f0` | `False` | **自動ピッチ予測**。README コメント: 「转换歌声时不要打开」（**歌声変換では off にせよ**）。話し声変換専用のスイッチ |
| `-ft` | `--f0_filter_threshold` | `0.05` | **F0 フィルタ閾値**。**`crepe` 使用時のみ有効**（README コメント明記） |
| `-lea` | `--loudness_envelope_adjustment` | `1` | **出力側の loudness envelope を入力に寄せる比率（0〜1）**。1 で完全に入力包絡を使う |
| `-ns` | `--noice_scale` | `0.4` | **VITS デコーダ側のノイズスケール**。咬字と音質に影響（README コメント） |

→ **`-a` の警告は重要**: 歌声では「与えた pitch を保持する」のが本来の挙動なので auto predict すると意味がない。話し声変換用途（配信用途）で初めて意味が出る選択肢。

#### 音色漏れ対策（K-means クラスタ / Feature Retrieval）

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-cm` | `--cluster_model_path` | `""` | **クラスタ or Retrieval index のパス**（同じ引数で両方を受ける） |
| `-cr` | `--cluster_infer_ratio` | `0` | **混合比率（0〜1）**。0 で実質無効化、1 でクラスタ中心 / 検索結果に固定 |
| `-fr` | `--feature_retrieval` | `False` | **Feature Retrieval モードに切替**。off のときは `-cm` をクラスタモデルとして解釈、on のときは Retrieval index として解釈 |

→ §2.4 の通り、**K-means クラスタと Feature Retrieval は同じスロット（`-cm` / `-cr`）を `-fr` フラグで切り替える排他構造**であることが argparse から確認できる（Phase 1 §2.4 の「**未確認**: 排他か併用か」の論点は **`-fr` フラグの存在から排他**と確定）。

#### Shallow Diffusion（4.1）

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-shd` | `--shallow_diffusion` | `False` | **Shallow diffusion 後段補正を有効化** |
| `-dm` | `--diffusion_model_path` | `logs/44k/diffusion/model_0.pt` | diffusion モデルのパス |
| `-dc` | `--diffusion_config_path` | `logs/44k/diffusion/config.yaml` | diffusion 用設定 |
| `-ks` | `--k_step` | `100` | **拡散ステップ数**。「越大越接近扩散模型的结果」（大きいほど diffusion 寄りの結果）。値が大きいほど推論コストも増える |
| `-od` | `--only_diffusion` | `False` | **diffusion のみで推論**（main model を経由しない極端モード） |
| `-se` | `--second_encoding` | `False` | diffusion 前に "二次エンコード" を挟む。README コメント: 「玄学选项」（=おまじない的オプション、**効果は経験則レベル**と公式が明示） |

→ §2.4 の通り、**diffusion を使うには事前に `preprocess_hubert_f0.py --use_diff` と `train_diff.py` で diffusion モデルを別途学習する必要**がある。`-shd` だけ立てても `-dm` の指す ckpt が無ければ動かない。

#### 話者融合 / Vocoder 増強

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-usm` | `--use_spk_mix` | `False` | **動的話者融合（Dynamic Sound Fusion）**。README は `spkmix.py` の「`[[start_time, end_time, start_value, end_value]]` 形式のタイムライン」で重みを指定する設計と説明 |
| `-eh` | `--enhance` | `False` | **NSF-HiFiGAN Enhancer を有効化**。README: 「certain effect on sound quality enhancement for some models with few training sets, but has negative effect on well-trained models, so it is disabled by default」（学習データが少ないモデルでは効くが、十分学習されたモデルでは逆効果） |
| `-eak` | `--enhancer_adaptive_key` | `0` | enhancer を「より高い音域に適応させる半音数」 |

→ **`-eh` は「学習データが薄い時の救済策」で、ちゃんと学習されたモデルでは off が正解**、と公式が明言している点が重要（コミュニティ配布チェックポイントの品質が読めない場合の判断材料）。

#### その他

| 短縮 | 長 | 既定値 | 意味 |
| --- | --- | --- | --- |
| `-d` | `--device` | `None`（自動） | 推論デバイス（cpu / cuda） |
| `-wf` | `--wav_format` | `'flac'` | **出力形式**。既定が wav ではなく **flac** な点が独特（ファイルサイズと音質の両立を意図） |

### 4.2 F0 抽出方式の整理

§2.5 で列挙した 6 方式について、用途観点で整理する。`-f0p` の選択肢:

| F0 抽出 | 由来 | 公式に書かれている範囲での特徴 |
| --- | --- | --- |
| `pm` | parselmouth（Praat） | **`inference_main.py` の既定値**。軽量・CPU 主体 |
| `dio` | pyworld の DIO | 学習時の前処理スクリプト（`preprocess_hubert_f0.py`）の README 例で使われている方式 |
| `harvest` | pyworld の Harvest | 公式 README で並列に列挙されているのみ。詳細評価なし |
| `crepe` | torchcrepe（CREPE 系ニューラル） | **`-ft` フィルタ閾値が効くのは crepe のみ**（§4.1 注記） |
| `rmvpe` | RMVPE（InterSpeech 2023） | 公式 README は事前学習部品としても列挙（§5.2 に `rmvpe.pt` の配布元あり） |
| `fcpe` | FCPE（Fast Context-base Pitch Estimation） | 公式 README が事前学習部品として `fcpe.pt` を列挙。**RVC main pipeline には無い so-vits-svc 独自の選択肢**（§2.5） |

学習時 F0 と推論時 F0 の関係:

- 学習時の F0 は `preprocess_hubert_f0.py --f0_predictor <name>` で**素材ごとに事前計算してディスクに保存**される（§3.2 Step 3）。
- 推論時の F0 は **入力波形に対してオンザフライで再抽出**される（`-f0p` 指定）。
- **学習時と推論時で別の F0 抽出方式を使える**（独立に指定）。ただし「学習時の f0 分布から離れすぎると変換品質が落ちる可能性」はコミュニティで一般に言われるが、公式 README には明示なし（**未確認**）。

### 4.3 w-okada/voice-changer UI 露出との対応表

[w-okada-voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) より so-vits-svc は **w-okada v.1 系のサポート対象**。**v.2 では非対応**。

[w-okada-voice-changer §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) / [§4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) に列挙されている UI 名称を、so-vits-svc 内部パラメータに対応付ける（ただし w-okada の公式チュートリアルは **RVC ベースで書かれており、so-vits-svc 選択時に UI 名称が完全に同一かどうかは確認できていない**点に注意。**未確認**マーカーを多めに付ける）。

| w-okada UI 名称 | so-vits-svc 内部パラメータ | 担当レイヤ | 備考 |
| --- | --- | --- | --- |
| **F0 Det (F0 Extractor)** | `-f0p` (`--f0_predictor`) | so-vits-svc 推論 | **`dio` 単独の選択肢が w-okada UI にあるのは so-vits-svc 由来の可能性が高い**（[rvc.md §4.2](./rvc.md#42-f0-抽出方式の整理) の「`dio` がどこ由来か」の未確認事項に、so-vits-svc 経由で答えが付く。**ただし w-okada 実装で実際に `dio` が so-vits-svc 経由かは未確認**） |
| **INDEX** | `-cr` (`--cluster_infer_ratio`) | so-vits-svc 推論 | **意味が RVC とは違う**: RVC は faiss top1 retrieval の寄せ比率、so-vits-svc は K-means クラスタ or Feature Retrieval の寄せ比率。**UI 名は同じでもモデル側で別の処理になる**点を本ラボでは明示する。w-okada UI が `-fr` フラグ（cluster vs retrieval 切替）を露出しているかは **未確認** |
| **TUNE** | `-t` (`--trans`) | so-vits-svc 推論 | 単純な半音ピッチシフト。RVC `f0_up_key` と意味は同等 |
| **GAIN (in / out)** | （該当なし） | **w-okada ホスト側** | so-vits-svc 側の `-lea`（出力 loudness envelope の入力寄せ比率）とは別物。GAIN は単純音量、`-lea` は包絡形状の追従率 |
| **CHUNK (Input Chunk Num)** | （該当なし） | **w-okada ホスト側**（バッファ管理） | so-vits-svc 本家の `-cl` / `-sd` / `-lg` / `-lgr` / `-p` はオフライン分割用で、リアルタイムのチャンク化とは別レイヤ |
| **EXTRA (Extra Data Length)** | （該当なし） | **w-okada ホスト側**（先行コンテキスト） | 同上 |
| **S. Thresh (Noise Gate)** | （該当なし） | w-okada ホスト側 | so-vits-svc 側の `-sd`（slice_db）は**無音"分割"用**で、ノイズゲート（音量ベースの入力カット）ではない |
| **Echo / Sup1 / Sup2** | （該当なし） | w-okada ホスト側（Client device mode のみ） | Chrome の getUserMedia 経由のノイズ抑制・エコーキャンセル |

w-okada UI で **so-vits-svc 選択時のみ追加表示されるパラメータ**があるかは、本 Phase の公式チュートリアル確認範囲（[w-okada-voice-changer §4](./w-okada-voice-changer.md#4-前処理後処理として提供されているもの)）には記述がなく **未確認**。可能性が高い候補:

- **話者選択 UI**（`-s | --spk_list` 相当） — so-vits-svc は 1 ckpt に複数話者を含められるため、必須の UI 要素のはず（**未確認**）
- **Shallow diffusion 切替**（`-shd` / `-ks` / `-od`） — w-okada が diffusion ckpt の読み込みをサポートしているかも含めて **未確認**
- **Cluster / Feature Retrieval 切替**（`-cm` / `-cr` / `-fr`） — INDEX スライダの裏で動いている可能性が高いが、ckpt の追加スロットが必要

w-okada UI に **露出が確認できなかった** so-vits-svc 推論パラメータ（=ホスト側でハードコード or 既定値運用と推測される）:

- `-a` / `--auto_predict_f0`（自動ピッチ予測）
- `-eh` / `--enhance`（NSF-HiFiGAN Enhancer）
- `-eak` / `--enhancer_adaptive_key`
- `-lea` / `--loudness_envelope_adjustment`
- `-ns` / `--noice_scale`
- `-ft` / `--f0_filter_threshold`（crepe 使用時）
- `-se` / `--second_encoding`
- `-usm` / `--use_spk_mix`（動的話者融合）
- `-lg` / `-lgr` / `-p`（オフライン分割関連 — リアルタイムでは概念ごと不要の可能性）
- `-wf` / `-d`（出力形式・デバイス — リアルタイムでは別の経路）

**実機 UI 確認は本 Phase のスコープ外**。後続の `experiments/` テンプレ整備タスク（[TODO.md](../../TODO.md)「w-okada/voice-changer の実測タスク用 `experiments/` テンプレート整備」）で確認する。

### 4.4 推論時パラメータの調整ガイド（README + コミュニティ知見）

公式 README が **挙動 / 注意点を明示**しているもの:

- **`-a` / `--auto_predict_f0`**: 「**歌声変換では絶対に off**」（README: "转换歌声时不要打开"）。
- **`-cr` / `--cluster_infer_ratio`**: **0〜1 の連続値**で、0 で無効化、1 で完全にクラスタ中心 / 検索結果へ寄せる（§2.4 と整合）。音色漏れ低減と滑舌のトレードオフ。
- **`-eh` / `--enhance`**: 「学習データが少ないモデルでは音質改善効果あり、十分学習されたモデルでは逆効果」（README）。**配布チェックポイントの素性が読めない時は off で始め、必要に応じ試す**のが安全。
- **`-ks` / `--k_step`**: 既定 100。「越大越接近扩散模型的结果」 — 大きいほど diffusion 後段補正が強く効くが、推論コストも線形に増える。
- **`-ft` / `--f0_filter_threshold`**: **`-f0p crepe` 使用時のみ有効**（README コメント明記）。他の F0 抽出方式では無視される。
- **`-se` / `--second_encoding`**: README が「玄学选项」（おまじない）と自評。**効果が経験則ベース**であることが公式に明示されている珍しいパラメータ。

公式 README に **具体的なガイドが書かれていない**もの:

- `-ns` / `--noice_scale` の **推奨範囲**（既定 0.4 が何を基準にした値か）
- `-lea` を **どの程度に設定すると配信向き**かの目安
- 学習データ量と `-cr` の有効値の関係

→ **未確認**項目として §9 に残す。実機検証時に詰める。

## 5. 配布形態とライセンス

### 5.1 リポジトリ本体のライセンス

- 公式リポジトリ [`svc-develop-team/so-vits-svc`](https://github.com/svc-develop-team/so-vits-svc) の `LICENSE` は **GNU AGPL-3.0**（GNU Affero General Public License Version 3、2007 年 11 月 19 日版）。
  - LICENSE ファイルは **AGPL-3.0 標準テキストそのまま**で、追加条項なし（preamble の "Copyright (C) 2007 Free Software Foundation, Inc." は AGPL 本文の著作権表記であり、プロジェクト本体の著作権者ではない）。
  - プロジェクト本体の著作権は **コントリビュータ集合**で、`svc-develop-team` Organization が継続管理する建て付け（§1.2 の通り、原作者は元リポジトリを削除済みで、現リポジトリはコミュニティ再構成）。
- **配信用途で重要なポイント**: AGPL-3.0 は **ネットワーク経由でサービス提供される場合にもソース開示を要求**するライセンス。[RVC が MIT](./rvc.md#51-リポジトリ本体のライセンス) なのとは大きく異なり、**so-vits-svc のコードをそのまま組み込んで配信サービスを構築する場合、サービス利用者に対するソース開示義務が発生し得る**。
  - 本ラボの想定（個人ローカル PC で動かして OBS に流す配信）であれば「ネットワーク経由でサービスを提供」には該当しない可能性が高いが、**Web ホスト型 / クラウド SaaS 型として so-vits-svc を組み込む場合は AGPL-3.0 の条項を確認する必要がある**。
  - [w-okada/voice-changer](./w-okada-voice-changer.md) が so-vits-svc コードを取り込んでいる場合に、ホスト全体のライセンス上どう扱われているか（AGPL 伝播の有無）は本書範囲では確認できておらず **未確認**。w-okada 側のライセンス整理タスク（[TODO.md](../../TODO.md) の「w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認」）と紐付ける。
- → **ライセンス面で RVC とは性質が違う**。OSS であるという点は同じだが、組み込み・再配布・サービス化の自由度に差がある。

### 5.2 公式が配布している部品（事前学習モデル類）

公式リポジトリは **特定話者のチェックポイントを配布しない**。配布されているのは **so-vits-svc の学習・推論に必要な部品**で、ユーザーが手動でダウンロードして `pretrain/` 配下などに配置する形（公式 README "Required pretrained models" 節）。

公式 README で列挙されている部品と配布元（**※ 配布元 URL は公式 README に出ているドメイン名までを記述。具体のチェックポイント URL は本書では網羅しない**）:

| 部品 | 用途 | 主な配布元（README 記載ベース） |
| --- | --- | --- |
| **ContentVec**（`vec256l9` / `vec768l12` 用） | コンテンツ表現抽出器 | Hugging Face `lj1995/VoiceConversionWebUI`（**RVC と同じリポジトリ**）／IBM Box（原著者配布） |
| **HuBERT-Soft / cnhubertlarge / dphubert / wavlmbase+** | 同上（speech_encoder 切替時） | 各 OSS プロジェクトの配布元 |
| **Whisper-PPG / Whisper-PPG-large** | 同上 | OpenAI 公式の Whisper 配布物 |
| **NSF-HiFiGAN** | Vocoder | GitHub `openvpi/vocoders` リリース |
| **RMVPE** | F0 抽出 | GitHub `yxlllc/RMVPE` リリース |
| **FCPE** | F0 抽出 | Hugging Face `ylzz1997` データセット |

注目すべき点:

- **`ContentVec` を RVC と同じ Hugging Face リポジトリ（`lj1995/VoiceConversionWebUI`）から取ってきている**: これは RVC が `hubert_base.pt` を取得する先と一致する（[rvc.md §5.2](./rvc.md#52-事前学習モデルの配布)）。本ラボのファイル管理上、**RVC と so-vits-svc が同じ HF リポジトリの別ディレクトリを使い回している**ことになり、ディスク上での共存が比較的素直に行える可能性がある（実機確認は別途）。
- **NSF-HiFiGAN は openvpi 系の配布**: VITS 系歌声プロジェクトで広く共有されている Vocoder。これも so-vits-svc 単体のライセンスとは独立に、openvpi 側の配布条件を確認する必要がある（**未確認**）。
- **Whisper 系の配布元は OpenAI**: Whisper 自体のモデルライセンス（MIT）と、so-vits-svc から呼び出して PPG として使うことに関する条件は別途確認が必要だが、Whisper は元から MIT で配布されているため一般的には問題になりにくい（**未確認**）。

### 5.3 公式が提供する学習済みターゲット話者モデル

- **公式リポジトリは特定話者のチェックポイント（`.pth`）を一切配布していない**。これは [RVC が VCTK 由来の base model](./rvc.md#52-事前学習モデルの配布) を Hugging Face で配布しているのと**対照的**な点。
- **「特定話者の声に変換できる学習済みモデル」を入手する経路は、公式リポジトリ内には存在しない**。すべてユーザー自身の学習、もしくはコミュニティ配布チェックポイント（§5.4）に依存する。
- 結果として、so-vits-svc は **「自分の声を別の声に変える」最終 1 段を、公式が一切肩代わりしない**設計になっており、配布チェックポイントを取り扱う際の権利チェックは **常に第三者配布物の規約を確認する作業**に集約される。

### 5.4 コミュニティ配布チェックポイントの扱い

- 歌声変換界隈で「so-vits-svc モデル」「○○の so-vits-svc モデル」と呼ばれているものの大半は、**コミュニティ（個人・サークル・歌い手ファンコミュニティ等）が学習させて配布しているチェックポイント**（`.pth` + 場合により K-means クラスタモデル / shallow diffusion モデル）。
- これらは公式リポジトリのライセンス（AGPL-3.0）とは **完全に独立**で、配布者が個別に設定した利用条件で判断する。
- **so-vits-svc の場合、RVC と比較してリスク要因が増える**:
  - **歌唱録音を学習素材として使っている割合が高い** → 楽曲の作詞・作曲権利、実演家権利が絡む可能性
  - **「キャラクター歌唱」「歌い手」「アーティスト」の声を再現するモデルが流通している** → 個人の声・歌唱の権利、所属事務所の規約、二次創作ガイドライン等が絡む
- 本ラボでの扱い:
  - **第三者の歌唱・話し声（実在人物・歌い手・声優・キャラクター）を許諾なく再現するような用途には誘導しない**（[CLAUDE.md](../../CLAUDE.md) 方針）。
  - 特定のチェックポイント取得方法・配布元 URL・モデル名を本ドキュメントには記載しない。
  - 「コミュニティでチェックポイントが流通している事実」は記述するが、「どこから取れるか」は書かない。
- 取得を伴うタスクは、**配布元の利用規約（再配布可否・歌唱／話し声利用範囲・商用配信可否・クレジット要否）の確認をユーザーに必ず促す**（[CLAUDE.md](../../CLAUDE.md)「やらないこと」と整合）。

### 5.5 公式が明文化している利用上の規約（README "Terms of Use" / "Disclaimer"）

公式 README には **規約・免責**の節が比較的厚く書かれており、**RVC 公式 README にはない**強い言い回しが含まれる。本ラボの方針（[CLAUDE.md](../../CLAUDE.md)）と整合する重要な部分を以下に整理（公式の英語表現と中国語表現の両方から引用）。

- **学術目的限定**:
  > 「This project is exclusively established for academic purposes... not intended for deployment in production environments.」
- **オープンソース / オフラインのフレームワークであり、コントリビュータは個別ユーザーの行為を制御しない**:
  > 「This project is an open-source, offline endeavor… contributors have no control over the project.」
  > 「This project serves as a framework only and does not possess speech synthesis functionality by itself.」
- **出力物に対する責任はユーザー側**:
  > 「Any AI models and synthesized audio produced through training are unrelated to the contributors. Any issues arising from their use are the sole responsibility of the user.」
- **配信・公開時の入力素材表示義務**:
  > 「When posting converted content, creators must clearly specify in the introduction the input source vocals and audio used.」
- **学習素材のライセンスはユーザー責任**:
  > 「请自行解决数据集授权问题，禁止使用非授权数据集进行训练」（中国語 README より。日本語要旨: データセットの権利は自分で解決すること。許諾のないデータセットでの学習は禁止）
- **違法行為・宗教・政治目的の禁止**:
  > 「Engaging in illegal activities, as well as religious and political activities, is strictly prohibited.」
- **アニメキャラクターなどの架空キャラクターを念頭に置いた設計、実在人物への適用は意図とずれる**:
  > 「The purpose of this project was to enable developers to have their beloved anime characters perform singing tasks.」
  > 公式は「実在人物に対する利用は開発者の本来の意図から外れる (deviates from the developer's original intention)」と明言

これらは **AGPL-3.0 の本体ライセンスとは別建ての "プロジェクト規約"** として README 内に書かれているもので、**ライセンスの遵守だけでは公式の意図には沿わない**点に注意。本ラボの [CLAUDE.md](../../CLAUDE.md) 方針（第三者声の許諾なし再現を扱わない、ライセンス未確認の素材を扱わない）とは方向性として整合する。

### 5.6 同梱されるサードパーティ要素の整理

公式 README / Related Projects / Acknowledgements で名前が挙がっているもの:

- **VITS** — 基盤アーキテクチャ
- **NSF-HiFiGAN**（openvpi 系） — Vocoder
- **ContentVec** — コンテンツ表現抽出（HuBERT 派生）
- **HuBERT / HuBERT-Soft** — 同上
- **Whisper**（OpenAI） — Whisper-PPG 用
- **WavLM** — 抽出器選択肢の一つ
- **RMVPE / FCPE** — F0 抽出
- **RVC 由来の Feature Retrieval ロジック** — 4.1-Stable で取り込み（§2.4）

各々のライセンスは独立。**so-vits-svc のコード本体は AGPL-3.0 だが、これらの依存物の重みファイルや一部コードは別ライセンス**で、配布バイナリの再配布や派生プロジェクトを作る際は個別確認が必要。本ラボはバイナリ再配布を行わない想定なので運用上の影響は当面なし。

### 5.7 「歌声」素材という性質に起因する追加リスク（RVC との差分の核心）

so-vits-svc を扱う際、本ラボの観点で **RVC と比べて取り扱いに余分なケアが要る**項目を整理しておく。これは §7.6（RVC との対比 / ライセンスと規約の違い）と接続する。

- **歌唱録音の権利関係**: 歌唱を学習素材にする場合、**楽曲の作詞・作曲（著作権）、編曲（著作隣接権）、歌唱者の実演（実演家権）**が複数絡む。話し声中心の RVC データセットでは表に出にくかった層が、so-vits-svc では現実的なリスクとして上がってくる。
- **キャラクター歌唱・歌い手・アーティスト声の流通**: コミュニティ配布チェックポイントに、**有名歌唱者・キャラクター歌唱を学習素材としたもの**が含まれる比率が RVC より体感的に高い（**コミュニティで一般に言われている範囲**。本ラボとして数値で示せるものではない）。これらは個別の二次創作ガイドライン・所属事務所規約に踏み込む話になり、**ライセンスチェックの工数が RVC 以上に重い**。
- **公式が "academic purposes only" / "anime characters performing singing tasks" と明言**: §5.5 のとおり、**公式自体が配信実運用や実在人物利用を意図していない**ことを明言している。**「OSS だから自由」ではなく、"OSS だが規約上は学術目的"** という整理が必要。
- **AGPL-3.0 という強めのコピーレフト**: §5.1 のとおり、サービス組み込み時のソース開示義務が RVC（MIT）よりはるかに重い。

→ 本書 §5 全体を踏まえると、**so-vits-svc は「RVC と並ぶ OSS の選択肢」ではあるが、ライセンス（AGPL）・規約（学術目的限定）・学習素材（歌唱）・配布チェックポイントの権利関係のすべてにおいて RVC より重い**、という整理になる。本ラボでの実機検証に進む際は、**公式部品の取得（§5.2）と自前学習（§5.3）に話を閉じて**、コミュニティ配布チェックポイントには [CLAUDE.md](../../CLAUDE.md) 方針に従い踏み込まないのが安全な出発点。

### 5.8 ライセンス判断軸まとめ

本ラボで so-vits-svc を扱う際に「ライセンス OK?」を判断する軸を、レイヤ別に整理（[rvc.md §5.6](./rvc.md#56-まとめ--ライセンス判断軸) と並行な整理）:

| レイヤ | 何のライセンス / 規約 | 本ラボでの扱い |
| --- | --- | --- |
| so-vits-svc コード本体 | **AGPL-3.0**（[LICENSE](https://github.com/svc-develop-team/so-vits-svc/blob/4.1-Stable/LICENSE)）+ README の "Terms of Use"（学術目的限定） | ローカル個人利用としてのコード改変は OSS 条項で可能だが、ネットワークサービス化・配布バイナリ化時はソース開示義務に注意。**規約レベルでは "学術目的"** と明言されている点を本ラボでは明示的に認識する |
| 必要部品（ContentVec / NSF-HiFiGAN / Whisper / RMVPE / FCPE 等） | 各々独立のライセンス（多くは OSS 系だが個別確認） | 公式 README が指定する配布元から取得。再配布時は各ライセンス継承の確認（バイナリ再配布は本ラボのスコープ外） |
| **公式配布の話者特化モデル** | **存在しない**（公式は配布していない） | RVC のような VCTK 由来 base model に相当するものは無く、話者特化は自前学習かコミュニティ配布物に依存（§5.3） |
| コミュニティ配布チェックポイント | **配布者ごとに別ライセンス／規約** | **常に個別確認**。本ラボでは具体的なチェックポイントの取得導線を書かない |
| **歌唱を学習素材としたチェックポイント** | 配布者規約 + **楽曲の著作権 + 編曲 + 実演家権利** の二重三重チェック | **許諾未確認のものは扱わない**（[CLAUDE.md](../../CLAUDE.md)「やらないこと」）。RVC より重く扱う |
| 第三者声を学習させた派生チェックポイント | 配布者規約 + **元音声の権利者の許諾** | **許諾未確認のものは扱わない**。実在人物・歌い手の声は特に厳格に |

## 6. w-okada/voice-changer 経由で触る場合の責任分界

[w-okada-voice-changer §3.2](./w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理) / [§4](./w-okada-voice-changer.md#4-前処理後処理として提供されているもの) / [§5](./w-okada-voice-changer.md#5-io-構成) で「ホスト側で吸収される / モデル別で違う」と整理した範囲を、本書 §3〜§5 の so-vits-svc 側知見と突き合わせて、**責任分界を 1 枚にまとめる**（[rvc.md §6](./rvc.md#6-w-okadavoice-changer-経由で触る場合の責任分界) と並行）。

**前提:** so-vits-svc は w-okada **v.1 系**でのみサポート（[w-okada-voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より)）。v.2 系では使えないので、配信用途で so-vits-svc を w-okada から触るときは v.1 系バイナリを使う前提になる。

### 6.1 責任分界マップ

| 層 | 担当 | 出どころ |
| --- | --- | --- |
| 入出力デバイス（input / output / monitor の選択、WASAPI / ASIO の選択、サンプリングレート整合） | **ホスト（w-okada）** | [w-okada §5.1 / §5.2 / §5.3](./w-okada-voice-changer.md#5-io-構成) |
| device mode（Client device mode / Server device mode） | **ホスト** | [w-okada §2.2 / §5.1](./w-okada-voice-changer.md#5-io-構成) |
| ノイズ抑制 / エコーキャンセル（Echo / Sup1 / Sup2） | **ホスト**（Client device mode 限定、Chrome 機能経由） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |
| ノイズゲート（S. Thresh） | **ホスト** | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |
| 入出力 GAIN（in / out） | **ホスト** | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。so-vits-svc の `-lea` とは独立 |
| チャンク長（CHUNK）／先行コンテキスト（EXTRA） | **ホスト**（リアルタイム化のためのバッファ管理） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。so-vits-svc 本家のオフライン分割パラメータ（`-cl`/`-sd`/`-lg`/`-lgr`/`-p`）とはレイヤが違う |
| モデルスロット管理（複数モデル切替、アップロード / ダウンロード） | **ホスト** | [w-okada §3.2](./w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理) |
| **複数 ckpt のセット管理**（main `G_*.pth` + `config.json` + 任意 cluster + 任意 diffusion） | **ホスト**（モデルスロット UI 内で扱う想定だが、具体 UI フローは未確認） | [本書 §3.5](#35-配布形態としての成果物)。RVC の「`.pth` + `.index` の 2 ファイル」より多いため、ホスト側がどう扱うかは要実機確認 |
| バッファ可視化・ショートカット | **ホスト** | [w-okada §4.3](./w-okada-voice-changer.md#43-ui-全体モニタリング系) |
| 話者音色（誰の声に変換するか） | **so-vits-svc モデル（チェックポイント）に固定** | [本書 §1.4 / §3.1](#14-配布チェックポイントとしての-so-vits-svc) |
| **話者選択**（`-s` / `--spk_list`） — 同一 ckpt 内の複数話者から選ぶ | **so-vits-svc ckpt + ホスト側 UI**（w-okada UI 露出は未確認） | [本書 §3.1 / §4.1](#31-必要な学習データの形式公式-readme-dataset-preparation)。RVC は 1 ckpt = 1 話者なので、この軸は so-vits-svc 固有 |
| モデルの出力サンプリングレート | **so-vits-svc は 44.1 kHz 固定**（4.0 以降） | [本書 §2.1 / §3.1](#21-4-段構成公式-readme-で確認できる範囲)。RVC が 32k/40k/48k から選べるのと対照的 |
| コンテンツ抽出器の種別（vec256l9 / vec768l12 / hubertsoft / whisper-ppg / wavlmbase+ 等） | **so-vits-svc ckpt に固定**（`config.json` の `speech_encoder`） | [本書 §2.2 / §3.2](#22-softvc-系コンテンツ表現抽出器の選択肢) |
| 4.0 系 / 4.1-Stable 系の判別 | **so-vits-svc ckpt の `config.json`**（`speech_encoder` で判断、§2.3） | [本書 §2.3](#23-40--41-stable-の差分) |
| F0 抽出方式（F0 Det） | **so-vits-svc 推論** | [本書 §4.2](#42-f0-抽出方式の整理) ↔ [w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) |
| 音色漏れ対策（INDEX） — クラスタ or Feature Retrieval | **so-vits-svc 推論**（`-cm`/`-cr`/`-fr`、§4.1） | [本書 §4.3](#43-w-okadavoice-changer-ui-露出との対応表)。RVC の faiss top1 retrieval とは**処理内容が違う**点に注意 |
| ピッチシフト（TUNE = `-t` / `--trans`） | **so-vits-svc 推論** | 同上 |
| 自動ピッチ予測（`-a`） | **so-vits-svc 推論**（既定 off。歌声では off 推奨） | [本書 §4.4](#44-推論時パラメータの調整ガイドreadme--コミュニティ知見) |
| NSF-HiFiGAN Enhancer（`-eh`） | **so-vits-svc 推論**（学習データが薄いモデル向け） | 同上 |
| Loudness Envelope Adjustment（`-lea`） | **so-vits-svc 推論**（出力包絡を入力に追従させる比率） | [本書 §4.1](#41-公式の推論スクリプトで受け取るパラメータ) |
| Loudness Embedding（学習時焼き付け） | **so-vits-svc 学習時に固定**（後から付け足せない） | [本書 §3.4](#34-任意機能を学習時に有効化するフラグ) |
| Shallow Diffusion 後段補正（`-shd`/`-od`/`-ks`） | **so-vits-svc ckpt が diffusion 部品を含むかに依存** | [本書 §2.4 / §3.3 / §3.4](#24-オプション機能音色漏れ対策後段補正音量制御)。w-okada が diffusion ckpt 読み込みをサポートしているかは未確認 |
| 動的話者融合（`-usm`） | **so-vits-svc 推論**（タイムライン定義は `spkmix.py` 経由） | [本書 §4.1](#41-公式の推論スクリプトで受け取るパラメータ)。配信用途で w-okada UI が露出する可能性は低い（未確認） |
| 配布チェックポイントのライセンス | **so-vits-svc 配布元の規約**（ホストの MIT / so-vits-svc コードの AGPL-3.0 とは独立） | [本書 §5.4 / §5.7](#54-コミュニティ配布チェックポイントの扱い)、[w-okada §7.3](./w-okada-voice-changer.md#73-本ラボで扱う際の注意点実運用観点) |
| **AGPL-3.0 の伝播範囲**（w-okada がコードを取り込んでいる場合） | ホスト側 LICENSE / LICENSE-NOTICE の整理に依存 | [本書 §5.1](#51-リポジトリ本体のライセンス)、[TODO.md](../../TODO.md)「w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認」タスク |

### 6.2 「同じ UI 名でも担当が違う」紛らわしい点

特に **RVC からの類推で誤解しやすい**ポイントを明示しておく。

- **INDEX の意味が RVC と so-vits-svc で違う**: 同じ「INDEX」ラベルでも、
  - RVC: **faiss top1 retrieval** の寄せ比率（学習データ側の HuBERT 特徴量に top1 で置換、`index_rate`）
  - so-vits-svc: **K-means クラスタ中心 or Feature Retrieval** の寄せ比率（`cluster_infer_ratio` + `feature_retrieval` フラグで切替）
  - **モデル側で「何に寄せているか」が違う**ため、同じ 0.5 という値でも音への影響は別物。`experiments/` でログを取るときは「モデル種別と一緒に」記録する。
- **GAIN ≠ `-lea` ≠ Loudness Embedding**: w-okada UI の GAIN は **単純音量**（ホスト）、`-lea` は **出力 loudness envelope の入力寄せ比率**（推論時、so-vits-svc）、Loudness Embedding は **学習時に音量条件を埋め込む機能**（学習時、so-vits-svc）。3 つとも音量周りで似た言葉が並ぶが、**レイヤがすべて違う**。
- **CHUNK / EXTRA は so-vits-svc のパラメータではない**: リアルタイム化のためにホストが導入した概念で、so-vits-svc 本家 CLI（`inference_main.py`）にはオフライン分割用の `-cl` / `-sd` / `-lg` / `-lgr` / `-p` しかない。RVC の `x_pad / x_query / x_center / x_max` のような内部コンテキスト長制御に相当するものが so-vits-svc 側にあるかは **未確認**（コード読解レベル）。
- **F0 抽出方式リストが RVC と微妙に違う**: w-okada UI が `dio` / `crepe full` / `crepe tiny` / `rmvpe` を露出している（[w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ)）。`dio` 単独選択肢は so-vits-svc 由来の可能性が高く、`fcpe` も so-vits-svc 側にしかない。**モデル種別を切り替えるだけで F0 抽出方式リストが変わる可能性**があるが、本 Phase の公式ドキュメント確認範囲では確証なし（**未確認**）。

### 6.3 本ラボでこの分界を意識する場面

- **遅延チューニング**: CHUNK / EXTRA / device mode / monitor 経路は **ホスト側で調整**、F0 抽出方式（`fcpe` の軽量性など）は **so-vits-svc 側で選択**。遅延の試行錯誤を `experiments/` に記録する際は、両方の軸を分けてログを残す。**`-shd` や `-eh` を有効化すると推論コストが増える**ため、遅延予算との兼ね合いも考慮する。
- **音色品質チューニング**: INDEX（`-cr`）/ F0 抽出方式 / `-lea` / `-ns` / `-eh` は so-vits-svc 側の話。GAIN / Noise Gate を上げ下げしても変換アルゴリズム自体の音色は変わらない。
- **モデル差し替え時の挙動再現**: ホスト側設定（CHUNK / EXTRA / GAIN / device mode）は **モデルを差し替えても引き継がれる**が、TUNE / INDEX / F0 抽出方式 / 話者選択（`-s`） / shallow diffusion 有効化は **モデル（≒声）と紐づけて記録しないと再現できない**。**so-vits-svc は ckpt セットが最大 5〜6 ファイル**（main + config + cluster + diffusion model + diffusion config）あり得るので、experiments テンプレでは「セットでバージョン管理する」前提を意識する。
- **ライセンス判断の重み**: ホストは MIT、**so-vits-svc コードは AGPL-3.0**（[§5.1](#51-リポジトリ本体のライセンス)）、**コミュニティ配布チェックポイント側は別ライセンス**、**歌唱を学習素材としたものは追加で楽曲権利・実演家権利**（[§5.7](#57-歌声素材という性質に起因する追加リスク-rvc-との差分の核心)）。RVC（[rvc.md §6](./rvc.md#6-w-okadavoice-changer-経由で触る場合の責任分界)）よりライセンス判断軸が 1 段重い。

### 6.4 RVC との責任分界の差分まとめ

[rvc.md §6.1](./rvc.md#61-責任分界マップ) と並べて読むと、so-vits-svc 固有で追加される責任分界項目は次の通り:

| 軸 | RVC | so-vits-svc | 備考 |
| --- | --- | --- | --- |
| 1 ckpt = 1 話者か | はい（1 話者固定） | **いいえ**（複数話者を `n_speakers` 席で持てる） | 話者選択 UI が必要 |
| ckpt セットの構成要素数 | 最大 2（`.pth` + 任意 `.index`） | **最大 5〜6**（main + config + 任意 cluster + 任意 diffusion ×2） | モデルスロット UI 側の負担増 |
| コード側ライセンス | MIT | **AGPL-3.0** | ネットワークサービス組み込み時のソース開示義務に注意 |
| 学習素材ジャンル | 主に話し声 | **主に歌声** | 楽曲権利・実演家権利が絡む比率が高い |
| 後段補正（diffusion） | なし | **あり**（任意） | 推論コスト・ckpt 構成に影響 |
| 動的話者融合 | なし | **あり**（タイムライン制御） | 配信用途では使われにくいが ckpt 側で対応する場合 UI 露出を要する |

→ **w-okada から so-vits-svc を扱うときは、ホスト側 UI の責任範囲はほぼ同じだが、モデル側の責任範囲が RVC より 1.5 倍くらい広がる**、という整理になる。実機検証時はモデル側パラメータの記録を厚めにする運用が向く。

## 7. RVC との対比

§1〜§6 で個別に触れた RVC ([rvc.md](./rvc.md)) との差異を、**構造・入出力・パラメータ・配布形態・ライセンス・運用感** の 6 軸に整理する。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**voice-changer-types** 上は両者とも §1.3 ニューラル変換 / §2.1 ローカル OSS / §3.1 話者依存型に分類されるが（[voice-changer-types §1.3](./voice-changer-types.md#13-ニューラル変換-neural-voice-conversion) / [§3.1](./voice-changer-types.md#31-話者依存型)）、その**同じカテゴリの中での構造的差異**を浮かび上がらせるのが本節の目的。

### 7.1 構造レベルの違い — Retrieval vs コンテンツ表現+話者条件付け

両者とも「**VITS ベースのデコーダ + HuBERT 系コンテンツ特徴量 + F0 条件**」という大枠を共有しているが、**話者性を出力に与える方法**が根本的に違う。

```
RVC（Retrieval ベース）:
入力 → HuBERT → [faiss top1 で学習データ側の特徴量に置換] → VITS デコーダ → 出力
              （話者性は "置き換える特徴量プール" 自体に焼き込まれている）

so-vits-svc（コンテンツ表現+話者条件付け）:
入力 → SoftVC 系エンコーダ → [話者埋め込み + F0 を条件として連結] → VITS デコーダ → NSF-HiFiGAN → 出力
                          （話者性は埋め込みベクトルとして "条件付け" で与える）
```

| 観点 | RVC | so-vits-svc |
| --- | --- | --- |
| 話者性の付与方式 | **Retrieval（faiss top1 近傍検索）** で学習データ側の HuBERT 特徴量に置換 | **話者埋め込みベクトル**を VITS デコーダの条件入力に連結 |
| コンテンツ抽出器 | **`hubert_base.pt` 固定**（v1 = 9 層 256 次元 / v2 = 12 層 768 次元の違いのみ） | **`speech_encoder` で切替可能**（ContentVec / HuBERT-Soft / Whisper-PPG / WavLM 等、§2.2） |
| 1 ckpt あたりの話者数 | **1 話者固定** | **複数話者を `n_speakers` 席で保持可能**（§3.1） |
| 後段補正 | なし | **Shallow Diffusion**（任意、§2.4） |
| Vocoder | HiFi-GAN 系（v2 で multi-period discriminator 3 段追加） | **NSF-HiFiGAN**（公式が「音切れ対策として置き換え」と明言、§2.1） |

含意:

- **so-vits-svc は「コンテンツ表現抽出器そのものを差し替えられる」拡張性**を持つ一方、ckpt の `config.json` が抽出器名を固定するため、配布チェックポイントを使う側からは抽出器の選択は不可（学習時に決まる）。
- **RVC の Retrieval は「学習データに無い音は置換先が無い」という性質**を持つのに対し、so-vits-svc は **学習データから条件として埋め込みを引いてくる**ため、入力にどれだけ近い素材が学習データにあるかという観点での挙動が違う（コミュニティで一般に言われている範囲。実測は本書のスコープ外）。
- どちらも「**VITS ベース**」という共通点を持つが、**VITS 本体（テキスト → 音声）の責任範囲は両者とも引き継いでいない**（テキスト中間表現を介さない点は両者共通、§2.1）。

### 7.2 入出力構成の違い

| 観点 | RVC | so-vits-svc |
| --- | --- | --- |
| 出力サンプリングレート | **モデル別に固定**（v1: 32k / 40k / 48k、v2: 32k / 48k） | **44.1 kHz 固定**（4.0 以降、§2.1） |
| 学習素材のサンプリングレート要件 | モデルの SR と揃える必要あり（FAQ Q18 で不一致対処も言及） | **任意**（`resample.py` で 44.1 kHz に統一、§3.2） |
| 学習素材の分割 | **WebUI が自動分割**（`max_sil_kept=5s`、無音検出ベース、[rvc.md §3.2](./rvc.md#32-前処理パイプラインtraining_tips-に書かれている範囲)） | **ユーザー側で 5〜15 秒に切ってから投入**（§3.1） |
| 入力 wav のジャンル想定 | 主に **話し声** | **歌声**（公式は "Singing" Voice Conversion を強調、§1.1） |
| リアルタイム動作の公式主張 | **公式 README に "end-to-end 170 ms / ASIO 90 ms" を明示**（[rvc.md §2.4](./rvc.md#24-モデル軽量化-f0-抽出方式の選択肢)） | **明示的記述なし**。「リアルタイム配信は `w-okada/voice-changer` に委ねる」立て付け（§2.6） |

含意:

- **so-vits-svc は SR 選択肢がない**ので、配信用途で SR を変えて遅延・GPU 負荷をスケールさせる手段が（モデル側では）ない。
- **歌声前提の前処理運用**（ユーザー側で 5〜15 秒に手動分割）が、話し声中心の RVC ワークフロー（WebUI 一括処理）と運用感を大きく変える。
- **リアルタイム性を公式が保証していない**ことは、配信用途で w-okada/voice-changer 側のチャンク管理（CHUNK / EXTRA）に依存する度合いが RVC より高い、ということを意味する（[§6.3](#63-本ラボでこの分界を意識する場面)）。

### 7.3 学習プロセスの違い

| ステップ | RVC | so-vits-svc |
| --- | --- | --- |
| 前処理の粒度 | **WebUI で一括**（無音分割 → 16 kHz リサンプル → HuBERT 抽出 → F0 抽出 → faiss index 構築） | **CLI 3 スクリプト分割**（`resample.py` → `preprocess_flist_config.py` → `preprocess_hubert_f0.py`、§3.2） |
| コンテンツ抽出器の選択 | **学習時にバージョン (v1/v2) で決まる**（モデル切替で切替） | **`--speech_encoder` で前処理時に明示指定**（§3.2 Step 2） |
| F0 抽出方式（学習時） | `pm` / `harvest` / `crepe` / `rmvpe` の 4 種（[rvc.md §4.2](./rvc.md#42-f0-抽出方式の整理)） | **`pm` / `dio` / `harvest` / `crepe` / `rmvpe` / `fcpe` の 6 種**（§2.5、`dio` 単独と `fcpe` が追加） |
| 任意機能の "学習時固定" / "推論時切替" | 推論時に `f0_method` / `index_rate` / `protect` 等を独立に変えられる | **Loudness Embedding は学習時に焼き付け**（後付け不可、§3.4）。Shallow Diffusion は別途学習スクリプト（`train_diff.py`） |
| クラスタリング / Retrieval の構築 | **faiss index は WebUI の学習フローに同梱**で `.index` として生成 | **K-means クラスタは `cluster/train_cluster.py` で別途学習**、Feature Retrieval（4.1 で追加）の index 構築コマンドは README 上明示薄（§3.3、**未確認**） |
| 必要な学習データ量の目安 | FAQ Q10 が **「10〜50 分」**と明示 | **README に合計時間の明示なし**（1 ファイル 5〜15 秒の規定のみ、§3.1。**未確認**） |
| 配布形態 | **`.pth` + 任意 `.index` の最大 2 ファイル** | **main G + config + 任意 cluster + 任意 diffusion ×2 の最大 5〜6 ファイル**（§3.5） |

含意:

- **so-vits-svc の前処理は「ユーザーがフラグの組み合わせを理解している」前提**（`--vol_aug` を Step 2 で付けたら Step 1 では `--skip_loudnorm` も必要、`--use_diff` を Step 3 で付けるなら別途 `train_diff.py` も走らせる、等）。RVC の WebUI 一括フローと比べると **運用ミスのリスクが大きい**。
- **配布チェックポイントの "セット完全性"** が so-vits-svc では問題になりやすい（main だけ配布 / config 同梱忘れ / diffusion ckpt と config の対応がずれている、等）。w-okada/voice-changer でロードする際にホスト側がどこまで吸収するかは [§6.1](#61-責任分界マップ) でも触れた通り **未確認**。
- 学習データ量の公式ガイドが薄い分、**so-vits-svc は "経験則による試行錯誤" の比重が大きい**（コミュニティで一般に言われている範囲）。

### 7.4 推論パラメータの違い — 「同じ UI 名で違う処理」を中心に

[§6.2](#62-同じ-ui-名でも担当が違う紛らわしい点) と一部重複するが、**RVC からの類推で踏み外しやすい**ポイントを 1 表にまとめる。

| w-okada UI 名 / 役割 | RVC | so-vits-svc | 同名でも処理が違う点 |
| --- | --- | --- | --- |
| **INDEX** | `index_rate`（faiss top1 retrieval の寄せ比率） | `cluster_infer_ratio`（K-means クラスタ中心 or Feature Retrieval の寄せ比率、`-fr` フラグで切替） | **検索アルゴリズムが別物**。同じ 0.5 でも音への影響は別 |
| **TUNE** | `f0_up_key`（半音単位ピッチシフト） | `--trans`（半音単位ピッチシフト） | 概念は同一 |
| **F0 Det** | `pm` / `harvest` / `crepe`（full/tiny） / `rmvpe` | **`pm` / `dio` / `harvest` / `crepe` / `rmvpe` / `fcpe`** | so-vits-svc は **`dio` 単独**と **`fcpe`** が追加。w-okada UI に `dio` が出る場合は so-vits-svc 由来の可能性が高い（§4.3、**未確認**） |
| GAIN（in/out） | ホスト側、`rms_mix_rate` とは独立 | ホスト側、`-lea` とも独立 | so-vits-svc は **音量周りに `-lea`（出力包絡寄せ） + Loudness Embedding（学習時焼き付け） + GAIN** の 3 レイヤがあり整理が必要 |
| CHUNK / EXTRA | ホスト側（リアルタイム用バッファ管理） | ホスト側（同上） | so-vits-svc 本家の `-cl` / `-sd` / `-lg` / `-lgr` / `-p` はオフライン分割用で別レイヤ（§4.1） |

so-vits-svc 固有で **RVC には対応するスイッチが無い** 推論パラメータ:

- `-a` / `--auto_predict_f0` — 自動ピッチ予測（歌声では off 推奨、§4.4）
- `-shd` / `-od` / `-ks` / `-dm` / `-dc` — Shallow Diffusion 系（§4.1）
- `-eh` / `--enhance` + `-eak` — NSF-HiFiGAN Enhancer（学習データが薄いモデル向け、§4.4）
- `-ns` / `--noice_scale` — VITS デコーダのノイズスケール
- `-lea` / `--loudness_envelope_adjustment` — 出力 loudness envelope の入力寄せ比率
- `-ft` / `--f0_filter_threshold` — `crepe` 使用時のみ有効な F0 フィルタ閾値
- `-se` / `--second_encoding` — 公式自身が「玄学选项（おまじない）」と明示している経験則オプション
- `-usm` / `--use_spk_mix` — 動的話者融合（タイムライン制御）

RVC 固有で **so-vits-svc には対応するスイッチが無い** もの:

- `protect` — 子音保護（[rvc.md §4.1](./rvc.md#41-公式の推論パイプラインで受け取るパラメータ)）
- `filter_radius` — 中央値フィルタ半径
- `resample_sr` — 推論時の追加リサンプル
- `rms_mix_rate` — 入出力 RMS ブレンド比率（so-vits-svc では `-lea` + Loudness Embedding が近い役割を別レイヤで担う）

含意:

- **「INDEX を上げる = 学習データ側に寄せる」というメンタルモデルは両者で成立する**が、**実処理は別物**なので、so-vits-svc 用に取った INDEX チューニングログを RVC に転用する（あるいは逆）のは原理的に意味がない。`experiments/` ではモデル種別を必ず併記する運用が要る（[§6.3](#63-本ラボでこの分界を意識する場面) で既述）。
- so-vits-svc は **「歌声向けの細かい補正パラメータ」が多い**（`-a` / `-eh` / `-ns` / `-se` 等）。配信（話し声）用途ではこれらの推奨設定が公式ガイドに薄く、コミュニティ経験則ベースになりやすい。
- **`fcpe` は so-vits-svc 独自**で、F0 抽出の選択肢として RVC より幅広い（§4.2）。配信用途で軽量寄りの選択肢を探す場合の候補に入る。

### 7.5 配布形態の違い

| 観点 | RVC | so-vits-svc |
| --- | --- | --- |
| 公式配布の話者特化モデル | **VCTK 由来 base model を Hugging Face で配布**（[rvc.md §5.2](./rvc.md#52-事前学習モデルの配布)） | **存在しない**（部品のみ配布、§5.2 / §5.3） |
| 配布部品の数 | `hubert_base.pt` + `rmvpe.pt` + `pretrained{,_v2}/` 等 | **ContentVec / HuBERT-Soft / Whisper-PPG / WavLM / NSF-HiFiGAN / RMVPE / FCPE** など複数（§5.2） |
| `ContentVec` の取得元 | （RVC 公式は v2 で ContentVec 系統に言及するのみ） | **Hugging Face `lj1995/VoiceConversionWebUI` = RVC と同じ HF リポジトリ**（§5.2 注記）。ディスク上で共存させやすい |
| 1 チェックポイント = 1 ファイルか | **`.pth` + 任意 `.index` の 2 ファイル** | **最大 5〜6 ファイル**（main G + config + 任意 cluster + 任意 diffusion ×2、§3.5） |
| Vocoder の同梱状況 | コード内蔵（HiFi-GAN 系） | **NSF-HiFiGAN は別配布**（openvpi/vocoders、§5.2） |

含意:

- **so-vits-svc は「base model 配布なしで自前学習を要求する」設計**で、コミュニティ配布チェックポイント or 自前学習以外の選択肢がない（[§5.3](#53-公式が提供する学習済みターゲット話者モデル)）。
- **NSF-HiFiGAN を別途取得する必要がある**ことが、初回セットアップ時の手間（および権利確認の手間）を増やす。RVC は base 一式が同じ HF リポジトリで完結するのに対し、so-vits-svc は **多元的な部品取得**が必要。
- 配布チェックポイントの "完全性チェック" の手数が **モデル単位で 1.5〜3 倍重い**（main / config / cluster / diffusion ×2）。

### 7.6 ライセンスと規約の違い

| 観点 | RVC | so-vits-svc |
| --- | --- | --- |
| コード本体のライセンス | **MIT**（[rvc.md §5.1](./rvc.md#51-リポジトリ本体のライセンス)） | **AGPL-3.0**（§5.1） |
| ネットワークサービス組み込み時のソース開示義務 | **なし**（MIT） | **あり**（AGPL の特徴的条項） |
| 公式の利用目的明文化 | 商用利用への明示的制限なし | **README の "Terms of Use" で「学術目的限定 / 配信投稿時の入力素材明示義務 / 違法・宗教・政治目的禁止」を明文化**（§5.5） |
| 実在人物利用に関する公式スタンス | 明示的な記述なし | **「実在人物への適用は開発者の本来の意図から外れる」と明言**（§5.5） |
| 公式 base model の素材ライセンス主張 | **VCTK 由来で「著作権懸念なし」と公式が主張**（[rvc.md §5.3](./rvc.md#53-事前学習モデルの学習素材ベースモデルが何で学習されたか)） | 公式 base 配布なし。部品（ContentVec / NSF-HiFiGAN 等）は個別ライセンス |
| コミュニティ配布チェックポイントの学習素材ジャンル | 主に話し声 | **主に歌声**（楽曲権利 + 編曲権 + 実演家権が絡む比率が高い、§5.7） |
| リポジトリ管理状態 | アクティブ | **2023-11-11 にアーカイブ済み**（§1.2、新規 commit/issue 不可） |

含意:

- **so-vits-svc は OSS だが、運用上のライセンス負荷が RVC より明確に重い**（AGPL の伝播範囲チェック + 規約レベルでの "学術目的限定" 認識 + 配布チェックポイントの追加権利チェック）。
- **w-okada/voice-changer が so-vits-svc を取り込んでいる場合の AGPL 伝播**は本書で結論を出せていない（§5.1、[TODO.md](../../TODO.md) の w-okada LICENSE 整理タスクで拾う）。
- **公式リポジトリのアーカイブ状態**は、so-vits-svc 本家側に新規バグ修正や機能追加が入らないことを意味する。今後の改善は派生フォーク（so-vits-svc-fork 等）側で行われる前提となり、**「本家公式 = 4.1-Stable で凍結」**という固定スナップショットとして扱うのが本ラボの方針（§1.2）。

### 7.7 運用感の違い — 配信用途での "重さ" の差

ここまでの差を **配信（リアルタイム話し声変換）用途で扱うときの体感的な重さ**として 1 行ずつまとめる。実測ではなく構造から導かれる **予想される運用感**（コミュニティで一般に言われている範囲を含む）として書く。

| 観点 | RVC | so-vits-svc |
| --- | --- | --- |
| 初回セットアップの手数 | 中（HF から base 一式 + 自前 ckpt） | **大**（多元的な部品取得 + 自前学習または配布物の完全性チェック） |
| モデル差し替え時の構成管理 | 軽（`.pth` + 任意 `.index`） | **重**（最大 5〜6 ファイルのセット管理） |
| 推論パラメータの試行錯誤コスト | 中（7 個程度、公式ガイドあり） | **大**（20 個超、公式ガイドが薄い `-ns` / `-lea` 等あり） |
| 「歌声 → 話し声」転用時の挙動 | 元から話し声中心、転用ストレス低 | **公式が "Singing" を強調**しており、話し声転用は `-a` 等のスイッチ理解が必要 |
| ライセンス判断の負荷 | 軽（MIT + 配布物個別チェック） | **重**（AGPL + 学術目的規約 + 歌唱権利 + 配布物個別チェック） |
| 公式の改善継続性 | 公式リポジトリはアクティブ | **アーカイブ済み**（4.1-Stable で凍結） |
| 配信用途での参考実装 | 公式リポジトリに `realtime-gui` 同梱、w-okada/voice-changer もサポート | **w-okada/voice-changer 経由が事実上の標準**（公式 Related Projects 経由、§1.3） |

→ **本ラボの立て付け**: RVC は「まず試す」候補として軽く、so-vits-svc は「歌声寄り素材を扱う必要が出てきた」段階で踏み込む候補として重く扱う。配信（話し声）専用なら RVC を優先するのが構造的に素直で、so-vits-svc を選ぶ動機は **コンテンツ抽出器の差し替え（Whisper-PPG / WavLM 等）**や **Shallow Diffusion による音質改善** など、RVC では届かない要件が出てきたときに限定される、というのが現時点の整理。

### 7.8 1 枚早見表

| 軸 | RVC | so-vits-svc |
| --- | --- | --- |
| 話者性の与え方 | Retrieval（faiss top1） | 話者埋め込み（条件付け） |
| コンテンツ抽出器 | `hubert_base.pt` 固定 | `speech_encoder` で切替可 |
| 1 ckpt の話者数 | 1 | 複数（`n_speakers` 席） |
| 出力 SR | 32k / 40k / 48k | 44.1 kHz 固定 |
| 後段補正 | なし | Shallow Diffusion（任意） |
| 推論パラメータ数 | ~7 | ~20+ |
| 配布物ファイル数 | 1〜2 | 1〜6 |
| 公式 base model | あり（VCTK） | なし |
| コード本体ライセンス | MIT | **AGPL-3.0** |
| 公式の利用目的 | 制限明示なし | **学術目的限定** |
| 学習素材ジャンル | 主に話し声 | 主に歌声 |
| 公式リポジトリ状態 | アクティブ | **アーカイブ済み (2023-11-11)** |
| F0 抽出選択肢 | 4 種 | 6 種（`dio` 単独 + `fcpe` が追加） |
| リアルタイム公式主張 | あり（170 ms / 90 ms） | なし |



## 8. voice-changer-types §4 評価軸への暫定マッピング

[voice-changer-types §4](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) の評価軸に、**so-vits-svc（モデル/アルゴリズムとしての立場）** の暫定マッピングを置く。so-vits-svc は単体ではリアルタイム IO や仮想オーディオデバイス接続を持たず（§2.6）、本ラボでは [w-okada/voice-changer](./w-okada-voice-changer.md) 経由で扱う前提なので、IO 構成・エコシステム面は w-okada 側との責任分界（§6）をそのまま反映する。実測値は本ドキュメントには書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。

| 評価軸 | so-vits-svc（モデル/アルゴリズム）としての暫定マッピング | 出どころ / 補足 |
| --- | --- | --- |
| レイテンシ | **公式 README に明示的なレイテンシ数値はない**（[rvc.md §2.4](./rvc.md#24-モデル軽量化-f0-抽出方式の選択肢) が 170 ms / 90 ms を明示するのと対照的）。リアルタイム配信は w-okada/voice-changer 側に委ねる立て付け（§2.6）で、実値はホスト側のチャンク化遅延（CHUNK / EXTRA）と推論コスト（特に `-shd` / `-eh` 有効時に上振れ）の合算。**本ラボでは未計測** | §2.6 / §6.3 |
| 音質 | モデル単体としての音質は **コンテンツ抽出器の選択（`vec256l9` / `vec768l12` / `whisper-ppg` / `wavlmbase+` 等、§2.2）/ Vocoder（NSF-HiFiGAN 固定）/ 出力サンプリングレート（44.1 kHz 固定、§2.1）/ 推論時の `-f0p` / `-cr` / `-fr` / `-ns` / `-lea` / `-shd` / `-eh`** で決まる。**学習時に `--vol_aug` で焼き付けた Loudness Embedding** が音量追従に効く（§3.4）。**実測の自然さ・破綻のしにくさは本書では扱わない** | §2.1 / §2.2 / §2.4 / §3.4 / §4.1 / §4.4 |
| 必要 GPU 性能 | **公式 README に具体的な VRAM プロファイル提示はない**（RVC FAQ Q8 の `x_pad/x_query/x_center/x_max` 3 プロファイルのような明示なし、**未確認**）。コンテンツ抽出器（ContentVec / Whisper-large 等）+ NSF-HiFiGAN + 任意で diffusion モデルのロードが前提で、**Whisper-PPG-large や WavLM 系を選ぶと VRAM が嵩む**ことはモデル選択上の論点（コミュニティで一般に言われている範囲）。**本書では未計測** | §2.2 / §5.2 |
| CPU 負荷 | 公式に明示的な記述はない。**F0 抽出方式によって負荷分担が変わる**（`pm` / `dio` / `harvest` は CPU 寄り、`crepe` / `rmvpe` / `fcpe` は GPU 寄り）と推測されるが、**本書では未計測**。`fcpe` は RVC main pipeline に無い軽量寄り選択肢として独自（§4.2） | §2.5 / §4.2 |
| 入出力構成 | **モデル単体は IO 構成を持たない**。公式リポジトリにリアルタイム配信用 GUI は同梱されず、**公式 README が "Related Projects" として w-okada/voice-changer を「A client supports real-time conversion」として名指し**（§1.3）。本ラボの想定上は **w-okada/voice-changer 経由**で扱う（IO 構成・device mode はホスト側の責任、§6） | §1.3 / §2.6 / §6.1 |
| モデル形態 | voice-changer-types **§3.1 話者依存型**。ただし **1 チェックポイントに複数話者を同梱できる**（`n_speakers` 席、§3.1）点が RVC（1 ckpt = 1 話者）との差。新しい声を増やすには学習データ + 学習が必要で、**Loudness Embedding は学習時にしか有効化できない**ため "後から付け足せない" 機能がある（§3.4） | §1.4 / §3.1 / §3.4 / §3.5 |
| カスタマイズ性 | **学習側**: コンテンツ抽出器の選択肢（`speech_encoder` で 8 種、§2.2）/ 任意機能の有効化（cluster / feature retrieval / shallow diffusion / loudness embedding）/ F0 抽出方式 6 種（§2.5）。**推論側**: `-f0p` / `-cr` / `-fr` / `-t` / `-a` / `-ft` / `-lea` / `-ns` / `-shd` / `-od` / `-ks` / `-dm` / `-dc` / `-se` / `-usm` / `-eh` / `-eak` 等 20 個超（§4.1）。**RVC（推論 ~7 個）の 3 倍弱**の自由度がある一方、公式 README に推奨値が薄いパラメータも多い（`-ns` / `-lea` 等、§4.4 / §9）。ホスト経由で UI 露出される範囲は §4.3 のとおりごく一部 | §2.2 / §2.4 / §3.4 / §4.1 / §4.3 |
| 配信での利用可否 | **コード本体は AGPL-3.0**（[RVC が MIT](./rvc.md#51-リポジトリ本体のライセンス) なのと対照的、§5.1）。**公式 README が "academic purposes only" / "anime characters performing singing tasks" を明言**しており、**実在人物への利用は開発者の本来の意図から外れる**と公式が明示（§5.5）。配信投稿時の **入力素材表示義務**も README で明文化されている。実運用上の判断は **コミュニティ配布チェックポイント側の規約 + 元音声の権利者許諾 + 歌唱録音の場合は楽曲・編曲・実演家権利**の多段チェックで決まる（§5.7）。本ラボでは [CLAUDE.md](../../CLAUDE.md) 方針により**第三者の声・歌唱を許諾なく再現する用途には誘導しない**、特定チェックポイントの取得導線は記載しない | §5.1 / §5.4 / §5.5 / §5.7 / §5.8 |
| エコシステム | 公式リポジトリ（`svc-develop-team/so-vits-svc`）は **2023-11-11 にアーカイブ済み**（§1.2）で、機能追加は派生フォーク（`voicepaw/so-vits-svc-fork` / MoeVoiceStudio 等、§1.3）側に移っている。**コミュニティ配布チェックポイントは歌声変換界隈で多数流通**するが、本書では取得導線を扱わない（§5.4）。配信向け対応は **w-okada/voice-changer v.1 系のみ**（v.2 系では非対応、§4.3） | §1.2 / §1.3 / §4.3 / §5.4 |
| コスト | コード本体（AGPL-3.0）・必要部品（ContentVec / NSF-HiFiGAN / RMVPE / FCPE 等、§5.2）はいずれも無償。**公式 base 話者モデルが存在しない**ため（§5.3）、**実質コストは GPU マシン + 自前学習用の音声データ収集（または配布元規約に従ったチェックポイント取得）**に集約。**自前学習を伴う比率が RVC より高い**（RVC は VCTK 由来 base から fine-tune できるが、so-vits-svc はゼロから話者特化を作る前提）。クラウド利用料は不要 | §5.1 / §5.2 / §5.3 |

モデル/アルゴリズム単体で値が出せる評価軸は **モデル形態（§3.1 話者依存 + 複数話者席）/ カスタマイズ性（学習・推論パラメータの自由度が広い）/ 配信での利用可否（コード AGPL-3.0 + 規約上学術目的 + チェックポイント別判断）/ コスト（OSS、ただし自前学習比率高）** の 4 つで、**レイテンシ・音質・必要 GPU・CPU 負荷** はホスト・ロード環境・実機計測と組み合わせて初めて値が確定する、というのが本 Phase の結論（[rvc.md §7](./rvc.md#7-voice-changer-types-§4-評価軸への暫定マッピング) と同じ構造）。w-okada/voice-changer 側の評価軸マッピング（[w-okada §8](./w-okada-voice-changer.md#8-voice-changer-types-§4-評価軸への暫定マッピング)）と組み合わせて、**ホスト × モデル**の二段でようやく voice-changer-types §4 の表が埋まる。

**RVC との対比視点での要点**（§7 のサマリを評価軸ごとに再投影）:

- レイテンシ・必要 GPU: **公式が数値を出していない**点で RVC より定量比較しにくい
- 音質: **コンテンツ抽出器の差し替えと Shallow Diffusion 後段補正**という RVC にない 2 軸の自由度がある一方、Vocoder（NSF-HiFiGAN）と出力 SR（44.1 kHz）は固定
- カスタマイズ性: 推論パラメータが ~3 倍だが、公式ガイドが薄いパラメータも多く **試行錯誤コストが高い**
- 配信での利用可否: **AGPL-3.0 + 学術目的規約 + 歌唱権利**の三重で RVC（MIT のみ）より重い
- エコシステム: **本家アーカイブ済み**で、改善継続性は派生フォーク側に委ねられている

## 9. 未確認事項 / 後続タスク

本書 §1〜§8 を通して残った「未確認」マーカーを、**(A) 既存 TODO で吸収するもの / (B) 新規起票するもの / (C) 当面深追いしないもの** の 3 区分で整理する（[rvc.md §8](./rvc.md#8-未確認事項--後続タスク) と並行な構成）。Phase 2 で解消できた項目（§2.4 の "K-means と Feature Retrieval は排他か" 等）は §4.1 / §6.1 で結論を出しており、ここには再掲しない。

### 9.1 既存タスクで吸収する未確認事項

[`TODO.md`](../../TODO.md) に既にある後続タスクで自然に拾えるもの。本書では結論を出さずに引き継ぐ。

- **w-okada UI 上で so-vits-svc 選択時に追加表示されるパラメータ群**（§4.3 / §6.1）— 話者選択 UI（`-s` / `--spk_list` 相当、so-vits-svc 固有）、Shallow Diffusion 切替（`-shd` / `-ks` / `-od` + `-dm` / `-dc`）、Cluster vs Feature Retrieval 切替（`-cm` / `-cr` / `-fr`）、Loudness Envelope Adjustment（`-lea`）等が UI 露出されているかの実機確認 → `TODO.md` の **「w-okada/voice-changer の実測タスク用 `experiments/` テンプレート整備」** で UI 確認と併せて拾う
- **w-okada UI の `dio` 単独選択肢が so-vits-svc 経由かどうか**（§2.5 / §4.3 / §6.2）— RVC main pipeline に `dio` 単独分岐がない事実（[rvc.md §4.2](./rvc.md#42-f0-抽出方式の整理)）と、so-vits-svc 本家に存在する事実は揃ったが、w-okada 実装で実際に `dio` 選択時にどちらのルートを通るかは未確認 → 同上の `experiments/` テンプレ整備で扱う
- **w-okada が so-vits-svc 用の複数 ckpt セット（main + config + 任意 cluster + 任意 diffusion ×2）をどう扱うか**（§3.5 / §6.1）— モデルスロット UI が 1 スロットあたり最大 5〜6 ファイル受け付けるかの実機確認 → 同上
- **AGPL-3.0 が w-okada/voice-changer ホスト経由で利用された場合の伝播範囲**（§5.1）— w-okada 側 LICENSE / LICENSE-NOTICE 整理に統合 → `TODO.md` の **「w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認とキャラクター音声利用条件の整理」**（[spec §7](./w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点) の深堀）で扱う
- **コミュニティ配布チェックポイントのライセンス判断軸（§5.4 / §5.7 / §5.8）を実運用に落とす**（特に歌唱録音の楽曲権利・実演家権利チェックの手順テンプレ化）→ 同 LICENSE 整理タスクで扱う

### 9.2 本タスクの follow-up として新規起票するもの

本書範囲では結論が出ず、かつ既存タスクでは吸収しきれない独立タスクは **現時点では起票しない**。理由:

- 実機計測（so-vits-svc 4.0/4.1 × コンテンツ抽出器 × F0 抽出方式 × INDEX/TUNE × Shallow Diffusion on/off）の計測条件テンプレは **w-okada 実測テンプレ整備の上に重ねる**形が自然で、先に独立 TODO に立てると RVC 用テンプレと重複する
- so-vits-svc-fork / MoeVoiceStudio の個別深掘りはプラン側スコープ外（[plan](../plans/so-vits-svc.md)「含めない」セクション）で、本家アーカイブ後の継続開発状況把握は §9.3 の通り当面様子見
- §5.7 で挙げた "歌声素材ゆえの追加リスク" の運用テンプレ化は、w-okada 側 LICENSE 整理タスク（§9.1）の成果物として書ける範囲で、独立タスクは不要

→ **新規 TODO 起票は 0 件**。実機検証段階で必要になった時点で改めて TODO 化する（[rvc.md §8.2](./rvc.md#82-本タスクの-follow-up-として新規起票するもの) と同じ判断）。

### 9.3 当面は深追いしない領域

本ラボのスコープでは現時点で踏み込む必要がなく、必要になった時点で再開するもの（いずれも公式 README / アーカイブ済みリポジトリの範囲を越えてコード読解または派生フォーク調査が要る項目）。

- **VITS のどの部分を継承／差し替えているか**（§2.1）— コード読解レベル。アーキ詳細を踏まずとも本ラボ用途には支障なし
- **SoftVC / ContentVec / HuBERT 派生それぞれの声質・歌声適性の使い分け**（§2.2）— 公式 README に明文ガイドなし。コミュニティ経験則ベースで、実機検証段で扱う方が筋が良い
- **学習時の F0 分布と推論時の F0 分布の乖離が変換品質に与える影響**（§4.2）— 公式 README に明示なし、コミュニティで一般に言われている範囲。実機検証時に扱う
- **データセット全体の推奨合計時間**（§3.5）— RVC FAQ Q10 の "10〜50 分推奨" に相当する記述が so-vits-svc README にない。自前学習を本格的に試す段階で実検証
- **Feature Retrieval（4.1）用 index 構築コマンドの正確な手順**（§3.3 / §3.4）— README 上の明示が薄い。Feature Retrieval を実機で試す段で確認
- **前処理後のディレクトリ命名規約 / `train.py` ckpt 互換性のメタデータ整合**（§3.2 / §3.3 末尾）— 自前学習を回す段になれば自然に解消
- **`-ns` / `-lea` の具体的推奨範囲**（§4.4 / §4.1）— 公式が値の意味を明示せず、`-se` に至っては「玄学选项」と自評。実機検証時にレンジを試す
- **NSF-HiFiGAN / Whisper / WavLM 等の依存物の個別ライセンス整合**（§5.2 / §5.6）— バイナリ再配布を行わない本ラボ運用では当面影響なし。必要になった時点で確認
- **`svc-develop-team/so-vits-svc` のアーカイブ後の継続開発がどこで行われているか**（§1.2 / §1.3）— so-vits-svc-fork（`voicepaw/so-vits-svc-fork`）など派生フォーク側で行われていると推測されるが、本書では「本家公式 = 4.1-Stable で凍結」というスナップショット運用を選んでおり、派生フォーク個別の深掘りはプラン側スコープ外

### 9.4 Phase 3 で確認できたこと（参考）

Phase 1〜2 から繰り越した未確認マーカーのうち、**§7（RVC 対比）/ §8（評価軸）執筆中に整理が進んだもの**を簡潔にメモする（本書本文に既に反映済み、再掲のため）。

- **構造レベルでの RVC との違い** — §7.1 で「Retrieval vs 話者埋め込み条件付け」として整理完了
- **配布形態の重さの差** — §7.5 で 1〜2 ファイル vs 1〜6 ファイルとして数値で対比できた
- **ライセンス負荷の差** — §7.6 で MIT vs AGPL-3.0 + 学術目的規約 + 歌唱権利の 3 段として整理完了
- **モデル単体で答えられる評価軸 / ホストと組み合わせて初めて埋まる評価軸の切り分け** — §8 で結論（モデル単体で値が出るのは 4 軸、ホスト × モデルで埋まるのが残り 6 軸）
