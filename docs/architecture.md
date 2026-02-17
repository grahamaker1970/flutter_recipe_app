# アーキテクチャ概要

## 1. システム構成
本アプリは Flutter クライアント単体で動作し、データをローカル SQLite に保存する。
現状のコードはシンプルさを優先し、主に `lib/main.dart` に集約されている。

- UI 層: 画面描画、入力処理、画面遷移
- ドメイン層: レシピ、材料、メモのモデル
- データ層: `DbService` による SQLite アクセスと永続化処理

## 2. コンポーネント

### 2.1 エントリーポイント
- `main()` で Flutter バインディングを初期化する。
- Web では `databaseFactoryFfiWeb` を設定する。
- `DbService.instance` を初期化してから `RecipeApp` を起動する。

### 2.2 ドメインモデル
- `MasterRecipe`: レシピの集約ルート
- `IngredientItem`: 基準量と調整量を持つ材料
- `AdjustmentNote`: 保存された調整メモ
- `NoteItem`: メモ内に保存される材料スナップショット

### 2.3 データアクセス
- `DbService` はシングルトンで実装されている。
- DB 初期化、レシピ CRUD、メモ永続化を担当する。
- Web で初期化に失敗した場合は `inMemoryDatabasePath` にフォールバックする。

### 2.4 画面構成
- `RecipeListScreen`: レシピ一覧と主要アクション
- `MasterRecipeEditorScreen`: レシピ作成・編集
- `LiveCalculatorScreen`: 比例計算とメモ保存
- `HistoryScreen`: レシピ単位のメモ履歴

## 3. データベース設計

### 3.1 テーブル
- `recipes(id, name)`
- `ingredients(id, recipe_id, name, base_amount)`
- `notes(id, recipe_id, title, memo, created_at)`
- `note_items(id, note_id, name, base_amount, adjusted_amount)`

### 3.2 リレーション
- `recipes` 1:N `ingredients`
- `recipes` 1:N `notes`
- `notes` 1:N `note_items`

## 4. 主要実行フロー

### 4.1 レシピ保存フロー
1. UI がレシピ名と材料行をバリデーションする。
2. UI が `DbService.insertRecipe` または `DbService.updateRecipe` を呼ぶ。
3. 保存後、ストレージから一覧を再読込する。

### 4.2 ライブ計算フロー
1. ユーザーが1つの調整量を編集する。
2. 当該材料の `adjusted/base` で倍率を計算する。
3. その倍率を全材料へ適用し、UI を更新する。

### 4.3 メモ保存フロー
1. 現在の材料値を `NoteItem` に変換する。
2. `notes` にメモヘッダを保存する。
3. `note_items` に明細行をバッチ保存する。

## 5. プラットフォーム別ストレージ
- Web 以外: アプリ documents 配下の SQLite ファイル `recipe_app.db`
- Web: `sqflite_common_ffi_web` を利用し、初期化エラー時はメモリDBへフォールバック

## 6. 現状トレードオフと今後の分割
- 単一ファイル構成は小規模アプリでセットアップと追跡が容易。
- 機能拡張時は責務ごとに以下へ分割する。
  - `lib/models/`
  - `lib/services/`
  - `lib/screens/`
  - `lib/widgets/`
