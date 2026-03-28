# UI Polish Audit Strategy

## Purpose

`T-503` の残りを場当たりで直さず、全画面を同じ基準で棚卸しするための方針を固定する。

## Scope

- authenticated shell
- server index
- server create
- server detail
- server membership management
- invite issuance / revocation
- Discord login
- invite redemption entry
- その他 active path 上の operator-facing page

## Goals

- 説明文を必要最小限にする
- 画面ごとの見た目のトーンを揃える
- 情報量の強弱を整理する
- 同じ意味の UI 要素を同じ見た目で統一する

## Copy Rules

### Baseline Rule

- 見て分かる内容には説明文を付けない
- ラベルだけで意味が通るなら helper text は置かない
- 操作結果が明白なら補足文は置かない
- 例外は、意味が推測しにくい語や Minecraft 固有用語のみ

### Keep Helper Text Only When

- `MOTD` のように略語だけでは伝わりにくい
- 次回起動時反映のように反映タイミングが UI だけでは分からない
- 入力制約を見落としやすい
- 失敗時の次の行動を示す必要がある

### Remove Helper Text When

- `難易度`, `ゲームモード`, `メモリ`, `最大プレイヤー数` のようにラベル自体で役割が明確
- ボタン文言で動作が十分に分かる
- 同じ説明を複数画面で繰り返している

## Visual Rules

### Shared Tone

- ログイン画面も authenticated shell と同じ色調、余白感、角丸、枠線トーンに揃える
- 特定ページだけ別プロダクトに見えるレイアウトを作らない
- 装飾は増やさず、情報のまとまりをカードと余白で見せる

### Form Rules

- 項目は意味単位でグループ化する
- 同じ種類の入力は同じ横幅とラベル位置に揃える
- `Switch`, `Select`, `TextInput`, `NumberInput` が混在しても、行の高さと揃いを崩さない
- helper text を置く場合でも 1 行で終える

### Page Rules

- 上段に「何の画面か」「主要操作」を置く
- 中段に主情報
- 下段に補助情報
- lower-priority 情報は主カードに混ぜない

## Page-by-Page Audit Targets

### 1. Login

- 管理画面と同じ visual system に揃える
- 説明文は最小限
- Discord ログイン導線だけを強く見せる
- 招待制の説明は 1 箇所に圧縮する

### 2. Server Create

- 基本情報、起動設定、確認の 3 ブロックで整理する
- helper text は入力判断に必要なものだけ残す
- 起動設定は意味単位で grouping する

### 3. Server Detail

- connection / action / ownership / runtime reads の優先度を保つ
- whitelist, logs, startup settings, RCON を横並びのノイズにしない
- startup settings は real-time / restart-applied の presentation を明確に分ける

### 4. Membership

- role 名と権限の意味を簡潔に揃える
- invite 導線と現在メンバー一覧の役割を明確に分ける

### 5. Invite

- 発行、コピー、失効の 3 操作に絞って見せる
- token や内部状態は operator が必要な範囲だけ出す

### 6. Other Pages

- active path にある画面だけを対象にする
- dead path や historical screen は polishing 対象に含めない

## Execution Order

1. login
2. create
3. detail
4. membership
5. invite
6. shell / navigation final pass

## Current Agreement

- まずは strategy doc だけを固定する
- 実装は、この棚卸し結果に合意してから進める
