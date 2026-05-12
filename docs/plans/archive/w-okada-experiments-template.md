# 整備プラン: w-okada/voice-changer 実測タスク用 `experiments/` テンプレート

## 目的・背景

[w-okada-voice-changer.md §9.2](../specs/w-okada-voice-changer.md#92-本タスクの-follow-up-として新規起票するもの) で follow-up として切り出した独立タスク。

w-okada/voice-changer (VCClient) は [voice-changer-types §1.4](../specs/voice-changer-types.md#14-ハイブリッド) のハイブリッドかつ「複数モデルを切り替えて動かす実行ホスト」なので、レイテンシ / GPU 使用量 / 音質といった評価軸はロードする個別モデル（RVC / Beatrice v2 / so-vits-svc 等）と組み合わせて初めて値が出る。

実測の各セッションで以下が漏れると、後で他環境・他モデルの結果と並べられない:

- **device mode**（Client / Server）と Server device mode 時の **input / output / monitor 3 デバイス分離**（[spec §5.1〜5.2](../specs/w-okada-voice-changer.md#5-io-構成)）
- **サンプリングレート**（3 デバイス間で一致が必要、§5.2 制約）
- **CHUNK (Input Chunk Num) / EXTRA (Extra Data Length)**（§4.1）
- **GAIN (in/out) / TUNE / Noise Gate (S.Thresh)**（§4.1）
- **F0 抽出方式**（RVC は dio / harvest / crepe / crepe full / crepe tiny / rmvpe、§4.2）
- **INDEX 比率（RVC のみ）/ モデル固有パラメータ**（Beatrice v2 のオートピッチシフト 等、§4.2）
- **モデル**（種類 / バージョン / ファイル名 / 配布元）
- **VCClient のバージョン / エディション**（`vcclient_win_std_xxx` / `_win_cuda_xxx` / `_mac_xxx` / `onnx`、§2.4）
- **ハードウェア**（GPU / VRAM / CPU / メモリ / OS）と **仮想オーディオデバイス**（VB-CABLE / VoiceMeeter / BlackHole）の構成

実測値を一切記入しない**骨格テンプレ**を先に用意することで、後続の RVC / Beatrice v2 等の実測タスクが「テンプレに沿って計測ログを残す」だけで揃った形のデータが集まる足場を作る。

このドキュメントが揃うと、

- 後続のモデル個別実測タスクで「何を記録すべきか」を再設計せずに済む
- 異なる環境・モデル・パラメータの実測ログを横並びで比較できる
- 公式ドキュメントとのズレ / 既知の問題が積み上がる形でログ化される

## スコープ

含める:

- `experiments/` ディレクトリの初期化と運用ルール
- VCClient 実測ログ用テンプレファイル本体（記入欄のみ。値は書かない）
- ファイル命名規約・記入運用ルール
- spec ([w-okada-voice-changer.md §9.2](../specs/w-okada-voice-changer.md#92-本タスクの-follow-up-として新規起票するもの)) からテンプレへの相互リンク

含めない:

- 実機計測（本タスクではテンプレに値を一切記入しない。[CLAUDE.md](../../CLAUDE.md)「実測値はユーザーが計測したもの以外を書かない」方針）
- VCClient 以外のツール（RVC 単体 CLI / Beatrice 単体等）の実測テンプレ — 必要になった時点で本テンプレを参考に派生させる
- モデル個別パラメータ（Beatrice 固有のオートピッチシフト等）の詳細仕様 — テンプレ側では自由記入欄として置き、各モデルの spec を参照する形にする
- インストール手順そのものの完全な再掲 — 各実測ログの「環境」セクションで必要に応じて記録するが、テンプレ整備時には扱わない

## 対応方針

### 成果物

- `experiments/README.md` — `experiments/` ディレクトリ全体の運用ルール
- `experiments/w-okada-voice-changer/README.md` — VCClient 実測の運用ルール（ファイル命名規約・記入ルール）
- `experiments/w-okada-voice-changer/_template.md` — 実測ログのテンプレ本体

### テンプレ本体の構成（`_template.md`）

Phase 1 で [spec §4.1 / §4.2 / §5 / §8 評価軸表](../specs/w-okada-voice-changer.md#4-前処理後処理として提供されているもの) と突き合わせて確定した記録項目。各セクションの最後には「その他自由記入」欄を 1 行ずつ置き、テンプレが拾い切れない観察事項を逃さない受け皿にする。

1. **計測概要**
   - 計測日 / 計測者 / 計測の目的（モデル比較 / パラメータ調整 / 他環境再現 等）
   - 主要な計測条件サマリ（device mode・主モデル・サンプリングレートを 1 行で）— 横並び比較・後から検索する時の見出し代わり

2. **環境**
   - ハードウェア: GPU (型番 / VRAM) / CPU / メモリ / OS（ビルド番号まで）
   - 音声機器: マイク / ヘッドホン / オーディオインターフェース / 仮想オーディオデバイス（種別・バージョン。VB-CABLE / VoiceMeeter Banana・Potato / BlackHole 等）
   - VCClient: エディション（`vcclient_win_std_xxx` / `_win_cuda_xxx` / `_mac_xxx` / `onnx`、[spec §2.4](../specs/w-okada-voice-changer.md#24-配布形態とエディション)）/ バージョン
   - 補助情報: ブラウザ（Chrome バージョン。Client device mode 計測時のみ。[spec §5.1](../specs/w-okada-voice-changer.md#51-2-系統の-device-mode)）/ NVIDIA ドライバ・CUDA Toolkit バージョン（CUDA エディション利用時のみ）

3. **VCClient 設定（共通 UI）** — [spec §4.1](../specs/w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) / [§5](../specs/w-okada-voice-changer.md#5-io-構成) と 1:1 対応
   - device mode（Client / Server）と**選択理由**
   - input / output / monitor デバイス（monitor は WASAPI / ASIO の別を併記。[spec §5.2](../specs/w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537)）
   - サンプリングレート（3 デバイス間で一致が必要、[spec §5.2](../specs/w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537) 制約）
   - CHUNK (Input Chunk Num) / EXTRA (Extra Data Length)
   - GAIN (in / out) / TUNE / Noise Gate (S.Thresh)
   - Echo / Sup1 / Sup2（Client device mode 時のみ。Server device mode では `n/a` と明示）

4. **モデル** — [spec §3](../specs/w-okada-voice-changer.md#3-対応モデル一覧と切替の仕組み) / [§4.2](../specs/w-okada-voice-changer.md#42-モデル固有のパラメータ) / [§7](../specs/w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点) を反映
   - モデル種類（RVC v.1 / RVC v.2 / Beatrice v1 / Beatrice v2 / MMVC / so-vits-svc / DDSP-SVC 等）
   - モデルファイル名 / バージョン / 配布元（URL）
   - モデルスロット番号（[spec §3.2](../specs/w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理) のモデルスロット UI 上の番号。同一計測内で複数スロットを比較する場合に必須）
   - **ライセンス / 利用条件確認状況**（確認日 / 確認したドキュメント名 / 営利利用可否 / 配信利用可否。未確認のモデルでは計測そのものを実施しない、[CLAUDE.md](../../CLAUDE.md) 方針）
   - INDEX 比率（RVC のみ）
   - F0 抽出方式（RVC: `dio` / `harvest` / `crepe` / `crepe full` / `crepe tiny` / `rmvpe`、[spec §4.2](../specs/w-okada-voice-changer.md#42-モデル固有のパラメータ)）
   - モデル固有パラメータ自由記入欄（Beatrice v2 のオートピッチシフト / 話者マージ / pitch / formant 等はここに集約。各モデルの spec を併記して書く）

5. **計測結果** — 各項目に**「値 / 計測方法 / 計測時の負荷状況」をセットで併記**する。値だけの記入はしない（[CLAUDE.md](../../CLAUDE.md) 方針 = 実測値はユーザーが計測したもの以外を書かない / 計測条件込みで残す）
   - レイテンシ（計測方法例: ループバック計測 / OBS タイムスタンプ比較 / VCClient のバッファ可視化 — [spec §4.3](../specs/w-okada-voice-changer.md#43-ui-全体モニタリング系) v.2.1.3-alpha 機能。バッファ可視化スクショの保管パスを併記可）
   - GPU 使用率（計測方法: nvidia-smi / タスクマネージャ / Activity Monitor 等を明示）
   - VRAM 使用量（同上）
   - CPU 負荷（同上）
   - 音質メモ（主観評価 / サンプル WAV 保管パス）

6. **配信ソフト連携（任意）** — [spec §6](../specs/w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) を反映
   - VCClient の output → 仮想オーディオデバイス → OBS / 通話アプリへの入力経路
   - 配信ソフト側の音声入力キャプチャ設定（サンプリングレート / モノラル・ステレオ）
   - monitor デバイスの繋ぎ先（自分用モニタリング用ヘッドホンなど）

7. **所見 / 既知の問題**
   - 公式ドキュメントとのズレ（記述と実機挙動の差）
   - 再現条件（再現したいときに必要な手順 / 設定）
   - 遭遇したトラブルと回避策

### 記述ルール

- 記入していない欄は空欄で曖昧にせず **`未計測`** または **`n/a`**（その条件では存在しない項目、例: Server device mode 時の Echo / Sup1 / Sup2）と明示する（[CLAUDE.md](../../CLAUDE.md) 方針）
- **計測方法を併記しない計測値は書かない**。レイテンシだけでなく GPU 使用率 / VRAM / CPU 負荷 / 音質メモすべてに「何のツールでどう測ったか・計測時の負荷状況」を併記する
- **モデルのライセンス / 利用条件は計測前に必ず確認**する（[CLAUDE.md](../../CLAUDE.md) 方針）。確認していないモデルでの計測ログは残さない
- 自由記入欄（モデル固有パラメータ / 所見）は **観察事実と推論を分けて書く**。推論には「推測」「未確認」を明示
- 実測ログのファイル名は `experiments/w-okada-voice-changer/YYYY-MM-DD_<model>_<env>.md` 形式
- テンプレに対する変更（項目の追加・廃止）は **spec 側の更新とセットで行う**。テンプレだけ先行して項目を増やさない

## 影響範囲

- 新規追加:
  - `docs/plans/w-okada-experiments-template.md`（本ファイル）
  - `experiments/README.md`
  - `experiments/w-okada-voice-changer/README.md`
  - `experiments/w-okada-voice-changer/_template.md`
- 既存ファイル変更:
  - `TODO.md` の該当項目に本プランへのリンク追記、Phase の子タスク化
  - `docs/specs/w-okada-voice-changer.md` §9.2 にテンプレへの相互リンク追加
- コードへの影響なし

## 進め方 (Phase)

- [x] Phase 1: テンプレ項目の最終確定 — [spec §4.1 / §4.2 / §5 / §8 評価軸表](../specs/w-okada-voice-changer.md#4-前処理後処理として提供されているもの) を見直して、漏れ・重複を解消した記録項目リストを本プラン内（上の「テンプレ本体の構成」）で確定し、自由記入欄の粒度（モデル固有パラメータ / 計測方法欄など）を決める
- [x] Phase 2: テンプレ・運用ルールの作成 — `experiments/` ディレクトリを作成し、`experiments/README.md` / `experiments/w-okada-voice-changer/README.md` / `experiments/w-okada-voice-changer/_template.md` を Phase 1 の項目リストに沿って書き起こす
- [x] Phase 3: 既存ドキュメントへの相互リンクと構造検証 — `docs/specs/w-okada-voice-changer.md` §9.2 からテンプレへのリンクを追加し、テンプレを **値を埋めずに** 1 度コピーして全項目が記入できる構造になっているかを確認（実測はしない / 構造の検証のみ）

## 完了条件

- `experiments/w-okada-voice-changer/_template.md` が「テンプレ本体の構成」の全 7 セクションを含む形で存在する
- `experiments/README.md` と `experiments/w-okada-voice-changer/README.md` がファイル命名規約・記入ルールを記載している
- spec 側 [§9.2](../specs/w-okada-voice-changer.md#92-本タスクの-follow-up-として新規起票するもの) から本テンプレへのリンクが追加されている
- 後続のモデル実測タスク（RVC / Beatrice v2 等）が「このテンプレに沿って書けば良い」状態になっている
- 実測値が一切含まれていない（[CLAUDE.md](../../CLAUDE.md) 方針）

## 想定リスク / 留意点

- テンプレが過剰に細かすぎると埋まらず形骸化する。Phase 2 完了時に項目数を見直す機会を 1 度設ける
- VCClient のバージョンアップで UI 露出パラメータが変わる可能性がある。Phase 2 完了時点の VCClient バージョンを `experiments/w-okada-voice-changer/README.md` に明記する
- モデル毎の追加項目（Beatrice v2 のオートピッチシフト等）はモデル固有パラメータの自由記入欄で吸収し、テンプレ側で全モデルを網羅しようとしない
- 本テンプレは VCClient 経由でモデルを動かす前提。VCClient を介さず RVC / Beatrice 単体の CLI / SDK で動かす計測が必要になった時点で派生テンプレを切る
