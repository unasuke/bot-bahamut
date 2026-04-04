# bot-bahamut

メンションに対してClaude AIで返答するDiscord bot。

## 技術スタック

- Ruby 4.0.2
- ruboty (botフレームワーク) + ruboty-discord (Discordアダプタ)
- Anthropic Ruby SDK (`anthropic` gem)
- Kamal 2 によるデプロイ
- GitHub Actions (CI/CD: Docker image build + Kamal deploy)

## プロジェクト構成

```
handlers.rb          # エントリポイント。ruboty --load で読み込まれる
handlers/ai_reply.rb # Handler: メンションを受け取りActionに委譲
actions/ai_reply.rb  # Action: Anthropic APIとのagentic loop実装
lib/ruboty/patches/  # discord_typing.rb - typing表示のためのモンキーパッチ
lib/tool_handlers/   # memories.rb - memory toolのファイル操作ハンドラ
config/deploy.yml    # Kamal設定
compose.yaml         # ローカル開発用Docker Compose
Dockerfile           # Ruby 4.0.2ベースのコンテナ
```

## 主要な処理フロー

1. ruboty がDiscord上のメンションを検知
2. `Handlers::AiReply` がメッセージを受け取る
3. `Actions::AiReply#call` で Anthropic Messages API を呼び出す (agentic loop)
4. web_search, web_fetch, memory ツールを使いながら応答を生成
5. テキストブロックごとにDiscordへ逐次返信し、最後に参照URLをまとめて送信

## 環境変数

- `RUBOTY_NAME` - botの名前
- `DISCORD_TOKEN` - Discord Botトークン
- `ANTHROPIC_API_KEY` - Anthropic APIキー
- `ANTHROPIC_MODEL` - 使用するモデル (省略時: `claude-haiku-4-5`)
- `LOCAL` - 設定するとDiscordアダプタ・typing表示をスキップ (ローカル開発用)
- `MEMORIES_DIR` - memoryツールの保存先 (省略時: `/var/bot-bahamut/memories`)

## ローカル実行

```shell
LOCAL=1 RUBOTY_NAME=bahamut ANTHROPIC_API_KEY=xxx bundle exec ruboty --load handlers.rb
```

## デプロイ

masterブランチへのpushで GitHub Actions が自動実行:
1. Docker imageをビルドし ghcr.io へpush
2. Kamal 2 でデプロイ
3. 結果をDiscord webhookで通知

## 開発時の注意点

- テストスイートは存在しない
- `ruboty-discord` gem は production group にのみ含まれる。ローカル開発時は `LOCAL` 環境変数を設定して使う
- メインブランチは `master`
- 日本語でコミットメッセージ・コメントを書くこと
