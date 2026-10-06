# Rainpans

廃墟の屋上で、雨を集めて音にするアンビエント・インクリメンタルゲーム。
空き缶やヘルメット、ドラム缶を好きな場所に置くと、当たった雨粒がそのまま音になります。
集めた「響き」で雨脚を強め、新しい雨受けを見つけ、崩れた街の奥へ進みます。

- エンジン: Godot 4.3（GL Compatibility）
- 解像度: 320×180（整数倍拡大）
- アート・音はすべてコードで生成（画像・音声ファイルなし。フォントのみ同梱）

## 遊び方

| 操作 | 内容 |
| --- | --- |
| 棚（Tab / B） | 雨受けを買う・ドラッグで置く |
| 手入れ（U / E） | 雨脚・雨樋・残響などの強化、場所の移動 |
| クリック | 置いた雨受けを自分で鳴らす |
| A〜L ／ 1〜0 キー | 左から順に雨受けを鳴らす（キーボードで演奏） |
| ホイール | 雨受けの音程を上下させる（音階の中で） |
| ドラッグ | 置いた雨受けを動かす（左右で音程が変わる） |
| 右クリック / 棚へドロップ | 雨受けを棚に戻す |
| ・・・（Esc） | 音量、拍にそろえる、全画面、雨の手帳 |

音程は左から右へ D メジャー・ペンタトニックを上っていくので、どう並べても濁りません。
ひさしの下は雨が当たりませんが、縁から落ちるしずくが一定のリズムを刻みます。

## 開発

```sh
tools/setup_godot.sh          # Godot 4.3 を ~/.local/share/godot に入れる（冪等）
godot --path .                # 起動
tools/shot.sh shots/a.png --demo --frames=120   # 仮想ディスプレイでスクリーンショット
tools/test.sh                 # ヘッドレスのロジックテスト
tools/scenario.sh drag        # 入力を再生して配置操作を確認
tools/check.sh                # GDScript の構文チェック
tools/ci.sh                   # 上の確認をまとめて実行
tools/balance_sim.py          # 経済バランスのシミュレーション
```

### 書き出し

```sh
tools/export.sh               # build/web（ブラウザ版）と build/windows/Rainpans.exe を作る
```

`.github/workflows/pages.yml` は main へのマージ時に Web 版を GitHub Pages へ公開します
（リポジトリの Settings → Pages で Source を「GitHub Actions」にすると有効になります）。

`--demo` はドラムを並べた状態から始めるデバッグ用フラグ、`--shelf` / `--upgrades` はパネルを開いた状態で起動します。
クラウドセッションでは `.claude/settings.json` の SessionStart フックが Godot を自動で入れます。

## 構成

```
src/
  autoload/  game.gd（経済・保存）, synth.gd（モーダル合成・バス）
  data/      drum_defs.gd（雨受けの見た目・音・価格）
  gfx/       pal.gd（パレット）, pix_canvas.gd（ドット描画）
  world/     stage.gd, rain.gd, drum.gd, ripples.gd, smoke.gd, env_fx.gd, areas/
  ui/        hud.gd, shelf.gd, upgrades_panel.gd, ui_kit.gd
```

## クレジット

- フォント: PixelMplus10（M+ FONTS License, `assets/fonts/LICENSE_PixelMplus.txt`）
