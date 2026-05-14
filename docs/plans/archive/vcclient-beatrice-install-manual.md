# 調査プラン: VCClient + Beatrice + 配信周辺ツール (Windows) インストールマニュアル

## 目的・背景

これまでの既存 spec で、

- リアルタイム声変換の**実行ホスト**としての [w-okada-voice-changer.md](../specs/w-okada-voice-changer.md)
- 声変換**アルゴリズム / モデル**としての [beatrice.md](../specs/beatrice.md)
- 両者の階層差を解きほぐす [vcclient-vs-beatrice.md](../specs/vcclient-vs-beatrice.md)
- 配信経路の「仮想オーディオデバイス層」を棚卸しした [virtual-audio-devices.md](../specs/virtual-audio-devices.md)
- 配信ソフト側の受け口を棚卸しした [obs-studio.md](../specs/obs-studio.md)

までの**個別仕様の調査**は完了している。一方で、これらを**実際に Windows PC 上で一連の手順として組み上げる**ためのドキュメントは存在しない。

このタスクが空白のままだと、

- 「VCClient と Beatrice を入れて配信に使いたい」という最頻ユースケースに対して、**既存 spec を 5〜6 ファイル横断して読まないと作業に着手できない**状態が続く。
- 既存 spec はそれぞれ「公式情報源ベースの棚卸し」であって**操作手順を順番に並べるドキュメントではない**ため、初めて触る人は spec 同士の関係（[vcclient-vs-beatrice.md §4 経路 A/B/C](../specs/vcclient-vs-beatrice.md#4-3-つの使い方パターン同じ-beatrice-を使っても起動経路が違う) を選ぶ → [virtual-audio-devices.md §5 P1〜P4](../specs/virtual-audio-devices.md#5-配信用途での典型構成) を選ぶ → [obs-studio.md §5 OBS レシピ](../specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) を当てる → 各ツール側のライセンスを確認する）を毎回自力で組み立てることになる。
- 後続の [experiments/w-okada-voice-changer/](../../experiments/w-okada-voice-changer/) 実測タスクで「セットアップ前提」を毎回書き直すことになり、計測条件の前提が揃わない。

このタスクは、**既存 spec の調査結果を「Windows 10/11 で配信用途に組む人」の視点で 1 本のチュートリアル**に並べ替え、操作手順ベースで通せる状態にすることが目的。新規の仕様調査は含めない（既存 spec への参照と、各ツール公式の**インストール手順** / **既知のハマりどころ**の引用に徹する）。

このドキュメントが揃うと、

- 配信用途で VCClient + Beatrice + 仮想オーディオデバイス + OBS をひと続きにセットアップする際、**1 ファイルを上から順に読みながら作業できる**状態になる。
- [vcclient-vs-beatrice.md §6.2 「VCClient + Beatrice（経路 B）」](../specs/vcclient-vs-beatrice.md#62-こういうときは-vcclient--beatrice経路-b) を選んだ人向けの具体的な着地点が示せる（公式 VST 単体経路 A は別ドキュメント、派生クライアント経路 C は本書のスコープ外）。
- experiments テンプレ側で「セットアップ前提」欄に本書へのリンクを置けば、計測条件の前提が共通化できる。

## 想定読者

- Windows 10 / 11 (x64) の自宅 PC でリアルタイム声変換を**配信用途**で試したい人
- VCClient / Beatrice / 仮想オーディオデバイス / OBS のうち**少なくとも 1 つは未経験**で、何から手を付ければ良いか分からない状態
- ある程度の PC リテラシー（zip 展開・ドライバインストール・OBS の基本操作・Discord/Zoom の音声設定変更）はあることを前提とする
- 既存の個別 spec を参照することは厭わないが、**手順を上から順に追える主動線**を別途欲しい

## スコープ

**含める:**

- **対象 OS**: Windows 10 / 11（x64）。ARM64 Windows は参考扱い（公式記述があれば触れる程度）
- **対象 VCClient エディション**: NVIDIA GPU 想定の **`vcclient_win_cuda_xxx.zip`** を主動線、CPU 系の `vcclient_win_std_xxx.zip` / `onnx` 系は分岐先として軽く言及（[w-okada-voice-changer.md §2.4](../specs/w-okada-voice-changer.md#24-配布形態とエディション) 参照）
- **対象 Beatrice バージョン**: **Beatrice 2** を主動線（公式キャラクターエディション / 公式モデル）、**Beatrice 1** は VCClient v.1 系で Windows 限定の選択肢として位置付けを明示（[beatrice.md §1.4](../specs/beatrice.md) / [w-okada-voice-changer.md §3.1](../specs/w-okada-voice-changer.md#31-v2-と-v1-のサポートモデル差分readme-表より) 参照）。**v1 と v2 のモデル形式が非互換**である点と、JVS Corpus Edition の**営利目的禁止**条項（[beatrice.md §5.4](../specs/beatrice.md)）は手順内で明示
- **対象 α**（配信周辺ツール）:
  - **仮想オーディオデバイス**: **VB-CABLE**（必須経路）と **VoiceMeeter Banana**（ハブ経路 / 推奨）。VoiceMeeter Potato は同系列の上位として位置付け言及（[virtual-audio-devices.md §3](../specs/virtual-audio-devices.md) のコア集合に準拠）
  - **配信ソフト**: **OBS Studio 32.1.x 系**（[obs-studio.md §1.2](../specs/obs-studio.md) の基準バージョンに合わせる）
  - **ノイズ抑制 / ゲート**: 「OBS 内蔵フィルタ（RNNoise / Speex / NVIDIA Audio Effects SDK 連携）」と「**NVIDIA Broadcast**（別アプリ・NVIDIA RTX 限定）」を**選択肢として提示**し、各公式入手元へリンク。**選定軸の比較は本書のスコープ外**（配信周辺ツール調査シリーズ第 3 弾候補）として明示
  - **通話アプリ**: **Discord** と **Zoom** の音声入力設定（VCClient output 系仮想デバイスをマイクに指定する手順）。アプリ固有の細かい挙動には踏み込まず、「マイク入力デバイス選択」「自動入力感度 / ノイズ抑制を OFF にする」程度のチェックリストに止める（[virtual-audio-devices.md §7.3 後続タスク](../specs/virtual-audio-devices.md#73-後続タスクtodomd-に上げるべき項目) と同じく、本格的な spec 化は別タスク扱い）
- **粒度・スタイル**: 操作手順ベース（チュートリアル型）。各ステップは「クリック対象」「期待される画面表記」「次に進む条件」の 3 点を文字で具体的に書く。スクリーンショットは本タスクでは添付しない（実機検証時に別途撮るかは後続タスクで判断）
- 各ツールの**公式ダウンロード URL** / **公式インストール手順ページ** / **公式ライセンスページ**へのリンクを章ごとに置く
- セットアップ完了時の音声経路（VCClient → 仮想ケーブル → OBS / 通話アプリ）を **Mermaid 図** で 1 枚にまとめる（[virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成) / [obs-studio.md §5](../specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) の P1〜P4 ラベルに揃える）
- セットアップ後の動作確認手順（VCClient の単体音出し → 仮想ケーブル経由のループバック確認 → OBS の音声メーター確認 → 通話アプリのマイクテスト）
- 既知のハマりどころ早見表（CUDA を認識しない / 仮想デバイスがデバイス一覧に出ない / OBS のサンプリングレート不一致 / Chrome 以外で UI が出ない / Beatrice v1 / v2 の混同 / monitor 分離未設定で自分の声が遅れて聞こえる 等）

**含めない:**

- **OS 別差分の網羅**: macOS / Linux 向け手順は本書では扱わない（必要になった時点で別ドキュメント化。`vcclient_mac_xxx.zip` + BlackHole 経路は spec 側 [virtual-audio-devices.md §3.4](../specs/virtual-audio-devices.md) で位置付けのみ把握済み）
- **公式 VST 単体経路（A）/ 派生クライアント経路（C）の手順**: [vcclient-vs-beatrice.md §4](../specs/vcclient-vs-beatrice.md#4-3-つの使い方パターン同じ-beatrice-を使っても起動経路が違う) で経路 A / C として整理済みだが、本書は**経路 B（VCClient + Beatrice）に絞る**。経路 A は将来別ドキュメント候補として §後続タスクに残す
- **モデル学習・自前モデル作成手順**（VCClient の `trainer/` / Beatrice 公式トレーナー）— 本書はインストールと配信用途での運用設定までで、学習ワークフローには立ち入らない（[w-okada-voice-changer.md §9.3](../specs/w-okada-voice-changer.md#93-当面は深追いしない領域) と同じ立て付け）
- **モデル個別の音質評価 / レイテンシ実測値** — [CLAUDE.md](../../CLAUDE.md) 方針通り実測は experiments タスクで個別に取る。本書では「動作確認手順」止まり
- **ノイズ抑制プラグインの選定軸比較**（NVIDIA Broadcast / Krisp / RNNoise / Speex の優劣判定）— 配信周辺ツール調査シリーズ第 3 弾の独立タスク。本書では選択肢提示と公式リンクまで
- **通話アプリ Discord / Zoom 固有の細かい挙動網羅**（サーバ側の音声品質設定、Discord Krisp の挙動、Zoom の Original Sound 等）— 別タスク扱い。本書では「マイク入力デバイスに VCClient 系仮想デバイスを指定する」「自動入力感度 / ノイズ抑制を OFF にする」レベルの汎用チェックリスト止まり
- **配信プラットフォーム側の規約解釈**（YouTube / Twitch / niconico での声変換配信に関する規約）— [obs-studio.md §1.4 含めないもの](../specs/obs-studio.md) と同じく踏み込まない
- **第三者の声を許諾なく再現するモデル**の入手手順 — [CLAUDE.md](../../CLAUDE.md) 方針
- **クラッキングされた配布物や非公式ミラー** — 公式配布元（GitHub Releases / Hugging Face / 公式サイト / Microsoft Store 等）のみを参照

## 対応方針

成果物は `docs/specs/install-vcclient-beatrice-windows.md` の 1 ファイル。

冒頭で本書が、

- [vcclient-vs-beatrice.md §4 経路 B](../specs/vcclient-vs-beatrice.md#4-3-つの使い方パターン同じ-beatrice-を使っても起動経路が違う)（VCClient + Beatrice）を **Windows 10/11 で配信用途に組む**ためのチュートリアル型ドキュメントであること
- 個別仕様の調査結果は既存 spec を参照し、本書は**手順の主動線**に徹すること
- 操作手順ベースで上から順に読みながら作業できる粒度で書くこと（spec の棚卸し / 比較表ではない）

を 1 段落で示す。

構成案:

1. **概要**（本書の位置付け / 想定読者 / 対象 OS と VCClient エディションと Beatrice バージョン / 既存 spec との関係 / 「インストールマニュアル」と本書で呼ぶ範囲定義）
2. **完成図と前提**（Mermaid 図でセットアップ完了時の音声経路を 1 枚提示 / 必要なハードウェア・ソフトウェア前提 / 用意するもののチェックリスト / 各ツールの公式入手元 URL を表で集約）
3. **VCClient のインストール**（エディション選択（CUDA / std / onnx / mac の選び方フロー）→ Hugging Face リポジトリからの zip 入手 → 展開先の選び方 → Windows Defender / SmartScreen の挙動 → 初回起動と Chrome 起動の確認 → モデルスロットの位置確認）
4. **Beatrice モデルの入手と VCClient へのロード**
   - Beatrice 2 公式モデル（[beatrice.md §5.1](../specs/beatrice.md) 公式 VST 本体バンドル / [§5.6](../specs/beatrice.md) 配布形態まとめ / 公式サイト [prj-beatrice.com](https://prj-beatrice.com)）
   - キャラクターエディション（つくよみちゃん / 刻鳴時雨 / OLUNE）の**個別 EULA 確認手順**（[beatrice.md §5.3](../specs/beatrice.md)）
   - Beatrice 1（JVS Corpus Edition）の VCClient v.1 系経由ロード手順と**営利目的禁止**条項（[beatrice.md §5.4](../specs/beatrice.md)）— 配信で収益化する人は v1 系を使わない、または許諾を取る、という分岐
   - モデルスロット UI へのロード手順（[w-okada-voice-changer.md §3.2](../specs/w-okada-voice-changer.md#32-ホストとモデルの責任分界暫定整理) のチュートリアル記述に準拠）
5. **VB-CABLE のインストール**（VB-Audio 公式ダウンロード → 管理者権限で `VBCABLE_Setup_x64.exe` 実行 → 再起動 → Windows の「サウンド」で `CABLE Input` / `CABLE Output` が見えることを確認 → 既知のハマりどころ: 旧バージョン残骸 / WDM ドライバ衝突）
6. **VoiceMeeter Banana のインストール**（VB-Audio 公式ダウンロード → インストール → 再起動 → 起動順序の注意（Banana を先に起動してから VCClient を起動する経路パターンの説明）→ Hardware Out / B1 / B2 の役割 → [virtual-audio-devices.md §3.2 / §3.3](../specs/virtual-audio-devices.md) の用語と一致させる）
7. **OBS Studio のインストールと音声設定**（公式 [obsproject.com](https://obsproject.com/) ダウンロード → インストール → **グローバル音声サンプリングレートの設定**（[obs-studio.md §3](../specs/obs-studio.md) を引用、44.1 kHz / 48 kHz の選択を VCClient / 仮想ケーブル側と整合させる）→ **音声入力キャプチャ**ソースの追加と VCClient output 系仮想デバイスの選択 → **モニタリングデバイス**設定 → **音声モニタリング**設定（モニターオフ / モニターのみ / モニターと出力の使い分け、[obs-studio.md §5](../specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) を引用））
8. **ノイズ抑制 / ゲートの選択肢**（OBS 内蔵の Noise Suppression フィルタで何が選べるか、NVIDIA Broadcast（NVIDIA RTX 限定）の入手元、選定軸は本書のスコープ外として配信周辺ツール調査シリーズ第 3 弾候補にリンクしておく）
9. **通話アプリ側の設定**（**Discord**: ユーザー設定 → 音声・ビデオ → 入力デバイスに VCClient output 系仮想デバイス指定 / 自動入力感度 / 入力音量 / Krisp ノイズ抑制 OFF のチェックリスト。**Zoom**: 設定 → オーディオ → マイク選択 / 自動音量調整 OFF / 背景雑音抑制 OFF / Original Sound 有効化の有無）
10. **典型構成のセットアップレシピ（P1〜P4 × OBS）**（[virtual-audio-devices.md §5 P1〜P4](../specs/virtual-audio-devices.md#5-配信用途での典型構成) × [obs-studio.md §5](../specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) を、本書では「Windows 配信用途で最初に組むなら **P2 / P3**」に絞ったレシピで提示。各レシピで VCClient 側の input / output / monitor デバイス選択 + VoiceMeeter 側のルーティング + OBS 側の音声入力キャプチャ / モニタリング設定の組み合わせを表で示す）
11. **動作確認手順**（VCClient だけ起動して音が出るか → 仮想ケーブル経由で OBS の音声メーターが振れるか → OBS の「録画開始」で 10 秒録って再生 → Discord のマイクテストでループバックが返るか → monitor デバイス分離が効いているか、の段階的チェックリスト）
12. **既知のハマりどころ早見表**（CUDA を認識しない / `vcclient_win_std` を入れていた / Chrome 以外でブラウザ UI が出ない / 仮想デバイスがサウンド設定に出ない（再起動忘れ・古い VB-CABLE 残骸）/ OBS のグローバル音声サンプリングレートが仮想ケーブルと不一致 / monitor 分離未設定で自分の声が遅れて聞こえる / Beatrice v1 のモデルを v.2 系 VCClient にロードしようとして失敗 / OS Mixer 経由で意図しないノイズ抑制が二重にかかる、等）
13. **ライセンス・規約まわりのチェックリスト**（[vcclient-vs-beatrice.md §6.3](../specs/vcclient-vs-beatrice.md#63-ライセンスの所在に注意) の「経路によって読むべき規約が変わる」表をそのまま再掲し、配信で収益化する場合の確認項目を列挙）
14. **後続タスク**（公式 VST 単体経路 A の手順 / macOS 版手順 / モデル学習ワークフロー / ノイズ抑制プラグイン選定の深掘り / Discord・Zoom 取り回しの深掘り spec 化 / 実機検証ログの experiments テンプレ化）

記述ルール（[obs-studio.md](../specs/obs-studio.md) / [virtual-audio-devices.md](../specs/virtual-audio-devices.md) と統一）:

- **公式ドキュメント / 公式 FAQ / 公式インストールガイド** に書かれていることと、コミュニティで一般に言われていることを明確に分ける。出典を行ごとに明記する
- 実測値・断定的な性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**ベンダー公称値は「ベンダー公称」として明示**し、本ラボでの実測値とは混ぜない
- ツール名・UI 表記は**各ツールの公式ドキュメントが使っている名称**をそのまま書く。和訳 UI かどうかは公式記述がある場合のみ採用
- 第三者の声を許諾なく再現する用途には誘導しない（[CLAUDE.md](../../CLAUDE.md) 方針）。モデルやキャラクター音声の利用条件は**配布元の EULA を一次情報として読む**よう各章で明示
- 図（音声経路）は **Mermaid**（` ```mermaid ` フェンスドコードブロック）で書き、ASCII 図は新規に書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。subgraph タイトルに `<br/>` 改行は入れない
- 編集後は **vibeboard プレビュー**（`http://localhost:3010` 等）で Mermaid の表示崩れ・リンク切れを目視確認してから push する
- 本書の**最終確認日**を §1 に明記する（VCClient / Beatrice / OBS の各ツールはリリースが活発で UI / 配布物名が変動するため、再訪時の判断材料として残す）

## 影響範囲

- 新規追加: `docs/plans/vcclient-beatrice-install-manual.md`（本ファイル）, `docs/specs/install-vcclient-beatrice-windows.md`
- 既存ファイル変更:
  - `TODO.md` の該当項目（「VCClient + Beatrice + α のインストールマニュアルを作る」）に本プランへのリンク追記、Phase の子タスク化
  - （Phase 3 で必要に応じて）`docs/specs/README.md` の目次に本書を追加
  - （Phase 3 で必要に応じて）`docs/specs/vcclient-vs-beatrice.md` §6.2 / §7 に本書（経路 B の具体手順）へのリンクを追記
  - （Phase 3 で必要に応じて）`docs/specs/w-okada-voice-changer.md` §6 / §9.1 で「実機セットアップ手順は本書を参照」のリンクを追記
  - （Phase 3 で必要に応じて）`docs/specs/beatrice.md` §5.3 / §5.4 のキャラクターエディション / JVS Corpus Edition 利用条件説明から本書のライセンスチェックリスト章へのリンクを追記
  - （Phase 3 で必要に応じて）`docs/specs/virtual-audio-devices.md` §5 P1〜P4 / `docs/specs/obs-studio.md` §5 の各レシピ末尾に「Windows での具体的セットアップ手順は本書を参照」のリンクを追記
  - （Phase 3 で必要に応じて）`experiments/w-okada-voice-changer/_template.md` のセットアップ前提欄に本書へのリンクを追加
- コードへの影響なし

## 進め方 (Phase)

- [x] **Phase 1**: 範囲確定 + 公式情報源収集 + マニュアル目次の最終化（成果物: [docs/specs/install-vcclient-beatrice-windows.md](../specs/install-vcclient-beatrice-windows.md) §1〜§2 + §3〜§14 見出し骨格、最終確認日 2026-05-14）
  - 対象 OS（Windows 10/11 x64）、対象 VCClient エディション（CUDA 主動線）、対象 Beatrice バージョン（v2 主動線・v1 言及）、α の集合（VB-CABLE / VoiceMeeter Banana / OBS Studio / ノイズ抑制（選択肢提示のみ）/ Discord・Zoom（汎用チェックリスト）まで）を本書 §1 で固定する
  - 各ツールの**公式ダウンロード URL** / **公式インストールガイド** / **公式ライセンスページ** / **公式 FAQ / Known Issues** の URL を本書 §2 の入手元表に並べる
  - 確認時の各ツールのメジャー / マイナーバージョン（VCClient v.2.x-beta 系・Beatrice 2 系・OBS Studio 32.1.x 系・VB-CABLE / VoiceMeeter Banana の現行バージョン）を §1 に明記する
  - 操作手順の粒度（クリック対象・期待される画面表記・次に進む条件の 3 点を文字で記述。スクショなし）を §1 に固定する
- [ ] **Phase 2**: 個別ツールのインストール手順記入（本書 §3〜§9）
  - §3 VCClient: エディション選択フロー → Hugging Face からの入手 → 展開 → 初回起動 → モデルスロット位置
  - §4 Beatrice モデル: 公式モデル入手 → キャラクターエディション EULA 確認 → VCClient へのロード → v1 / v2 の混同回避（**営利目的禁止**条項は v1 のセクションで明示）
  - §5 VB-CABLE: 公式ダウンロード → インストーラ実行 → 再起動 → サウンド設定での確認
  - §6 VoiceMeeter Banana: 公式ダウンロード → インストール → 起動順序 → Hardware Out / B1 / B2 の役割
  - §7 OBS Studio: 公式ダウンロード → グローバル音声サンプリングレート → 音声入力キャプチャ → モニタリングデバイス → 音声モニタリング設定（既存 [obs-studio.md](../specs/obs-studio.md) を引用）
  - §8 ノイズ抑制 / ゲート: OBS 内蔵フィルタの選択肢列挙 + NVIDIA Broadcast の公式入手元（選定軸比較は本書のスコープ外と明示）
  - §9 通話アプリ: Discord / Zoom のマイク入力設定チェックリスト
  - 公式ドキュメントで読み取れなかった項目は**未確認事項として明示**する（推測で埋めない）
- [ ] **Phase 3**: 典型構成レシピ + 動作確認 + ハマりどころ + ライセンスチェックリスト + 上流反映
  - §10 で [virtual-audio-devices.md §5](../specs/virtual-audio-devices.md#5-配信用途での典型構成) × [obs-studio.md §5](../specs/obs-studio.md#5-配信用途での典型構成p1p4--obs-レシピ) のレシピを Windows 配信用途に絞った形（P2 / P3 中心）で表化
  - §11 で段階的な動作確認手順を列挙
  - §12 で既知のハマりどころ早見表を作成
  - §13 で [vcclient-vs-beatrice.md §6.3](../specs/vcclient-vs-beatrice.md#63-ライセンスの所在に注意) のライセンス表を再掲 + 配信収益化時の確認項目を列挙
  - §14 で後続タスクを起票（公式 VST 単体経路 A の手順 / macOS 版手順 / モデル学習ワークフロー / ノイズ抑制プラグイン選定深掘り / Discord・Zoom 深掘り spec / experiments テンプレへの反映）
  - **影響範囲**節で挙げた既存ファイル群への双方向リンクを追加（必要なものに絞る）
  - 完成図 Mermaid を vibeboard プレビューで目視確認

## 関連

- [vcclient-vs-beatrice.md](../specs/vcclient-vs-beatrice.md) — 経路 A/B/C の整理。本書は **経路 B** に絞る
- [w-okada-voice-changer.md](../specs/w-okada-voice-changer.md) — 実行ホストとしての VCClient の仕様
- [beatrice.md](../specs/beatrice.md) — アルゴリズム / モデルとしての Beatrice の仕様
- [virtual-audio-devices.md](../specs/virtual-audio-devices.md) — 仮想オーディオデバイス層の横断棚卸し
- [obs-studio.md](../specs/obs-studio.md) — OBS Studio との接続パターン
- [overview.md](../specs/overview.md) — ボイスチェンジャー入門
- [voice-changer-types.md](../specs/voice-changer-types.md) — 分類軸の見取り図
