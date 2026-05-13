# 仮想オーディオデバイスまとめ

> [voice-changer-types §2 補助カテゴリ「周辺ツール」](./voice-changer-types.md#補助カテゴリ-周辺ツール) のうち **「仮想オーディオデバイス」レイヤー**を掘り下げる横断棚卸し。
>
> 本ページは [docs/plans/virtual-audio-devices.md](../plans/virtual-audio-devices.md) のスコープに沿って、各ツールの**公式情報源**（公式サイト / 公式ダウンロードページ / 公式ライセンスページ / 公式 FAQ）に書かれている内容を中心に**複数ツールの横断棚卸し**を行う。
> [rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md) / [w-okada-voice-changer.md](./w-okada-voice-changer.md) と異なり、**1 ツール深掘りではなく複数ツールの横断棚卸し**である点を冒頭で明示する（[cloud-saas-realtime.md](./cloud-saas-realtime.md) と同じ立て付け）。
> 各項目で「公式に書かれている内容」「ベンダー公称値」「コミュニティで一般に言われている内容」「未確認」を区別する。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**ベンダー公称のレイテンシ / CPU 負荷はベンダー名と値を出典付きで明記**し、本ラボでの実測値とは混ぜない。
>
> **進捗:** Phase 1〜3 完了。Phase 2 までで §3 各ツールエントリを公式情報源ベースで記入（コア集合 4 件 + 補足 2 件、各ツールの最終確認日 2026-05-12）、Phase 3 で **§4 横断棚卸し表 / §5 配信用途の典型構成 / §6 上流ドキュメントへの反映方針 / §7 後続タスク起票**を記入し、§6 に沿って [voice-changer-types §2 / §4](./voice-changer-types.md) / [w-okada-voice-changer §6](./w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) / [experiments/w-okada-voice-changer/_template.md](../../experiments/w-okada-voice-changer/_template.md) を更新済み。

## 1. 概要

### 1.1 本書の位置付け

[voice-changer-types §2 補助カテゴリ「周辺ツール」](./voice-changer-types.md#補助カテゴリ-周辺ツール) は現時点で、仮想オーディオデバイスの代表例として `VB-CABLE / VoiceMeeter Banana / Potato / BlackHole / Soundflower (旧 macOS)` を**名前出しのみ**で止めている。一方で、配信用途のリアルタイム声変換は `マイク → (ノイズ抑制) → 声変換ホスト → 仮想オーディオデバイス → OBS / 通話ソフト` という経路で組むのが既定であり、声変換ホスト側 spec ([w-okada-voice-changer.md §6](./w-okada-voice-changer.md#6-配信ソフトとの連携) ほか) も「VC Client の output を仮想オーディオデバイスに流して OBS で拾う」前提で書かれている。仮想オーディオデバイス側が空白のままだと、

- [voice-changer-types §4 配信用途で見るべき主な評価軸](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) の「入出力構成」「エコシステム」軸が評価できない
- [w-okada-voice-changer.md §6](./w-okada-voice-changer.md#6-配信ソフトとの連携) と、後続の [experiments/w-okada-voice-changer/](../../experiments/w-okada-voice-changer/) 実測テンプレートで「どの仮想デバイスでどう繋ぐか」を都度考えることになり、計測条件が揃わない
- [cloud-saas-realtime.md §4.1](./cloud-saas-realtime.md#41-判定サマリ足切り判断) で Voice.ai が "VB-Audio Virtual Cable 経由で OS に仮想入力デバイスとして露出" を理由に判定 A になっているが、その前提となる VB-CABLE 側の仕様（モノラル/ステレオ / サンプルレート / ライセンス / ループバック構成）がこちら側の spec で裏取りされていない

という空白が残る。本書は**配信周辺ツール調査の第 1 弾**として、その空白を埋めることを目的に、**仮想オーディオデバイス単体の仕様棚卸し**に絞って書く。OBS Studio 側の経路図 / 内部設定は本書のスコープ外（同シリーズ第 2 弾の「OBS Studio との接続パターンまとめ」が本書の成果物を前提にする想定）。

個別ツール spec ([rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md) / [w-okada-voice-changer.md](./w-okada-voice-changer.md)) は **1 ツールの内部実装を深掘り**するが、本書はそれと異なり**複数ツールの横断棚卸し**が成果物となる。個別ツールでの深掘りが必要になった時点で、本書を起点に個別タスクへ昇格させる（§7）。

### 1.2 対象ツール集合（Phase 1 で確定）

**コア集合（§3 で個別エントリを書く対象）:**

- **VB-CABLE**（VB-Audio Software 提供、Windows 向け仮想オーディオケーブル）
- **VoiceMeeter Banana**（VB-Audio Software 提供、Windows 向け仮想ミキサー兼仮想オーディオデバイス）
- **VoiceMeeter Potato**（VB-Audio Software 提供、VoiceMeeter ファミリー最上位）
- **BlackHole**（Existential Audio Inc. 提供、macOS 向け仮想オーディオドライバ）

**補足扱い（経路の歴史的経緯 / 他 OS の対応状況把握のため軽く触れる対象。§3.5 / §3.6）:**

- **Soundflower**（macOS 旧。BlackHole 以前に広く使われていた仮想オーディオドライバ。BlackHole への移行関係を確認するためだけに位置付けを記す）
- **Linux PulseAudio / PipeWire の仮想シンク**（参考。本ラボのメイン環境ではないが、他資料との照合のため経路概要のみ触れる）

**スコープ外として §7 に名前のみ残す候補:**

- **VoiceMeeter Standard**（VB-Audio。VoiceMeeter ファミリーの最小構成。配信用途では Banana / Potato が事実上の選択肢になるため本書のコア集合には含めず、Banana のエントリ内で「VoiceMeeter ファミリーには Standard / Banana / Potato の 3 構成がある」と一言触れるに留める）
- **VB-CABLE A+B / VB-CABLE C+D / Hi-Fi Cable（+ ASIO Bridge）**（VB-Audio。複数本の仮想ケーブルを組むときの追加 Donationware 製品。VB-CABLE エントリ内で「VB-Audio は同系列の追加ケーブルも配布している」と言及するに留める）
- **Virtual Audio Cable (VAC)**（Eugene Muzychenko 製、Windows 向け有償の仮想ケーブル。VB-CABLE と並ぶ Windows 向け代替）
- **Loopback**（Rogue Amoeba 製、macOS 向け有償のオーディオルーティングツール）
- **Wave Link**（Elgato 製、Windows / macOS 向けミキサー兼仮想デバイス）
- **JACK Audio Connection Kit**（クロスプラットフォームの pro-audio ルーティング基盤。Linux 側で実際に使われるケースの参照先として）

スコープ外候補を §7 に残す理由は、配信用途で「VB-CABLE / VoiceMeeter / BlackHole で足りないユースケース（複数ストリームの本数増し、特殊なフォーマット要件、macOS 上での商用配信での選定など）」が出てきた時点で、本書の判定軸を当てはめて棚卸しすべき対象として残しておくため。Phase 1 では取り扱わない。

### 1.3 「仮想オーディオデバイス」と本書で呼ぶ範囲

本書では「**仮想オーディオデバイス**」を、次の両方を満たすソフトウェアと定義する。

1. **OS の音声入出力デバイス一覧に「仮想の入力 / 出力デバイス」として現れる**こと。配信ソフト・声変換ホスト・通話ソフトはいずれも「OS のデバイス一覧から入出力デバイスを選ぶ」モデルなので、これを満たさないと配信経路に挟めない
2. **アプリ A の音声出力をアプリ B の音声入力として渡せる**こと（= ループバック / 仮想ケーブルの機能を持つ）。物理デバイスを抽象化するだけの仮想ドライバ（例: ASIO のブリッジドライバ）は本書のスコープ外

**含めるもの:**

- ドライバレベルの仮想ケーブル（例: VB-CABLE / BlackHole）。OS のデバイス一覧に「仮想入力」「仮想出力」として現れ、A→B の単方向にオーディオを流す
- ドライバ + ソフトウェアミキサー一体型（例: VoiceMeeter Banana / Potato）。ドライバ層で仮想入出力を提供しつつ、ユーザーランドに GUI ミキサーを持つ。ミキサーは複数入力をミックス / ルーティングする「ソフトウェア機能」だが、その出力先・入力元として**仮想デバイスを露出している**点で本書のスコープに含める

**含めないもの:**

- **OS の音声デバイスとして露出しない純粋なソフトウェアミキサー / DAW のバス**（DAW 内部のバス、OBS 内部の音声ミキサー、配信ソフトのオーディオ Bus）。これらはアプリ内部のルーティングであり、別アプリへ「OS のデバイスとして」渡せないため本書のスコープ外
- **物理デバイスを抽象化するだけのブリッジドライバ**（例: ASIO4ALL）。仮想ケーブル機能を持たない
- **入力前段の前処理プラグイン**（ノイズ抑制 / ゲート。NVIDIA Broadcast / Krisp / RNNoise）。[voice-changer-types §2 補助カテゴリ](./voice-changer-types.md#補助カテゴリ-周辺ツール) のうち別レイヤー
- **配信ソフト本体**（OBS Studio / Streamlabs Desktop）。同じく別レイヤー
- **通話アプリ固有の仮想デバイス取り回し**（Discord / Zoom のオーディオ設定。必要になった時点で個別タスクへ）
- **クラッキングされたドライバなど著作権・配布規約上問題のある配布物** — そもそも触れない

VoiceMeeter は「ミキサー」と呼ばれるが、その入出力（"VoiceMeeter Input" / "VoiceMeeter AUX Input" などの名前で OS に露出する仮想デバイス）を介して他のアプリと音声をやりとりできる点で、本書の定義 (1)(2) を満たす。一方で、もし将来「OS に仮想デバイスを露出せず、アプリ間で音声をルーティングするだけ」のソフトウェアが候補に挙がった場合は、本書のスコープ外として §7 に残す。

## 2. 評価項目

§3 各ツールエントリで埋め、§4 横断棚卸し表のカラムにする評価項目の定義。Phase 2 で本文を埋める時点では、ここに列挙したカラムをツール別に書く。

| 評価項目 | 何を書くか |
| --- | --- |
| 公式情報源 | 公式サイト / 公式ダウンロードページ / 公式ライセンスページ / 公式 FAQ / 公式 GitHub の URL。§3 では各エントリ冒頭にまとめる |
| 公式プロダクト名 | **ベンダーが何と呼んでいるか**をそのまま書く（本ラボの分類に勝手に翻訳しない） |
| 提供形態 | 無償 / Donationware / 有償 / オープンソース。配布物の入手経路と、寄付の有無・金額レンジ |
| ライセンス | **ベンダー公式の明示があるもののみ**書く。とくに**商用配信での利用可否**について公式が触れているか。明示がない場合は「公式記述なし」と明記し、勝手に判断しない |
| 動作プラットフォーム | OS / バージョン。**Apple Silicon / ARM Windows 対応の有無**を明示 |
| 仮想 IO ペア構成 | 何本の仮想ケーブル / 何チャンネルの入出力 / マルチクライアントの可否 / ループバック有無 / ミキサー機能の有無 |
| サンプルレート / ビット深度 / チャンネル数 | 公式に書かれている公称値のみ |
| OS 上のデバイス名 | 配信ソフト / 声変換ホストから見たときの名称（**公式が明示している場合のみ**採用し、推測では書かない） |
| インストール / アンインストール手順所在 | 公式ガイドへのリンクと、ハマりやすい注意点 1〜2 行 |
| 既知の制約 | 公式 FAQ / Known Issues に記載のあるもの |
| 最終確認日 | YYYY-MM-DD。バイナリ配布のバージョンと OS 対応は変動が早いためツールごとに記録 |
| 未確認事項 | 公式から読み取れなかった項目を明示。**推測で埋めない** |

記述ルール（[cloud-saas-realtime.md](./cloud-saas-realtime.md) / [rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md) / [w-okada-voice-changer.md](./w-okada-voice-changer.md) と統一）:

- **公式サイト / 公式ドキュメント / 公式 FAQ** に書かれていることと、コミュニティで一般に言われていることを**明確に分ける**。出典を行ごとに明記する
- 実測値・断定的な性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**ベンダー公称レイテンシや CPU 負荷は「ベンダー公称」として明示**し、本ラボでの実測値とは混ぜない
- 製品名 / デバイス名は**ベンダーがそう呼んでいる名称**をそのまま書く。OS のデバイス一覧での見え方は、公式が明示している場合のみ採用する
- ライセンス / 商用配信での利用可否は**ベンダー公式の明示がある項目のみ**書く。明示がない場合は「公式記述なし」と明記し、勝手に判断しない
- ツールごとに**最終確認日**を明記する
- 価格表記は**ベンダー表記そのまま**（USD / EUR / JPY / Donation 金額レンジ等）。為替換算は行わない

## 3. ツール別エントリ

> **Phase 2 で本文記入済み**: 各ツールエントリは公式情報源（公式サイト / 製品ページ / ユーザーマニュアル PDF / GitHub README・LICENSE / 公式 FAQ）から読み取れた範囲のみで埋め、読み取れなかった項目は **未確認事項**として明示している。**ベンダー公称値** / **コミュニティ言及** / **未確認** の区別は各エントリ内で行単位に明記する（[CLAUDE.md](../../CLAUDE.md) 方針）。

### 3.1 VB-CABLE

- **提供元**: VB-Audio Software（Vincent Burel 氏）
- **本書での位置付け**: Windows 向け仮想オーディオケーブルの定番。`マイク → 声変換 → VB-CABLE → 配信ソフト` の経路で、ボイチェン界隈で事実上の標準として参照されるケースが多い（コミュニティ言及）。Mac 向けに別 SKU の **VB-CABLE for Mac** が同社から配布されており、本書のコア集合では Windows 版 VB-CABLE を中心に扱う。
- **公式情報源:**
  - 製品ページ / ダウンロード: <https://vb-audio.com/Cable/>
  - リファレンスマニュアル PDF: <https://vb-audio.com/Cable/VBCABLE_ReferenceManual.pdf>
  - 同系列追加ケーブル解説: <https://vb-audio.com/Cable/VirtualCables.htm>
  - Donationware モデル説明: <https://vb-audio.com/Voicemeeter/Donationware.htm>
  - VB-Audio ライセンス: <https://vb-audio.com/Services/licensing.htm>
  - VB-Audio Webshop（Win 版 / Mac 版 / 追加ケーブル）: <https://shop.vb-audio.com/>
- **提供形態 / ライセンス**:
  - 製品ページ公式記述: 「VB-CABLE is a Donationware!」「you can adjust the License Price to your means or usage!」（[Cable/](https://vb-audio.com/Cable/)）。バイナリは登録不要で同ページから直接 ZIP / DMG をダウンロード可能（公式）。
  - VB-Audio 共通の Donationware モデル: 「free to use ... but you are expected to pay your license if you find it useful or if you make any professional use」（[Donationware.htm](https://vb-audio.com/Voicemeeter/Donationware.htm)）。
  - **商用配信での利用可否は公式 EULA の原文を直接引用できる位置にこちら側で裏取りできなかったため断定しない**。Licensing ページには「professional use / server installation / volume licensing / OEM 配布の場合は個別ライセンス」相当の記述があるが、配信（broadcast）用途を名指しで禁止/許諾分離する文言は今回確認できず → **未確認事項として §未確認事項に残す**。
- **動作プラットフォーム**（[Cable/](https://vb-audio.com/Cable/) 公式記述）:
  - Windows 版（新パッケージ）: 「XP to WIN11 32/64 bits/Arm64」
  - Windows 版（旧パッケージ）: 「XP to WIN11 32/64 bits」（ARM64 未対応の従来版）
  - macOS 版（別 SKU "VB-CABLE for Mac"）: 「Intel / Apple Silicon」「macOS 64bits version 10.10 and higher」
- **仮想 IO ペア構成**:
  - 本体: **1 ペア**（CABLE Input → CABLE Output。同一ホスト内のアプリ A の再生出力をアプリ B の録音入力として受け取る単方向経路）。
  - 追加製品で本数を増やせる: VB-CABLE A+B は +2 ペア、VB-CABLE C+D はさらに +2 ペア（最大 5 ペアまで併用可、[VirtualCables.htm](https://vb-audio.com/Cable/VirtualCables.htm)）。
  - マルチクライアント可否についての**公式記述は未確認**（WASAPI 共有モードでの利用は実運用上一般的だが本書では公式記述として扱わない）。
- **サンプルレート / ビット深度 / チャンネル数**:
  - リファレンスマニュアル PDF（[VBCABLE_ReferenceManual.pdf](https://vb-audio.com/Cable/VBCABLE_ReferenceManual.pdf)）公称: Windows 10/11 x64/Arm64 版は MME / WASAPI / KS の各インターフェイスで 8 kHz〜192 kHz、最大 8 チャンネル（コントロールパネルで内部サンプルレート / レイテンシを切替可能）。
  - 関連製品 Hi-Fi Cable は「bit perfect、24 bits 384 kHz まで対応」（[Cable/](https://vb-audio.com/Cable/) 公式記述）— ただし本書のコア集合は VB-CABLE 本体のため Hi-Fi Cable の数値は参考扱い。
  - VB-CABLE 本体のビット深度の具体的公称値は今回の取得範囲では明示確認できず → **未確認**。
- **OS 上のデバイス名**:
  - 公式表記: `CABLE Input (VB-Audio Virtual Cable)` / `CABLE Output (VB-Audio Virtual Cable)`（[VirtualCables.htm](https://vb-audio.com/Cable/VirtualCables.htm) のアイコン・ピン名はドライバ内ハードコードと記載）。
  - 配信ソフト・声変換ホストのデバイス選択 UI でも基本同名で露出する（ベンダー公称）。
- **インストール / アンインストール**:
  - 公式手順（[Cable/](https://vb-audio.com/Cable/) および Reference Manual）: ZIP を展開し **管理者権限で Setup を実行 → インストール後に再起動**。アンインストールも **REMOVE 実行後に再起動が必須**（公式）。
  - 更新時は「旧版アンインストール → 再起動 → 新版インストール → 再起動」を推奨（マニュアル）。
- **既知の制約 / FAQ**:
  - Hi-Fi Cable 系の前提として「入出力で同一サンプルレートに揃える必要がある」（[Cable/](https://vb-audio.com/Cable/)）— VB-CABLE 本体側にも内部レート切替 UI があり、配信ホストとの SR ミスマッチ時はコントロールパネルでの調整が必要（マニュアル）。
  - 公式の集約 FAQ ページは今回特定できず、ハマりどころの多くは forum.vb-audio.com に分散している → 詳細は**コミュニティ言及**扱い。
- **未確認事項**:
  - EULA 原文での商用配信の可否区分
  - VB-CABLE 本体のビット深度の公称値
  - マルチクライアント時の挙動の公式記述
  - 公式集約 FAQ ページの有無
- **最終確認日**: 2026-05-12

### 3.2 VoiceMeeter Banana

- **提供元**: VB-Audio Software（Vincent Burel 氏）
- **本書での位置付け**: VoiceMeeter ファミリーの中核。仮想ミキサーと仮想オーディオデバイスが一体になっており、**複数の物理入力 + 仮想入力をミックス**して、複数の出力先（物理スピーカー / 仮想出力デバイス）へルーティングできる。w-okada/voice-changer 公式チュートリアルでも Discord / Zoom 連携用途で名指しで言及されている（[w-okada-voice-changer.md §6.1](./w-okada-voice-changer.md#6-配信ソフトとの連携) 参照）
- **公式情報源:**
  - 製品ページ: <https://vb-audio.com/Voicemeeter/banana.htm>
  - ファミリー一覧: <https://vb-audio.com/Voicemeeter/>
  - ユーザーマニュアル PDF: <https://vb-audio.com/Voicemeeter/VoicemeeterBanana_UserManual.pdf>
  - ARM64 対応プレスリリース（2024-10）: <https://vb-audio.com/archive/Blog/VBAudioPressRelease_Oct2024.htm>
  - Donationware モデル: <https://vb-audio.com/Voicemeeter/Donationware.htm>
  - ライセンス: <https://vb-audio.com/Services/licensing.htm>
- **提供形態 / ライセンス**:
  - VB-Audio 共通の Donationware モデル（[Donationware.htm](https://vb-audio.com/Voicemeeter/Donationware.htm)）。「free to use, with all functions available ... you are expected to pay your license if you find it useful or if you make any professional use」（公式）。
  - ファミリー一覧の評価期間説明: 「After 30 days, Voicemeeter About box will invite you to buy a license or continue to evaluate the program」（[Voicemeeter/](https://vb-audio.com/Voicemeeter/)）。Banana も Standard と同じく Donationware 配布で、Potato のような明示的なアクティベーション必須化はされていない（[Donationware.htm](https://vb-audio.com/Voicemeeter/Donationware.htm) 内で Standard / Banana / Potato の差を区別している）。
  - **商用配信での利用可否は公式 EULA 原文の引用が今回取れていない**ため断定しない（[Services/licensing.htm](https://vb-audio.com/Services/licensing.htm) 側に professional use / volume licensing / 配布契約の存在は記述あり）→ **未確認事項として残す**。
- **動作プラットフォーム**:
  - 製品ページ・ファミリー一覧の公式記述: Windows XP / Vista / 7 / 8 / 8.1 / 10 / 11（32-bit / 64-bit）。
  - **Windows 10/11 ARM64 対応は v2.1.1.8（2024-10）から**（[ARM64 プレスリリース](https://vb-audio.com/archive/Blog/VBAudioPressRelease_Oct2024.htm)）。同タイミングで Windows 11 24H2 対応の VAIO ドライバ更新が行われている。
- **入出力構成**（製品ページ・マニュアル公称）:
  - **5 inputs / 5 Buses / 5 outputs Mixing Console**（[banana.htm](https://vb-audio.com/Voicemeeter/banana.htm) 公式）
  - 物理 / 仮想 内訳: **3x Physical I/O + 2x Virtual I/O**（入力側 3 物理 + 2 仮想、出力側 3 物理 + 2 仮想）。
  - Virtual Audio Point の位置: Input #4 & #5 と BUS B1 / B2（公式マニュアル）。
- **ASIO 対応**: Voicemeeter Banana には専用の **Voicemeeter Virtual ASIO driver** が同梱され、ASIO 出力先として接続できるのは **A1（メイン出力）のみ**（[VoicemeeterBanana_UserManual.pdf](https://vb-audio.com/Voicemeeter/VoicemeeterBanana_UserManual.pdf)）。
- **サンプルレート / ビット深度**:
  - A1（Main Device）の SR が VoiceMeeter Banana 内部 SR を決定（マニュアル）。
  - 公式マニュアル: デフォルトビット深度 24-bit、フォーラム公式回答で 44.1k / 48k / 96k への言及あり。**192 kHz 上限の公式明示は今回未確認**（Potato 製品ページの DSP 仕様は 32〜192 kHz だが Banana 製品ページ側の同等表現は確認できず）→ **未確認**。
- **OS 上のデバイス名**:
  - 旧来表記（マニュアル）: `Voicemeeter Input` / `Voicemeeter Output` / `Voicemeeter AUX Input` / `Voicemeeter AUX Output`。
  - 2024 VAIO ドライバ以降は `Voicemeeter Out B1 / B2` 形式の名称に再編されている旨が forum.vb-audio.com に公式アナウンスあり。本ラボで実機確認した訳ではないため、experiments テンプレに書き起こす際は **インストール版に応じて両表記を許容**する想定（§6 で反映方針を書く）。
- **VoiceMeeter ファミリー内位置付け**（[Voicemeeter/](https://vb-audio.com/Voicemeeter/) 公式比較記述）:
  - Standard: 3 inputs / 3 outputs（2 物理 + 1 仮想 / 2 物理 + 1 仮想）、2 BUS（A/B）、シングルレイヤー
  - Banana: 上記 5×5×5、Integrated Recorder と Full Parametric Equalizer を追加
  - Potato: 「The Ultimate Audio Mixer」。詳細は §3.3
- **インストール / アンインストール**: 管理者権限で Setup → INSTALL → **再起動必須**。アンインストールも REMOVE → 再起動（マニュアル）。不完全な場合は Device Manager から VoiceMeeter Virtual Audio Driver を手動削除（マニュアル）。
- **既知の制約 / FAQ**:
  - 内部 SR は A1 デバイスに従属（マニュアル）。
  - ASIO バッファサイズはマニュアル上 256 推奨、512 がより安定（公式）。
  - Windows 11 24H2 / ARM64 対応は 2024-10 以降の VAIO ドライバ更新が前提。
- **未確認事項**:
  - サンプルレート上限の Banana ページ側の明示
  - 商用配信の可否区分（EULA 原文）
  - 2024 VAIO ドライバ前後でのデバイス名差異を experiments テンプレで両表記許容するかどうかの確定（§6 で別途整理）
- **最終確認日**: 2026-05-12

> VoiceMeeter ファミリーには **Standard / Banana / Potato** の 3 構成があるが、配信用途で実用ラインに乗るのは Banana 以上であるため、本書のコア集合では **Banana / Potato の 2 件**に絞り、Standard には本セクションで一言触れるに留める（[§1.2](#12-対象ツール集合phase-1-で確定) のスコープ外候補に対応）。

### 3.3 VoiceMeeter Potato

- **提供元**: VB-Audio Software（Vincent Burel 氏）
- **本書での位置付け**: VoiceMeeter ファミリー最上位。Banana より入出力本数・バス数が多く、ASIO 周りや内蔵 FX が拡張されている。複雑な配信構成（ゲーム音 + マイク + ボイチェン後音声 + BGM を別々に扱う等）で選ばれる。
- **公式情報源:**
  - 製品ページ: <https://vb-audio.com/Voicemeeter/potato.htm>
  - ファミリー一覧: <https://vb-audio.com/Voicemeeter/>
  - ユーザーマニュアル PDF: <https://vb-audio.com/Voicemeeter/VoicemeeterPotato_UserManual.pdf>
  - Webshop（ライセンス入手）: <https://shop.vb-audio.com/en/win-apps/21-voicemeeter8.html>
  - Donationware モデル: <https://vb-audio.com/Voicemeeter/Donationware.htm>
  - ライセンス: <https://vb-audio.com/Services/licensing.htm>
  - ARM64 対応プレスリリース（2024-10）: <https://vb-audio.com/archive/Blog/VBAudioPressRelease_Oct2024.htm>
- **提供形態 / ライセンス**:
  - 製品ページ公式記述: 「Donationware License! Voicemeeter Potato application is free to use with all functions available (except optional features). You pay what you want when you want if you find it useful.」（[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm)）。
  - Banana との差分（[Donationware.htm](https://vb-audio.com/Voicemeeter/Donationware.htm)）: 「Voicemeeter Standard and Voicemeeter Banana are distributed as simple Donationware, while Voicemeeter Potato is distributed as donationware with an activation code (for your PC only)」（公式）。Potato は試用期間後にアクティベーションコード要求が発生する点が Banana / Standard と異なる。
  - 試用 / アクティベーション: 「After 30 days, Voicemeeter Potato About box will invite you to buy a license or continue to evaluate the program」（[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm) 公式）。アクティベーションは「1 PC につき 1 ライセンス、PC 固有の Challenge Code に対する Response Code 方式」（forum.vb-audio.com 公式 Info）。
  - 価格表記: 製品ページ上には具体的金額の記載なし。Webshop で「複数価格のドネーション式販売」（5 段階）が運用されているが、**5 段階それぞれの数値は本確認時点で原文未取得** → 本ラボ内記述としては「ベンダー表記そのまま」の方針に従い具体額は記載しない。記入が必要になった時点で [Webshop](https://shop.vb-audio.com/en/win-apps/21-voicemeeter8.html) を参照する。
  - **商用配信での利用可否は公式 EULA 原文の引用が今回取れていない**（[Services/licensing.htm](https://vb-audio.com/Services/licensing.htm) に professional use / volume licensing への言及あり）→ **未確認事項として残す**。
- **動作プラットフォーム**（[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm) 公式）:
  - 「XP(SP2), VISTA, WIN7, WIN8, WIN8.1, WIN10/11 (32 / 64 bits)」「WIN11 32/64 bits & ARM64」
  - ARM64 サポートは v3.1.1.8（2024-10）以降（[ARM64 プレスリリース](https://vb-audio.com/archive/Blog/VBAudioPressRelease_Oct2024.htm)、Standard / Banana / Potato それぞれ x.1.1.8 で対応）。
- **入出力構成**（Banana 差分。[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm) 公式）:
  - **8 Inputs (5 physicals / 3 Virtual)** / **8 Outputs (5 physicals / 3 Virtual)** — Banana の 5×5×5 から拡張
  - マニュアル公称: 「8 multichannel busses (A1, A2, A3, A4, A5 & B1, B2, B3)」（[VoicemeeterPotato_UserManual.pdf](https://vb-audio.com/Voicemeeter/VoicemeeterPotato_UserManual.pdf)）。
- **ASIO 対応**（Potato 固有拡張、[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm) 公式）:
  - **3x Virtual ASIO I/O**: ASIO 32 kHz〜192 kHz、8 ch in/out
  - **1x Virtual Insert ASIO I/O**: ASIO 32 kHz〜192 kHz、34 ch in/out
  - 加えてマニュアル記述: 「Voicemeeter virtual INSERT ASIO Driver (there is one for Banana and one for Potato)」「2 true aux to manage external FX with an ASIO device」「6 cells full parametric EQ on every BUS」
- **サンプルレート**:
  - 製品ページ DSP 仕様: 「32, 44.1, 48, 88.2, 96, 176.4 or 192 kHz DSP Processing」（[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm)）。
  - マニュアル補足: 「Main stream (A1) can work in 44.1, 48, 88.2 or 96 kHz」「Internal computation is limited to 96 kHz maximum」「Virtual I/O support 192 kHz but work internally at 96 kHz maximum」（[VoicemeeterPotato_UserManual.pdf](https://vb-audio.com/Voicemeeter/VoicemeeterPotato_UserManual.pdf)）。実効内部処理は **96 kHz 上限**である点を本書では明示しておく。
- **OS 上のデバイス名**（Potato で増える 3 つめの仮想 I/O、マニュアル）:
  - 入力側: `Voicemeeter Input` / `Voicemeeter AUX Input` / `Voicemeeter VAIO3 Input`
  - 出力側: `Voicemeeter Out B1` / `Voicemeeter Out B2` / `Voicemeeter Out B3`
  - 第三 VAIO（呼称「VAIO-3」）は Potato で初登場。
- **インストール / アンインストール / ライセンスキー**:
  - 製品ページ公式手順: 「Run Setup program in administrative mode / Reboot after installation」（[potato.htm](https://vb-audio.com/Voicemeeter/potato.htm)）。
  - アンインストール後の不完全状態は Device Manager から残存ドライバを手動削除して再起動（マニュアル）。
  - アクティベーションは Webshop 経由でライセンス購入 → PC 固有の Challenge Code に対する Response Code 入力（forum.vb-audio.com 公式 Info）。
- **既知の制約 / FAQ**:
  - 内部処理は 96 kHz 上限（マニュアル、上記）。
  - 30 日試用後はアクティベーションを促されるが、未入力でも継続評価は可能（公式）。
  - Banana 同様、内部 SR は A1 デバイスに従属。
- **未確認事項**:
  - Webshop 5 段階の具体的価格表記（USD / EUR / JPY）
  - 商用配信での EULA 上の取り扱い（professional use の具体的線引き）
- **最終確認日**: 2026-05-12

### 3.4 BlackHole

- **提供元**: Existential Audio Inc.（Devin Roth 氏）
- **本書での位置付け**: macOS 向け仮想オーディオドライバ。GitHub README で「modern macOS virtual audio loopback driver」と位置付けられている。チャンネル数違いの 3 バリエーション（**BlackHole 2ch / 16ch / 64ch**）が配布されている。Soundflower の後継として広く参照されているが、Soundflower 側 / BlackHole 側のいずれの README にも「公式に推奨」という双方向の明示記述は確認できなかった（[§3.5](#35-soundflower補足) と合わせて、ポジションは「コミュニティで一般に言われている」レベルで扱う）。
- **公式情報源:**
  - 製品ページ: <https://existential.audio/blackhole/>
  - GitHub リポジトリ: <https://github.com/ExistentialAudio/BlackHole>
- **提供形態 / ライセンス**:
  - **GPL-3.0 license**（GitHub リポジトリのライセンス表示・README フッター）。オープンソース。
  - 配布: 公式インストーラ（製品ページからメールフォーム経由でダウンロード）または Homebrew（後述）。
- **動作プラットフォーム**（README 公式記述）:
  - 「Compatible with macOS 10.10 Yosemite and newer」
  - 「Builds for Intel and Apple Silicon」 — Apple Silicon 公式対応。
- **2ch / 16ch / 64ch の差分**:
  - 公式 README は機能差分を明示せず、**チャンネル数の差**のみを示している（Homebrew 経由の場合）:
    - `brew install blackhole-2ch`
    - `brew install blackhole-16ch`
    - `brew install blackhole-64ch`
  - 注意書き: 「Be careful when specifying high channel counts.」（README）
  - 3 つを並行インストールして併用することも可能（README）。
- **サンプルレート / ビット深度**（README 公式記述）:
  - サンプルレート: 「8kHz, 16kHz, 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz, 352.8kHz, 384kHz, 705.6kHz and 768kHz」
  - ビット深度: 「BlackHole uses 32-bit float bit depth since macOS Core Audio natively uses 32-bit at the system level.」
- **OS 上のデバイス名**:
  - macOS の Audio MIDI Setup / Sound Preferences / 各オーディオアプリの入出力一覧に表示される（README）。バリエーション名（`BlackHole 2ch` / `BlackHole 16ch` / `BlackHole 64ch`）でそのまま露出する（ベンダー公称、Homebrew パッケージ名と一致）。
- **Aggregate Device / Multi-Output Device**（README FAQ）:
  - 「Due to issues with macOS the Built-in Output must be enabled and listed as the top device in the Multi-Output.」
  - 「You need to enable drift correction for all devices except the Clock Source.」
  - AirPods のマイクは低サンプルレートで動作するため Aggregate の Primary には置かない、と FAQ で明示。
  - 既知の非互換アプリ: Apple Podcasts / Apple Messages / HDHomeRun（README）。
- **インストール / アンインストール**:
  - インストール: 公式インストーラを開く前にオーディオアプリをすべて閉じ、`.pkg` を実行し、システムを再起動（README）。または Homebrew (`brew install blackhole-[2ch|16ch|64ch]`)。
  - アンインストール: 公式アンインストーラ、または手動で `rm -R /Library/Audio/Plug-Ins/HAL/BlackHoleXch.driver`（X はチャンネル数）→ `sudo killall -9 coreaudiod`（README）。
- **既知の制約 / FAQ**（README）:
  - 「Certain versions of macOS have a known issue where install packages may fail」 — `.pkg` を別フォルダへ移動する回避手順あり。
  - 「Multi-outputs can be buggy and some apps won't work with them at all.」
  - 「macOS does not support changing the volume of a Multi-Output device.」
  - 長時間使用時の音切れは Aggregate の drift correction 設定で改善する旨が公式 FAQ に記載。
- **未確認事項**:
  - 2ch / 16ch / 64ch の用途別ガイダンスの公式記述（README は機能差分を明示せず、配信用途で 2ch / 16ch のどちらを推すかは公式に書かれていない）
  - 商用配信での GPL-3.0 適用範囲（ドライバ単体利用は GPL の通常理解で許容されるが、配信ソフトと組み合わせた配信物に GPL のコピーレフトが波及するかは公式に明示されておらず、本書では断定しない）
- **最終確認日**: 2026-05-12

### 3.5 Soundflower（補足）

- **提供元**: Cycling '74（原作）→ Matt Ingalls（メンテナ）
- **本書での位置付け**: macOS 旧。BlackHole 以前に広く使われていた仮想オーディオドライバ。**本書では配信用途での新規採用には推奨しない方針**で扱う（理由は下記の公式記述）。
- **公式情報源:**
  - レガシーリポジトリ: <https://github.com/mattingalls/Soundflower>
  - 最終 Release: <https://github.com/mattingalls/Soundflower/releases/tag/2.0b2>
- **メンテナンス状況**:
  - README 冒頭に **「DEPRECATED Silicon Macs are not supported. New version coming shortly!」** と公式表記（GitHub のアーカイブフラグは立っていないが、README 上で DEPRECATED 宣言済み）。
  - 最終 Release: **2020-12-19、v2.0b2（"Signed Version for macOS Big Sur (11.1) and earlier"）**。Releases 一覧全 2 件（`2.0b1` 2020-12-01 / `2.0b2` 2020-12-19）。
  - master ブランチの最新コミットは 2024-12-07 だが README 編集のみで、コードベース自体は 2020 年以降更新が止まっている。
- **ライセンス**: **MIT License**（README 記載: 「Soundflower is licenced under the MIT licence.」）。
- **対応 macOS バージョン**:
  - 最終リリース `2.0b2` タイトル: 「Signed Version for **macOS Big Sur (11.1) and earlier**」
  - Apple Silicon: 「**M1 chip-based Macs are NOT YET SUPPORTED**」（Release notes）/「Silicon Macs are not supported」（README 冒頭）
- **BlackHole 等への移行に関する公式記述**:
  - README / Issues / Wiki いずれにも **「BlackHole を使ってほしい」のような明示的な誘導は見当たらない**。README は「New version coming shortly!」とだけ書き、代替案・タイムラインは提示していない。
  - Soundflower 側からの公式誘導が無い点は明確化しておく（コミュニティで広く「BlackHole 後継」と語られる経緯はあくまでコミュニティ言及）。
- **配布形態**: GitHub Releases のバイナリ（署名済み `.pkg` インストーラ）のみ。独立した公式サイトは無し。
- **本書での扱い**: 新規導入は推奨しない（Apple Silicon 非対応 + コード更新が 2020 年で停止 + README に DEPRECATED 表記）。macOS では §3.4 BlackHole を本ラボの標準として扱う。
- **最終確認日**: 2026-05-12

### 3.6 Linux PulseAudio / PipeWire の仮想シンク（参考）

- **提供元**: PulseAudio は freedesktop.org / PipeWire は PipeWire プロジェクト（freedesktop.org ホスト）
- **本書での位置付け**: 参考扱い。本ラボのメイン環境（Windows / macOS）と異なるが、Linux で配信を組む場合の同等経路として 1 段落でまとめる。実機検証はスコープ外。
- **公式情報源:**
  - PulseAudio Modules ドキュメント: <https://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/Modules/>
  - PipeWire 本家: <https://pipewire.org/>
  - PipeWire Loopback モジュール: <https://docs.pipewire.org/page_module_loopback.html>
  - `pw-loopback` man: <https://docs.pipewire.org/page_man_pw-loopback_1.html>
  - PipeWire 内の Pulse 互換 `module-null-sink`: <https://docs.pipewire.org/page_pulse_module_null_sink.html>
  - PipeWire PulseAudio 互換: <https://docs.pipewire.org/page_pulseaudio.html>
  - PipeWire Pulse モジュール対応状況: <https://docs.pipewire.org/page_pulse_modules.html>
- **PulseAudio の仮想シンク**:
  - `module-null-sink` は **「データを silently に drop する null sink」を作る**モジュール（公式 Modules ドキュメント）。全 sink には**モニターソース**（"monitor" source）が自動で対応付くため、null sink は「アプリ A の出力をアプリ B の入力に流す」プラミング先として実用される。
  - 公式に列挙されている引数: `sink_name=<name>` / `sink_properties` / `format` / `rate` / `channels` / `channel_map`。代表コマンド: `pactl load-module module-null-sink sink_name=<name>`。
- **PipeWire の仮想ノード**:
  - Loopback モジュール（公式 `page_module_loopback.html`）: キャプチャストリームの出力を再生ストリームへそのまま渡す。**source / sink を繋ぐ用途だけでなく、新規の仮想 sink / 仮想 source を作る用途**にも使えると公式に明記。
  - `pw-loopback` クライアント（公式 man）でも同モジュールを呼び出して loopback ノードを作れる。
  - PulseAudio の `module-null-sink` 相当は PipeWire の Pulse 互換レイヤーで実装済み（公式 `page_pulse_module_null_sink.html`）。
- **PulseAudio API 互換**:
  - `pipewire-pulse` は **PulseAudio デーモンの drop-in replacement** であり、`pactl` / `pavucontrol` / `paplay` 等の既存ツールがそのまま動く（公式 `page_pulseaudio.html`）。
- **配信ソフト連携（1 行参考）**:
  - OBS Studio Linux 版は PulseAudio をネイティブの音声入出力キャプチャ元として扱っており、PipeWire 環境でも `pipewire-pulse` 互換レイヤー経由で同じ経路が利用できる（OBS 側ドキュメントの裏取りは次タスク「OBS Studio との接続パターンまとめ」のスコープ）。
- **既知の制約 / 注意**:
  - PipeWire の Pulse 互換層は**ビルトインの Pulse モジュールのみ**を実装しており、PulseAudio 用に書かれた外部モジュールはロードできない（公式 `page_pulse_modules.html`）。Linux 環境での声変換経路を組む際の互換性境界。
- **未確認事項**:
  - ディストリビューション固有のパッケージ名 / systemd ユニット名（本書スコープ外）
  - OBS Linux 版での PulseAudio / PipeWire 経路の OBS 側公式推奨記述（次タスクで裏取り）
- **最終確認日**: 2026-05-12

## 4. 横断棚卸し表

§3 で個別エントリを書いた 6 件（コア集合 4 件 + 補足 2 件）を、§2 評価項目の主要カラムで横並びに比較する。**配信用途でそもそも候補に入るか / 入らないか**の足切り判断を 1 表で出すことを優先し、各セルは公式情報源で裏取りした要点のみを抜粋する。詳細・出典・原文引用は §3 各エントリを参照。

### 4.1 ツール × 評価項目マトリクス

| 評価項目 | VB-CABLE | VoiceMeeter Banana | VoiceMeeter Potato | BlackHole | Soundflower（補足） | Linux PA/PW（参考） |
| --- | --- | --- | --- | --- | --- | --- |
| 公式情報源 | [vb-audio.com/Cable/](https://vb-audio.com/Cable/) | [banana.htm](https://vb-audio.com/Voicemeeter/banana.htm) | [potato.htm](https://vb-audio.com/Voicemeeter/potato.htm) | [existential.audio/blackhole/](https://existential.audio/blackhole/) | [mattingalls/Soundflower](https://github.com/mattingalls/Soundflower) | [PulseAudio Modules](https://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/Modules/) / [PipeWire](https://pipewire.org/) |
| 提供形態 | Donationware | Donationware | Donationware（30 日後アクティベーション要求） | OSS（GPL-3.0） | OSS（MIT、**DEPRECATED**） | OSS（PA / PW 各プロジェクト準拠） |
| 動作プラットフォーム | Win XP〜11 32/64/ARM64（新パッケージ）／Mac 10.10+ Intel/AS（別 SKU） | Win XP〜11 32/64／ARM64 は **v2.1.1.8（2024-10）+** | Win XP〜11 32/64／ARM64 は **v3.1.1.8（2024-10）+** | macOS 10.10+、**Intel / Apple Silicon 両対応** | macOS Big Sur (11.1) 以前のみ。**M1 chip-based Macs NOT YET SUPPORTED** | Linux 全般 |
| 仮想 IO ペア構成 | **1 ペア**（Input → Output）。追加 SKU で +2/+2 ペア | **5×5×5**、仮想 I/O 2 ペア + バス（B1/B2）、ASIO は A1 のみ | **8×8×8**、仮想 I/O 3 ペア + バス（B1/B2/B3）、Virtual ASIO 3 + Insert ASIO 1 | バリエーション **2ch / 16ch / 64ch**。並行インストール可 | バリエーション **2ch / 64ch** | `module-null-sink` / `pw-loopback` で動的生成 |
| ミキサー機能 | なし（純粋な仮想ケーブル） | あり（5 入力ミックス + 内蔵 Recorder + Parametric EQ） | あり（8 入力ミックス + Virtual Insert ASIO + 6-cell EQ + 2 AUX 等） | なし（loopback driver のみ） | なし | アプリ側（`pavucontrol` 等） |
| サンプルレート | 8 k〜192 kHz、最大 8 ch（MME/WASAPI/KS、Reference Manual）。ビット深度の公称値は本書では未確認 | A1 の SR に従属。マニュアル / フォーラムで 44.1k / 48k / 96k 言及。192k 上限の Banana 側明示は未確認 | DSP 表記 **32, 44.1, 48, 88.2, 96, 176.4, 192 kHz**。**内部処理は 96 kHz 上限**（マニュアル） | **8 k〜768 kHz**、**32-bit float** | macOS Core Audio 経由（旧版） | 引数 `rate=` で指定 |
| OS 上のデバイス名（公式記述） | `CABLE Input (VB-Audio Virtual Cable)` / `CABLE Output (...)` | `Voicemeeter Input` / `Voicemeeter AUX Input` / `Voicemeeter Out B1` / `Voicemeeter Out B2`（2024 VAIO ドライバ前後で名称再編あり） | 上記 +`Voicemeeter VAIO3 Input` / `Voicemeeter Out B3` | `BlackHole 2ch` / `BlackHole 16ch` / `BlackHole 64ch` | `Soundflower (2ch)` / `Soundflower (64ch)` | `sink_name=` で任意 |
| 商用配信での利用可否（公式明示） | **公式記述なし**（Donationware の professional use 言及はあるが配信用途の名指しは未確認） | **公式記述なし**（Banana も professional use の表現あるが配信用途の名指しは未確認） | **公式記述なし**（Potato は professional use はアクティベーション必須運用） | **公式記述なし**（GPL-3.0 のドライバ単体利用） | MIT。ただし**新規採用は非推奨**（DEPRECATED） | 各モジュールのライセンス準拠 |
| 既知の制約（公式 FAQ） | Hi-Fi Cable 系は入出力 SR 一致が必須（VB-CABLE 本体も内部 SR 切替 UI あり）／公式集約 FAQ ページは未特定 | 内部 SR は A1 に従属／ASIO バッファは 256 推奨・512 がより安定／Win11 24H2・ARM64 対応は 2024-10 以降の VAIO ドライバ前提 | 内部処理は 96 kHz 上限／30 日試用後アクティベーション要求／A1 SR 従属は Banana と共通 | Multi-Output は Built-in Output を Top に・drift correction 推奨／既知非互換アプリ: Apple Podcasts/Messages, HDHomeRun／一部 macOS で `.pkg` 不具合あり | DEPRECATED 表記／Apple Silicon 非対応／コード更新は 2020 年で停止 | PipeWire Pulse 互換層は **builtin Pulse モジュールのみ**実装、外部 Pulse モジュールはロード不可 |
| 最終確認日 | 2026-05-12 | 2026-05-12 | 2026-05-12 | 2026-05-12 | 2026-05-12 | 2026-05-12 |

### 4.2 OS × ツール早見表（足切り判断）

「配信ホスト OS が決まっているとき、まず候補に入れるのはどれか」の一次フィルタとして使う。本ラボのメイン環境は Windows / macOS のため、Linux は参考扱い。

| OS | 第一候補（実用ラインで使われるもの） | 補足候補 / 注意 |
| --- | --- | --- |
| **Windows 10 / 11（x64）** | **VB-CABLE**（単純経路）／**VoiceMeeter Banana**（複数音源を混ぜる）／**VoiceMeeter Potato**（更に本数増 + ASIO） | VB-CABLE は 1 ペア固定。本数が必要なら追加 SKU（A+B / C+D）または Banana 以上 |
| **Windows 11 ARM64** | **VB-CABLE 新パッケージ**（XP〜11 32/64/ARM64）／**VoiceMeeter Banana v2.1.1.8+**／**Potato v3.1.1.8+** | 旧 VB-CABLE パッケージ / 旧 VoiceMeeter は ARM64 非対応 → バージョン要確認 |
| **macOS（Intel）** | **BlackHole 2ch / 16ch / 64ch**（GPL-3.0 / loopback driver） | VB-CABLE for Mac（別 SKU）も同社が配布。Soundflower は **DEPRECATED で新規採用非推奨**（§3.5） |
| **macOS（Apple Silicon）** | **BlackHole 2ch / 16ch / 64ch**（Intel / Apple Silicon 両対応） | VB-CABLE for Mac は公式記述で Apple Silicon 対応／Soundflower は **M1 chip-based Macs NOT YET SUPPORTED** で対象外 |
| **Linux（PA / PW）** | （参考）`module-null-sink` / `pw-loopback` / Pulse 互換 `module-null-sink` | 本ラボでは実機検証スコープ外。詳細は §3.6 |

「ミキサーが要らない単純な 1 経路」は OS 横断でも仮想ケーブル単体（VB-CABLE / BlackHole）で十分。「複数音源を混ぜる」「ASIO で低遅延に組む」「3 本以上の独立経路が必要」のいずれかが必要になった時点で、**Windows なら VoiceMeeter Banana → Potato への昇格**を検討する、というのが本書の基本判断ライン。

### 4.3 表の使い方（足切りの一例）

- **配信先の OS が決まっていて、まず候補を絞りたい** → §4.2 で OS 行を選び、第一候補から検討する。
- **必要な仮想 IO ペア本数で足切りしたい** → §4.1 「仮想 IO ペア構成」行。1 経路なら VB-CABLE / BlackHole で十分、複数音源を混ぜるなら VoiceMeeter ファミリー。
- **商用配信での EULA を厳密に確認したい** → 本書だけでは判断材料が揃わない。§4.1「商用配信での利用可否」行はいずれも「公式記述なし」または「未確認」になっているため、配信プラットフォームの規約（YouTube / Twitch / niconico 等）と各ツールの最新 EULA を**別途**確認する。本書では断定しない（[CLAUDE.md](../../CLAUDE.md) 方針）。
- **macOS 向けの選定** → 新規採用は **BlackHole 一択**（コア集合）。Soundflower は DEPRECATED で非推奨であることが公式 README で明示されている（§3.5）。

## 5. 配信用途での典型構成

§4 の足切りを通った構成を、`マイク → 声変換ホスト → 仮想オーディオデバイス → 配信ソフト / 通話ソフト` の経路図レベルで 4 パターンに分けて示す。OBS 側の音声入力キャプチャの内部設定値・モニタリング詳細・遅延ハンドリングは**本書のスコープ外**で、次タスク「OBS Studio との接続パターンまとめ」が本節を前提にする想定。

各パターンの「声変換ホスト」は [w-okada-voice-changer.md](./w-okada-voice-changer.md) を主な想定として書く（[§5.2 input / output / monitor の 3 デバイス構成](./w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537)）。他の OSS 声変換ホスト（[RVC](./rvc.md) / [so-vits-svc](./so-vits-svc.md) / [Beatrice](./beatrice.md) を単体で動かす場合）でも、IO 構成 UI が同等であれば経路図は同じ。

### 5.1 P1: シングル仮想ケーブル経路（Windows / macOS、最小構成）

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
                  [配信ソフト or 通話ソフト の音声入力キャプチャ]
```

- **使う仮想デバイス**: Windows なら **VB-CABLE 1 ペア**、macOS なら **BlackHole 2ch**（§4.1）。
- **特徴**: 1 経路のみ。声変換した音を別アプリへ渡すための最小構成。
- **前提**: 声変換ホストの **input / output / monitor 3 デバイス分離**が使えること（w-okada §5.2、v.1.5.3.7+）。VC Client のサンプリングレートを「3 デバイス間で一致」させる必要がある（同公式制約）。
- **足切り**: ゲーム音 / BGM 等の他音源を混ぜる必要があるなら P2 へ。
- **OBS 側の設定**: [obs-studio.md §5.1 P1 × OBS](./obs-studio.md#51-p1--obs-シングル仮想ケーブル経路windows--macos最小構成) を参照（音声入力キャプチャ ソース / Settings → Audio / Audio Monitoring Device / Sync Offset）。

### 5.2 P2: VoiceMeeter ハブ経路（Windows、複数音源を混ぜる）

```
[マイク] ─▶ [声変換ホスト] ──▶ [Voicemeeter Input / AUX Input (仮想入力)]
                                        ▼
[ゲーム音 / BGM 等] ───────────────▶ [Voicemeeter Bus B1 (仮想出力)]
                                        │
                                        ▼
                            [配信ソフト の音声入力キャプチャ]
                                        ▲
[Voicemeeter Bus A1 (物理出力)] ───▶ [物理ヘッドホン]
```

- **使う仮想デバイス**: **VoiceMeeter Banana**（5×5×5、入力 3 物理 + 2 仮想 / 出力 3 物理 + 2 仮想）または **Potato**（8×8×8、+ Virtual Insert ASIO / 6-cell EQ）。
- **特徴**: VoiceMeeter のミキサーで「声変換後のマイク」と「ゲーム音 / BGM」を 1 つの仮想出力 B1 に合流させる。配信ソフト側は B1 を 1 つ拾えば良い。
- **前提**: 内部 SR は **A1（メイン物理出力）に従属**するため、A1 のサンプリングレートを声変換ホストと揃える（[§3.2](#32-voicemeeter-banana) / [§3.3](#33-voicemeeter-potato)）。
- **足切り**: 「**マイク経路と配信に出る音を完全に分けたい**」「**自分用モニタには素のマイクも混ぜたい**」など、3 系統以上の独立経路が必要なら P3 へ。
- **OBS 側の設定**: [obs-studio.md §5.2 P2 × OBS](./obs-studio.md#52-p2--obs-voicemeeter-ハブ経路windows複数音源を混ぜる) を参照（B1 / B2 のソース割り / multi-track 録画 / Audio Monitoring Device は基本未設定）。

### 5.3 P3: monitor 分離経路（Windows、低遅延モニタリング Tip）

```
[マイク] ─▶ [声変換ホスト]
                 │
                 ├─ output  ──▶ [VB-CABLE / VoiceMeeter Input] ──▶ [配信ソフト]
                 │
                 └─ monitor ──▶ [WASAPI / ASIO 物理出力 (直接)] ──▶ [物理ヘッドホン]
```

- **使う仮想デバイス**: 配信用には **VB-CABLE** または **VoiceMeeter** いずれか。**モニタには仮想デバイスを挟まない**（=ここが本パターンの肝）。
- **特徴**: w-okada §5.2 の公式 Tip「**Input, Monitor を WASAPI デバイス、output を任意にすることで遅延をかなり少なく運用することができました**」を素直に組んだ形。配信パス（仮想ケーブル経由）と自分用モニタパス（WASAPI/ASIO 直接）を独立させ、モニタ側に仮想デバイスのオーバーヘッドが乗らないようにする。
- **前提**: 声変換ホストの **v.1.5.3.7+** で 3 デバイス分離 UI が使えること。サンプリングレート 3 デバイス一致の制約は P1 と同じ。
- **macOS 等価**: 同じ発想で「output→BlackHole」「monitor→Built-in Output（CoreAudio 直接）」とすれば同じ構造になる（ホスト側 UI が monitor を 3 つめのデバイスとして許容することが前提）。
- **OBS 側の設定**: [obs-studio.md §5.3 P3 × OBS](./obs-studio.md#53-p3--obs-monitor-分離経路windows低遅延モニタリング-tip) を参照（OBS 側 Monitor は全ソース Off / Audio Monitoring Device は仮想ケーブルを絶対に選ばない / [Issue #4531](https://github.com/obsproject/obs-studio/issues/4531) のモニタ側バッファ蓄積問題からも遠ざかる設計）。

### 5.4 P4: macOS BlackHole + Multi-Output 経路（macOS、自分用モニタリング併用）

```
[マイク] ─▶ [声変換ホスト]
                 │
                 └─ output ──▶ [Aggregate / Multi-Output Device]
                                       │
                                       ├──▶ [Built-in Output (Top)] ──▶ [物理ヘッドホン]
                                       │
                                       └──▶ [BlackHole 2ch / 16ch] ──▶ [配信ソフト]
```

- **使う仮想デバイス**: **BlackHole**（2ch で 1 経路、16ch 以上でアプリ別の独立経路を切りたい場合）。
- **特徴**: macOS の Audio MIDI Setup で **Multi-Output Device** を組み、Built-in Output（物理ヘッドホン）と BlackHole を同時に出力先にする。配信ソフトは BlackHole を音声入力キャプチャ元として拾い、配信者自身は Built-in 経由でモニタする。
- **前提（BlackHole 公式 FAQ）**: Multi-Output Device は **Built-in Output を最上位（Top）に置き、Clock Source 以外は drift correction を有効に**する。AirPods のマイクは Aggregate の Primary に置かない（[§3.4](#34-blackhole) FAQ）。Multi-Output は macOS の制約でボリューム調整が効かない点も公式記述。
- **足切り**: 「**配信先で受け取る音と自分のヘッドホンで聞く音を、ボリュームバランスを変えて出したい**」場合は Multi-Output だけでは制御幅が足りない。VoiceMeeter 同等の柔軟さが macOS で必要になった時点で、**Loopback (Rogue Amoeba) などの有償アプリ**を候補に挙げる（§7 スコープ外候補）。
- **OBS 側の設定**: [obs-studio.md §5.4 P4 × OBS](./obs-studio.md#54-p4--obs-macos-blackhole--multi-output-経路macos自分用モニタリング併用) を参照（音声入力キャプチャ ソース = BlackHole 2ch / Audio Monitoring Device は Built-in Output を選び、**Multi-Output Device 自体は選ばない**）。

### 5.5 パターン選択の指針

| 必要要件 | 選ぶパターン |
| --- | --- |
| 1 経路で配信ソフトに渡せれば十分（最小構成） | P1（VB-CABLE / BlackHole 2ch） |
| ゲーム音 / BGM などを 1 つの配信出力に合流させたい（Windows） | P2（VoiceMeeter Banana 以上） |
| モニタリングを低遅延に保ちつつ配信ソフトには仮想ケーブルで渡す | P3（w-okada 3 デバイス分離 + 仮想ケーブル分離） |
| macOS で自分用モニタと配信用出力を併用する | P4（BlackHole + Multi-Output Device） |
| アプリ別に独立した経路を 3 本以上組みたい（Windows） | P2 を **Potato** で組む（VAIO3 / B3 を活用） |

経路図と本ラボの記録テンプレ ([experiments/w-okada-voice-changer/_template.md §3.2 IO デバイス](../../experiments/w-okada-voice-changer/_template.md)) を対応付けると、実測ログで「どのパターンで測ったか」が一意に書ける状態になる（§6.4 で更新差分を提示する）。

## 6. 上流ドキュメントへの反映方針

本書の成果物を、これまで「仮想オーディオデバイス＝名前出しのみ」で止まっていた箇所に反映する。本 Phase 3 で**本書から見て参照されるべき側の更新を実施した上で**、それぞれの差分要旨を以下に残す（後から経緯を辿るための記録）。

### 6.1 voice-changer-types §2 補助カテゴリ「周辺ツール」への反映

**Before（現行）**: 「代表例: VB-CABLE, VoiceMeeter Banana / Potato, BlackHole (macOS), Soundflower (旧 macOS)」と**名前出しのみ**。

**After**: 名前出しの直後に本書 [virtual-audio-devices.md](./virtual-audio-devices.md) への参照を追記し、**横断棚卸し表へのリンク**を張る。Soundflower の DEPRECATED 状態（[§3.5](#35-soundflower補足)）も name-only 段階で誤誘導しないよう一言補足する。

更新後の文面方針（[voice-changer-types §補助カテゴリ](./voice-changer-types.md#補助カテゴリ-周辺ツール)）:

> 仮想オーディオデバイス（変換後の音声を配信ソフトに渡すための仮想ケーブル）
>   - 代表例: VB-CABLE, VoiceMeeter Banana / Potato, BlackHole (macOS)。横断棚卸しは [virtual-audio-devices.md](./virtual-audio-devices.md) を参照（最終確認日 2026-05-12）
>   - Soundflower は macOS Big Sur 以前のレガシー扱いで、本ラボでの新規採用は非推奨（[§3.5](./virtual-audio-devices.md#35-soundflower補足)）

### 6.2 voice-changer-types §4 評価軸「入出力構成」「エコシステム」行への反映

「入出力構成」「エコシステム」両行の脚注として、本書の §4 横断棚卸し表 / §5 配信用途の典型構成を**参照先として明示**する。これで個別ツール調査ページが「入出力構成: 仮想オーディオデバイスは [virtual-audio-devices.md §4](./virtual-audio-devices.md#4-横断棚卸し表) のラベル参照」と書ける土台が揃う。

### 6.3 w-okada-voice-changer.md §6 配信ソフトとの連携への反映

[§6.3 本ラボでの一般論整理](./w-okada-voice-changer.md#63-本ラボでの一般論整理公式言及ではない) で「VC Client の output を仮想オーディオデバイス（VB-CABLE / VoiceMeeter Banana・Potato / BlackHole 等）に流し」と**名前出し**している段落に、本書 §4 横断棚卸し表 / §5 P1〜P4 の典型構成へのリンクを追加する。w-okada §9.1 既存タスク引き継ぎ欄の「仮想オーディオデバイス選定の比較軸」行にも本書を相互参照として張る。

### 6.4 experiments/w-okada-voice-changer/_template.md への反映

§2.2 音声機器の「仮想オーディオデバイス（種別・バージョン）」欄を、本書 §4 のラベル参照に揃える。さらに §6 配信ソフト連携の「VCClient output → 仮想オーディオデバイス → 配信先の経路」欄に、本書 §5 の P1〜P4 から選んで記入する形を案内する。

更新後の文面方針（テンプレ）:

> 仮想オーディオデバイス（種別・バージョン）: `<VB-CABLE / VoiceMeeter Banana / VoiceMeeter Potato / BlackHole 2ch / BlackHole 16ch / BlackHole 64ch / その他>`。最終確認日と公式情報源は [virtual-audio-devices.md §4](../../docs/specs/virtual-audio-devices.md#4-横断棚卸し表) 参照
> 経路パターン: `<P1: シングル仮想ケーブル / P2: VoiceMeeter ハブ / P3: monitor 分離 / P4: BlackHole + Multi-Output>`（[virtual-audio-devices.md §5](../../docs/specs/virtual-audio-devices.md#5-配信用途での典型構成)）

### 6.5 反映の境界（本書で扱わない上流）

- **OBS Studio の音声入力キャプチャ設定 / モニタリング設計 / 配信出力のサンプリングレート整合** は、本書ではなく次タスク **「OBS Studio との接続パターンまとめ」**のスコープ。経路図レベルで「仮想ケーブルがどこに刺さるか」までは P1〜P4 で示したので、次タスクは本書を前提に **OBS 側の設定値とモニタリング**を埋めることで成立する。
- **ノイズ抑制 / ゲート系**（NVIDIA Broadcast / Krisp / RNNoise）は [voice-changer-types §2 補助カテゴリ](./voice-changer-types.md#補助カテゴリ-周辺ツール) の別レイヤー。本書では触れない（§7 後続タスク候補）。

## 7. 未確認事項 / 後続タスク

### 7.1 本書のコア集合エントリで残った未確認事項

§3 各エントリの「未確認事項」を、後で個別に裏取りすべき粒度で集約する。実運用で困った時点で個別タスクへ昇格する。

- **VB-CABLE の EULA 原文での商用配信可否区分** / 本体ビット深度の公称値 / マルチクライアント時の挙動の公式記述 / 公式集約 FAQ ページの有無（[§3.1](#31-vb-cable)）
- **VoiceMeeter Banana / Potato の EULA 原文での商用配信可否区分**（Banana / Potato 共通。VB-Audio の Donationware モデルでの「professional use」線引きの原文）（[§3.2](#32-voicemeeter-banana) / [§3.3](#33-voicemeeter-potato)）
- **VoiceMeeter Banana のサンプルレート上限の公称値**（Banana 製品ページ側に Potato 同等の 192 kHz 表記があるかどうか）（[§3.2](#32-voicemeeter-banana)）
- **VoiceMeeter 2024 VAIO ドライバ前後でのデバイス名差異の確定**（旧来表記 `Voicemeeter Input` 系と新表記 `Voicemeeter Out B1/B2` 系を、experiments テンプレで両表記許容するかの方針）（[§3.2](#32-voicemeeter-banana)）
- **VoiceMeeter Potato の Webshop 5 段階の具体的価格表記**（USD / EUR / JPY の各段階）（[§3.3](#33-voicemeeter-potato)）
- **BlackHole の 2ch / 16ch / 64ch の用途別ガイダンス**（公式 README は機能差分を明示せず、配信用途で 2ch / 16ch のどちらを推すかは公式記述なし）／**配信物への GPL-3.0 のコピーレフト波及範囲**（[§3.4](#34-blackhole)）

### 7.2 スコープ外候補（§1.2 で名前のみ残したもの）

本書のコア集合（VB-CABLE / VoiceMeeter Banana・Potato / BlackHole）で足りないユースケースが出てきた時点で、本書の評価軸（§2）を当てはめて棚卸しする対象。Phase 3 時点では着手しない。

- **VoiceMeeter Standard**（VB-Audio。VoiceMeeter ファミリーの最小構成。3×3 + 1 仮想 I/O）
- **VB-CABLE A+B / VB-CABLE C+D / Hi-Fi Cable（+ ASIO Bridge）**（VB-Audio。複数本の仮想ケーブルを組むときの追加 Donationware 製品）
- **Virtual Audio Cable (VAC)**（Eugene Muzychenko 製、Windows 向け有償の仮想ケーブル）
- **Loopback**（Rogue Amoeba 製、macOS 向け有償のオーディオルーティング。**P4 で VoiceMeeter 同等の柔軟さが macOS で必要になった場合の昇格候補**として §5.4 で言及）
- **Wave Link**（Elgato 製、Windows / macOS 向けミキサー兼仮想デバイス）
- **JACK Audio Connection Kit**（クロスプラットフォームの pro-audio ルーティング基盤）

### 7.3 後続タスク（`TODO.md` に上げるべき項目）

本書を前提に次に着手する候補。優先度の高いものから:

- **[高] OBS Studio との接続パターンまとめ**（既に `TODO.md` 配信周辺ツール調査セクションに起票済み）。本書 §4 / §5 を前提に、OBS の「音声入力キャプチャ」設定値・モニタリング・配信出力のサンプリングレート整合・遅延ハンドリングを埋める。本書 §6.5 で境界を明示済み。
- **[中] ノイズ抑制 / ゲート系（NVIDIA Broadcast / Krisp / RNNoise）の棚卸し**（[voice-changer-types §2 補助カテゴリ](./voice-changer-types.md#補助カテゴリ-周辺ツール) のうち別レイヤー）。配信周辺ツール調査シリーズの第 3 弾として起票候補。本書と同じ「公式情報源ベースの横断棚卸し」の立て付けで書ける見込み。
- **[低] 通話アプリ（Discord / Zoom）固有の仮想デバイス取り回し**。w-okada §6.1 でも Voicemeeter 経由の Discord / Zoom 連携が公式言及されており、配信ソフトとは別系統で深掘りすべき余地がある。配信周辺ツール調査が一通り済んだ後の候補。
- **[低] スコープ外候補（[§7.2](#72-スコープ外候補12-で名前のみ残したもの)）の個別棚卸し**。コア集合で足りないユースケースが出てきた時点で初めて昇格させる方針なので、現時点では `TODO.md` への起票はしない（候補プールとして本書 §7.2 に残す）。
