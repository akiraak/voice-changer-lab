# クラウド SaaS のリアルタイム入力対応棚卸し

> [voice-changer-types §2.3 クラウド SaaS / API](./voice-changer-types.md#23-クラウド-saas--api) の代表例リスト（CoeFont / Resemble AI / ElevenLabs / Voice.ai）を、**配信ソフトに流せるリアルタイム入力ストリーム**として実用になるかの観点で棚卸しする。
>
> 本ページは [docs/plans/cloud-saas-realtime.md](../plans/cloud-saas-realtime.md) のスコープに沿って、各 SaaS の**公式情報源**（公式サイト / 公式ドキュメント / 公式 API リファレンス / 公式プライシング）に書かれている内容を中心に**複数 SaaS の横断棚卸し**を行う。
> [rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md) / [w-okada-voice-changer.md](./w-okada-voice-changer.md) と異なり、**1 ツール深掘りではなく複数 SaaS の横断棚卸し**である点を冒頭で明示する。
> 各項目で「公式に書かれている内容」「ベンダー公称値」「コミュニティで一般に言われている内容」「未確認」を区別する。実測値は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）。**ベンダー公称レイテンシはベンダー名と値を出典付きで明記**し、本ラボでの実測値とは混ぜない。
>
> **進捗:** Phase 1〜Phase 3 完了（§1 判定基準・§2 評価項目・§3 SaaS 別エントリ・§4 横断棚卸し表・§5 voice-changer-types §2.3 への反映方針・§6 配信用途で見えてきた論点 を確定。各 SaaS の最終確認日は **2026-05-12**）。§3 内の §1.4 判定ラベルは §4.1 判定サマリと一致するよう Phase 3 で確定済み。残課題は §7.2 / §7.3 / §7.4 / §7.5 に整理してある。

## 1. 概要 — 本書の位置付けと「リアルタイム入力対応」の判定基準

### 1.1 本書の位置付け

[voice-changer-types §2.3](./voice-changer-types.md#23-クラウド-saas--api) は現時点で、代表例（CoeFont / Resemble AI / ElevenLabs / Voice.ai）の**名前出しのみ**で、「**配信ソフトに流せるリアルタイム入力ストリームとして提供されているか**は各サービスで条件が異なり、TTS / 録音後変換が中心の製品も多い。リアルタイム配信用途で使えるかは個別に要検証」とラベル無しで止まっている。同 [§未確定事項](./voice-changer-types.md#未確定事項-phase-3-以降で再評価) でも「§2.3 クラウド SaaS にリアルタイム入力を流し込むユースケースが現実的かは、実例が出てきた時点で再評価する」と明示されている。

本書は、§2.3 を**個別検証可能な解像度**まで上げることを目的に、

- 各 SaaS の**公式情報源**で「マイク入力 → 別声へリアルタイム変換 → 配信ソフトに流せるストリーム出力」というユースケースが**公式機能として提供されているか**を裏取りする
- 「リアルタイム TTS（テキスト → ストリーミング音声）」「録音アップロード → 変換ダウンロード（バッチ）」「会話/通話 SDK 向けの S2S」「配信用途のローカル仮想オーディオ出力」のどこに該当するかを**機能粒度で切り分ける**
- 配信用途で「そもそも候補に入るか」の足切り判断の根拠を、**棚卸し表 1 枚**に集約する

を行う。

OSS 系の個別ツール spec とは異なり、本書は**1 ツールの内部実装を深掘りしない**。**複数 SaaS の横断比較**が成果物であり、個別 SaaS の深掘りが必要になった時点で本書を起点に個別タスク（[docs/plans/](../plans/) 配下）へ昇格させる。

### 1.2 対象 SaaS 集合（Phase 1 で確定）

**確定した対象 4 件**:

- **CoeFont**（株式会社 CoeFont）
- **Resemble AI**（Resemble AI, Inc.）
- **ElevenLabs**（ElevenLabs Inc.）
- **Voice.ai**（Voice AI Inc.）

選定の根拠と境界:

- 4 件はいずれも [voice-changer-types §2.3](./voice-changer-types.md#23-クラウド-saas--api) で**代表例として明示的に名前が挙がっているクラウド SaaS** であり、本書はこの代表例リストの裏取りを直接の目的とする。本書のスコープを 4 件に絞ることで、棚卸しが**汎用的な AI 音声ランドスケープ調査に拡散しない**ようにする
- スコープ外の候補（Respeecher の Live 系プロダクト、Altered AI / Altered Studio、Supertone Shift / Supertone API、Voicemod のクラウド連携、Murf.ai / PlayHT / Speechify などの TTS 寄り SaaS 等）は、本書の判定基準を当てはめて棚卸しすべき候補として **§7 未確認事項 / 後続タスク**に名前のみ残し、**Phase 1 では取り扱わない**
- **Voice.ai は提供形態が 2 経路に分かれる**点に注意する。デスクトップクライアントは [voice-changer-types §2.2 ローカル商用ソフトウェア](./voice-changer-types.md#22-ローカル商用ソフトウェア) 側の話だが、Voice.ai は同社の Voice Changer 機能を **デスクトップアプリ＋クラウド連動**で提供しているため、本書ではクラウド経路に絞らず**Voice.ai の Voice Changer 全体**を一つのエントリとして棚卸しする。デスクトップ単体としての商用ソフトウェア観点の評価が後で必要になった場合は、§7 に分離タスクとして残す

### 1.3 「リアルタイム入力対応」と判定する条件

本書では、ある SaaS が「**配信ソフトに流せるリアルタイム入力ストリーム**として実用になる」と判定する条件を、以下 3 点を**すべて満たすこと**と定義する。3 点はすべて**公式情報源**（公式サイト / 公式ドキュメント / 公式 API リファレンス）で裏が取れる必要がある（コミュニティ言及のみは満たさない）。

- **(R1) 連続マイク入力対応**: 録音ファイル単発のアップロードではなく、**マイクからの連続音声入力**（任意の長さ・配信中の継続入力）を逐次受け取れる経路があること。「マイクで録音 → ファイルになってからアップロード → 変換結果をダウンロード」というワークフローは満たさない
- **(R2) ストリーム出力**: 入力末尾を待たず、**変換後音声をチャンク／ストリームで返す**経路があること。一括レスポンスのみ・録音終了後にダウンロードしか出来ない経路は満たさない
- **(R3) 配信ソフトへ流せる経路**: 次の (a) (b) いずれかが成立すること
  - (a) ベンダー公式のデスクトップアプリ / プラグインから、**OS の音声出力デバイス（実デバイス or 仮想オーディオデバイス）**として変換後音声を取り出せる。OBS 等の配信ソフトはその出力を入力デバイスとして受け取る前提
  - (b) 開発者向け API（**WebSocket / gRPC ストリーミング**等）でストリーム出力が取り出せ、**開発者側でその出力を仮想オーディオデバイスに渡す経路が現実的に構築可能**である（本書はその構築ガイドは扱わないが、API 仕様上明らかにストリーム前提として設計されているかを判定基準とする）

「会話 / 通話 SDK（例: Web 会議向けの Voice Agent / Conversational AI SDK）」は、(a)(b) いずれにも該当しなければ満たさない（音声を**配信ソフトに流す**経路として現実的に組めるかが論点）。

スコープ外の経路（明示的に「リアルタイム入力対応ではない」と扱うもの）:

- **リアルタイム TTS のみ**: テキスト → ストリーミング音声生成は、**マイク入力を起点としない**ため (R1) を満たさない。本書のスコープは「マイクから入った音を別声にしてストリーム出力する」用途に限定する
- **録音アップロード → 変換ダウンロード（バッチ）**: (R1) (R2) いずれも満たさない
- **クローニング（特定の声を作る学習工程）のみ**: 学習工程は本書のスコープ外。クローニング機能の有無 / 利用規約上の制約は §3 各エントリで触れるが、学習工程そのものは「リアルタイム入力対応」の判定に使わない

### 1.4 判定ラベル

§4 横断棚卸し表で使うラベル。Phase 2 で各エントリを埋めた結果、Phase 3 でこのラベルが確定する。

- **A: 公式リアルタイム配信経路あり** — (R1)(R2)(R3-a) を公式に満たす。ベンダー公式デスクトップアプリ / プラグインが OS の音声出力に変換後音声を載せられ、OBS 等の配信ソフトに取り回せる
- **B: 開発者 API でリアルタイム可、配信経路は自前構築** — (R1)(R2)(R3-b) を公式に満たす。WebSocket / ストリーミング API が公式に提供されており、開発者側で出力を仮想オーディオデバイスに渡す経路は組める前提
- **C: 部分的** — (R1)〜(R3) の一部を公式に満たすが、すべては満たさない。例: 「リアルタイム TTS は公式提供だが声 → 声のリアルタイム経路は無い」「Voice Changer 機能はあるが録音アップロード型」など
- **D: リアルタイム不可** — (R1)(R2)(R3) のいずれも公式に提供されていない。バッチ型 / TTS 専業 / 通話 SDK 埋め込み専用など
- **E: 未確認** — 公式情報源から (R1)〜(R3) の充足を判定できなかった。Phase 2 で埋まらなければそのまま **E** で残し、§7 に後続タスクとして起票する

ラベルは**公式情報源での記述**を根拠に付ける。「ベンダー公式アプリの動作確認」「実測でストリーム化されているか」のような本ラボ実測は判定根拠としない（[CLAUDE.md](../../CLAUDE.md) 方針）。

## 2. 評価項目

§3 各 SaaS エントリで埋め、§4 横断棚卸し表のカラムにする評価項目の定義。Phase 2 で本文を埋める時点では、ここに列挙したカラムを SaaS 別に書く。

| 評価項目 | 何を書くか |
| --- | --- |
| 公式情報源 | 公式サイト / 公式ドキュメント / 公式 API リファレンス / 公式プライシングページの URL。§3 では各エントリ冒頭にまとめる |
| 公式プロダクト名 / 機能名 | **ベンダーが何と呼んでいるか**をそのまま書く（本ラボの分類に勝手に翻訳しない）。例: "Speech to Speech" / "Voice Changer" / "ボイスチェンジャー" 等 |
| 機能粒度の切り分け | 該当機能がどれに当たるか: リアルタイム VC / リアルタイム TTS / バッチ VC / クローニング学習 / 通話 SDK 埋め込み |
| 提供形態 | Web アプリ / デスクトップクライアント / REST API / WebSocket・gRPC ストリーミング API / 通話 SDK の埋め込み のどれが公式に提供されているか |
| 配信ソフト経路 | §1.3 の (R3-a) / (R3-b) / 該当なし のどれか。仮想オーディオデバイスへ載せる経路の公式記載があるか |
| ベンダー公称レイテンシ | **ベンダーが公式に記載している値のみ**を、ベンダー名・出典 URL 付きで明記。本ラボ実測値は混ぜない |
| モデル形態 | [voice-changer-types §3](./voice-changer-types.md#3-モデル形態の軸) のどれに該当するか（プリセット固定 / Zero-shot / カスタム学習 / 話者依存 など） |
| 料金体系 | 無料枠 / 月額 / 従量 / エンタープライズ別建ての大枠。**プラン名と公称価格を出典付きで**。配信用途で実用ラインがどのプランかの推定もここに |
| 利用規約上の制約 | 配信での利用可否 / 商用配信での利用可否 / 第三者声のクローニング可否 / クレジット要件。**ベンダー利用規約・ヘルプの該当箇所を出典付きで** |
| 最終確認日 | 公式サイト / プライシング / 利用規約は変動が早いため、**SaaS ごとに最終確認日を YYYY-MM-DD で記録** |
| 未確認事項 | 公式情報源から読み取れなかった項目を明示。推測で埋めない |

記述ルール（[rvc.md](./rvc.md) / [so-vits-svc.md](./so-vits-svc.md) / [beatrice.md](./beatrice.md) / [w-okada-voice-changer.md](./w-okada-voice-changer.md) と統一）:

- **公式情報源とコミュニティ言及を明確に分ける**。出典を行ごとに明記する
- 機能名・プロダクト名は**ベンダーがそう呼んでいる名称**をそのまま書く（本ラボの分類軸へは別カラムで対応付ける）
- 実測値・断定的な性能評価は書かない（[CLAUDE.md](../../CLAUDE.md) 方針）
- 第三者キャラクター音声 / 特定声優のクローニング**手順**は書かない（言及はしても、具体的な再現導線・リンクは記載しない）
- 「リアルタイム声変換」と「リアルタイム TTS」を**同じカラムに混ぜない**（[CLAUDE.md](../../CLAUDE.md) 方針）
- 料金は USD / JPY / 月額 / 従量 を**ベンダー表記そのまま**で書き、為替換算は行わない

## 3. SaaS 別エントリ

各 SaaS の最終確認日は **2026-05-12**（Phase 2 実施日）。§1.4 判定ラベルは Phase 3 §4.1 で確定済み（本セクションのラベル行は §4.1 と一致）。公式情報源で確認できなかった項目は推測で埋めず「未確認」として明示する（[CLAUDE.md](../../CLAUDE.md) 方針）。

### 3.1 CoeFont

**最終確認日:** 2026-05-12

**公式情報源:**

- 公式サイト (ja): <https://coefont.cloud/>
- 公式サイト (en): <https://coefont.cloud/en>
- ボイスチェンジャー製品ページ (ja): <https://coefont.cloud/vc>
- ボイスチェンジャー製品ページ (en): <https://coefont.cloud/vc/en>
- CoeFont Interpreter 製品ページ: <https://coefont.cloud/cir>
- TTS 製品ページ: <https://coefont.cloud/en/tts>
- 公式 API ドキュメント: <https://docs.coefont.cloud/en/>
- プライシング (en): <https://coefont.cloud/selectPlan/en>
- 利用規約 (Notion ホスト): <https://coefont.notion.site/Terms-of-Service-2557427ab234802882c9f33b3dbcd619>（**本セッションで WebFetch 権限拒否、本文未確認**）
- プライバシーポリシー (Notion ホスト): <https://coefont.notion.site/Service-Privacy-Policy-061f0bc94b874aafb51a6171c6a1cb2d>（**同上、本文未確認**）

**公式プロダクト名 / 機能名（ベンダー表記そのまま）:**

- 「CoeFont Voice Changer」 / 「VoiceChanger」（出典: <https://coefont.cloud/vc/en>）
- 「Voice Replication」（VC 側のクローニング系機能呼称）（出典: <https://coefont.cloud/vc/en>）
- 「CoeFont Interpreter」（リアルタイム音声通訳製品）（出典: <https://coefont.cloud/en>）
- 「Text-to-Speech (TTS)」 / 「TTS Editor」 / 「TTS API」（出典: <https://coefont.cloud/en/tts> / <https://coefont.cloud/selectPlan/en>）
- 「Digital Voices」「Characters」「more than 10k different voices」（音声ライブラリ呼称）（出典: <https://coefont.cloud/vc/en> / <https://coefont.cloud/en/tts>）

**機能粒度の切り分け:**

- **リアルタイム VC（マイク→別声）**: 一部 / 詳細未確認。VC 製品ページに "Transform Your Voice in Real-time" および "Reduced time lag during conversations and livestreams" の記載があるが、入出力の技術仕様（連続マイク入力 / ストリーム出力の有無）は VC 製品ページ上に明示なし。`/vc/download` 以降はサインアップ画面に遷移し未ログインでは詳細確認不可（出典: <https://coefont.cloud/vc/en> / <https://coefont.cloud/vc>）
- **リアルタイム TTS（テキスト→ストリーミング音声）**: 未確認。TTS LP に "minimizes time lag during conversations and live streams" の表現はあるが、公式 API ドキュメントの `/text2speech` は同期 HTTP POST で完了後の音声ファイル URL（7 日有効）を返す仕様であり、ストリーミング / WebSocket エンドポイントは記載なし（出典: <https://docs.coefont.cloud/en/>）
- **バッチ VC（録音アップロード→変換ダウンロード）**: 未確認。VC 製品ページ・API ドキュメントいずれにも明示記載なし（出典: <https://coefont.cloud/vc/en> / <https://docs.coefont.cloud/en/>）
- **クローニング学習**: あり。「Voice Replication」（VC 側）、「Custom AI Voice Creation: From web recording / reading 50 sentences」（TTS 側、Free〜Enterprise の全プランで提供。Enterprise のみ "From web recording or existing videos/audio" を年契約者向け追加料金で提供）と公式に記載。手順は本書では扱わない（出典: <https://coefont.cloud/vc/en> / <https://coefont.cloud/en/tts> / <https://coefont.cloud/selectPlan/en>）
- **通話 SDK 埋め込み**: なし / 未確認。Interpreter ページに Zoom / Teams / Google Meet / Webex / Discord と "compatible"、TTS ページに Zoom / Google Meet / Discord / Twitch と "connect the CoeFont app to" の記述はあるが、これは CoeFont 側アプリ経由の利用を指す。組み込み可能な SDK の提供は公式に確認できず（出典: <https://coefont.cloud/en> / <https://coefont.cloud/en/tts>）

**提供形態:**

- Web アプリ（TTS Editor 等）: あり（出典: <https://coefont.cloud/en/tts>）
- デスクトップクライアント: あり。`https://coefont.cloud/desktop/download?feature=interpreter` がダウンロードリンクとして公開。VC 側にも `/vc/download` 導線あり。対応 OS の詳細は未ログイン状態では確認できず（出典: <https://coefont.cloud/en> / <https://coefont.cloud/vc/en>）
- モバイルアプリ: iOS / Android あり（Interpreter）（出典: <https://coefont.cloud/en>）
- REST API（TTS）: あり。Base URL `https://api.coefont.cloud/v2/`、`POST /text2speech` ほか。HMAC-SHA256 署名認証（出典: <https://docs.coefont.cloud/en/>）
- WebSocket / gRPC ストリーミング API: 公式ドキュメント上に記載なし（出典: <https://docs.coefont.cloud/en/>）
- Voice Changer 用 API: 公式ドキュメント上に記載なし。API ドキュメントは TTS / 辞書 / CoeFont Pro 一覧のみ（出典: <https://docs.coefont.cloud/en/>）

**配信ソフト経路（R3 評価）:**

- **(R3-a) 公式デスクトップ / プラグインが OS 音声出力に変換後音声を載せられるか**: 未確認。VC 製品ページに OBS / 仮想オーディオ / 出力デバイス選択への直接的言及なし。VC LP の "Reduced time lag during conversations and livestreams"、TTS LP の "you can connect the CoeFont app to Zoom, Google Meet, Discord, Twitch, etc." の記述はあるが、OS の音声出力経路の構成は未ログイン状態のページからは確認できず（出典: <https://coefont.cloud/vc/en> / <https://coefont.cloud/en/tts>）
- **(R3-b) 開発者向けストリーミング API で出力を取り出して仮想オーディオに渡せる前提があるか**: なし。公式 API ドキュメントに VC API もストリーミング API も記載なし（出典: <https://docs.coefont.cloud/en/>）
- **OBS / 配信ソフトとの連携を公式が明記しているか**: 限定的。VC ページに "livestreams" 単語の言及あり、TTS ページに "Twitch" を含む接続先例示あり。具体的なセットアップ・対応バージョン・仮想オーディオデバイス指定の手順は公式記載なし（出典: <https://coefont.cloud/vc/en> / <https://coefont.cloud/en/tts>）

**ベンダー公称レイテンシ:**

- Voice Changer 単体: ベンダー公称値の記載は確認できず（出典: <https://coefont.cloud/vc/en>）
- 参考: CoeFont Interpreter（音声通訳）には「1-second delay between your speech and its interpretation」のベンダー公称あり。ただしこれは通訳製品の値であり VC のレイテンシではない（出典: <https://coefont.cloud/en>）

**モデル形態:**

- プリセット: あり（"Choose From a Library of Characters" / "more than 10k different voices"）（出典: <https://coefont.cloud/vc/en>）
- カスタム学習（話者依存）: あり。TTS 側は "Custom AI Voice Creation: From web recording"（50 文の収録、Free プランから利用可）、Enterprise は録音済み音声・動画からの学習も対象。VC 側は "Voice Replication" として記載（出典: <https://coefont.cloud/selectPlan/en> / <https://coefont.cloud/en/tts> / <https://coefont.cloud/vc/en>）
- Zero-shot: 公式記載なし / 未確認（出典: <https://coefont.cloud/vc/en>）

**料金体系:**

価格はすべてベンダー表記そのまま。プライシングページ (en) の 4 プランは Interpreter / TTS 中心の構成で、**Voice Changer 専用プランや VC 別建ての従量課金は公式記載なし**（出典: <https://coefont.cloud/selectPlan/en>）。

- **Free**: $0、Non-Commercial Use、CoeFont Interpreter 1 hour/month、TTS 800 characters/month・1 project、Custom AI Voice Creation: From web recording、Users 1
- **Standard**: $20.00/month (tax included)、Individuals、Interpreter 5 hours/month、TTS 80,000 characters/month・unlimited projects、Users 1
- **Plus**: $350.00/month (tax included)、Small Organizations、Interpreter 8 hours/month、TTS 1,000,000 characters/month・unlimited projects、"Access to TTS API for bulk voice generation"、Users up to 5、"Excluded from AI training by default"
- **Enterprise**: Contact for pricing、Interpreter スケーラブル＋高度機能（custom dictionary、context files、speaker identification）、TTS API 提供、Custom AI Voice Creation は録音 / 既存音声・動画ベースの両方（年契約者のみ、追加料金）、Users 無制限、SSO

配信用途で実用ラインがどのプランか: 公式記載なし（Voice Changer の利用条件がプラン表に明示されていないため、配信前提でのプラン推奨は公式情報からは導けない）（出典: <https://coefont.cloud/selectPlan/en>）。

**利用規約上の制約:**

- 配信での利用可否 / 商用配信・収益化 / 第三者声のクローニング可否 / クレジット要件 / 帰属表示: **本調査時点で未確認**。利用規約は Notion 公開ページ（<https://coefont.notion.site/Terms-of-Service-2557427ab234802882c9f33b3dbcd619>）にホストされているが、本セッションでは当該 URL の WebFetch 権限が拒否されたため内容を取得できず
- プライシングページ脚注に「"Voiced by coefont.cloud" ラベル要件」の言及あり（TTS 用途の記載。Free プランは "Non-Commercial Use" 表記）（出典: <https://coefont.cloud/selectPlan/en>）

**§1.4 判定ラベル:** **E（未確認）**

Voice Changer 製品として LP は存在し "Real-time" "livestreams" を標榜しているが、(1) R1（連続マイク入力）/R2（ストリーム出力）の技術仕様が VC 製品ページに明示されておらず、(2) R3-a（OS 音声出力 / 仮想オーディオ経路）の公式記述が確認できず、(3) 公式 API ドキュメントには VC API・ストリーミング API のいずれも記載がない（TTS バッチ REST のみ）。配信ソフト連携が明示されていない時点で A は付与不可、開発者ストリーミング API も不在のため B も付与不可。**主要な技術仕様が未確認のため E（未確認）として確定。再裏取り（[§7.5](#75-todomd-に上げる後続タスク) の高優先タスク）で A〜D のいずれかに転びうる**（出典: <https://coefont.cloud/vc/en> / <https://docs.coefont.cloud/en/>）。

**未確認事項:**

- VC デスクトップアプリの対応 OS・システム要件・出力デバイス選択 / 仮想オーディオ連携可否（`/vc/download` がサインアップ画面へ遷移するため未ログインで確認不可）
- VC のベンダー公称レイテンシ
- VC が利用するモデルが Zero-shot か話者依存かの内部仕様
- VC 用 API の有無（公式 API ドキュメントには未掲載）
- TTS のストリーミング配信エンドポイントの有無（API ドキュメントには非ストリーミングのみ記載）
- 利用規約（Notion ホスト）本文: 配信利用 / 商用配信 / 第三者クローニング / 帰属表示要件 — 本セッションで <https://coefont.notion.site/Terms-of-Service-2557427ab234802882c9f33b3dbcd619> への WebFetch 権限が拒否されたため未確認（Privacy Policy の Notion ページも同様）
- 会社サイト <https://www.coefont.com/> も本セッションで WebFetch 権限が拒否されたため未確認
- VC 専用プラン / VC の文字数・時間あたり課金条件（プライシングページに VC 個別の entitlement 記載なし）

### 3.2 Resemble AI

**最終確認日:** 2026-05-12

**公式情報源:**

- 公式サイト: <https://www.resemble.ai/>
- Voice AI Platform 全体ページ: <https://www.resemble.ai/voice-ai-platform/>
- Speech-to-Speech 製品ページ: <https://www.resemble.ai/products/speech-to-speech>
- Text-to-Speech 製品ページ（公称レイテンシ裏取り用）: <https://www.resemble.ai/products/text-to-speech>
- 公式ドキュメント Welcome: <https://docs.resemble.ai/welcome>
- Speech-to-Speech ドキュメント: <https://docs.resemble.ai/voice-generation/speech-to-speech>
- WebSocket ストリーミング ドキュメント: <https://docs.resemble.ai/voice-generation/text-to-speech/streaming-websocket>
- プライシング: <https://www.resemble.ai/pricing>
- 利用規約 / ToS: <https://www.resemble.ai/terms-of-service/>

**公式プロダクト名 / 機能名（ベンダー表記そのまま）:**

- "Resemble Text-to-Speech"（出典: <https://www.resemble.ai/voice-ai-platform/>）
- "Resemble Voice Creation"（"Clone from 10s of audio"）（出典: <https://www.resemble.ai/voice-ai-platform/>）
- "Resemble Audio"（出典: <https://www.resemble.ai/voice-ai-platform/>）
- "Resemble Speech-to-Speech"（出典: <https://www.resemble.ai/voice-ai-platform/> / <https://www.resemble.ai/products/speech-to-speech>）
- "Resemble Identity" / "Resemble Watermarker" / "Resemble Detect" / "Resemble Meetings"（出典: <https://www.resemble.ai/voice-ai-platform/>）
- "Deepfake Detector for Chrome"（検出用途。声変換用途ではない）（出典: <https://www.resemble.ai/voice-ai-platform/>）
- モデル名 "Chatterbox" / "Chatterbox Turbo" / "Chatterbox Multilingual"（出典: <https://www.resemble.ai/>）
- API カテゴリ名 "Streaming over WebSocket"（出典: <https://docs.resemble.ai/welcome>）
- 料金表項目名 "AI voice changer"（出典: <https://www.resemble.ai/pricing>）
- 注: "Realtime" / "Live" という独立プロダクトページ（`/realtime/`, `/voice-changer/`）は 404 で存在を確認できず

**機能粒度の切り分け:**

- **リアルタイム VC（マイク→別声、ストリーム）**: なし / 一部（同期 REST のみ）。Speech-to-Speech ドキュメントは同期 REST `POST https://f.cluster.resemble.ai/synthesize` のみ記載。入力は SSML 内 `<resemble:convert>` の `src` に「WAV input: single speaker, max 50 MB, max 5 min」を URL で渡す方式。製品ページに "Streaming: supported on all model versions" の記載はあるが、これがマイク連続入力のフルデュプレックスか出力ストリーミングのみかは判別できず（出典: <https://docs.resemble.ai/voice-generation/speech-to-speech> / <https://www.resemble.ai/products/speech-to-speech>）
- **リアルタイム TTS**: あり。WebSocket ストリーミング配信に対応、エンドポイントは `wss://websocket.cluster.resemble.ai/stream`。TTS 製品ページに "WebSocket streaming" と "Delivers speech via WebSocket at 200ms TTFS for conversational agents, HTTP streaming for longer-form content" を明記（出典: <https://docs.resemble.ai/voice-generation/text-to-speech/streaming-websocket> / <https://www.resemble.ai/products/text-to-speech>）
- **バッチ VC**: あり。Speech-to-Speech の同期 REST 経由、最大 5 分 / 50 MB の WAV（出典: <https://docs.resemble.ai/voice-generation/speech-to-speech>）
- **クローニング学習**: あり。"Resemble Voice Creation — Clone from 10s of audio"。ToS により被クローン者の同意が必要（後述）（出典: <https://www.resemble.ai/voice-ai-platform/>）
- **通話 / 会話 SDK 埋め込み**: 未確認。"power real-time agents" の文脈は確認したが、通話 SDK としての提供形態は公式情報源から特定できず（出典: <https://docs.resemble.ai/welcome>）

**提供形態:**

- Web アプリ: 公式は "Sign in" / プロジェクト管理 UI を提供（出典: <https://www.resemble.ai/>）。詳細仕様は未確認
- デスクトップクライアント: 公式情報源では確認できず（TTS 製品ページにデスクトップアプリの明示記述なし）（出典: <https://www.resemble.ai/products/text-to-speech>）
- REST API: あり。Speech-to-Speech は `POST https://f.cluster.resemble.ai/synthesize`（出典: <https://docs.resemble.ai/voice-generation/speech-to-speech>）
- WebSocket ストリーミング API: あり。`wss://websocket.cluster.resemble.ai/stream`。ただしドキュメント上のリクエストペイロードは `voice_uuid` / `project_uuid` / `data`（Text or SSML, ≤ 3,000 chars）が中心で、Speech-to-Speech の `<resemble:convert>` `src` フィールドへの言及は確認できず（出典: <https://docs.resemble.ai/voice-generation/text-to-speech/streaming-websocket>）
- 通話 SDK: 未確認
- ブラウザ拡張: Deepfake Detector for Chrome（検出用途、声変換用途ではない）（出典: <https://www.resemble.ai/voice-ai-platform/>）

**配信ソフト経路（R3 評価）:**

- **(R3-a) 公式デスクトップ / プラグインが OS 音声出力に変換後音声を載せられるか**: 公式デスクトップクライアントの提供記述を確認できず（出典: <https://www.resemble.ai/products/text-to-speech> / <https://www.resemble.ai/products/speech-to-speech>）
- **(R3-b) 開発者向けストリーミング API で出力を取り出して仮想オーディオに渡せる前提があるか**: **TTS については成立**（WebSocket で PCM/WAV/MP3 を受信可能、サンプルレート 8000/16000/22050/32000/44100、精度 PCM_32/PCM_24/PCM_16/MULAW）。**Speech-to-Speech 側を WebSocket で受け取れるかは公式ドキュメント上で確認できず**（Speech-to-Speech は同期 REST のみ記載）（出典: <https://docs.resemble.ai/voice-generation/text-to-speech/streaming-websocket> / <https://docs.resemble.ai/voice-generation/speech-to-speech>）
- **OBS / 配信ソフトとの連携を公式が明記しているか**: 明記なし。公式トップ・プラットフォームページに OBS / streaming software / broadcasting への言及は確認できず（出典: <https://www.resemble.ai/> / <https://www.resemble.ai/voice-ai-platform/>）

**ベンダー公称レイテンシ:**

- TTS について: ベンダー公称「"Sub-200ms"」「"200ms TTFS"（Time to First Speech, Chatterbox Turbo）」「"Delivers speech via WebSocket at 200ms TTFS for conversational agents"」（出典: <https://www.resemble.ai/products/text-to-speech>）
- Speech-to-Speech のレイテンシについて**ベンダー公称値の記載は確認できず**（出典: <https://docs.resemble.ai/voice-generation/speech-to-speech> / <https://www.resemble.ai/products/speech-to-speech>）

**モデル形態:**

- カスタム学習（話者依存）: あり。"Resemble Voice Creation — Clone from 10s of audio" によりユーザ固有のクローン音声を作成可能（出典: <https://www.resemble.ai/voice-ai-platform/>）
- プリセット / Zero-shot: 公式情報源から明示確認できず（"Voices API" の存在は確認）（出典: <https://docs.resemble.ai/welcome>）
- Speech-to-Speech は WAV 入力（≤ 50 MB, ≤ 5 min, 単一話者）を Resemble 上の `voice_uuid` で指定された声へ変換する形式（出典: <https://docs.resemble.ai/voice-generation/speech-to-speech>）

**料金体系:**

ベンダー表記そのまま（出典: <https://www.resemble.ai/pricing>）:

- **Flex Plan**: 開始 $0、"Pay per consumption based on usage"、"Full API access"
- **Enterprise**: "Custom solutions for your organization"（Contact）
- 従量単価（per second）:
  - Text-to-Speech: $0.0005
  - Voice agents: $0.001
  - AI voice changer: $0.0005
  - Speech-to-text: $0.001
  - Audio enhancement: $0.002
  - Audio editing: $0.0005
  - Audio detection: $0.001 / Video detection: $0.07 / Image detection: $0.04

配信用途で実用ラインがどのプランか: 料金ページ上「Full API access」を含むのは Flex Plan（出典: <https://www.resemble.ai/pricing>）。ただし Speech-to-Speech をストリーミング配信向けに使う前提を公式が明記したプラン区分は確認できず。

**利用規約上の制約:**

- 配信での利用可否: ToS 本文に streaming / broadcasting を明示する条項は確認できず（出典: <https://www.resemble.ai/terms-of-service/>）
- 商用配信 / 収益化: 直接許可・禁止する明示条項は確認できず。ただし「except as expressly permitted by Resemble AI, licenses, sublicenses, rents or leases the Services to third parties」の制約あり（出典: <https://www.resemble.ai/terms-of-service/>）
- クローニング可否: あり、ただし同意要件 — "Resemble may require consent form the individual or third party whose voice is being cloned. Consent needs to be verbal, unless otherwise stated by Resemble."（出典: <https://www.resemble.ai/terms-of-service/>）
- なりすまし禁止: あり — "falsely states or otherwise misrepresents your affiliation with any person or entity"（出典: <https://www.resemble.ai/terms-of-service/>）
- 出力で他社モデル学習する用途の禁止: あり — "accesses the Services or otherwise uses any output generated from the Services (including without limitation audio files) to train, improve, or otherwise further develop your own or any third party's product"（出典: <https://www.resemble.ai/terms-of-service/>）
- クレジット要件: ToS 本文に明示の attribution / credit 要件は確認できず（出典: <https://www.resemble.ai/terms-of-service/>）

**§1.4 判定ラベル:** **C（部分的）**

TTS は WebSocket ストリーミング（200ms TTFS 公称）が公式に揃い R3-b を満たすが、本書のスコープであるリアルタイム声変換 = Speech-to-Speech については、公式ドキュメント上の提供形態が同期 REST `POST /synthesize`（WAV ファイル URL 入力、最大 5 分）に限られ、マイク連続入力（R1）と出力ストリーミング（R2）の WebSocket 経路が公式情報源から確認できないため。製品ページの "Streaming: supported on all model versions" の解釈が公式ドキュメントと整合しない点は未確認（[§7.5](#75-todomd-に上げる後続タスク) の中優先タスク）。

**未確認事項:**

- Speech-to-Speech を WebSocket（`wss://websocket.cluster.resemble.ai/stream`）経由で実行できるか — WebSocket ドキュメントのペイロードは `voice_uuid` + `data`(Text/SSML, ≤ 3,000 chars) が中心で、`<resemble:convert>` `src` フィールドの可否に関する明示記述を確認できず
- Speech-to-Speech 製品ページ記載の "Streaming: supported on all model versions" が指す具体的なエンドポイント・プロトコル
- Speech-to-Speech のベンダー公称レイテンシ値
- 公式デスクトップアプリ / OS 音声デバイスへの出力経路の有無
- OBS / 仮想オーディオデバイスとの連携を示す公式ドキュメント
- 通話 / 会話 SDK 形態の埋め込み提供の有無（"power real-time agents" 文脈はあるが SDK としての形態は未特定）
- WebSocket エンドポイントの認証方式の詳細（API キーの言及はあるが具体的なヘッダ仕様は当該ページからは確認できず）
- 配信用途・商用配信・収益化を明示的に許可 / 禁止する ToS 条項
- WebFetch で 404 を返した URL: `https://www.resemble.ai/terms/`（→ `/terms-of-service/` 側を採用）、`https://www.resemble.ai/voice-changer/`、`https://www.resemble.ai/realtime/`。これらの名称の独立ページが存在しないことを意味するとは限らず、公式サイト構造上の単なる URL 不一致の可能性あり

### 3.3 ElevenLabs

**最終確認日:** 2026-05-12

**公式情報源:**

- 公式サイト: <https://elevenlabs.io/>
- Voice Changer 製品ページ: <https://elevenlabs.io/voice-changer>
- 公式ドキュメント Overview: <https://elevenlabs.io/docs/overview/intro>
- Voice Changer 機能ドキュメント: <https://elevenlabs.io/docs/overview/capabilities/voice-changer>
- Voice Changer API リファレンス (convert): <https://elevenlabs.io/docs/api-reference/speech-to-speech/convert>
- Voice Changer API リファレンス (stream): <https://elevenlabs.io/docs/api-reference/speech-to-speech/stream>
- ElevenAgents Overview: <https://elevenlabs.io/docs/eleven-agents/overview>
- プライシング: <https://elevenlabs.io/pricing>
- プライシング (API): <https://elevenlabs.io/pricing/api>
- 利用規約 / ToS: <https://elevenlabs.io/terms-of-use>
- Prohibited Use Policy: <https://elevenlabs.io/use-policy>

**公式プロダクト名 / 機能名（ベンダー表記そのまま）:**

- "Voice Changer"（製品ページ表記）（出典: <https://elevenlabs.io/voice-changer>）
- "Speech to Speech"（API 名・URL パス表記）（出典: <https://elevenlabs.io/docs/api-reference/speech-to-speech/convert>）
- "Voice Cloning"（"Instant Voice Cloning" / "Professional Voice Cloning"）（出典: <https://elevenlabs.io/pricing>）
- "Voice Isolator"（ドキュメント Overview）（出典: <https://elevenlabs.io/docs/overview/intro>）
- "Text to Speech" / "Speech to Text"（"Scribe v2 Realtime" を含む）（出典: <https://elevenlabs.io/docs/overview/intro>）
- "ElevenAgents"（Conversational Agents）（出典: <https://elevenlabs.io/docs/eleven-agents/overview>）
- モデル名: "Eleven Flash v2.5", "Eleven Multilingual v2", "Eleven v3", `eleven_english_sts_v2`, `eleven_multilingual_sts_v2`

**機能粒度の切り分け:**

- **リアルタイム VC（マイク→別声、ストリーム）**: なし（少なくとも公式に Voice Changer としては未提供）
  - 製品ページは入力を「Record audio or click to upload」「Audio or video files up to 50mb each」と明記し、ファイル単位の処理を前提（出典: <https://elevenlabs.io/voice-changer>）
  - API リファレンス（convert / stream いずれも）は入力を `multipart/form-data` の `audio` バイナリ「The audio file which holds the content and emotion that will control the generated speech.」と定義しており、チャンク入力や WebSocket 入力の記述は確認できず（出典: <https://elevenlabs.io/docs/api-reference/speech-to-speech/convert> / <https://elevenlabs.io/docs/api-reference/speech-to-speech/stream>）
  - Voice Changer 機能ドキュメントに "Maximum segment length: 5 minutes — split longer recordings into chunks" とあり、セグメント分割は利用者側で行う設計（出典: <https://elevenlabs.io/docs/overview/capabilities/voice-changer>）
- **リアルタイム TTS**: あり。"Realtime TTS" の WebSocket ガイドが存在し、"Eleven Flash v2.5" は「Ultra-low latency (~75ms†)」とベンダー公称（出典: <https://elevenlabs.io/docs/overview/intro>）
- **バッチ VC**: あり。Voice Changer の Web UI / `speech-to-speech/convert` API がファイル単位の変換を提供（出典: <https://elevenlabs.io/voice-changer> / <https://elevenlabs.io/docs/api-reference/speech-to-speech/convert>）
- **クローニング学習**: あり（Instant Voice Cloning / Professional Voice Cloning）。機能の有無のみ記載（出典: <https://elevenlabs.io/pricing>）
- **通話 / 会話 SDK 埋め込み**: あり（"ElevenAgents"、WebSocket プロトコルあり）。ただし TTS 出力前提で、Speech-to-Speech 変換モードは ElevenAgents Overview 上には記載が確認できず（出典: <https://elevenlabs.io/docs/eleven-agents/overview>）

**提供形態:**

- Web アプリ: Voice Changer の Web プレイグラウンドあり（出典: <https://elevenlabs.io/voice-changer>）
- デスクトップクライアント: 公式記述を確認できず（公式サイト・ドキュメント上で「desktop app」への言及は見当たらず）
- REST API: あり（`POST /v1/speech-to-speech/{voice_id}` 等）（出典: <https://elevenlabs.io/docs/api-reference/speech-to-speech/convert>）
- HTTP ストリーミング応答: あり。`speech-to-speech/stream` は `text/event-stream` で音声チャンクを返す（出典: <https://elevenlabs.io/docs/api-reference/speech-to-speech/stream>）
- WebSocket API: TTS / ElevenAgents 向けにはあり（Realtime TTS, Multi-Context WebSocket, Agent WebSocket）。Speech-to-Speech に対する WebSocket は確認できず（出典: <https://elevenlabs.io/docs/overview/intro> / <https://elevenlabs.io/docs/eleven-agents/overview>）
- モバイル / SDK: 製品ページに「web, mobile and via APIs or SDKs」と記載（出典: <https://elevenlabs.io/voice-changer>）

**配信ソフト経路（R3 評価）:**

- **(R3-a) 公式デスクトップ / プラグインが OS 音声出力に変換後音声を載せられるか**: 公式記述を確認できず（=未確認）。Voice Changer 製品ページ / Voice Changer 機能ドキュメント / 公式サイト いずれにも、OS 音声出力デバイスへ載せる公式デスクトップアプリ / プラグインの言及は見当たらず（出典: <https://elevenlabs.io/voice-changer> / <https://elevenlabs.io/docs/overview/capabilities/voice-changer>）
- **(R3-b) 開発者向けストリーミング API で出力を取り出して仮想オーディオに渡せる前提があるか**: 限定的。`speech-to-speech/stream` は応答側のみチャンク返却で、入力側はファイル単位。配信中の継続マイク入力を直接受け付ける公式の Speech-to-Speech ストリーム入力 API は確認できず（出典: <https://elevenlabs.io/docs/api-reference/speech-to-speech/stream>）
- **OBS / 配信ソフトとの連携を公式が明記しているか**: 明記なし（"OBS" "virtual audio" 等のキーワードは公式サイト・ドキュメント上で確認できず）

**ベンダー公称レイテンシ:**

- Voice Changer 製品ページ FAQ に「fast processing times (~400ms)」の記載（ベンダー公称、Voice Changer 文脈）（出典: <https://elevenlabs.io/voice-changer>）
- "Eleven Flash v2.5": "Ultra-low latency (~75ms†)"（ベンダー公称、TTS 文脈）（出典: <https://elevenlabs.io/docs/overview/intro>）
- "Scribe v2 Realtime": "Low latency (~150ms†)"（ベンダー公称、STT 文脈）（出典: <https://elevenlabs.io/docs/overview/intro>）
- いずれも Speech-to-Speech の連続マイク入力に対する end-to-end レイテンシのベンダー公称値ではない点に注意

**モデル形態:**

- プリセット固定: あり（"10,000+ available voices" のライブラリ）（出典: <https://elevenlabs.io/voice-changer>）
- カスタム学習（話者依存）: あり（Instant Voice Cloning / Professional Voice Cloning）（出典: <https://elevenlabs.io/pricing>）
- Speech-to-Speech モデル: `eleven_multilingual_sts_v2`（既定 `eleven_english_sts_v2`、公式ドキュメントは multilingual 推奨）（出典: <https://elevenlabs.io/docs/overview/capabilities/voice-changer> / <https://elevenlabs.io/docs/api-reference/speech-to-speech/convert>）
- Zero-shot 入力ボイスへの完全な無学習対応の表現は公式に確認できず（=未確認）

**料金体系（ベンダー表記そのまま、Individual / Business プラン）（出典: <https://elevenlabs.io/pricing>）:**

- **Free** $0/month — 10k credits/month、no commercial license
- **Starter** $6/month — 30k credits/month、Commercial License、Instant Voice Cloning
- **Creator** $11/month（初月 50% off、通常 $22/month と表示）— 121k credits/month、Professional Voice Cloning
- **Pro** $99/month — 600k credits/month、44.1kHz PCM audio output via API、192kbps quality audio
- **Scale** $299/month — 1.8M credits/month、3 Workspace seats、3 Professional Voice Clones
- **Business** $990/month — 6M credits/month、"Low-latency TTS as low as 5c/minute"、10 Professional Voice Clones
- **Enterprise**: Custom pricing

API 課金単位（出典: <https://elevenlabs.io/pricing/api>）:

- TTS は per character 課金（Flash/Turbo "$0.05" per 1K characters、Multilingual v2/v3 "$0.1" per 1K characters）
- Voice Changer (Speech-to-Speech) は per minute 課金（"$0.12" per minute、全プラン共通レート、含まれる分数はプランごとにスケール）

配信用途で実用ラインがどのプランか: 公式に「配信向け推奨プラン」の記載は確認できず。商用利用には最低 Starter 以上が必要（出典: <https://elevenlabs.io/terms-of-use>）。Voice Changer の含まれる分数は Starter で 8.3 分、Business で 8,250 分（出典: <https://elevenlabs.io/pricing/api>）。

**利用規約上の制約:**

- 商用利用: Free は non-commercial のみ。"if you access or use our Services through a paid subscription plan...you may use the Services for commercial purposes"（Paid Users のみ商用可）（出典: <https://elevenlabs.io/terms-of-use>）
- ライブ配信 / ブロードキャスト: ToS 内に明示的な記述は確認できず（=未確認）（出典: <https://elevenlabs.io/terms-of-use>）
- クローニング可否: 自分の声、または「the voice you are authorized to share with us」のみ許可（出典: <https://elevenlabs.io/terms-of-use>）
- 他者なりすまし / ディープフェイク: Prohibited Use Policy で明示禁止。"creating or using ElevenLabs audio output to intentionally replicate the voice of another person: (a) without consent or legal right, (b) in a way that harasses or causes harm to that person, (c) in a manner intended to deceive others about whether the voice was generated by artificial intelligence."（出典: <https://elevenlabs.io/use-policy>）
- AI 開示要件: "Organizations using our Services...to power AI agents must clearly and prominently disclose to their users they are interacting with AI rather than a human."（AI エージェント向け文脈）（出典: <https://elevenlabs.io/use-policy>）
- クレジット要件: ToS 上、出力に対する明示的なアトリビューション要件は確認できず（出典: <https://elevenlabs.io/terms-of-use>）

**§1.4 判定ラベル:** **C（部分的）**

R2（ストリーム出力）は `speech-to-speech/stream` の SSE で公式に充足。一方 R1（連続マイク入力）に対応する公式の Speech-to-Speech ストリーム入力経路（WebSocket / チャンク入力）は確認できず、入力はファイル単位設計。公式デスクトップアプリも確認できなかったため R3-a も非充足。配信中のマイクからの連続変換用途には、利用者側で短いセグメントを切り出して逐次 POST する形になり、R1 を満たす公式設計ではない（[§7.5](#75-todomd-に上げる後続タスク) の中優先タスクで継続追跡）。

**未確認事項:**

- 公式デスクトップアプリ / 公式 OBS プラグイン / 仮想オーディオデバイス連携の有無（公式サイト・ドキュメントで言及を確認できず）
- Speech-to-Speech に対する WebSocket / チャンク入力 API の有無（API リファレンス上は確認できず）
- ライブ配信 / ブロードキャストでの利用可否の明文条項（ToS 上、明示的記述を確認できず）
- Voice Changer の end-to-end レイテンシ（マイク→出力）のベンダー公称値（製品ページ FAQ の "~400ms" は処理時間表現で、配信中の連続入力に対する end-to-end の公称ではない）
- ElevenAgents における Speech-to-Speech 変換モード（声質変換）の有無（Overview 上は TTS 出力前提で、明示記述は確認できず）
- WebFetch で 404 となった以下のページは未参照: <https://elevenlabs.io/docs/capabilities/voice-changer> / <https://elevenlabs.io/docs/cookbooks/voice-changer> / <https://elevenlabs.io/docs/product-guides/products/voice-changer> / <https://elevenlabs.io/docs/conversational-ai/overview>
- Prohibited Use Policy 旧 URL（`/prohibited-content-and-uses-policy`）は 502 で読めず、代替の `/use-policy` を参照した

### 3.4 Voice.ai

**最終確認日:** 2026-05-12

**公式情報源:**

- 公式サイト: <https://voice.ai/>
- Voice Changer 製品ページ: <https://voice.ai/voice-changer> / <https://voice.ai/ai-voice-changer>
- 開発者ドキュメント (Introduction): <https://voice.ai/docs/introduction>
- 開発者ドキュメント (Overview): <https://voice.ai/docs>
- API リファレンス: <https://voice.ai/docs/api-reference>
- TTS Quickstart: <https://voice.ai/docs/guides/text-to-speech/quickstart>
- Voice Agents Quickstart: <https://voice.ai/docs/guides/voice-agents/quickstart>
- プライシング: <https://voice.ai/pricing>
- 利用規約 / ToS: <https://voice.ai/tos>
- Discord 連携セットアップ: <https://voice.ai/apps/discord>

**公式プロダクト名 / 機能名（ベンダー表記そのまま）:**

- "Free Real-Time AI Voice Changer for PC & Mac"（出典: <https://voice.ai/voice-changer>）
- "Voice AI Agent™"（出典: <https://voice.ai/>）
- "Voice Universe®"（出典: <https://voice.ai/>）
- "Voice Cloning" / "Instant Voice Clones"（出典: <https://voice.ai/voice-cloning> / <https://voice.ai/pricing>）
- "Soundboards" / "Voice Skins, Voice Filters, and Voice Avatars"（出典: <https://voice.ai/voice-changer>）
- "Text-to-Speech (TTS)" / "Voice Agents" / "Auto Evals (Alpha)"（出典: <https://voice.ai/docs/introduction>）
- "Speech-to-speech voice conversion"（Voice Changer 説明文中）（出典: <https://voice.ai/voice-changer>）

**機能粒度の切り分け:**

- **リアルタイム VC（マイク→別声、デスクトップアプリ経由）**: あり。"Transform your voice in real time with our voice changer. Switch between thousands of voices instantly"、"Free Real-Time AI Voice Changer for PC & Mac"（出典: <https://voice.ai/> / <https://voice.ai/voice-changer> / <https://voice.ai/ai-voice-changer>）
- **リアルタイム VC（クラウド API 経由）**: 未確認。API リファレンス（<https://voice.ai/docs/api-reference>）には `POST /api/v1/tts/speech`（TTS）と Voice Agents しか掲載されておらず、speech-to-speech / Voice Changer 単独の REST/WS エンドポイントは公式ドキュメント上で確認できず
- **リアルタイム TTS**: あり。HTTP ストリーミング用 `https://dev.voice.ai/api/v1/tts/speech/stream` と "Use the WebSocket endpoint for conversational AI" / `/multi-stream` が TTS Quickstart に記載（出典: <https://voice.ai/docs/guides/text-to-speech/quickstart>）
- **バッチ VC**: 未確認（公式ドキュメントから単独で「バッチ音声変換」を切り出した記載は確認できず）
- **クローニング学習**: あり。"Instant Voice Clones" としてプラン別に本数が割り当てられている。`POST /api/v1/tts/speech` が `voice_id` を受け取り、Web SDK が "MP3/WAV/OGG" のサンプルアップロードを受け付ける（出典: <https://voice.ai/pricing> / <https://voice.ai/docs/api-reference> / <https://voice.ai/docs/guides/voice-agents/web>）
- **通話 / 会話 SDK 埋め込み**: あり（Voice Agents）。"Build intelligent voice agents that can handle phone calls, answer questions" および Web SDK `/docs/guides/voice-agents/web` で "Connect from JavaScript/TypeScript with real-time voice, TTS, and more"（出典: <https://voice.ai/docs> / <https://voice.ai/docs/guides/voice-agents/quickstart>）

**提供形態:**

- デスクトップクライアント: "Free Real-Time AI Voice Changer for PC & Mac"。トップページのインストーラ案内は Windows のみ言及。macOS 対応版の存在は Voice Changer 製品ページのタイトル "for PC & Mac" でのみ確認（出典: <https://voice.ai/voice-changer> / <https://voice.ai/ai-voice-changer> / <https://voice.ai/>）
- Web ダッシュボード: <https://voice.ai/app/dashboard/home>（出典: <https://voice.ai/docs>）
- REST API: `https://dev.voice.ai/api/v1/tts/speech`（TTS、Bearer API key）（出典: <https://voice.ai/docs/api-reference> / <https://voice.ai/docs/guides/text-to-speech/quickstart>）
- HTTP ストリーミング / WebSocket: TTS の `/speech/stream` と `/multi-stream` を Quickstart が案内（出典: <https://voice.ai/docs/guides/text-to-speech/quickstart>）
- SDK: Python / Node.js / TypeScript / Web / iOS / Android の言及あり（出典: <https://voice.ai/api> / <https://voice.ai/docs/introduction>）
- **仮想オーディオデバイス**: Discord 連携セットアップで "Voice.ai (VB-Audio Virtual Cable)" を Discord の入力デバイスとして選択する手順が公式に掲載されており、デスクトップアプリは VB-Audio Virtual Cable 系の仮想入力デバイスとして OS に露出する形態が示唆されている（出典: <https://voice.ai/apps/discord>）
- 変換がローカル完結かクラウドかの公式明記: 未確認。トップページに "Cloud-based with on-premise options for enterprise" の記述はあるが、これは Voice AI Agent プラットフォーム全体に対する表現で、デスクトップ Voice Changer の処理ロケーションを名指しした記述は公式ページ上で確認できず（出典: <https://voice.ai/>）
- ToS には "you consent to Voice.ai utilizing your hardware for metamodel training and computational purposes"（ユーザーハードウェアの計算利用に同意）の文言があり、ローカル / 分散計算が一部含まれることは示唆される（出典: <https://voice.ai/tos>）

**配信ソフト経路（R3 評価）:**

- **(R3-a) 公式デスクトップが OS 音声出力に変換後音声を載せられるか**: あり（VB-Audio Virtual Cable を介した入力デバイス公開という形）。"Compatible with Streamlabs OBS" と明記。Discord 設定例は "Simply click on the Voice.ai (VB-Audio Virtual Cable)" と仮想ケーブル経由（出典: <https://voice.ai/voice-changer> / <https://voice.ai/apps/discord>）
- **(R3-b) 開発者向けストリーミング API で出力を取り出して仮想オーディオに渡せる前提**: TTS については HTTP ストリーミングと WebSocket `/multi-stream` が公式に存在。ただし speech-to-speech（マイク入力を別声で返す）用の独立した開発者 API は公式ドキュメントから確認できなかった（=未確認）（出典: <https://voice.ai/docs/guides/text-to-speech/quickstart>）
- **OBS / 配信ソフトとの連携を公式が明記しているか**: あり。"Whether you want to use it with Streamlabs OBS, Twitch, TikTok Live Studio"、"Compatible with Streamlabs OBS"。Discord / Twitch / TikTok Live Studio / Zoom / WhatsApp / Skype など個別アプリのセットアップページあり（出典: <https://voice.ai/ai-voice-changer> / <https://voice.ai/voice-changer> / <https://voice.ai/apps/discord>）

**ベンダー公称レイテンシ:**

- ミリ秒単位の数値表記は確認できず。トップページおよび Voice Changer ページは "in real time" / "instantly" の表現に留まる（出典: <https://voice.ai/> / <https://voice.ai/voice-changer>）。TTS API は "Low-latency audio generation for conversational AI"、"lowest latency in multi-turn conversations" と表現するのみで具体的な数値は記載なし（出典: <https://voice.ai/docs> / <https://voice.ai/docs/guides/text-to-speech/quickstart>）

**モデル形態:**

- プリセット固定: あり。"Switch between thousands of voices instantly" / "Access thousands of free voices" / "thousands of user-generated voices in Voice Universe"（出典: <https://voice.ai/> / <https://voice.ai/ai-voice-changer>）
- カスタム学習（話者依存）: あり。"clone a voice in just 15 seconds" / "With only 10 seconds of audio, our AI voice cloning and voice changer can replicate voices with stunning realism"。プラン別の "Instant Voice Clones" 上限を提示（出典: <https://voice.ai/voice-cloning> / <https://voice.ai/> / <https://voice.ai/pricing>）
- Zero-shot 専用 API としての位置付け: 未確認
- ライブラリの規模: "thousands of free voices" / "thousands of user-generated voices" と表現され、正確な数値は確認できず（出典: <https://voice.ai/ai-voice-changer> / <https://voice.ai/voice-changer>）

**料金体系:**

クレジット制（プラン別の月間 credits）。配信向けデスクトップ Voice Changer と TTS / Voice Agents API は同一の credits 課金体系で記載されている（出典: <https://voice.ai/pricing>）。

- **Consumer Free**: $0 / 月、5,000 credits / 月、"No Instant Voice Clones"、500 Characters per Conversion、音声ツール 5 分まで
- **Consumer Starter**: $5 / 月、15,000 credits / 月、5 Instant Voice Clones、5,000 Characters per Conversion、commercial license、1 phone number
- **Consumer Launch**: $12 / 月（初月 50% off）、200,000 credits / 月、10 Instant Voice Clones、3 phone numbers、音声ツール 20 分まで
- **Business Core**: $99 / 月、1,000,000 credits / 月、50 Instant Voice Clones、priority support、10 phone numbers
- **Business Scale**: $330 / 月、4,000,000 credits / 月、200 Instant Voice Clones、20 phone numbers
- **Business**: $880 / 月、22,000,000 credits / 月、2,200 Voice Clones、50 phone numbers、technical success manager
- **Enterprise**: Custom pricing、BAAs for HIPAA、custom SSO、elevated concurrency limits

配信用途で実用ラインがどのプランか: ToS が "the Services are provided for personal, non-commercial use only" を既定とし、"commercial license" を明示しているのは Starter プラン以上のため、配信での商用利用は最低でも Starter ($5 / 月) 以上が公式表記の前提となる（出典: <https://voice.ai/tos> / <https://voice.ai/pricing>）。それ以上の具体的な配信向け推奨プランは公式に記載なし。

**利用規約上の制約:**

- 商用 / 配信での利用: "Unless expressly authorized in writing by Voice.ai (including pursuant to a separate written business agreement), the Services are provided for personal, non-commercial use only." "Business, enterprise, API, or other commercial use of the Services requires a separate agreement with Voice.ai."（出典: <https://voice.ai/tos>）。Starter プラン以上に "commercial license" が含まれることはプライシング側に明記（出典: <https://voice.ai/pricing>）
- クローニング / 第三者音声: "You are using your own voice / You have explicit legal authorization from the person whose voice is used / Your use is clearly permitted under applicable law (e.g., parody or satire)" のいずれかを満たすこと（出典: <https://voice.ai/tos>）
- なりすまし禁止: "Any use of our software to impersonate real individuals -- living or deceased -- with the intent to deceive, defraud, or mislead others is strictly prohibited."（出典: <https://voice.ai/tos>）
- クレジット要件: "In accordance with the Brand Use Guidelines, you agree to provide proper credit to Voice.ai for any use of its products."（出典: <https://voice.ai/tos> / <https://voice.ai/branding-guidelines>）
- ハードウェア利用条項: "you consent to Voice.ai utilizing your hardware for metamodel training and computational purposes, though all users have the option to disable this feature at any time."（出典: <https://voice.ai/tos>）
- 再販禁止: "Rent, lease, sell, distribute, sublicense, or otherwise commercially exploit the Services" を事前書面許可なしで行うことは不可（出典: <https://voice.ai/tos>）
- DMCA: 別途 <https://voice.ai/dmca-policy> にて運用

**§1.4 判定ラベル:** **A（公式リアルタイム配信経路あり）**

公式デスクトップアプリが「Real-Time AI Voice Changer for PC & Mac」として提供され（R1 / R2 充足）、VB-Audio Virtual Cable を介した仮想オーディオ入力として OS に露出し、Streamlabs OBS / Twitch / TikTok Live Studio / Discord との互換性が公式に明記されている（R3-a 充足）。なお speech-to-speech の独立した開発者 API（R3-b 経路）は公式ドキュメント上で確認できなかったため、R3-b 単独評価としては「未確認」だが、R3-a での A 判定は成立する。

**未確認事項:**

- デスクトップ Voice Changer の音声変換がローカル GPU 完結か、クラウド推論経由かを名指しで述べた公式記述（トップページの "Cloud-based with on-premise options for enterprise" は Voice AI Agent プラットフォーム全体の説明であり、Voice Changer 単独の処理ロケーションは未確認）
- macOS 版インストーラの個別配布ページ・対応 macOS バージョン・対応 CPU / Apple Silicon の公式明記（"PC & Mac" 表記のみ確認）
- 配信時のレイテンシ（ms 単位）のベンダー公称値
- speech-to-speech / Voice Changer 用の独立した REST / WebSocket / gRPC エンドポイントの有無（公開 API リファレンスは TTS と Voice Agents のみを掲載）
- Web SDK の音声トランスポート（WebRTC か WebSocket か）と返却ストリーム形式の公式記載
- `https://voice.ai/llms.txt` は WebFetch で HTTP 404 が返り全索引を取得できず
- ボイスライブラリの正確な収録数（公式は "thousands of …" 表記のみ）
- 配信向けクレジット消費量（credits / 分）の明示的な換算表
- Voice Changer デスクトップアプリ内で OS 出力デバイスへ出力する詳細（VB-Audio Virtual Cable が同梱配布されるのか、別途インストールが必要かは Discord 連携ページのスクリーンショット以上の情報が確認できず）

## 4. 横断棚卸し表

§2 の評価項目を横軸、§1.2 で確定した 4 SaaS を縦軸に取った棚卸し。§4.1 で §1.4 の判定ラベル（A / B / C / D / E）を 1 表に並べ、配信用途で**そもそも候補に入るか / 入らないか**の足切り判断が一目で分かる形にする。§4.2 以降は項目別の比較表で、出典は §3 SaaS 別エントリの該当ブロックに集約しているため本表では再掲しない（必要に応じて §3.X へ参照する）。

判定ラベルは §1.4 の定義どおり**公式情報源で裏が取れた範囲のみ**で付けている。「コミュニティで使われている / 一般に知られている」は判定根拠としない（[CLAUDE.md](../../CLAUDE.md) 方針）。

### 4.1 判定サマリ（足切り判断）

| SaaS | 判定 | 一行サマリ |
| --- | --- | --- |
| CoeFont | **E（未確認）** | VC LP は "Real-time" / "livestreams" を標榜しているが、R1 / R2 / R3 を裏付ける技術仕様（連続マイク入力・ストリーム出力・OS 音声出力経路）が公式情報源で確認できず、判定確定不能。利用規約も Notion ホストで本セッションでは WebFetch 拒否のため本文未確認（詳細: [§3.1](#31-coefont)） |
| Resemble AI | **C（部分的）** | リアルタイム TTS は WebSocket ストリーミング（200ms TTFS 公称）で R2 充足。**本書スコープのリアルタイム声変換（Speech-to-Speech）は同期 REST `POST /synthesize`、最大 5 分 WAV のファイル入力**で R1 / R2 非充足。製品ページ "Streaming: supported on all model versions" の具体的エンドポイントは未確認（詳細: [§3.2](#32-resemble-ai)） |
| ElevenLabs | **C（部分的）** | `speech-to-speech/stream` で**応答** SSE ストリーミングはあるが、**入力**は `multipart/form-data` のファイル単位 + 1 セグメント 5 分上限。連続マイク入力（R1）の公式経路なし。公式デスクトップアプリ / OBS プラグイン / 仮想オーディオ連携の言及なし（詳細: [§3.3](#33-elevenlabs)） |
| Voice.ai | **A（公式リアルタイム配信経路あり）** | "Free Real-Time AI Voice Changer for PC & Mac" デスクトップアプリが VB-Audio Virtual Cable を介して OS に仮想入力デバイスとして露出。"Compatible with Streamlabs OBS" を公式明記、Twitch / TikTok Live Studio / Discord 等の連携手順も公式に整備。商用利用は Starter（$5/月）以上が公式前提（詳細: [§3.4](#34-voiceai)） |

**配信用途で「現時点で候補に入る」のは Voice.ai のみ**。残り 3 件は本書スコープ（マイク → 別声 → 配信ソフトに流せるストリーム）を**公式機能として提供しているとは公式情報源から確認できなかった**。CoeFont は技術仕様自体が未確認のため再裏取りで A〜D のいずれにも転びうる。Resemble AI / ElevenLabs はリアルタイム **TTS** は揃っているが本書スコープではない。

### 4.2 機能粒度の切り分け

凡例: ○ = 公式提供あり / △ = 部分的・限定的提供 / × = 公式提供なし / ? = 未確認

| SaaS | リアルタイム VC<br>（マイク → 別声、ストリーム） | リアルタイム TTS<br>（本書スコープ外） | バッチ VC<br>（録音→変換ダウンロード） | クローニング学習 | 通話 / 会話 SDK |
| --- | --- | --- | --- | --- | --- |
| CoeFont | △（LP は "Real-time" を標榜するが技術仕様未確認） | ?（TTS API は同期 REST のみ、ストリーミング記載なし） | ? | ○（"Voice Replication" / "Custom AI Voice Creation"） | ×（"compatible" 表現あるがアプリ経由） |
| Resemble AI | △（S2S は同期 REST、最大 5 分 WAV） | ○（WebSocket ストリーミング） | ○（S2S 同期 REST） | ○（"Clone from 10s of audio"） | ? |
| ElevenLabs | △（応答 SSE ストリーミングはあるが入力はファイル単位、1 セグメント最大 5 分） | ○（Realtime TTS WebSocket） | ○（Voice Changer Web UI / `speech-to-speech/convert`） | ○（Instant / Professional Voice Cloning） | ○（ElevenAgents） |
| Voice.ai | ○（デスクトップアプリ） | ○（HTTP ストリーミング + WebSocket `/multi-stream`） | ? | ○（"Instant Voice Clones"） | ○（Voice Agents） |

### 4.3 提供形態

| SaaS | Web アプリ | デスクトップ | REST API | ストリーミング API（WS / SSE） | 通話 / 会話 SDK |
| --- | --- | --- | --- | --- | --- |
| CoeFont | ○（TTS Editor） | ○（`/desktop/download`、`/vc/download`。OS / 仮想オーディオ詳細は未ログインで確認不可） | ○（TTS のみ、HMAC-SHA256） | ×（公式 API ドキュメントに記載なし） | × |
| Resemble AI | ○ | ?（公式記述未確認） | ○（S2S `POST /synthesize` 等） | ○（TTS `wss://websocket.cluster.resemble.ai/stream`。S2S 対応は未確認） | ? |
| ElevenLabs | ○（Voice Changer プレイグラウンド） | ×（公式記述未確認） | ○（`/v1/speech-to-speech/{voice_id}` 等） | △（TTS / Agents は WebSocket、S2S は応答のみ SSE） | ○（ElevenAgents WebSocket） |
| Voice.ai | ○（ダッシュボード） | ○（PC & Mac、VB-Audio Virtual Cable 経由で OS 露出） | ○（TTS / Voice Agents） | ○（TTS `/speech/stream` / `/multi-stream`。S2S 独立 API は未確認） | ○（Voice Agents Web / iOS / Android SDK） |

### 4.4 配信ソフト経路（R3）評価

凡例: ○ = 公式に成立 / △ = 限定的 / × = 公式に確認できず / ? = 未確認

| SaaS | (R3-a) 公式デスクトップ → OS 音声出力 / 仮想オーディオ | (R3-b) 開発者ストリーミング API でリアルタイム VC 出力 | OBS / 配信ソフトの公式言及 |
| --- | --- | --- | --- |
| CoeFont | ?（VC LP に "livestreams" 単語あり、TTS LP に Twitch 等の例示あり。仮想オーディオ / 出力デバイス選択の手順は未確認） | ×（公式 API ドキュメントに VC API なし） | △（"livestreams" / "Twitch" 単語のみ、セットアップ手順なし） |
| Resemble AI | ×（公式デスクトップ提供記述を確認できず） | △（TTS WebSocket は明確、S2S を WebSocket で受けられるかは未確認） | ×（OBS / streaming software / broadcasting への言及確認できず） |
| ElevenLabs | ×（公式デスクトップ / OBS プラグイン / 仮想オーディオ連携の言及なし） | △（応答 SSE はあるが入力ファイル単位のため連続マイク入力ではない） | ×（"OBS" / "virtual audio" 等のキーワード未確認） |
| Voice.ai | ○（"VB-Audio Virtual Cable" 経由で OS 入力デバイス公開、Discord 設定例で公式明記） | ×（speech-to-speech 用の独立した REST / WebSocket は公式 API リファレンスに掲載なし） | ○（"Compatible with Streamlabs OBS"、Twitch / TikTok Live Studio / Discord 等の個別セットアップページあり） |

### 4.5 ベンダー公称レイテンシ（VC 文脈のみ）

「リアルタイム声変換」と「リアルタイム TTS」を同じカラムに混ぜない（[CLAUDE.md](../../CLAUDE.md) 方針）。本表は本書スコープである**声 → 声**の文脈に限定する。TTS / STT / 通訳のレイテンシ公称は本表のスコープ外（§3 各エントリに併記済み）。

| SaaS | VC 文脈のベンダー公称 | 備考 |
| --- | --- | --- |
| CoeFont | 数値公称なし | VC LP は "Real-time" / "Reduced time lag" 等の定性表現のみ。Interpreter 製品の "1-second delay" は通訳製品の値であり VC のレイテンシではない |
| Resemble AI | 数値公称なし（Speech-to-Speech 文脈） | TTS は "Sub-200ms" / "200ms TTFS" 公称ありだが本書スコープ外 |
| ElevenLabs | "fast processing times (~400ms)"（Voice Changer 製品ページ FAQ、ベンダー公称、**処理時間**表現） | Voice Changer の end-to-end（マイク入力 → 出力）の数値ではない。"~75ms" は Eleven Flash v2.5（TTS）、"~150ms" は Scribe v2 Realtime（STT）で本書スコープ外 |
| Voice.ai | 数値公称なし | トップページ / Voice Changer ページとも "in real time" / "instantly" の定性表現のみ |

**本ラボでの実測値は本書では一切扱わない**（[CLAUDE.md](../../CLAUDE.md) 方針）。VC 文脈で ms 単位の公称値が出ているのは ElevenLabs（~400ms 処理時間）のみで、それも end-to-end ではない点に留意。

### 4.6 モデル形態（[voice-changer-types §3](./voice-changer-types.md#3-モデル形態の軸) 対応）

| SaaS | プリセット固定 | カスタム学習（話者依存） | Zero-shot / Any-to-any | ライブラリ規模の公称 |
| --- | --- | --- | --- | --- |
| CoeFont | ○（"Choose From a Library of Characters"） | ○（"Voice Replication" / "Custom AI Voice Creation: From web recording / reading 50 sentences"） | ?（公式記載なし） | "more than 10k different voices" |
| Resemble AI | ?（Voices API 経由のプリセット有無は明示確認できず） | ○（"Clone from 10s of audio"） | ? | 未確認 |
| ElevenLabs | ○（Voice Library） | ○（Instant Voice Cloning / Professional Voice Cloning） | ? | "10,000+ available voices" |
| Voice.ai | ○（Voice Universe） | ○（"clone a voice in just 15 seconds" / "10 seconds of audio"） | ? | "thousands of voices"（数値非公称） |

### 4.7 料金体系の大枠（VC 利用ライン）

VC を商用配信で使う前提でプラン名と価格を抜粋（ベンダー表記そのまま、為替換算なし）。

| SaaS | 無料枠 | 商用利用可となる最低プラン | VC の課金単位 | 配信向け実用プランの公称 |
| --- | --- | --- | --- | --- |
| CoeFont | Free $0（Non-Commercial Use、TTS 800 chars / Interpreter 1h） | プライシング上 VC 専用プランの明示なし。TTS / Interpreter は Standard $20.00/月 から | **VC 別建ての従量課金は公式記載なし** | 公式に「配信向け推奨プラン」の記載なし |
| Resemble AI | Flex Plan 開始 $0（Pay per consumption） | Flex Plan（Full API access） | "AI voice changer: $0.0005 / 秒"（= $0.03/分） | 公式記載なし |
| ElevenLabs | Free $0/月（no commercial license） | Starter $6/月 | "$0.12 / 分"（全プラン共通）。VC 分数は Starter 8.3 分 〜 Business 8,250 分 | 公式記載なし。Voice Changer 連続使用なら Pro / Scale 以上の credits 数を要する |
| Voice.ai | Consumer Free $0/月（5,000 credits、commercial license なし） | Consumer Starter $5/月（commercial license） | クレジット制（VC / TTS / Voice Agents 共通） | 公式記載なし。credits / 分の換算表もなし |

### 4.8 利用規約上の制約

| SaaS | 配信 / ブロードキャストの明示条項 | 商用配信 / 収益化 | 第三者クローニング | クレジット（帰属表示）要件 |
| --- | --- | --- | --- | --- |
| CoeFont | **未確認**（Notion ホストの ToS 本文を本セッションでは取得不可） | プライシング側で Free = Non-Commercial Use、Standard 以上で商用可と読める。ToS 本文は未確認 | **未確認** | プライシング脚注に「"Voiced by coefont.cloud" ラベル要件」の言及あり（TTS 文脈） |
| Resemble AI | ToS 本文に streaming / broadcasting の明示条項を確認できず | 商用配信を直接許可・禁止する明示条項なし。再販 / sublicense / lease は事前許可必須 | あり（要同意。"Resemble may require consent form the individual or third party whose voice is being cloned. Consent needs to be verbal, unless otherwise stated"）+ なりすまし禁止 + 出力で他社モデル学習する用途の禁止 | ToS 上の明示なし |
| ElevenLabs | ToS 内に明示記述なし（=未確認） | Free = non-commercial、Paid（Starter $6 以上）= commercial。ToS 明文 | あり（要許諾。「自分の声、または認可された声のみ」）。Prohibited Use Policy で意図的ななりすまし / ディープフェイク禁止 | ToS 上の明示なし。AI エージェント用途は「AI と対話している」開示要件あり |
| Voice.ai | ToS が "personal, non-commercial use only" を既定とし、配信での実利用には**事実上 Starter 以上の商用ライセンスが必須** | "Business, enterprise, API, or other commercial use of the Services requires a separate agreement"。Starter プランから "commercial license" 同梱（プライシング側に明記） | あり（要許諾。「自分の声 / 法的許諾を持つ / 法令で明示的に許される」のいずれかを満たすこと）+ 意図したなりすまし禁止 | あり（"provide proper credit to Voice.ai for any use of its products"、Brand Use Guidelines 準拠）+ ユーザーハードウェアでの metamodel training 利用条項（オプトアウト可） |

## 5. voice-changer-types §2.3 への反映方針

[voice-changer-types §2.3](./voice-changer-types.md#23-クラウド-saas--api) と [§未確定事項](./voice-changer-types.md#未確定事項-phase-3-以降で再評価) を本書の棚卸し結果で更新する。voice-changer-types は**分類ドキュメント**であって個別 SaaS の深掘りは持たないので、**本書（cloud-saas-realtime.md）への参照リンクを足し、§4.1 判定サマリと同じ粒度のラベルだけ載せる**方針とする。各 SaaS の詳細記述は本書側に保持する（同期更新の負担を二重化しないため）。

### 5.1 §2.3 代表例の差し替え案

現在の §2.3 末尾の「代表例」段落:

> **代表例:** CoeFont の声質変換系機能、Resemble AI（Live / Realtime 系プロダクト）、ElevenLabs（Voice Changer 機能）、Voice.ai のクラウド経路など。ただし「配信ソフトに流せるリアルタイム入力ストリームとして提供されているか」は各サービスで条件が異なり、TTS / 録音後変換が中心の製品も多い。リアルタイム配信用途で使えるかは個別に要検証。

更新案（**配信向けリアルタイム経路の有無をラベルで明示し、本書へのリンクで詳細を参照させる**）:

> **代表例とリアルタイム配信経路の有無:** 棚卸しの一次判断は [cloud-saas-realtime.md §4.1](./cloud-saas-realtime.md#41-判定サマリ足切り判断) を参照（最終確認日 2026-05-12）。
>
> - **CoeFont** — 判定 **E（未確認）**。VC LP は "Real-time" を標榜するが、連続マイク入力 / ストリーム出力 / 仮想オーディオ経路の公式技術仕様および ToS 本文が未確認
> - **Resemble AI** — 判定 **C（部分的）**。リアルタイム TTS は WebSocket ストリーミング（200ms TTFS 公称）で揃うが、本書スコープのリアルタイム声変換（Speech-to-Speech）は同期 REST / 最大 5 分 WAV のファイル入力で R1 / R2 非充足
> - **ElevenLabs** — 判定 **C（部分的）**。`speech-to-speech/stream` は応答 SSE のみで、入力はファイル単位（1 セグメント最大 5 分）。公式デスクトップ / OBS プラグイン / 仮想オーディオ連携の公式言及なし
> - **Voice.ai** — 判定 **A（公式リアルタイム配信経路あり）**。デスクトップアプリ "Free Real-Time AI Voice Changer for PC & Mac" が VB-Audio Virtual Cable 経由で OS に仮想入力デバイスとして露出。"Compatible with Streamlabs OBS" を公式明記。商用配信は Starter（$5/月）以上の commercial license プランが ToS 上の前提
>
> 棚卸し対象外の SaaS（Respeecher / Altered AI / Supertone / Voicemod クラウド / Murf.ai / PlayHT / Speechify / Camb.ai 等）は [cloud-saas-realtime.md §7.3](./cloud-saas-realtime.md#73-棚卸し対象に追加する候補-saas本書-phase-1-ではスコープ外) に名前のみ残し、必要が出た時点で個別タスクへ昇格する。

### 5.2 §未確定事項 の更新案

現在の §未確定事項 該当項目:

> §2.3 クラウド SaaS にリアルタイム入力を流し込むユースケースが現実的かは、実例が出てきた時点で再評価する

更新案（**本書での一次判断に置き換える**）:

> §2.3 クラウド SaaS にリアルタイム入力を流し込むユースケースは、[cloud-saas-realtime.md](./cloud-saas-realtime.md) で対象 4 SaaS（CoeFont / Resemble AI / ElevenLabs / Voice.ai）の公式情報源を棚卸し済み（最終確認日 2026-05-12）。**現時点で「マイク入力 → 別声 → 配信ソフトに流せるストリーム出力」を公式機能として提供していると公式情報源で裏が取れたのは Voice.ai のデスクトップアプリ経由 1 件のみ**。Resemble AI / ElevenLabs はリアルタイム TTS は揃っているが本書スコープのリアルタイム声変換は揃わない。CoeFont は技術仕様自体が未確認で再裏取りが必要。後続候補（Respeecher / Altered AI / Supertone / Voicemod クラウド連携 等）は [cloud-saas-realtime.md §7.3](./cloud-saas-realtime.md#73-棚卸し対象に追加する候補-saas本書-phase-1-ではスコープ外) に列挙済み。

## 6. 配信用途で見えてきた論点

本書のスコープは「公式情報源での裏取り」であり、本セクションは**裏取り結果から見えてくる配信用途特有の論点**を整理する。本ラボでの実測値は扱わない（[CLAUDE.md](../../CLAUDE.md) 方針）。

### 6.1 公式に配信向けと位置付けられている SaaS は限定的

§4.1 のとおり、対象 4 SaaS のうち**「マイク入力 → 別声 → 配信ソフトに流せるストリーム出力」を公式機能として提供していると裏が取れた**のは Voice.ai のみ。Resemble AI / ElevenLabs はリアルタイム TTS では公式に WebSocket / SSE ストリーミング（それぞれ 200ms TTFS / ~75ms ベンダー公称）を整備しているが、**本書スコープのリアルタイム声変換（Speech-to-Speech）は同等のストリーミング設計を確認できなかった**。両社とも S2S は「ファイルアップロード → 変換結果ダウンロード」のバッチ型と読める設計が公式ドキュメントの中心で、配信中の連続マイク入力を直接受け付ける公式経路はない。

つまり、SaaS の公式提供範囲としては:

- **リアルタイム TTS は SaaS 各社が公式にストリーミング対応している**（本書スコープ外）
- **リアルタイム声変換は S2S = バッチ型が主流で、配信用デスクトップアプリを公式に出しているのは Voice.ai のみ**

という非対称が見える。voice-changer-types §2.3 の「リアルタイム配信用途で使えるかは個別に要検証」は、本書を経て「**配信用 OSS / ローカル商用ソフトウェアと比べると、リアルタイム声変換の SaaS は選択肢が限定的**」という一次判断にアップグレードできる。

### 6.2 ローカル OSS（§2.1）との比較

[voice-changer-types §2.1 ローカル OSS](./voice-changer-types.md#21-ローカル-oss) で扱う [RVC](./rvc.md) / [so-vits-svc](./so-vits-svc.md) / [Beatrice](./beatrice.md) / [w-okada/voice-changer](./w-okada-voice-changer.md) 系は、VC アプリ側で OS の音声入出力デバイスを掴み、仮想オーディオデバイス（VB-CABLE / VoiceMeeter / BlackHole 等）で OBS に流す前提のソフトウェア設計を持つ。配信ソフトに流す経路は「VC アプリ → 仮想オーディオ → OBS」というローカルパスで完結する。

これに対し本書スコープの SaaS は:

- **Voice.ai**: デスクトップアプリが仮想オーディオデバイス露出を担う点で OSS と同じ経路設計。違いは推論を行う場所（ローカル GPU 完結か / クラウド推論か、公式記述では未確認）
- **Resemble AI / ElevenLabs**: 推論はクラウド、出力経路は開発者が API → 仮想オーディオへ自作する前提（公式デスクトップなし）
- **CoeFont**: VC デスクトップアプリ自体は存在するが、仮想オーディオ連携の公式記述が未確認

OSS は「ローカル GPU 推論 + 仮想オーディオ」までを 1 つの VC アプリ内で組むのが普通だが、SaaS では「推論 = クラウド」「経路 = ローカル」が分離するため、**ローカル / クラウドの境界面が SaaS の選定軸として OSS には現れないレイヤーで効いてくる**。

### 6.3 ネットワーク前提と公称レイテンシ

クラウド推論を前提にする限り、本ラボでの実測値とは別に**最低でも RTT + 推論時間 + ジッタ**が配信レイテンシに乗る。これは OSS のローカル GPU 推論には存在しない構成要素で、**ベンダー公称レイテンシが「処理時間 / TTFS」のみで end-to-end ではないことが多い**点と組み合わせると、配信向けの最終レイテンシは公称値より大きくなる方向に振れる構造がある。

§4.5 のとおり VC 文脈で ms 単位の公称が出ているのは ElevenLabs（~400ms 処理時間）のみで、それも end-to-end ではない。Voice.ai の "in real time" / "instantly"、Resemble の S2S レイテンシ未公称、CoeFont の VC レイテンシ未公称は、配信のリアルタイム要件（[voice-changer-types §4](./voice-changer-types.md#4-配信用途で見るべき主な評価軸) でいう total latency）と直接比較するには情報不足。

ベンダー公称値だけからは「配信に乗るかどうか」は判定できない。**実用判断には個別の実機検証が必要**だが、本書はそれを扱わない（[CLAUDE.md](../../CLAUDE.md) 方針）。実機検証は別タスクへ切り出す（§7.5 参照）。

### 6.4 料金前提と配信のランニングコスト

配信は「連続して長時間動かす」用途であり、**バッチ用途の従量課金とは原価構造が違う**。§4.7 から拾うと:

- **Resemble AI** "AI voice changer": $0.0005 / 秒 = **$0.03 / 分 = $1.80 / 時**
- **ElevenLabs** Voice Changer: $0.12 / 分 = **$7.20 / 時**（共通レート、含まれる分数はプランごと）
- **Voice.ai**: クレジット制で credits / 分の公称換算表なし、VC / TTS / Voice Agents 共通
- **CoeFont**: VC 別建ての従量課金が公式に確認できず、プラン上の VC entitlement も未明示

OSS のローカル GPU 推論は電気代と機材償却のみで時間あたり追加コストが原則発生しない。配信を「数時間/日 × 数日 〜 連日」のスパンで回す前提では、**SaaS の従量課金は配信本数が増えると無視できないランニングになる**。特に ElevenLabs $0.12/分 は 1 時間配信あたり $7.20、月 30 時間配信なら $216 で、Pro $99/月 や Scale $299/月 の含み分数を超える運用なら従量分が積み上がる構造。

加えて Voice.ai / ElevenLabs ともに**無料プランは商用ライセンスを含まない**ため、配信収益化を伴う用途では事実上有料プラン必須。CoeFont は VC のプラン entitlement が公式に明示されていないため、配信導入時に**ベンダーへの問い合わせが必須**になる構造。

### 6.5 利用規約から来る配信用途の論点

§4.8 から見える、配信導入時の意思決定に直接効く ToS 条項:

- **第三者の声を許諾なく再現することは 4 社とも明示的に禁止**（Resemble は要同意、ElevenLabs は許諾された声に限定、Voice.ai は自分の声 / 法的許諾 / 法令で許される範囲、CoeFont は本文未確認だが本ラボ方針として同等に扱う）
- **意図的ななりすまし / 詐欺・誤導目的での使用は 3 社で明示禁止**（CoeFont のみ ToS 未確認）
- **配信での利用可否を ToS が明示的に許可 / 禁止する条項は 4 社いずれも確認できなかった**。実態としては「商用利用可否」「再販禁止」「なりすまし禁止」の組み合わせで配信用途を判断する形になる
- **Voice.ai の "personal, non-commercial use only" 既定 + ハードウェア利用条項**（ユーザー端末を metamodel training に使う、オプトアウト可）は他 3 社にない特徴。配信導入時は明示的にオプトアウトするかを意思決定する必要

[CLAUDE.md](../../CLAUDE.md) 方針との照合では、**第三者の声を許諾なく再現する手順 / 特定キャラクター音声へのクローニング誘導は 4 社いずれの ToS とも独立に本ラボ側で扱わない**。SaaS の機能としては許諾済みの自分の声をクローンする経路がいずれも公式提供されているため、配信用途で SaaS を導入する場合は**自分の声 / 法的に許諾を得た声に限定する運用**が前提になる。

### 6.6 一次判断の要約

本書（公式情報源での裏取りベース）で確定できた一次判断:

- **配信向けにそのまま乗せられる SaaS は Voice.ai 1 件のみ**（A 判定）。残り 3 件は本書スコープのリアルタイム声変換を公式機能として確認できなかったか、技術仕様自体が未確認
- **Resemble AI / ElevenLabs はリアルタイム TTS は公式に揃うが、本書スコープ（声 → 声）は同等の WebSocket 設計が確認できない**。S2S をストリーミング化するには開発者側でセグメント分割を実装する必要があり、配信中の連続マイク入力を直接受ける公式設計ではない
- **CoeFont は本書時点では判定確定不能**（E）。再裏取り（ToS 本文 + VC デスクトップ仕様）の優先度が他 3 件より高い
- **OSS（§2.1）との使い分けの主軸**は、配信のリアルタイム要件（低ジッタ・低 end-to-end レイテンシ）と、SaaS 側のネットワーク / 料金 / 商用 ToS 制約のバランス。OSS は推論を含めてローカル完結し時間あたり追加コストがない一方、SaaS は配信用デスクトップ + 仮想オーディオの整備度に大きな差がある（Voice.ai のみ A、他 3 件はそこに辿り着いていない）

## 7. 未確認事項 / 後続タスク

### 7.1 Phase 3 で完了した項目

Phase 3 で本書に組み込み済み（再掲しない）:

- §4 横断棚卸し表（判定サマリ + 機能粒度 / 提供形態 / R3 経路 / レイテンシ / モデル形態 / 料金 / ToS の 7 項目別比較表）
- §5 voice-changer-types §2.3 / §未確定事項 への更新差分案
- §6 配信用途で見えてきた論点（OSS との比較、ネットワーク前提、料金前提、ToS 観点、一次判断の要約）

§5 の更新差分案は本書とは別タスクで voice-changer-types.md 側に反映する（§7.5 参照）。

### 7.2 Phase 2 で残った SaaS 別の未確認事項

各 SaaS の §3 末尾「未確認事項」サブセクションに詳細を記載済み。**配信用途で結論を確定させるために優先度の高い再裏取り項目**:

- **CoeFont**: 利用規約（Notion ホスト、本セッションでは WebFetch 権限拒否で本文未確認）の配信利用 / 商用配信 / 第三者クローニング条項。VC デスクトップアプリのサインアップ後画面でしか確認できない仕様（OS 対応・仮想オーディオ連携・出力デバイス選択）。**§1.4 判定ラベルが E のままなので、ここが埋まらないと棚卸し表で確定できない（再裏取りで A〜D のいずれにも転びうる）**
- **Resemble AI**: Speech-to-Speech が WebSocket（`wss://websocket.cluster.resemble.ai/stream`）で実行できるかの公式記述。製品ページ「Streaming: supported on all model versions」が指す具体的なエンドポイント・プロトコル。Speech-to-Speech のベンダー公称レイテンシ
- **ElevenLabs**: 公式デスクトップアプリ / OBS プラグイン / 仮想オーディオデバイス連携の有無（公式ページで言及未確認）。Speech-to-Speech に対するチャンク入力 / WebSocket 入力 API の有無。ライブ配信 / ブロードキャストでの利用可否の ToS 明文条項
- **Voice.ai**: Voice Changer の音声変換がローカル GPU 完結か、クラウド推論経由かの公式記述。macOS 版の対応バージョン・Apple Silicon 対応。speech-to-speech 用の独立した REST / WebSocket エンドポイントの公開有無

### 7.3 棚卸し対象に追加する候補 SaaS（本書 Phase 1 ではスコープ外）

必要が出た時点で個別タスクに昇格する:

- **Respeecher**（公式に "Live" 系プロダクトを案内している。ポストプロダクション・吹替向けのリアルタイム声変換）
- **Altered AI / Altered Studio**（"Altered Live" として配信向けリアルタイム機能を案内している）
- **Supertone**（Supertone Shift デスクトップ製品 + Supertone API。配信向けリアルタイム声変換と API 提供を併せ持つ）
- **Voicemod クラウド連携**（本来 [voice-changer-types §2.2](./voice-changer-types.md#22-ローカル商用ソフトウェア) 側だが、クラウド API 提供があるか確認）
- **Murf.ai / PlayHT / Speechify / Camb.ai 等の TTS 寄り SaaS**（リアルタイム VC を提供しているかの最低限の確認のみ。提供していなければ本書のスコープ外として確定）

### 7.4 規約・プライシングの再確認

本書の判定は **最終確認日 (2026-05-12)** 時点での公式情報源に基づくため、Phase 3 完了後も**規約・プライシングの定期再確認タスク**として残す。料金プラン名・価格・利用規約はベンダー側で変動が早く、特に商用 / 配信利用条項は本書の足切り判断を直接書き換える可能性がある。

### 7.5 TODO.md に上げる後続タスク

本書の結論を受けて、[TODO.md](../../TODO.md)（ボイスチェンジャー個別調査セクション）に新規タスクとして上げるべき項目:

- **（高優先）CoeFont 再裏取り**: ToS 本文（Notion ホスト）の取得 + VC デスクトップアプリ実機での OS 対応・仮想オーディオ連携・出力デバイス選択の確認。判定ラベルを E から A〜D のいずれかへ確定させる
- **（中優先）Resemble AI Speech-to-Speech のストリーミング経路確認**: WebSocket `wss://websocket.cluster.resemble.ai/stream` での S2S 利用可否と、製品ページ "Streaming: supported on all model versions" の具体的エンドポイント
- **（中優先）ElevenLabs Speech-to-Speech のチャンク入力 / WebSocket 入力 API の有無 + ライブ配信での利用可否 ToS 明文条項**の追跡（公式ロードマップが公開された場合の再確認）
- **（中優先）Voice.ai Voice Changer の推論ロケーション（ローカル GPU / クラウド）の公式記述確認**: 配信のレイテンシ評価軸で意思決定に直接効く
- **（低優先）§7.3 候補 SaaS の棚卸し**: Respeecher / Altered AI / Supertone / Voicemod クラウド連携 / Murf.ai 系。各 SaaS について本書 §1.3 の判定基準を当てはめた最低限の確認
- **（低優先）規約・プライシング再確認**: 2026-05-12 を基準とした半年〜1年スパンの再確認（§7.4）
- **（別タスク）voice-changer-types.md §2.3 / §未確定事項 を §5 差分案に従って更新**: 本書の更新差分案を voice-changer-types 側に反映する作業（本タスクの後片付け Phase で同時実施する場合は別 TODO 化不要）
