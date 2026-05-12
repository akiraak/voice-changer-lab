# experiments/w-okada-voice-changer

[w-okada/voice-changer (VCClient)](../../docs/specs/w-okada-voice-changer.md) 経由でモデルを動かした実測ログ置き場。

VCClient は[ハイブリッド型ホスト](../../docs/specs/voice-changer-types.md#14-ハイブリッド)で「複数モデルを切り替えて動かす実行ホスト」のため、レイテンシ / GPU 使用量 / 音質といった評価軸は**ロードする個別モデル**（RVC / Beatrice v2 / so-vits-svc 等）**と組み合わせて初めて値が出る**。このサブディレクトリでは、VCClient 設定とロード対象モデルをセットで記録する形でログを残す。

## ファイル構成

- [`_template.md`](./_template.md) — 実測ログのテンプレ本体（値を一切含まない骨格）
- `YYYY-MM-DD_<model>_<env>.md` — 個別の実測ログ（このサブディレクトリ直下に置く）

## ファイル命名規約

実測ログのファイル名は以下の形式に揃える（[../README.md](../README.md#ファイル命名規約) 参照）。

```
YYYY-MM-DD_<model>_<env>.md
```

- `<model>` の例: `rvc-v2-someone` / `beatrice-v2-someone` / `so-vits-svc-someone`
- `<env>` の例: `winpc-rtx4090` / `mac-m2pro`
- 複数モデルを横並び比較する場合は `<model>` を `compare` 等にし、本文「モデル」セクションで対象一覧を明記する

VCClient のホスト名はファイル名に含めない（このサブディレクトリ配下に置いてあること自体が「VCClient 経由」を示すため）。

## テンプレの使い方

1. `_template.md` をコピーして上記の命名規約でリネーム
2. テンプレの全 7 セクションを上から順に埋める
3. 値が無い欄は空欄にせず **`未計測`** または **`n/a`**（その条件では存在しない項目、例: Server device mode 時の Echo / Sup1 / Sup2）と明示する
4. **計測値には必ず計測方法と計測時の負荷状況を併記**する（[../README.md](../README.md#共通の記入ルール) 参照）
5. **モデルのライセンス / 利用条件を確認していないモデルでの計測ログは残さない**（[../../CLAUDE.md](../../CLAUDE.md) 方針）

## 記録項目の出典

`_template.md` の各セクションは [w-okada-voice-changer.md](../../docs/specs/w-okada-voice-changer.md) の以下と 1:1 対応している。

| テンプレセクション | 出典 spec セクション |
| --- | --- |
| 環境 / VCClient エディション | [§2.4 配布形態とエディション](../../docs/specs/w-okada-voice-changer.md#24-配布形態とエディション) |
| VCClient 設定（共通 UI） | [§4.1 共通 UI 上のパラメータ](../../docs/specs/w-okada-voice-changer.md#41-共通-ui-上のパラメータrvc-チュートリアルでの表記) |
| VCClient 設定 / device mode | [§5.1 2 系統の device mode](../../docs/specs/w-okada-voice-changer.md#51-2-系統の-device-mode) |
| VCClient 設定 / input・output・monitor | [§5.2 input / output / monitor の 3 デバイス構成](../../docs/specs/w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537) |
| モデル / モデル種類・スロット | [§3 対応モデル一覧と切替の仕組み](../../docs/specs/w-okada-voice-changer.md#3-対応モデル一覧と切替の仕組み) |
| モデル / モデル固有パラメータ | [§4.2 モデル固有のパラメータ](../../docs/specs/w-okada-voice-changer.md#42-モデル固有のパラメータ) |
| モデル / ライセンス確認 | [§7 ライセンス / 配布物の利用条件](../../docs/specs/w-okada-voice-changer.md#7-ライセンス--配布物の利用条件と本ラボで扱う際の注意点) |
| 計測結果 / レイテンシ計測手段 | [§4.3 UI 全体・モニタリング系（バッファ可視化）](../../docs/specs/w-okada-voice-changer.md#43-ui-全体モニタリング系) |
| 配信ソフト連携 | [§6 配信ソフト（OBS 等）との接続パターンの公式言及](../../docs/specs/w-okada-voice-changer.md#6-配信ソフトobs-等との接続パターンの公式言及) |

spec 側の構成が変わった場合は、上の対応表とテンプレの参照リンクを揃えて更新する。

## テンプレ整備時の VCClient バージョン

このテンプレは spec で参照している以下のバージョン情報を前提に作成している。

- **device mode（Client / Server）**: v.1.5.2.9 で Server device mode が追加（[§5.1](../../docs/specs/w-okada-voice-changer.md#51-2-系統の-device-mode)）
- **input / output / monitor の 3 デバイス分離**: v.1.5.3.7〜（[§5.2](../../docs/specs/w-okada-voice-changer.md#52-input--output--monitor-の-3-デバイス構成server-device-modev1537)）
- **CHUNK の選択肢拡張**: v.2.0.78-beta（[§4.3](../../docs/specs/w-okada-voice-changer.md#43-ui-全体モニタリング系)）
- **バッファ可視化 / ショートカットキー**: v.2.1.3-alpha（[§4.3](../../docs/specs/w-okada-voice-changer.md#43-ui-全体モニタリング系)）
- **Beatrice 系**: v.2.0.73-beta で pitch / formant 反映バグ修正、v.2.0.76-beta でオートピッチシフト / 話者マージ追加（[§4.2](../../docs/specs/w-okada-voice-changer.md#42-モデル固有のパラメータ)）

これより新しいバージョンで UI 露出パラメータが変わった場合は、テンプレ更新を spec 更新とセットで行う（テンプレだけ先行して項目を増やさない）。

## VCClient を介さない単体実測について

このサブディレクトリは **VCClient 経由でモデルを動かす前提**。RVC / Beatrice / so-vits-svc 等を VCClient を介さず単体 CLI / SDK で動かす計測が必要になったら、そのツール用のサブディレクトリ（例: `experiments/rvc/`）を別途切って派生テンプレを用意する。
