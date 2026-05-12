# TODO

vibeboard で編集するタスクリスト。運用ルールは [CLAUDE.md](./CLAUDE.md) の「タスク管理ルール」「作業着手ルール」を参照。

## ボイスチェンジャー個別調査

[voice-changer-types](./docs/specs/voice-changer-types.md) の Phase 2 で挙げた代表例から派生した個別調査。各タスク着手時に `docs/plans/<task-name>.md` を作り、結果は `docs/specs/<tool-name>.md` に書く。冒頭で voice-changer-types の分類のどこに該当するかを 1 行で示す。

- [ ] RVC の仕様調査（Retrieval ベース VC、話者依存型）
- [ ] so-vits-svc の仕様調査（コンテンツ表現 + 話者条件付け系、話者依存型）
- [ ] Beatrice の仕様調査（OSS、配信向け軽量を謳う系統。実装系統は要裏取り）
- [ ] クラウド SaaS のリアルタイム入力対応棚卸し（CoeFont / Resemble AI / ElevenLabs / Voice.ai 等の現状確認）
- [ ] w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認とキャラクター音声利用条件（つくよみちゃん / あみたろ / 琴葉茜 等）の整理（[spec §7](docs/specs/w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点) の深堀。キャラクター音声モデルに踏み込む前段）
- [ ] w-okada/voice-changer の実測タスク用 `experiments/` テンプレート整備（device mode / monitor 分離 / サンプリングレート / CHUNK / EXTRA / F0 抽出方式 等の計測条件記録テンプレ。後続モデル実測の足場）

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
