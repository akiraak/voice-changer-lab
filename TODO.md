# TODO

vibeboard で編集するタスクリスト。運用ルールは [CLAUDE.md](./CLAUDE.md) の「タスク管理ルール」「作業着手ルール」を参照。

## ボイスチェンジャー個別調査

[voice-changer-types](./docs/specs/voice-changer-types.md) の Phase 2 で挙げた代表例から派生した個別調査。各タスク着手時に `docs/plans/<task-name>.md` を作り、結果は `docs/specs/<tool-name>.md` に書く。冒頭で voice-changer-types の分類のどこに該当するかを 1 行で示す。

- [ ] w-okada/voice-changer の仕様調査（OSS 実行ホスト。RVC / so-vits-svc 等のモデル切替・前処理・IO 配線） [plan](docs/plans/w-okada-voice-changer.md)
  - [x] Phase 1: 公式リポジトリから全体アーキテクチャ・対応モデル・配布形態/ライセンスを整理
  - [x] Phase 2: 前処理 / 後処理 / IO 構成 / OBS 等との接続パターンを整理
  - [ ] Phase 3: voice-changer-types §4 評価軸への暫定マッピングと後続調査タスク起票
- [ ] RVC の仕様調査（Retrieval ベース VC、話者依存型）
- [ ] so-vits-svc の仕様調査（コンテンツ表現 + 話者条件付け系、話者依存型）
- [ ] Beatrice の仕様調査（OSS、配信向け軽量を謳う系統。実装系統は要裏取り）
- [ ] クラウド SaaS のリアルタイム入力対応棚卸し（CoeFont / Resemble AI / ElevenLabs / Voice.ai 等の現状確認）

## 配信周辺ツール調査

- [ ] 仮想オーディオデバイスまとめ（VB-CABLE / VoiceMeeter Banana・Potato / BlackHole）
- [ ] OBS Studio との接続パターンまとめ（入出力デバイス・モニタリング・遅延ハンドリング）

## 候補プール（必要になったら個別タスクに昇格）

候補から外したわけではなく、優先順位的に後回し。個別調査に着手する段階で上のセクションへ移す。

- MMVC（多話者 / 話者非依存系の代表）
- DDSP-SVC（DSP × ニューラルの歌声変換系）
- Voicemod（商用デスクトップ、プリセット型）
- Voidol（商用デスクトップ）
- ノイズ抑制 / ゲートの選定軸まとめ（NVIDIA Broadcast / Krisp / RNNoise）
