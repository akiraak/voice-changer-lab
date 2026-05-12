# 調査プラン: OBS Studio との接続パターンまとめ

## 目的・背景

配信周辺ツール調査シリーズの第 2 弾。前段の [virtual-audio-devices.md](../specs/virtual-audio-devices.md)（最終確認日 2026-05-12）で「マイク → 声変換ホスト → 仮想オーディオデバイス → 配信ソフト」の **仮想オーディオデバイス側**を `VB-CABLE / VoiceMeeter Banana・Potato / BlackHole` のコア集合で棚卸しし、配信用途の典型構成を [§4 横断棚卸し表](../specs/virtual-audio-devices.md#4-横断棚卸し表) / [§5 P1〜P4](../specs/virtual-audio-devices.md#5-配信用途での典型構成) として経路図化済み。ただし [virtual-audio-devices.md §6.5](../specs/virtual-audio-devices.md#65-反映の境界本書で扱わない上流) で明示している通り、**OBS Studio の音声入力キャプチャ設定値・モニタリング設計・配信出力のサンプリングレート整合・遅延ハンドリング**は本書のスコープ外として残しており、本タスクで埋める。

このタスクが空白のままだと、

- [voice-changer-types §4 配信用途で見るべき主な評価軸](../specs/voice-changer-types.md#4-配信用途で見るべき主な評価軸) の「入出力構成」「エコシステム」軸が、**配信ソフト側に渡してからの設定**まで含めて評価できない（仮想ケーブル側だけ揃っても「OBS でモニターするとエコーする」「48 kHz / 44.1 kHz の不整合で音が乗らない」等の具体的なハマりどころが見えない）。
- [w-okada-voice-changer.md §6](../specs/w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) の「公式チュートリアルに OBS 名指しの記述は見つかっていない（未確認）」「§6.3 本ラボでの一般論整理は後続の OBS 接続調査タスクで上書き予定」という未確定状態が解消されない。同 [§9.1](../specs/w-okada-voice-changer.md#91-既存タスクに引き継ぐ未確認事項) の「OBS Studio との具体的な接続パターン」未確認項目も塞がらない。
- 後続の [experiments/w-okada-voice-changer/_template.md §6 配信ソフト連携](../../experiments/w-okada-voice-changer/_template.md) で「経路パターン: P1〜P4」までは選べるが、**OBS 側で何を設定したか**を記録する欄が抽象記入のままになり、計測条件が揃わない。
- [virtual-audio-devices.md §7.3 後続タスク](../specs/virtual-audio-devices.md#73-後続タスクtodomd-に上げるべき項目) の最優先項目（OBS Studio 接続パターン）として既に外向きに約束されている状態を、いつまでも放置することになる。

このタスクは、**仮想オーディオデバイス側（前段タスク）の成果物を入力**として、配信ソフト側（OBS Studio）で「音声入力キャプチャをどう繋ぐか / モニタリングをどう設計するか / サンプリングレート整合と遅延ハンドリングをどう取るか」を**公式情報源ベース**で棚卸しすることを目的とする。

このドキュメントが揃うと、

- [virtual-audio-devices.md §5 P1〜P4](../specs/virtual-audio-devices.md#5-配信用途での典型構成) で「仮想ケーブルがどこに刺さるか」までだった経路図に、**OBS 側の受け口（音声入力キャプチャ / アプリケーション音声キャプチャ / 音声モニタリング設定 / オーディオ同期オフセット / グローバル音声サンプルレート）**が紐づき、経路全体が読める状態になる。
- [w-okada-voice-changer.md §6](../specs/w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) で公式チュートリアルに無かった「OBS 連携」を、本ラボ側のドキュメントとして補完できる。
- experiments テンプレの §6 配信ソフト連携が、「OBS の音声入力キャプチャ設定」「モニタリングデバイス」「オーディオ同期オフセット」を**選択肢から指定する形**で揃う。
- 配信周辺ツール調査シリーズ第 3 弾候補（ノイズ抑制 / ゲート系の棚卸し、通話アプリ Discord/Zoom 取り回し）の前提が固まる。

## スコープ

含める:

- **対象 OBS バージョン**: OBS Studio（OBS Project 公式配布の本家）。代表的な系統別派生は本書では参考扱いとし、必要に応じて差異だけ §未確認事項に残す:
  - **Streamlabs Desktop**（旧 Streamlabs OBS、現 Streamlabs）— OBS ベースだが UI / 内部処理は別物
  - **OBS.Live** / **OBS Studio + StreamFX 等のプラグイン拡張** — 派生版ではなく公式 OBS + プラグイン構成
- **対象 OS**: Windows 10 / 11（x64・ARM64）、macOS（Intel / Apple Silicon）。Linux は参考扱い（[virtual-audio-devices.md §4.2](../specs/virtual-audio-devices.md#42-os--ツール早見表足切り判断) と同じ立て付け）。
- 各 OBS 機能について、**公式 Help / Knowledge Base / Wiki / Settings リファレンス**で確認できる範囲での
  - **音声入力キャプチャ（Audio Input Capture）** ソースの仕様（対応する OS のデバイス種別 / モノラル・ステレオ・マルチチャンネルの扱い / サンプリングレート整合 / レイテンシ要因）
  - **アプリケーション音声キャプチャ（Application Audio Output Capture）**（Windows 限定 / macOS の対応状況）と、仮想オーディオデバイス経由との使い分け
  - **音声モニタリング設定**（モニターオフ / モニターのみ（出力をミュート）/ モニターと出力）と「**モニタリングデバイス**」グローバル設定の選び方
  - **グローバル音声設定のサンプリングレート**（44.1 kHz / 48 kHz）と、OS / 仮想オーディオデバイス / 声変換ホスト側との整合（[virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成) の各経路パターンを基準に）
  - **オーディオ同期オフセット（Sync Offset）**による遅延補正の仕組み（公式ヘルプの説明範囲、適用される処理段）
  - **音声フィルタ**のうち遅延に直接効く項目（Compressor / Noise Gate / Noise Suppression（OBS 内蔵 NVIDIA Broadcast / RNNoise / Speex の選択）/ VST）。**ノイズ抑制プラグインの選定軸自体**は配信周辺ツール調査シリーズ第 3 弾のスコープなので、本書では「OBS 内蔵で何が選べるか」までの粒度に止める
  - 配信エンコーダー側のオーディオ出力設定（**Audio Bitrate / トラック数**）と本書の経路設計との関係
  - 既知の制約 / 公式 FAQ / Forum / GitHub Issues に書かれているハマりどころ（仮想オーディオデバイス連携時のサンプリングレート不一致、Apple Silicon での音声入力キャプチャの挙動、Windows のアプリケーション音声キャプチャの WGC 制約 等）
- **[virtual-audio-devices.md §5 P1〜P4](../specs/virtual-audio-devices.md#5-配信用途での典型構成) の各パターンに対する OBS 側のレシピ**:
  - P1（シングル仮想ケーブル経路）で OBS 側の音声入力キャプチャをどう設定するか
  - P2（VoiceMeeter ハブ経路）で B1 / B2 のどちらを拾うか・モニタリングデバイスをどこに置くか
  - P3（monitor 分離経路）で OBS 側のモニタリング設定を「モニターオフ」「モニターのみ」「モニターと出力」のどれにするのが整合するか
  - P4（macOS BlackHole + Multi-Output 経路）で OBS 側がどう見えるか・モニタリングデバイスの選び方
- **遅延ハンドリング**: オーディオ同期オフセットの適用ポリシー（プラスとマイナスの意味・実測の取り方）、ASIO / WASAPI / CoreAudio とのバッファ整合、OBS の音声バッファリング設定（公式記述がある場合のみ）。**ベンダー公称値 / 公式ドキュメント記載値**と本ラボの実測は明確に分ける。
- 配信プラットフォーム別の音声設定推奨値（YouTube Live / Twitch / niconico 等）について、**OBS 側 wiki / 公式ヘルプが推奨値を明示している場合のみ**棚卸す。プラットフォーム側ガイドラインの解釈には踏み込まない。
- [voice-changer-types §2 補助カテゴリ](../specs/voice-changer-types.md#補助カテゴリ-周辺ツール) /  [§4 評価軸（入出力構成・エコシステム）](../specs/voice-changer-types.md#4-配信用途で見るべき主な評価軸) / [w-okada-voice-changer.md §6](../specs/w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) /  [experiments/w-okada-voice-changer/_template.md §6](../../experiments/w-okada-voice-changer/_template.md) / [virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成) への反映方針
- 後続タスク起票（OBS プラグイン系の深掘り、ノイズ抑制 / ゲート系の棚卸し（シリーズ第 3 弾候補）、通話アプリ Discord / Zoom 取り回し、Streamlabs Desktop 等派生版の差分調査）

含めない:

- **OBS Studio の映像側機能**（映像キャプチャソース / シーン構成 / エンコーダー設定の映像部分 / 配信先プラットフォームの映像設定）— 本書のスコープ外。音声トラックの**配信エンコーダー側の音声ビットレート / トラック数**は経路設計との関係で触れるが、映像側のビットレート・解像度・キーフレーム間隔等には踏み込まない。
- **実測のレイテンシ / 音質 / CPU 負荷**（[CLAUDE.md](../../CLAUDE.md) 方針）。公称値・公式ヘルプ記載値の引用は出典付きで明示し、本ラボでの実測値とは混ぜない。実測は後続の experiments タスクで個別モデルと組み合わせて取る。
- **ノイズ抑制 / ゲート系プラグインの選定軸**（NVIDIA Broadcast / Krisp / RNNoise の比較）— 配信周辺ツール調査シリーズ**第 3 弾の独立タスク**として §後続タスク に残す。本書では「OBS 内蔵のノイズ抑制フィルタで何が選べるか」までの粒度で触れる。
- **通話アプリ（Discord / Zoom）固有の仮想デバイス取り回し**（[virtual-audio-devices.md §7.3 後続タスク](../specs/virtual-audio-devices.md#73-後続タスクtodomd-に上げるべき項目) と同じく独立タスク扱い）。本書では OBS Studio 単体への接続までを扱う。
- **Streamlabs Desktop / OBS.Live 等の派生版固有挙動の網羅**。本書は OBS Studio 本家を基準に書き、派生版で挙動が違うことが分かった点だけ §未確認事項に残す。
- **第三者の声を許諾なく再現するモデル**を前提とした配信フロー — [CLAUDE.md](../../CLAUDE.md) 方針。
- **配信プラットフォーム固有の規約解釈**（YouTube / Twitch / niconico の音声配信ルール、収益化規約等）— 本書では推奨値の公式記述があれば引用するに留め、規約解釈には踏み込まない。

## 対応方針

成果物は `docs/specs/obs-studio.md` の 1 ファイル。
冒頭で本書が [voice-changer-types §2 補助カテゴリ「周辺ツール」](../specs/voice-changer-types.md#補助カテゴリ-周辺ツール) の「配信ソフト・通話ソフト」レイヤーのうち **OBS Studio（本家）** を扱い、**仮想オーディオデバイス層（[virtual-audio-devices.md](../specs/virtual-audio-devices.md)）の P1〜P4 を前提に、OBS 側の音声入力キャプチャ・モニタリング・遅延ハンドリングを公式情報源ベースで横断棚卸しする**ものであることを 1 行で示す。立て付けは [virtual-audio-devices.md](../specs/virtual-audio-devices.md) と同じ「1 ツール深掘り + 横断的な経路レシピ」の混合型（1 製品なのでツール別エントリは OBS Studio に集中するが、§4 / §5 で P1〜P4 を横断するレシピ表を作る）。

構成案:

1. **概要**（本書の位置付け / 対象 OBS バージョンと OS / 「OBS Studio との接続パターン」と本書で呼ぶ範囲定義（音声側に絞り、映像側を含めないことを明示）/ 前段の [virtual-audio-devices.md](../specs/virtual-audio-devices.md) との関係）
2. **評価項目一覧**（§3 で個別機能を埋めるためのカラム定義。`公式情報源 / 機能の概要 / OS 別の対応状況 / 仮想オーディオデバイスとの噛み合い / 遅延要因 / 既知の制約` を縦軸の機能 × 横軸の項目で表す）
3. **OBS Studio の音声系機能エントリ**（音声入力キャプチャ / アプリケーション音声キャプチャ / 音声出力キャプチャ / 音声モニタリング設定 / グローバル音声サンプリングレート / オーディオ同期オフセット / 音声フィルタ（内蔵ノイズ抑制 / Noise Gate / Compressor / VST））。各エントリは
   - 公式情報源へのリンク（OBS Help / Knowledge Base / Wiki / Settings リファレンス）
   - 公式の説明範囲（OBS 公式が何と呼んでいるか・どの用途を公式に想定しているか）
   - OS 別の対応状況（Windows / macOS / Linux）と Apple Silicon / ARM Windows での挙動の公式記述
   - 仮想オーディオデバイス（[virtual-audio-devices.md §4.1](../specs/virtual-audio-devices.md#41-ツール--評価項目マトリクス) のコア集合）との噛み合い
   - 既知の制約 / 公式 FAQ / Forum / GitHub Issues に書かれているハマりどころ
   - 未確認事項（公式ドキュメントから読み取れなかった項目）
4. **横断棚卸し表**（§3 で定義した評価項目のマトリクス。配信用途で「音声入力キャプチャ vs アプリケーション音声キャプチャをどう使い分けるか」「モニタリング設定をどれにするか」の足切り判断が 1 表で出せる形）
5. **配信用途での典型構成（P1〜P4 × OBS レシピ）**: [virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成) の P1〜P4 を行に、OBS 側の `音声入力キャプチャの設定 / グローバル音声サンプリングレート / モニタリングデバイス / 各ソースのモニタリング設定 / オーディオ同期オフセットの取り方` を列にしたレシピ表 + 各パターンの経路図（OBS 側の音声 mixer ブロックまで描く）。本書の中核。
6. **遅延ハンドリング**: オーディオ同期オフセットの正負の意味・実測の取り方の公式記述・ASIO / WASAPI / CoreAudio とのバッファ整合・OBS の音声バッファリング設定（公式記述がある場合のみ）・**ベンダー公称値と実測の分離**ポリシー。
7. **上流ドキュメントへの反映方針**: [voice-changer-types §2 補助カテゴリ](../specs/voice-changer-types.md#補助カテゴリ-周辺ツール) /  [§4 評価軸（入出力構成・エコシステム）](../specs/voice-changer-types.md#4-配信用途で見るべき主な評価軸) / [w-okada-voice-changer.md §6（特に §6.3 を上書き）](../specs/w-okada-voice-changer.md#63-本ラボでの一般論整理公式言及ではない) / [experiments/w-okada-voice-changer/_template.md §6](../../experiments/w-okada-voice-changer/_template.md) / [virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成)（後者は §5 各パターンの「OBS 側で何を設定するかは [obs-studio.md §5](./obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) 参照」へのリンクを追記）への更新差分案。
8. **未確認事項 / 後続タスク**: 本書 §3 各エントリで残った未確認事項 / Streamlabs Desktop 等派生版の差分調査 / ノイズ抑制 / ゲート系の棚卸し（シリーズ第 3 弾候補） / 通話アプリ Discord / Zoom 取り回し / OBS プラグイン系の深掘り。

記述ルール（[cloud-saas-realtime.md](../specs/cloud-saas-realtime.md) / [virtual-audio-devices.md](../specs/virtual-audio-devices.md) / [rvc.md](../specs/rvc.md) / [so-vits-svc.md](../specs/so-vits-svc.md) / [beatrice.md](../specs/beatrice.md) / [w-okada-voice-changer.md](../specs/w-okada-voice-changer.md) と統一）:

- **公式 Help / Knowledge Base / Wiki / 公式 Forum / GitHub Issues** に書かれていることと、コミュニティで一般に言われていることを明確に分ける。出典を行ごとに明記する
- 実測値・断定的な性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**OBS 公式が公称している値（推奨サンプリングレート / 推奨ビットレート 等）は「公式記述」として明示**し、本ラボでの実測値とは混ぜない
- 機能名・設定名は **OBS Studio UI / 公式ドキュメントが使っている名称**をそのまま書く（UI 上の表記が和訳されているかどうかは公式記述がある場合のみ採用）
- ライセンス / 商用配信での利用可否（OBS Studio 本体の GPL-2.0）は**ベンダー公式の明示がある項目のみ書く**。明示がない場合は「公式記述なし」と明記し、勝手に判断しない
- 本ドキュメントの**最終確認日**を §1 に明記する（OBS のリリースは活発なため、機能名・UI 表記が変動しうる）。確認時に参照した OBS Studio のメジャー / マイナーバージョンも記録する
- 仮想オーディオデバイス側のラベル参照は [virtual-audio-devices.md §4.1](../specs/virtual-audio-devices.md#41-ツール--評価項目マトリクス) に揃え、本書内で名称を再定義しない（**横断棚卸し済みのラベルを使う**）

## 影響範囲

- 新規追加: `docs/plans/obs-studio-connection.md`（本ファイル）, `docs/specs/obs-studio.md`
- 既存ファイル変更:
  - `TODO.md` の該当項目（[配信周辺ツール調査セクション](../../TODO.md#配信周辺ツール調査) 「OBS Studio との接続パターンまとめ」）に本プランへのリンク追記、Phase の子タスク化
  - （必要に応じて）`docs/specs/voice-changer-types.md` §2 補助カテゴリ「周辺ツール」の「配信ソフト・通話ソフト」記述に本書へのリンクを追記
  - （必要に応じて）`docs/specs/voice-changer-types.md` §4 評価軸「入出力構成」「エコシステム」行に本書（[obs-studio.md §5](../specs/obs-studio.md)）への参照を追記
  - （必要に応じて）`docs/specs/w-okada-voice-changer.md` §6 を「OBS Studio との接続パターン」の本書側へリンクし、§6.3 の「本ラボでの一般論整理（後続で上書き予定）」段落を本書の §5 P1〜P4 レシピへ差し替え
  - （必要に応じて）`docs/specs/w-okada-voice-changer.md` §9.1「OBS Studio との具体的な接続パターン」未確認項目を本書で解消した旨に更新
  - （必要に応じて）`docs/specs/virtual-audio-devices.md` §5 P1〜P4 の各パターン末尾に「OBS 側の設定は [obs-studio.md §5](../specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) 参照」を追記
  - （必要に応じて）`experiments/w-okada-voice-changer/_template.md` §6 配信ソフト連携の「配信ソフト側の音声入力キャプチャ設定」「monitor デバイスの繋ぎ先」欄に、本書 §5 のラベル参照（P1〜P4 × OBS レシピ）を入れる
- コードへの影響なし

## 進め方 (Phase)

- [ ] **Phase 1**: 対象集合の確定 + 範囲定義の確定
  - 対象 OBS バージョン（OBS Studio 本家）と参考扱いの派生版（Streamlabs Desktop / OBS.Live）の線引きを本書 §1 で固定する
  - 「OBS Studio との接続パターン」と本書で呼ぶ範囲（音声側に絞り、映像側を含めない / OBS 内蔵フィルタは選択肢の列挙までで深掘りはシリーズ第 3 弾に分離）を本書 §1 で先に固定する
  - 公式情報源（OBS Help / Knowledge Base / Wiki / Settings リファレンス / GitHub Issues）の URL を本書 §3 のエントリ冒頭に並べる
  - 確認時の OBS Studio メジャー / マイナーバージョンを §1 に明記する
- [ ] **Phase 2**: OBS 音声系機能の個別エントリ記入（本書 §3）
  - 音声入力キャプチャ / アプリケーション音声キャプチャ / 音声出力キャプチャ / 音声モニタリング設定 / グローバル音声サンプリングレート / オーディオ同期オフセット / 音声フィルタ（内蔵ノイズ抑制 / Noise Gate / Compressor / VST）について、公式の説明範囲・OS 別対応・既知の制約を出典付きで埋める
  - 公式ドキュメントで読み取れなかった項目は**未確認事項として明示**する（推測で埋めない）
  - 各エントリで仮想オーディオデバイス側（[virtual-audio-devices.md §4.1](../specs/virtual-audio-devices.md#41-ツール--評価項目マトリクス) のコア集合）との噛み合いを 1 段落書く
- [ ] **Phase 3**: 横断棚卸し表 + P1〜P4 × OBS レシピ + 遅延ハンドリング + 上流反映
  - 本書 §4 の横断棚卸し表（音声入力キャプチャ vs アプリケーション音声キャプチャの使い分け / モニタリング設定 / グローバルサンプリングレート の足切り早見表）を作成
  - 本書 §5 で [virtual-audio-devices.md §5 P1〜P4](../specs/virtual-audio-devices.md#5-配信用途での典型構成) に対応する OBS 側レシピを行 = パターン × 列 = OBS 設定の表で提示。各パターンの経路図に OBS 側の音声 mixer ブロックを追加
  - 本書 §6 で遅延ハンドリングのポリシー（オーディオ同期オフセットの正負・実測の取り方の公式記述・ベンダー公称値と実測の分離）を整理
  - 本書 §7 で voice-changer-types §2 / §4 / w-okada-voice-changer §6・§9.1 / experiments/_template.md §6 / virtual-audio-devices.md §5 への更新差分案を書く（必要なら同 PR / 同コミットで実施）
  - 本書 §8 で後続タスク起票（OBS プラグイン系深掘り / ノイズ抑制系棚卸し（シリーズ第 3 弾） / 通話アプリ Discord・Zoom 取り回し / Streamlabs Desktop 等派生版の差分）

## 完了条件

- `docs/specs/obs-studio.md` が上記構成で書かれている
- 冒頭で **voice-changer-types §2 補助カテゴリ「周辺ツール」の「配信ソフト・通話ソフト」レイヤーのうち OBS Studio（本家）を扱い、仮想オーディオデバイス層の P1〜P4 を前提に音声入力キャプチャ・モニタリング・遅延ハンドリングを横断棚卸しする**ものであることが 1 行で示されている
- 「公式に書かれている内容 / OBS 公式の推奨値 / コミュニティで一般に言われている内容 / 未確認」の区別が読み手に分かる
- 実測値・断定的な性能評価が含まれていない（**公式 / ベンダー公称値は公称値と明示**されている）
- §3 の音声系機能エントリと §4 の横断棚卸し表が**抜けなく**埋まっている。公式ドキュメントから読み取れなかった項目は未確認として明示されている
- §5 の P1〜P4 × OBS レシピ表が、[virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成) の各パターンと**1 対 1 で対応している**（パターン番号 / 経路図のレイヤー構成が揃っている）
- §6 の遅延ハンドリングで、オーディオ同期オフセットの正負の意味と「ベンダー公称値 vs 実測」の分離ポリシーが明示されている
- 本書の**最終確認日**と参照した OBS Studio バージョンが §1 に記録されている
- voice-changer-types §2 / §4 / w-okada-voice-changer §6・§9.1 / experiments/_template.md §6 / virtual-audio-devices.md §5 への反映方針が §7 に書かれており、必要なら上流側の更新も実施されている
- 後続タスクが §8 に整理されており、`TODO.md` に上げるべき項目（とくにシリーズ第 3 弾候補の「ノイズ抑制 / ゲート系の棚卸し」が次の起票候補として読み手に分かる状態）が読み取れる
