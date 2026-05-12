# TODO

vibeboard で編集するタスクリスト。運用ルールは [CLAUDE.md](./CLAUDE.md) の「タスク管理ルール」「作業着手ルール」を参照。

## ボイスチェンジャー個別調査

[voice-changer-types](./docs/specs/voice-changer-types.md) の Phase 2 で挙げた代表例から派生した個別調査。各タスク着手時に `docs/plans/<task-name>.md` を作り、結果は `docs/specs/<tool-name>.md` に書く。冒頭で voice-changer-types の分類のどこに該当するかを 1 行で示す。

### クラウド SaaS - 追加裏取り

[cloud-saas-realtime.md](docs/specs/cloud-saas-realtime.md) の派生。判定ラベル / レイテンシ評価軸を確定させるための追加調査。

- [ ] **[高]** CoeFont 再裏取り: ToS 本文（Notion ホスト）+ VC デスクトップアプリの OS 対応・仮想オーディオ連携・出力デバイス選択を実機で確認し、[cloud-saas-realtime.md §4.1](docs/specs/cloud-saas-realtime.md#41-判定サマリ足切り判断) の判定ラベルを E から A〜D のいずれかへ確定させる
- [ ] **[中]** Resemble AI Speech-to-Speech のストリーミング経路確認: WebSocket `wss://websocket.cluster.resemble.ai/stream` での S2S 利用可否と、製品ページ "Streaming: supported on all model versions" の具体的エンドポイント
- [ ] **[中]** ElevenLabs Speech-to-Speech のチャンク入力 / WebSocket 入力 API の有無 + ライブ配信での利用可否 ToS 明文条項（公式ロードマップ更新時に再確認）
- [ ] **[中]** Voice.ai Voice Changer の推論ロケーション（ローカル GPU / クラウド）の公式記述確認（配信のレイテンシ評価軸で意思決定に直接効く）

### クラウド SaaS - 継続棚卸し

- [ ] **[低]** 候補 SaaS の棚卸し: Respeecher / Altered AI / Supertone / Voicemod クラウド連携 / Murf.ai / PlayHT / Speechify / Camb.ai。各 SaaS について [cloud-saas-realtime.md §1.3](docs/specs/cloud-saas-realtime.md#13-リアルタイム入力対応と判定する条件) の判定基準を当てはめた最低限の確認
- [ ] **[低]** クラウド SaaS 棚卸しの規約・プライシング再確認: 2026-05-12 を基準とした半年〜1年スパンの再確認（[cloud-saas-realtime.md §7.4](docs/specs/cloud-saas-realtime.md#74-規約プライシングの再確認)）

### OSS ホスト / モデル

- [ ] w-okada/voice-changer の LICENSE / LICENSE-NOTICE 全文確認とキャラクター音声利用条件（つくよみちゃん / あみたろ / 琴葉茜 等）の整理（[spec §7](docs/specs/w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点) の深堀。キャラクター音声モデルに踏み込む前段）

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
