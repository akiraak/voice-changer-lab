# voice-changer-lab

配信などで使う**リアルタイム声変換**について、手法・ツール・セットアップを調査・検証するための個人ラボリポジトリです。

## 目的

- ライブ配信や通話で利用できるリアルタイム声変換の選択肢を整理する
- 各ツールの**遅延・音質・必要GPU性能・運用コスト**を実際に試して比較する
- OBS / 配信ソフトとの連携手順や、安定運用のための設定を記録する
- 後から自分が見返したときに再現できる粒度でメモを残す

## スコープ

含めるもの:

- リアルタイム実行を前提とした声変換ツール (例: RVC, w-okada/voice-changer, Beatrice, Voidol, Voicemod など)
- ローカルGPUで動かす構成を中心に据え、必要に応じてクラウド/商用サービスにも触れる
- OBS・配信ソフト・仮想オーディオデバイス (VB-CABLE, VoiceMeeter 等) との接続

含めないもの:

- オフライン・バッチ処理専用のボイスチェンジ (録音済み音声の事後変換)
- TTS 単体の比較 (声変換と関係する範囲では言及する場合あり)

## リポジトリの構成 (予定)

```
.
├── README.md          # このファイル
├── CLAUDE.md          # Claude Code 向けの作業ガイド
├── TODO.md / DONE.md  # タスク管理 (vibeboard で編集)
├── vibeboard/         # ローカル管理画面 (vendor: github.com/akiraak/vibeboard)
├── docs/
│   ├── plans/         # 作業着手時のプランファイル (完了後は plans/archive/ へ)
│   └── specs/         # ツールごとの調査メモ・比較表
└── experiments/       # セットアップ手順・実測ログ
```

ディレクトリは検証を進めながら追加していきます。

## ローカル管理画面 (vibeboard)

タスクとプランを一覧/編集するためのローカル UI として [vibeboard](https://github.com/akiraak/vibeboard) を vendor 取り込みしています。

セットアップ (初回のみ):

```bash
cd vibeboard && npm install
```

起動 (リポジトリ直下から):

```bash
./run-vibeboard.sh            # デフォルトポート 3010 で起動
./run-vibeboard.sh --port 3020 # ポート変更などの追加引数はそのまま渡せる
```

`run-vibeboard.sh` は内部で `node vibeboard/dist/cli.js --root <repo>` を呼び出します。

ブラウザで `http://localhost:3010` を開くと `docs/plans/` / `docs/specs/` / `TODO.md` / `DONE.md` を閲覧・編集できます。ポートは `--port` か `VIBEBOARD_PORT` で変更可能です。

> **WSL2 での注意**: ホスト (Windows) 側で `docs/` 配下を直接編集した場合、`fs.watch` が変更を拾わずに UI が更新されないことがあります。WSL 内のエディタから編集するか、`R` キーで手動再取得してください。

## ライセンス・素材の取り扱い

- 学習済みモデル・音声素材・話者データを扱う場合は、配布元の利用規約を都度確認する
- 第三者の声を再現する用途で本リポジトリの成果物を使うことは想定しない
- コード自体のライセンスは [LICENSE](./LICENSE) を参照
