# RVC (Retrieval-based Voice Conversion)

> [voice-changer-types](./voice-changer-types.md) 上の位置付け: **技術アプローチ: 1.3 ニューラル変換（Retrieval ベース系）/ 提供形態: 2.1 ローカル OSS / モデル形態: 3.1 話者依存**
>
> 本ページは [docs/plans/rvc.md](../plans/rvc.md) のスコープに沿って、**公式リポジトリ（[RVC-Project/Retrieval-based-Voice-Conversion-WebUI](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI)）の README / docs で述べられている内容**を中心にまとめる。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。
> 各項目で「公式に書かれている内容」「コミュニティで一般に言われている内容」「未確認」を区別する。
>
> **進捗:** Phase 1〜3 完了（§1〜§8）。実測値は本書では扱わず、`experiments/` 配下のタスクへ引き継ぐ。

## 1. 概要 — 「RVC」が指す 3 つのレイヤ

「RVC」という名前は文脈によって少なくとも次の 3 つを指す。本ラボでは混同しないように分けて扱う。

### 1.1 アルゴリズムとしての RVC

- **Retrieval-based Voice Conversion** の略。
- 公式 README は次のように要約している:
  > 「An easy-to-use Voice Conversion framework based on VITS」（[docs/en/README.en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/README.en.md)）
  > 「Reduce tone leakage by replacing the source feature to training-set feature using top1 retrieval」（同上）
- 中国語版 README では「top1检索替换输入源特征为训练集特征」と記述されており、**入力から抽出した特徴量を、学習データから top1 で検索した特徴量に置き換える**点が「Retrieval-based」の由来。
- voice-changer-types §1.3 で挙げた「Retrieval ベース系」のまさに語源にあたる系統で、コンテンツ表現抽出器（HuBERT 系）と Retrieval（faiss kNN）と VITS ベースのデコーダ／HiFiGAN 系 Vocoder を組み合わせた構成（詳細 §2）。

### 1.2 公式リポジトリとしての RVC

- 現行の公式リポジトリは **`RVC-Project/Retrieval-based-Voice-Conversion-WebUI`**（GitHub Organization `RVC-Project` 配下）。
- 公式キャッチコピーは "Easily train a good VC model with voice data <= 10 mins!"。
- 提供されるのは **学習用 WebUI + 推論機能** の一体型。リアルタイム推論用 GUI（`realtime-gui`）も同梱されているが、配信用途では本ラボの想定上ホスト側（[w-okada/voice-changer](./w-okada-voice-changer.md)）から呼ぶケースが多い。
- 同名・近名のリポジトリが複数存在する（例: `fumiama/Retrieval-based-Voice-Conversion-WebUI`, `ddPn08/rvc-webui`）が、これらは派生 / 再構成プロジェクト。**本ページが公式扱いするのは `RVC-Project/Retrieval-based-Voice-Conversion-WebUI` のみ**。
- 別途 `RVC-Project/Retrieval-based-Voice-Conversion` というリポジトリも `RVC-Project` 組織配下に存在するが README が "in preparation..." 状態であり、現時点では参照対象にしない（**未確認**）。

### 1.3 配布チェックポイントとしての RVC

- ここで言う「チェックポイント」は **ユーザー（または第三者）が作った話者特化の `.pth` ファイル + faiss index ファイル** を指す。
- 公式が Hugging Face で配布しているのは **事前学習モデル（base model）** であって、特定キャラ／個人の声に変換するためのチェックポイントではない（§5.2 参照）。
- 配信界隈で「RVC モデル」と言う場合、ほとんどが **コミュニティ配布のチェックポイント**（個人・キャラクター声で学習されたもの）を指す。これらの利用条件は **公式リポジトリのライセンスとは独立に**、配布者の規約・学習素材の規約で判断する（[CLAUDE.md](../../CLAUDE.md) 方針との接点が最も大きい部分。§5.4 で再掲）。

### 1.4 v.2 / v.1 という呼び方

- 公式リポジトリ内に **v1 / v2 の事前学習モデル**（`pretrained/` と `pretrained_v2/`）が併置されている（§2.4 / §5.2）。
- w-okada/voice-changer 側のサポートモデル表でも「RVC (v.2 / v.1)」として両者がサポートされていることが確認できる（[w-okada-voice-changer §3.1](./w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より)）。
- 本ラボでは、特に断らない限り「RVC」と書いたときは **アルゴリズム＋公式リポジトリの総体**を指し、モデルバージョンに依存する話は明示的に v1 / v2 と書き分ける。

## 2. アーキテクチャ概観

### 2.1 3 段構成（公式 README で確認できる範囲）

公式 README（中国語版・英語版）で言及されている要素を、本ラボの理解で 3 段に整理すると以下になる。

```
入力波形
   │
   ▼
[1] コンテンツ表現抽出  ── HuBERT 系（hubert_base.pt）
   │       v1: 9 層目 + final_proj、256 次元
   │       v2: 12 層目、768 次元
   ▼
[2] Retrieval（faiss）  ── 学習データ側で構築した index に対し top1 検索
   │       「元の特徴量にすべて寄せる」比率は推論時パラメータ（INDEX 比率）
   ▼
[3] デコーダ／Vocoder  ── VITS ベース + HiFiGAN 系 Vocoder
   │       話者は学習済みチェックポイント（.pth）固有で固定
   │       F0 を別途条件として入力（F0 抽出方式は推論時に選択）
   ▼
出力波形
```

公式に明示的に確認できる根拠:

- **VITS ベース**: 公式 README は「基于VITS的」「based on VITS」と明記。[docs/en/README.en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/README.en.md) の Credits でも `VITS` が筆頭に挙げられている。
- **HuBERT 系コンテンツ抽出**: 必要ファイルとして `hubert_base.pt`（約 190 MB）が `assets/hubert/` に配置される。
- **HiFiGAN 系 Vocoder**: 同 Credits に `HIFIGAN` が挙げられている。
- **Retrieval は top1**: 中国語版 README に「top1检索替换输入源特征为训练集特征」、英語版 README に「Reduce tone leakage by replacing the source feature to training-set feature using top1 retrieval」と明記。
- **faiss 利用**: 学習側ドキュメント [docs/en/training_tips_en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/training_tips_en.md) に「For index learning, we use the approximate neighborhood search library faiss」と明記。

「VITS ベース」と書かれている部分は、**FastSpeech 系の TTS とは異なるアーキ系統**で、エンコーダ／デュレーション／フローを含む生成型モデルだ、というレベルで本ラボでは扱う。**VITS のどのバージョンを継承しているか・どこを差し替えているか**といったコード読解レベルの裏取りは Phase 1 のスコープ外（**未確認**）。

### 2.2 Retrieval（faiss index）の役割

- 学習データ側で **HuBERT 特徴量に対する faiss の近似最近傍 index を別途構築**する。これが配布物に含まれる `.index` ファイル。
- 推論時、入力波形から抽出した HuBERT 特徴量を index で top1 検索し、**「元の特徴量にどれだけ寄せるか」の比率**を UI から指定する（公式 FAQ で `index_rate` として説明されている。[docs/en/faq_en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md) Q11）。
- 公式 FAQ の表現:
  > 「Setting it to 1 theoretically prevents leakage toward the training set's timbre. Setting it to 0 disables retrieval-based protection.」（[docs/en/faq_en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md) Q11 から要旨。本ラボ訳: 1 にすると学習データ側の音色への寄せが強くなり、0 にすると Retrieval を実質無効化する）
  > 「If the training set has good audio quality and long duration, ... the index_rate is not important and you can even not create/share the index file.」（同上）
- → **`.index` は配布が任意**。学習データ品質が高ければ index 無しでも運用できる、というのが公式の立場。w-okada/voice-changer 側の UI で「INDEX」スライダが 0〜1 で出ている挙動と整合する（[w-okada-voice-changer §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ)）。

### 2.3 v1 / v2 の差分（公式 README で確認できる範囲）

公式の英語 README に書かれている差分は次のとおり:

> 「v2 uses 768 dimensional feature of 12-layer Hubert versus v1's 256 dimensional feature of 9-layer Hubert+final_proj and added 3 period discriminators」
> （[docs/en/README.en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/README.en.md) より）

これを表に直すと:

| 項目 | v1 | v2 |
| --- | --- | --- |
| コンテンツ特徴量 | HuBERT 9 層目 + `final_proj` | HuBERT 12 層目 |
| 特徴量次元 | 256 | 768 |
| 識別器（discriminator） | （デフォルト） | period discriminator を 3 個追加 |

その他、本ラボで間接的に確認できる差分:

- **事前学習モデルディレクトリ**が `pretrained/`（v1）と `pretrained_v2/`（v2）に分かれている（§5.2）。
- **サンプリングレート違い**のファイル名（`32k`, `40k`, `48k` 等）が `.pth` 名に含まれており、各サンプリングレートで base model が用意されている。ただし「v1 はどのサンプリングレートをサポート、v2 はどれ」のような正確な対応表は本 Phase で確認した README / FAQ の範囲では網羅されていない（**未確認**。Phase 2 の学習プロセス整理で再確認する）。
- **3 period discriminators 追加**の正確な意味（HiFi-GAN 系の multi-period discriminator を 3 段に増やしたという理解で良いか）は **公式 README にこれ以上の説明はなく未確認**。コード読解が必要なレベルなので Phase 1 では踏み込まない。

### 2.4 「リアルタイム」のための工夫として README に挙がっているもの

公式 README で **「real-time」「end-to-end latency」**として明示的に書かれているのは次の 2 点。

- **エンドツーエンド 170 ms**:
  > 「We have achieved an end-to-end latency of 170ms.」（[docs/en/README.en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/README.en.md)）
- **ASIO 入出力で 90 ms**:
  > 「With the use of ASIO input and output devices, we have managed to achieve an end-to-end latency of 90ms.」（同上）

これらは **公式が README に書いている数値**で、本ラボが実測した値ではない。**本ラボでの実測は別途 `experiments/` で扱う**（[CLAUDE.md](../../CLAUDE.md) 方針）。

また、ピッチ抽出側のリアルタイム性能向上として、

- **InterSpeech 2023 - RMVPE** を公式が推している:
  > 「High-pitch Voice Extraction Algorithm [InterSpeech2023-RMVPE]」（features 一覧）
  > 「significantly ... faster and resource-efficient compared to crepe_full」（[docs/en/README.en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/README.en.md) 周辺の RMVPE 評）

ことが確認できる。**選択可能な F0 抽出方式の網羅的なリスト**（dio / harvest / crepe / crepe-tiny / rmvpe など）は w-okada/voice-changer 側の UI 露出からは確認済みだが（[w-okada-voice-changer §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ)）、**RVC 本家の README / FAQ / training_tips を Phase 1 で当たった範囲では網羅リストは見つかっていない**（学習用 training_tips では parselmouth / pyworld、FAQ では harvest / pm が言及される程度）。**完全なリストは Phase 2 で改めて確認する**。

## 3. 学習プロセスの大枠

本節は **公式 [docs/en/training_tips_en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/training_tips_en.md) / [docs/jp/training_tips_ja.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/jp/training_tips_ja.md) と [docs/en/faq_en.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md) / [docs/jp/faq_ja.md](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/jp/faq_ja.md) で確認できる範囲**を整理する。コードレベル（学習ループの実装詳細）には踏み込まない。

### 3.1 必要な学習データ量・エポック数（FAQ ベース）

FAQ Q9 / Q10 で公式が推奨している目安。

| 観点 | 推奨値 | 出典 |
| --- | --- | --- |
| 学習データ長（標準） | **10〜50 分** | [FAQ Q10](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md) |
| 学習データ長（高品質・特徴的な音色なら） | 5〜10 分でも可 | 同上 |
| 学習データ長（1〜2 分） | 「再現性は低い、非常に特徴的な音色＋高音質が必要」 | 同上 |
| 学習データ長（1 分未満） | 「成功した試みなし、非推奨」 | 同上 |
| `total_epoch`（ノイズが多い / 品質が低いデータ） | **20〜30 で十分** | [FAQ Q9](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md) |
| `total_epoch`（高品質データ） | 200 まで上げてよい | 同上 |

本ラボでは「VC として最低 10 分」が公式の最低ラインだと理解し、それ未満で学習されたコミュニティ配布チェックポイントは品質期待値を下げる、という方針で扱う。

### 3.2 前処理パイプライン（training_tips に書かれている範囲）

`training_tips_en.md` / `training_tips_ja.md` に書かれている前処理の流れは以下の通り（用語は本ラボの整理）。

1. **音声ファイルの読み込み** — フォルダ指定で一括読み込み。内部で **FFmpeg** 経由（training_tips_ja: 「ffmpeg を利用」）。
2. **denoising** — `scipy` の `filtfilt` で平滑化（training_tips_ja: 「scipy の filtfilt による平滑化」）。
3. **無音分割** — **`max_sil_kept=5` 秒**より長い無音区間を検出して分割。その後 **4 秒区切り・0.3 秒オーバーラップ** で再分割（training_tips_en: "split the audio every 4 seconds with an overlap of 0.3 seconds"）。出力先: `/logs/{experiment_name}/0_gt_wavs`。
4. **16 kHz リサンプリング** — 特徴量抽出用に 16k へ変換し `/logs/{experiment_name}/1_16k_wavs` へ保存（training_tips_en: "convert it to 16k sampling rate"）。**学習データ側の素材波形と HuBERT への入力波形は別のサンプリングレートで管理されている**点に注意（出力モデルのサンプリングレートは v1/v2 によって 32k/40k/48k、§3.4）。
5. **HuBERT 特徴量抽出** — `hubert_base.pt` で特徴量を抽出し npy 形式で保存。training_tips では **「256 次元の特徴量に変換し `/logs/{exp}/3_feature256`」** と書かれている（v1 ベースの記述。v2 の 768 次元については training_tips 本文では言及されておらず、§2.3 の README 引用と推論パイプラインのコード分岐から確認できる）。
6. **F0 抽出** — training_tips では **「parselmouth や pyworld に内蔵されている手法でピッチ情報 (=f0) を抽出」** と書かれており、**学習時の F0 抽出は parselmouth / pyworld（pm / harvest / dio 系）が使われる**ことが確認できる。training_tips_ja には「ピッチ情報を対数で変換して 1〜255 の整数に変換」とあり、ログスケール → 1〜255 量子化されてから学習に使われる。
7. **faiss index 構築** — `/logs/{exp}/3_feature256` の特徴量に対し近似最近傍 index を構築（training_tips_en: "we use the approximate neighborhood search library faiss"）。**index の具体的構築アルゴリズム（IVF / PQ 等）は training_tips では明示されていない**（**未確認**。コード読解必要）。
8. **学習** — 事前学習モデル（§3.4）から fine-tune する形で学習ループを実行。

### 3.3 v1 / v2 でのコンテンツ特徴量の違い（再掲 + 補足）

§2.3 の表に書いたとおり、v1 / v2 で HuBERT の取り出し方が違う。これは推論側のコード [`infer/modules/vc/pipeline.py`](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/infer/modules/vc/pipeline.py) の以下の分岐から確認できる:

> `"output_layer": 9 if version == "v1" else 12`

すなわち推論時に同じ HuBERT 重み（`hubert_base.pt`）を使いつつ、**抽出する層を v1=9 / v2=12 で切り替えている**。学習時に保存される特徴量も同様にバージョン依存（v1=256 次元・v2=768 次元）になっており、`3_feature256` / `3_feature768` のディレクトリ名で分かれる。training_tips 本文は v1 ベースで書かれているため `3_feature256` のみが登場するが、コード上は v2 で次元数違いのパスが使われる（**未確認**: ディレクトリ名の正確な命名規約はコードレベルで再確認していない）。

### 3.4 事前学習モデルの命名規約とサンプリングレート対応

[`configs/config.py`](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/configs/config.py) の `version_config_list` には以下の組み合わせが定義されており、**v1 と v2 で対応サンプリングレートが異なる**ことが確認できる。

| バージョン | 設定ファイル | サンプリングレート |
| --- | --- | --- |
| v1 | `v1/32k.json` | 32 kHz |
| v1 | `v1/40k.json` | 40 kHz |
| v1 | `v1/48k.json` | 48 kHz |
| v2 | `v2/32k.json` | 32 kHz |
| v2 | `v2/48k.json` | 48 kHz |

→ **v2 では 40k のサポートはコード上見当たらない**（Phase 1 で「未確認」としていた点が解決）。

事前学習モデルのファイル名は **`{f0?}{G|D}{sr}.pth`** という規則:

- `G` は Generator、`D` は Discriminator
- 接頭辞 `f0` がついていれば F0 条件付きモデル（普通の話し声 / 歌声 VC ではこちら）。`f0` がなければ F0 を使わないバージョン
- 例: `pretrained/f0G40k.pth` / `pretrained/f0D40k.pth`（v1, 40k, F0 あり）、`pretrained_v2/f0G48k.pth` / `pretrained_v2/f0D48k.pth`（v2, 48k, F0 あり）

training_tips_ja の記述例:

> 「RVC のある場所/pretrained/f0G40k.pth と RVC のある場所/pretrained/f0D40k.pth …RVC のある場所/pretrained/G40k.pth と RVC のある場所/pretrained/D40k.pth」

学習時はここから fine-tune が始まり、結果が `logs/{experiment_name}/G_{epoch}.pth` / `D_{epoch}.pth` として保存される。

### 3.5 学習中断・再開・差分追加・ckpt 抽出（FAQ より）

FAQ で言及されている運用パターン:

- **Q13: 学習途中で保存されたモデルから推論する**: 「ckpt 処理タブ下部のモデル抽出機能を使う」。学習中の G/D ファイルをそのまま推論には使えないため、**ckpt 抽出ステップを通して `weights/exp_name.pth` を生成する**必要がある。Q4 でも「checkpoint ファイルを直接使うと f0 / tgt_sr 等が欠落するエラーが出る」と注意がある。
- **Q15: データを追加して学習を継続する**:
  1. 新しい wav を別のパス（`path2`）に置き、`exp_name2` として前処理＋特徴量抽出を実行
  2. **`exp_name1` の最新 G / D ファイルを `exp_name2` フォルダにコピー**
  3. 「train the model」を押すと前の epoch から継続できる
- **Q18: テンソルサイズ不一致 (24 vs 16)**: 「学習中にサンプリングレートを変えるな」。**いったん始めた学習中のサンプリングレート変更は不可**で、新規 exp で最初から学習し直す。あるいは前処理結果（`0/1/2/2b` フォルダ）を流用する。

### 3.6 配布形態としての成果物

学習完了後にユーザが手にするのは **モデルスロット単位で 2 つ**:

- `weights/{exp_name}.pth` — 60 MB 程度の話者特化モデル（ckpt 抽出済み）。これ単独で推論可能。
- `logs/{exp_name}/added_*.index` — faiss index ファイル。**配布は任意**（§2.2 の通り index_rate=0 で運用すれば index なしでも推論はできる）。

FAQ Q4 は「将来、weights は index と統合して 1 つの zip ファイルになる予定」と書いており、現状は **2 ファイルセットでの配布が一般的**だが、index なしのケースもあり得るという立場。

> 本節で踏み込まなかった点（**未確認**として §8 に引き継ぐ）:
>
> - faiss index の具体的アルゴリズム（IVF / PQ 等の構造）
> - v2 における HuBERT 特徴量保存ディレクトリの正確な命名規約（`3_feature768` か別名か）
> - サンプリングレート差（32k/40k/48k）が音質・遅延・GPU 負荷に与える実用的な影響（**未計測**）

## 4. 推論パラメータ（w-okada UI との対応表）

### 4.1 公式の推論パイプラインで受け取るパラメータ

[`infer/modules/vc/pipeline.py`](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/infer/modules/vc/pipeline.py)（メインの推論パイプライン）と [`tools/infer_cli.py`](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/tools/infer_cli.py)（CLI スクリプト）から確認できる、推論時のパラメータ。

| パラメータ名（内部名） | 意味 | 既定値（CLI） | 取りうる値 |
| --- | --- | --- | --- |
| `f0_up_key` (`--f0up_key`) | ピッチシフト量（半音単位）。`f0 *= pow(2, f0_up_key / 12)` で適用される | `0` | 整数（±12 程度の範囲が現実的） |
| `f0_method` (`--f0method`) | F0 抽出アルゴリズムの選択 | `"harvest"` | **`pm` / `harvest` / `crepe` / `rmvpe`**（pipeline.py の if 分岐から確認）。CLI は `harvest` と `pm` の 2 択に絞られている |
| `index_rate` (`--index_rate`) | Retrieval（faiss index）での寄せ比率。`feats = npy * index_rate + (1 - index_rate) * feats` | `0.66` | `0.0`〜`1.0` |
| `filter_radius` (`--filter_radius`) | F0 のメディアンフィルタ半径。`signal.medfilt(f0, 3)` でノイズ除去 | `3` | 整数（奇数） |
| `resample_sr` (`--resample_sr`) | 出力のリサンプリング先サンプリングレート。`0` ならモデル本来の `tgt_sr` のまま | `0` | 整数（0 でバイパス） |
| `rms_mix_rate` (`--rms_mix_rate`) | 入力 RMS と出力 RMS のブレンド比率（音量整形） | `1` | `0.0`〜`1.0` |
| `protect` (`--protect`) | **子音保護**の閾値。`protect < 0.5` のときだけ有効化される | `0.33` | `0.0`〜`0.5` |
| `version` | モデルバージョン（`v1` / `v2`）。HuBERT 出力層を切替（`output_layer = 9 if version == "v1" else 12`） | モデルから判定 | `v1` / `v2` |

これらは **モデル本体（チェックポイント）ではなく推論側で指定するパラメータ**で、`weights/{exp_name}.pth` 自体には焼き付けられていない。

### 4.2 F0 抽出方式の整理

公式の **メインパイプライン（pipeline.py）が直接 if 分岐で受ける** F0 抽出方式は次の 4 つ:

| F0 抽出 | 由来 | 特徴（公式 README / FAQ で言及されている範囲） |
| --- | --- | --- |
| `pm` | **parselmouth**（Praat バインディング） | 軽量。CLI のもう一つの選択肢として FAQ Q7 で言及 |
| `harvest` | **pyworld** の Harvest | CLI の既定。FAQ Q7 で言及。学習時の F0 抽出にも使われる |
| `crepe` | **torchcrepe**（CREPE 系ニューラルモデル） | pipeline.py に if 分岐あり |
| `rmvpe` | **RMVPE**（InterSpeech 2023, `rmvpe.pt` / `rmvpe.onnx`） | 公式 README が「best results, faster and lower resource than crepe_full」と推している（§2.4 引用） |

w-okada UI が露出している `dio`・`crepe full`・`crepe tiny` との対応関係:

- **`dio`** — pyworld 内蔵の DIO アルゴリズム。training_tips では「parselmouth や pyworld に内蔵されている手法」と一般化されて言及されているが、**公式 main の pipeline.py の if 分岐には現時点で `dio` 単独の選択肢は見つからない**（**未確認**。w-okada 側で別ルートで実装している、もしくはフォーク／古いバージョンの分岐が残っている可能性）。
- **`crepe full` / `crepe tiny`** — torchcrepe の `model=` 引数の選択肢（`full` / `tiny` のモデルサイズ違い）。pipeline.py は `crepe` の一括分岐内で `torchcrepe.predict(...)` を呼ぶため、**「crepe」一括選択肢を UI 側でサイズ違いとして展開している**と読むのが自然（**未確認**: w-okada 側の実装ファイルでの裏取りが必要）。

### 4.3 w-okada/voice-changer UI 露出との対応表

[w-okada-voice-changer §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) と [§4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) に出てくる UI 名称を、上の RVC 内部パラメータに対応付ける。

| w-okada UI 名称 | RVC 内部パラメータ | 担当レイヤ | 出典 |
| --- | --- | --- | --- |
| **F0 Det (F0 Extractor)** | `f0_method` | RVC モデル / 推論パイプライン | [w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) ↔ [pipeline.py](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/infer/modules/vc/pipeline.py) |
| **INDEX** | `index_rate` | RVC モデル / 推論パイプライン | [w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) ↔ [FAQ Q11](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md) |
| **TUNE** | `f0_up_key` | RVC モデル / 推論パイプライン | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) ↔ pipeline.py |
| **GAIN (in / out)** | （該当なし） | **w-okada ホスト側** | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。RVC の `rms_mix_rate` とは別物で、ホスト側の単純な音量調整 |
| **CHUNK (Input Chunk Num)** | （該当なし） | **w-okada ホスト側**（バッファ管理） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。配信用ホスト側がチャンク単位で推論を回すための長さ。RVC 本家パイプラインはオフラインを想定したフルファイル変換なので存在しない |
| **EXTRA (Extra Data Length)** | （該当なし） | **w-okada ホスト側**（先行コンテキスト） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。チャンク前に追加する過去音声長 |
| **S. Thresh (Noise Gate)** | （該当なし） | w-okada ホスト側 | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |
| **Echo / Sup1 / Sup2** | （該当なし） | w-okada ホスト側（Client device mode のみ、Chrome 機能経由） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |

**w-okada UI 上では露出が確認できなかった RVC 内部パラメータ**（=ホスト側でハードコード or 既定値運用、もしくは隠れパラメータ）:

- `filter_radius`（F0 メディアンフィルタ半径）
- `resample_sr`（出力リサンプリング）
- `rms_mix_rate`（RMS ブレンド）
- `protect`（子音保護閾値）

これらは [w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) で言及されている UI 露出パラメータには含まれていない。**w-okada 側で UI に出していないだけで内部的に既定値で動いている可能性が高い**が、本 Phase の公式ドキュメント確認範囲では確証なし（**未確認**。実機での UI 確認 or w-okada コード読解で裏取りが必要）。

### 4.4 推論時パラメータの調整ガイド（FAQ ベース）

公式 FAQ で具体的に「いつどう調整するか」が書かれている数少ない部分:

- **`index_rate`（INDEX）の使い分け**（[FAQ Q11](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md)）:
  - `1` に近いほど **学習データ側の音色に強く寄せる**（音色漏れ＝入力話者の音色が残るのを防ぐ）。理論上「1 にすれば推論ソースの音色漏れがゼロになる」とまで書かれている。
  - ただし「学習データの音質が推論ソースより低い場合、`index_rate` を上げると音質が下がる」ので、必ずしも 1 が最適ではない。
  - **学習データが高品質かつ長尺であれば `index_rate` の重要性は下がり、`.index` の作成・配布を省いてもよい**（同 FAQ）。
- **GPU メモリ不足時の推論パラメータ**（[FAQ Q8](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/en/faq_en.md)）: `config.py` の `x_pad / x_query / x_center / x_max` を下げる。これらは **推論時のコンテキスト長制御**（fp16 既定 = 3/10/60/65、fp32 既定 = 1/6/38/41、4GB 以下 GPU = 1/5/30/32）に対応する内部パラメータで、UI には出ない。
- **`f0_up_key`（TUNE）**: FAQ では具体的な調整ガイドはなく、CLI の引数として存在することが言及されているのみ。コード上は `f0 *= pow(2, f0_up_key / 12)` の単純な半音シフトなので、男声→女声で +12、女声→男声で -12 を基準にユーザが手動で詰める形になる（**コミュニティで一般に言われている** 範囲。公式ガイドではない）。

## 5. 配布形態とライセンス

### 5.1 リポジトリ本体のライセンス

- 公式リポジトリ [`RVC-Project/Retrieval-based-Voice-Conversion-WebUI`](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI) の `LICENSE` は **MIT License**。
- 著作権表記（[LICENSE](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/LICENSE) より、本 Phase で確認した範囲）:
  - liujing04 (2023)
  - 源文雨 (2023)
  - Ftps (2023)
- 標準的な MIT 条文（無保証・著作権表記の保持）以外の追加条件はない。
- → **コード本体に関しては配信用途での利用・改変・再配布に法的な制約は実質ない**が、後述する事前学習モデル・コミュニティ配布チェックポイントは別ライセンスで扱う必要がある。

### 5.2 事前学習モデルの配布

- 公式配布元: Hugging Face リポジトリ [`lj1995/VoiceConversionWebUI`](https://huggingface.co/lj1995/VoiceConversionWebUI/tree/main)。
- 確認できたディレクトリ構成:
  - `pretrained/` — v1 用の事前学習モデル（`.pth`、サンプリングレート別: `32k` / `40k` / `48k` がファイル名に含まれる）
  - `pretrained_v2/` — v2 用の事前学習モデル
  - `pretrained_v0/` — レガシー（v0）用。本ラボでは触れない想定
  - `hubert_base.pt` — コンテンツ表現抽出用 HuBERT 重み（約 190 MB）
  - `rmvpe.pt` / `rmvpe.onnx` — RMVPE による F0 抽出モデル
  - `uvr5_weights/` — Ultimate Vocal Remover（UVR5）の重み（学習素材作成用、ボーカルと伴奏の分離）
  - `infer_pack/` / `uvr5_pack/` — Python ソース／パッケージ群（ホスト側の配布バイナリ用）
  - `RVC20240604Nvidia.7z` 等の `.7z` アーカイブ — Windows 向けの一括配布バイナリ
- 公式 README の指示:
  > 「Download all needed models from https://huggingface.co/lj1995/VoiceConversionWebUI/tree/main/」
  > 「`python tools/download_models.py`」（一括ダウンロードスクリプトが同梱）
- **これらは「特定話者に変換するためのモデル」ではなく、ユーザーが自身のチェックポイントを学習する際の base となる重み**。話者特化のチェックポイントを使うには、§5.3 のコミュニティ配布物を別途用意するか、自分で学習する。

### 5.3 事前学習モデルの学習素材（ベースモデルが何で学習されたか）

- 公式 README より:
  > 「The base model is trained using nearly 50 hours of high-quality open-source VCTK training set」
  > （中国語原文: 「使用接近50小时的开源高质量VCTK训练集训练」）
- **VCTK**（Voice Cloning Toolkit corpus）は学術用の英語多話者コーパスで、研究・派生利用に比較的寛容なライセンスで配布されているコーパス。
- 公式の主張: 「so there are no copyright concerns」（base model の素材レベルでは著作権上の懸念がないという立場）。
- ただしこれは **公式が配布している base model 自体について**の話で、ユーザーが追加学習に使うデータ（自分の声・第三者の声）はユーザー側のライセンス／許諾が別途必要、という点は変わらない（[CLAUDE.md](../../CLAUDE.md) 方針）。

### 5.4 コミュニティ配布チェックポイントの扱い

- 配信界隈で「RVC モデル」「○○の RVC モデル」と呼ばれているものの大半は、**コミュニティ（個人・サークル）が学習させて配布しているチェックポイント**（`.pth` + 場合により `.index`）。
- これらは公式リポジトリのライセンス（MIT）とは **完全に独立** で、配布者が個別に設定した利用条件で判断する。
- 本ラボでの扱い:
  - **第三者の声（実在人物・配信者・声優・キャラクター）を許諾なく再現するような用途には誘導しない**（[CLAUDE.md](../../CLAUDE.md) 方針）。
  - 特定のチェックポイント取得方法・配布元 URL・モデル名を本ドキュメントには記載しない。
  - 「コミュニティでチェックポイントが流通している事実」は記述するが、「どこから取れるか」は書かない。
- 取得を伴うタスクは、配布元の利用規約（再配布可否・商用配信可否・クレジット要否）の確認をユーザーに必ず促す（CLAUDE.md「やらないこと」と整合）。

### 5.5 同梱されるサードパーティ要素の整理

公式 README の Credits に挙がっているもの:

- **VITS** — 基盤アーキテクチャ（[Jaehyeon Kim et al.](https://github.com/jaywalnut310/vits)）
- **HiFiGAN** — Vocoder 系統
- **ContentVec** — コンテンツ特徴量抽出の派生系統（HuBERT 派生の一種）。RVC が必須としているのは `hubert_base.pt` で、ContentVec は系統名としての言及
- **HuBERT** — 同上のコンテンツ表現
- **RMVPE** — F0 抽出（InterSpeech 2023 論文ベース）
- **faiss** — Retrieval（top1 近似最近傍検索）
- **Gradio** — WebUI フレームワーク（学習側 UI）
- **FFmpeg** — 音声前処理
- **Ultimate Vocal Remover (UVR5)** — 学習素材作成時のボーカル分離
- **audio-slicer** — 無音検出によるクリップ分割

これらは公式リポジトリ内で **依存ライブラリ／呼び出し対象**として組み込まれており、各々のライセンスは独立。配布バイナリ（Hugging Face 上の `.7z`）を再配布する際には、これらのライセンス継承条件の確認が必要だが、本ラボはバイナリ再配布を行わない想定なので運用上の影響は当面なし。

### 5.6 まとめ — ライセンス判断軸

本ラボで RVC を扱う際に「ライセンス OK?」を判断する軸を、レイヤ別に整理:

| レイヤ | 何のライセンス | 本ラボでの扱い |
| --- | --- | --- |
| RVC コード本体 | MIT（[LICENSE](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/LICENSE)） | 配信・改変・再配布いずれも法的な実質的制約なし |
| 事前学習 base model | Hugging Face 配布物（公式の主張: VCTK 由来で著作権懸念なし） | 自前学習の起点として利用可。再配布時は HF リポジトリ規約と VCTK 由来部分を確認 |
| HuBERT / RMVPE / UVR5 / VITS / HiFi-GAN 等の依存物 | 各々独立のライセンス | コードを呼び出す範囲なら問題になりにくいが、バイナリ再配布時は各ライセンス継承の確認が必要（バイナリ再配布は本ラボのスコープ外） |
| コミュニティ配布チェックポイント | 配布者ごとに別ライセンス／規約 | **常に個別確認**。本ラボでは具体的なチェックポイントの取得導線を書かない |
| 第三者声を学習させた派生チェックポイント | 配布者規約 + **元音声の権利者の許諾**の二重チェック | **許諾未確認のものは扱わない**（CLAUDE.md「やらないこと」） |

## 6. w-okada/voice-changer 経由で触る場合の責任分界

[w-okada-voice-changer §3.2](./w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理) / [§4](./w-okada-voice-changer.md#4-前処理後処理として提供されているもの) / [§5](./w-okada-voice-changer.md#5-io-構成) で「ホスト側で吸収される / モデル別で違う」と整理した範囲を、本ドキュメント §3〜§4 の RVC 側知見と突き合わせて、**責任分界を 1 枚にまとめる**。

### 6.1 責任分界マップ

| 層 | 担当 | 出どころ |
| --- | --- | --- |
| 入出力デバイス（input / output / monitor の選択、WASAPI / ASIO の選択、サンプリングレート整合） | **ホスト（w-okada）** | [w-okada §5.1 / §5.2 / §5.3](./w-okada-voice-changer.md#5-io-構成) |
| device mode（Client device mode / Server device mode） | **ホスト** | [w-okada §2.2 / §5.1](./w-okada-voice-changer.md#5-io-構成) |
| ノイズ抑制 / エコーキャンセル（Echo / Sup1 / Sup2） | **ホスト**（Client device mode 限定、Chrome 機能経由） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |
| ノイズゲート（S. Thresh） | **ホスト** | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |
| 入出力 GAIN（in / out） | **ホスト** | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。RVC の `rms_mix_rate` とは独立 |
| チャンク長（CHUNK）／先行コンテキスト（EXTRA） | **ホスト**（リアルタイム化のためのバッファ管理） | [w-okada §4.1](./w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記)。RVC 本家のオフライン推論パイプラインには存在しない概念 |
| モデルスロット管理（複数モデル切替、アップロード / ダウンロード） | **ホスト** | [w-okada §3.2](./w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理) |
| バッファ可視化・ショートカット | **ホスト** | [w-okada §4.3](./w-okada-voice-changer.md#43-ui-全体モニタリング系) |
| 話者音色（誰の声に変換するか） | **RVC モデル（チェックポイント）に固定** | [本書 §1.3 / §2.1](#13-配布チェックポイントとしての-rvc) |
| モデルのサンプリングレート（32k / 40k / 48k） | **RVC モデルに固定**（v1: 3 通り / v2: 32k/48k） | [本書 §3.4](#34-事前学習モデルの命名規約とサンプリングレート対応) |
| v1 / v2（HuBERT 9 層 / 12 層、特徴量 256 / 768 次元） | **RVC モデルに固定** | [本書 §2.3 / §3.3](#23-v1--v2-の差分公式-readme-で確認できる範囲) |
| F0 抽出方式（F0 Det） | **RVC 推論パイプライン**（ホストが UI を提供、選択肢は RVC 側） | [本書 §4.2](#42-f0-抽出方式の整理) ↔ [w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) |
| 学習データ側への寄せ比率（INDEX） | **RVC 推論パイプライン** | [本書 §4.3](#43-w-okadavoice-changer-ui-露出との対応表) ↔ [w-okada §4.2](./w-okada-voice-changer.md#42-モデル固有のパラメータ) |
| ピッチシフト（TUNE = `f0_up_key`） | **RVC 推論パイプライン** | 同上 |
| `filter_radius` / `resample_sr` / `rms_mix_rate` / `protect` | **RVC 推論パイプライン（既定値運用と推測）** | [本書 §4.3](#43-w-okadavoice-changer-ui-露出との対応表)。w-okada UI への露出は本 Phase で未確認 |
| 配布チェックポイント（`.pth` / `.index`）のライセンス | **RVC モデル配布元の規約**（ホストの MIT とは独立） | [本書 §5.4](#54-コミュニティ配布チェックポイントの扱い)、[w-okada §7.3](./w-okada-voice-changer.md#73-本ラボで扱う際の注意点実運用観点) |

### 6.2 「同じ UI 名でも担当が違う」紛らわしい点

特に混同しやすい 2 点を明示しておく。

- **GAIN ≠ `rms_mix_rate`**: w-okada UI の GAIN は **入出力経路の単純な音量調整（ホスト）** で、RVC の `rms_mix_rate`（入出力 RMS のブレンド比率、§4.1）とは別物。後者は w-okada UI には現状露出が確認できておらず、RVC 推論パイプラインの既定値で動いていると考えられる。
- **CHUNK / EXTRA は RVC のパラメータではない**: これらはリアルタイム化のためにホストが導入したバッファ管理パラメータで、`infer_cli.py` や `pipeline.py` には対応する概念がない。`x_pad / x_query / x_center / x_max`（§4.4）も RVC 側の内部パラメータだが、UI で触る CHUNK / EXTRA とはレイヤが違う。

### 6.3 本ラボでこの分界を意識する場面

- **遅延チューニング**: CHUNK / EXTRA / device mode / monitor 経路は **ホスト側で調整**、F0 抽出方式（`rmvpe` は公式が「crepe_full より高速」と主張、§2.4）は **RVC 側で選択**。遅延の試行錯誤を `experiments/` に記録する際は、両方の軸を分けてログを残す。
- **音色品質チューニング**: INDEX（`index_rate`）と F0 抽出方式は RVC 側の話。GAIN / Noise Gate を上げ下げしても変換アルゴリズム自体の音色は変わらない。
- **モデル差し替え時の挙動再現**: ホスト側設定（CHUNK / EXTRA / GAIN / device mode）は **モデルを差し替えても引き継がれる**が、TUNE / INDEX / F0 抽出方式は **モデル（≒声）と紐づけて記録しないと再現できない**。後続の `experiments/` テンプレで両者を分けて書ける構造にする。
- **ライセンス判断**: ホストは MIT、RVC コードも MIT。**実際の利用可否を決めるのは RVC チェックポイント側の配布規約**で、ここはホスト側からは判定できない（[本書 §5.4](#54-コミュニティ配布チェックポイントの扱い)）。

## 7. voice-changer-types §4 評価軸への暫定マッピング

[voice-changer-types §4](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) の評価軸に、**RVC（モデル/アルゴリズムとしての立場）** の暫定マッピングを置く。RVC は単体ではリアルタイム IO や仮想オーディオデバイス接続を持たず、本ラボでは [w-okada/voice-changer](./w-okada-voice-changer.md) 経由で扱う前提なので、IO 構成・エコシステム面は w-okada 側との責任分界（§6）をそのまま反映する。実測値は本ドキュメントには書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。

| 評価軸 | RVC（モデル/アルゴリズム）としての暫定マッピング | 出どころ / 補足 |
| --- | --- | --- |
| レイテンシ | 公式 README が **エンドツーエンド 170 ms / ASIO 入出力で 90 ms** を明示している。**本ラボでは未計測**で、配信用途では実際の値はホスト側のチャンク化遅延（CHUNK / EXTRA）と合算される | §2.4。実値は `experiments/` 後続タスクで計測 |
| 音質 | モデル単体としての音質は **v1/v2 選択（HuBERT 9 層 256 次元 vs 12 層 768 次元 + 3 period discriminators）/ 出力サンプリングレート（v1: 32k / 40k / 48k、v2: 32k / 48k）/ 推論時の `f0_method` / `index_rate` / `protect` / 学習データ量（FAQ 推奨 10〜50 分）・エポック数** で決まる。これらはモデル/推論パラメータ側で固定/調整できる軸。**実測の自然さ・破綻のしにくさは本書では扱わない** | §2.3 / §3.1 / §3.4 / §4.1 / §4.4 |
| 必要 GPU 性能 | FAQ Q8 が **fp16 既定（`x_pad/x_query/x_center/x_max = 3/10/60/65`）/ fp32 既定（`1/6/38/41`）/ 4GB 以下 GPU（`1/5/30/32`）** の 3 プロファイルを明示しており、**4GB クラスでも公式に動作想定がある**。具体的 VRAM 値は **未計測**。base model（`hubert_base.pt` 約 190 MB）+ `rmvpe.pt` 等のロードが前提 | §4.4 / §5.2 |
| CPU 負荷 | 公式に明示的な記述はない。**F0 抽出方式によって負荷分担が変わる**（`pm` / `harvest` は CPU 寄り、`crepe` / `rmvpe` は GPU 寄り）と推測されるが、**本書では未計測** | §4.2 |
| 入出力構成 | **モデル単体は IO 構成を持たない**。公式リポジトリ同梱の `realtime-gui` は存在するが、本ラボの想定上は **w-okada/voice-changer 経由**で扱う（IO 構成・device mode はホスト側の責任、§6） | §1.2 / §6.1 |
| モデル形態 | voice-changer-types **§3.1 話者依存型**。1 ターゲット話者につき 1 チェックポイント（`weights/{exp}.pth` + 任意で `.index`）を学習する形式。新しい声を増やすたびに学習データ（FAQ 推奨 10〜50 分）と学習が必要 | §1.3 / §3.1 / §3.6 |
| カスタマイズ性 | **学習側**: v1/v2 と出力サンプリングレート（32k / 40k / 48k、v2 は 40k 非対応）を選択可。FAQ Q15 でデータ追加学習、Q13 で ckpt 抽出、Q18 でサンプリングレート不一致対処が言及されており、運用パターンが公式ガイドで揃っている。**推論側**: `f0_method` / `index_rate` / `f0_up_key` / `filter_radius` / `resample_sr` / `rms_mix_rate` / `protect` の 7 個（§4.1）。ホスト経由で UI 露出されるのはこのうち 3 個（F0 Det / INDEX / TUNE）まで | §3.4 / §3.5 / §4.1 / §4.3 |
| 配信での利用可否 | **コード本体は MIT**。公式配布の **base model は VCTK 由来で公式が「著作権懸念なし」と主張**。実運用上の判断は **コミュニティ配布チェックポイント側の規約 + 元音声の権利者許諾** の二段階で決まる。本ラボでは [CLAUDE.md](../../CLAUDE.md) 方針により**第三者の声を許諾なく再現する用途には誘導しない**、特定チェックポイントの取得導線は記載しない | §5.1 / §5.3 / §5.4 / §5.6 |
| エコシステム | 公式リポジトリ（`RVC-Project/Retrieval-based-Voice-Conversion-WebUI`）は活発、**コミュニティ配布チェックポイントが多数流通**。配信向けには w-okada/voice-changer をはじめ複数のホスト実装でサポートされており、本書 §4.3 のとおり主要パラメータが UI 露出されている。**RMVPE が公式推奨の F0 抽出方式**で配信寄りの軽量化も進んでいる | §1.3 / §2.4 / §4.2 / §4.3 |
| コスト | コード本体（MIT）・base model（HF 配布）はいずれも無償。**実質コストは GPU マシンの用意と、自前学習用の音声データ収集（または配布元規約に従ったチェックポイント取得）に集約**。クラウド利用料は不要 | §5.1 / §5.2 / §5.4 |

モデル/アルゴリズム単体で値が出せる評価軸は **モデル形態（§3.1 話者依存）/ カスタマイズ性（学習・推論パラメータの自由度）/ 配信での利用可否（コード MIT + チェックポイント別判断）/ コスト（OSS）** の 4 つで、**レイテンシ・音質・必要 GPU・CPU 負荷** はホスト・ロード環境・実機計測と組み合わせて初めて値が確定する、というのが本 Phase の結論。w-okada/voice-changer 側の評価軸マッピング（[w-okada §8](./w-okada-voice-changer.md#8-voice-changer-types-§4-評価軸への暫定マッピング)）と組み合わせて、**ホスト × モデル**の二段でようやく voice-changer-types §4 の表が埋まる。

## 8. 未確認事項 / 後続タスク

### 8.1 既存タスクで吸収する未確認事項

`TODO.md` に既にある後続タスクで自然に拾えるもの。本書では結論を出さずに引き継ぐ。

- **w-okada UI 上で RVC の非露出パラメータ（`filter_radius` / `resample_sr` / `rms_mix_rate` / `protect`）が既定値運用されているかの裏取り**（§4.3）→ `TODO.md` の **「w-okada/voice-changer の実測タスク用 `experiments/` テンプレート整備」** で実機 UI 確認と併せて拾う
- **w-okada UI に出る `dio` / `crepe full` / `crepe tiny` の実装ルート**（公式 `pipeline.py` には `dio` 単独分岐がなく `crepe` は 1 つの分岐で `torchcrepe.predict(model="full" or "tiny")` を切替）が w-okada 側でどう繋がっているか（§4.2）→ 同上
- **サンプリングレート違い（32k / 40k / 48k）が音質・遅延・GPU 負荷に与える実用的な影響**（§3.6）→ 同 `experiments/` テンプレート整備の延長で実測条件として扱う
- **コミュニティ配布チェックポイントのライセンス判断軸（§5.4 / §5.6）を実運用に落とす**（チェックポイント取得時の確認手順テンプレ化）→ `TODO.md` の **「w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認とキャラクター音声利用条件の整理」** とまとめて扱う（§5.4 のリンク先ガイドラインとして本書を参照する形）

### 8.2 本タスクの follow-up として新規起票するもの

本書範囲では結論が出ず、かつ既存タスクでは吸収しきれない独立タスクは **現時点では起票しない**。理由:

- 実機計測（RVC v1/v2 × サンプリングレート × F0 抽出方式 × INDEX / TUNE）の計測条件テンプレは **w-okada 実測テンプレ整備の上に重ねる**形が自然で、先に独立 TODO に立てると重複する
- v2 アーキ詳細・faiss 構築アルゴリズム等のコード読解レベルの裏取りは §8.3 のとおり当面深追いしない

→ **新規 TODO 起票は 0 件**。実機検証段階で必要になった時点で改めて TODO 化する。

### 8.3 当面は深追いしない領域

本ラボのスコープでは現時点で踏み込む必要がなく、必要になった時点で再開するもの（いずれも公式 README / FAQ / training_tips の範囲を越えてコード読解が要る項目）。

- **v2 で追加された "3 period discriminators" のアーキ詳細**（§2.3）— HiFi-GAN 系の multi-period discriminator を 3 段増やしたという理解で本書は止める
- **faiss index の具体的構築アルゴリズム（IVF / PQ 等の構造）**（§3.2）— `.index` の配布有無の判断には影響しないため当面不要
- **v2 における HuBERT 特徴量保存ディレクトリの正確な命名規約**（`3_feature768` か別名か）（§3.3）— 学習を自前で回す段になれば自然に確認できる
- **もう一つの公式系リポジトリ `RVC-Project/Retrieval-based-Voice-Conversion`（"in preparation..." 状態）の位置付け**（§1.2）— 当該リポジトリが整備された時点で再確認
- **学習スクリプト（`infer/`・`tools/` 以外の学習ループ）のコード詳細**（plans/rvc.md スコープ外）— 自前学習を本格的に検証する段で着手
