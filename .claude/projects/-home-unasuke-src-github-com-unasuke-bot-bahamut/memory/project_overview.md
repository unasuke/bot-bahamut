---
name: Project Overview
description: bot-bahamut — Ruby (Ruboty) 製 Discord bot。Splatoon情報提供とチャット応答機能。
type: project
---

Ruby製のDiscord bot。Rubotyフレームワークを使用。

**主な機能:**
- Splatoonのブランド・ギアパワー情報、ステージスケジュール表示 (ikasuke handler)
- チャット応答 (「眠い」→「寝てくれ」、「10マナ」→「燃やしてやる」)

**デプロイ:** GitHub Actions → ghcr.io (linux/amd64, arm64)。Heroku対応のProcfileもあり。

**Why:** unasukeが個人で運用しているDiscordコミュニティ向けbot。

**How to apply:** 変更はシンプルに保つ。Ruby 2.7.6、Ruboty のハンドラーパターンに従う。
