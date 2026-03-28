# UI Polish Audit Inventory

## Purpose

`T-512` の棚卸し結果をページごとに残す。

このメモは、次の UI 修正を始める前の keep/remove/unify 一覧として使う。

## Audit Rules

- 見て分かる内容の helper text は削る
- 同じ意味の見出し、カード、説明は page をまたいで統一する
- active path にある画面だけを対象にする
- 実装はまだ始めず、まず残すものと消すものを固定する

## 1. Login

対象:
- [app/views/sessions/new.html.erb](../app/views/sessions/new.html.erb)

現状:
- authenticated shell と完全に別デザイン
- brand panel と form panel の二段構成が強すぎる
- 説明文が重複している
- `Discord Login` / `招待制ログイン` / feature list が同時にあり情報が多い

Keep:
- `Discord でログイン` の主導線
- 招待制であることの短い説明
- flash

Remove:
- feature list
- 同じ意味の説明の重複
- `Discord Login` の英語 kicker

Unify:
- app shell と同じ dark palette
- 見出し、カード角丸、border tone
- flash 表示

Decision:
- `T-513` で最優先で直す

## 2. Server Index

対象:
- [app/javascript/pages/servers/index.jsx](../app/javascript/pages/servers/index.jsx)

現状:
- 上段 summary は概ね整理済み
- helper text がまだ少し多い
- `現在の表示`、`プレイヤーには接続先だけ共有すれば十分です。` は説明過多
- empty state もやや説明が長い

Keep:
- summary cards
- search
- connection-first の server card

Remove:
- stat card の `現在の表示`
- 検索欄横の補助文
- empty state の説明のうち冗長な部分

Unify:
- 見出し周りの eyebrow / title / short copy の密度

## 3. Server Create

対象:
- [app/javascript/pages/servers/new.jsx](../app/javascript/pages/servers/new.jsx)

現状:
- grouping は改善済み
- まだ helper text の要不要を個別判定する余地がある
- `MOTD` は説明維持でよい
- hostname と runtime family は補足が必要

Keep:
- hostname 制約
- runtime family の説明
- `MOTD` の説明
- connection preview
- quota card

Remove candidate:
- 難易度、ゲームモード、PvP の説明
- create confirmation 側の冗長なラベル補足

Unify:
- Paper 内の section title 密度
- Switch / Select / NumberInput の揃い

## 4. Server Detail

対象:
- [app/javascript/pages/servers/show.jsx](../app/javascript/pages/servers/show.jsx)

現状:
- 主要情報の整理は進んでいる
- panel 数が増えてきたので優先度の再確認が必要
- startup settings は section 分離済み
- logs / whitelist / bounded RCON / startup settings の見出しトーンを揃えたい

Keep:
- top header
- abnormal-only alert
- player panel
- logs
- whitelist
- bounded RCON
- startup settings

Remove candidate:
- panel ごとの過剰な helper text
- owner/admin 向け補足文のうち自明なもの

Unify:
- panel title line
- refresh/save button placement
- read-only vs editable section wording

## 5. Membership

対象:
- [app/javascript/pages/servers/members/index.jsx](../app/javascript/pages/servers/members/index.jsx)

現状:
- shell に比べて plain で、密度配分が古い
- owner block が少し浮いている
- helper text は多くないが、table と add form の強弱を調整したい

Keep:
- owner summary
- add member form
- current membership table

Remove candidate:
- `接続先` 行は detail への戻り先で十分なら弱める

Unify:
- page hero を他画面と同じトーンへ
- add form card と list card の hierarchy
- role label language

## 6. Invite

対象:
- [app/javascript/pages/discord_invitations/index.jsx](../app/javascript/pages/discord_invitations/index.jsx)

現状:
- 機能は揃っているが説明がやや多い
- `raw token は保存しない...` と最下部説明が近い意味で重なる
- 発行済み一覧は十分

Keep:
- pending invite URL alert
- issue form
- issued table

Remove candidate:
- 発行フォーム下の長い説明
- pending URL alert 内の重複説明

Unify:
- create/detail と同じ hero density
- status badge tone

## 7. Shell / Navigation

対象:
- [app/javascript/layouts/AppLayout.jsx](../app/javascript/layouts/AppLayout.jsx)

現状:
- 基本トーンは揃っている
- page title / subtitle の差がページごとに揺れる

Keep:
- current user pill
- Japanese role labels
- simple nav

Unify:
- page-level hero usage
- flash spacing
- subtitle の有無と長さ

## Suggested Execution Order

1. login
2. invite
3. membership
4. index
5. create
6. detail
7. shell final pass
