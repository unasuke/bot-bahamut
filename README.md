# bot-bahamut

メンションに対してClaude AIで返答するDiscord bot。

## 必要な環境変数

| 変数名 | 説明 |
|---|---|
| `RUBOTY_NAME` | botの名前 |
| `DISCORD_TOKEN` | Discord Botトークン |
| `ANTHROPIC_API_KEY` | Anthropic APIキー |
| `ANTHROPIC_MODEL` | 使用するモデル（省略時: `claude-haiku-4-5`） |

## ローカルで実行する方法
```shell
$ RUBOTY_NAME=bahamut DISCORD_TOKEN=xxx ANTHROPIC_API_KEY=xxx bundle exec ruboty --load handlers.rb
```
