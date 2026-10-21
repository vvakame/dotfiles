# sandbox 内で通る書き方

sandbox 外での実行(`dangerouslyDisableSandbox: true`)は許容されているが、回数は少なく保つ。ここは作業中のセッション向けに、迂回せずに済む書き方をまとめる。

2026-10-21 にセッションログの集計と実測から書いた。根拠は [pitfalls.md](pitfalls.md) の「`excludedCommands` の挙動」にある。実態と食い違ったら直す。

## 迂回は拒否されたコマンド1回だけ

- 迂回した後も、次のコマンドはまず sandbox 内で試す。
- 別のコマンドが拒否されたからといって、まだ試していないコマンドを先回りして迂回しない。**これが迂回の最大の発生源だった。**

## `excludedCommands` のコマンドは単独で実行する

`~/.claude/settings.json` の `sandbox.excludedCommands` にあるコマンド(`gh`, `docker`, `kubectl get` など)は、そのコマンド1つを単独で実行したときだけ sandbox 外で動く。

| 通る形 | 落ちる形 |
|---|---|
| 引数付きの素の形 | パイプ |
| `2>&1` | `> file` |
| 先頭の `cd <dir> &&` | `;`、別コマンドとの `&&` |
| | 改行区切りの複数行 |
| | `VAR=x` の前置 |
| | `for` ループの中 |

- 出力の加工はパイプではなくツールのオプションで行う(`gh ... --jq` / `--json` / `--template`、`kubectl -o jsonpath=...`、`docker ... --format`)。
- 複数回実行するなら、1回ずつ別の Bash 呼び出しにする。
- 長い本文は引数に改行を入れず、ファイルに書いてから `--body-file` などで渡す。
- `open /Users/.../.config/gh/config.yml: operation not permitted` は「落ちる形」になっているサイン。素の形に直して再実行し、それでも落ちたときだけ迂回する。

## 個別のコマンド

| 症状 | 代わりに |
|---|---|
| `git push -u` / `--set-upstream` が `.git/config` を書けず失敗 | `git push origin <branch>`。`gh pr create` に upstream の設定は要らない |
| `mise exec` / `mise run` の自動インストールが失敗 | 先に `mise install` を素の形で実行する |
| `ps` / `pkill` / `killall` がプロセス一覧を取れず失敗 | `lsof -ti :<port>` で PID を引き、`kill <pid>` |

## 迂回が正当なもの

sandbox が意図して塞いでいるもの。迂回するのは必要なコマンドだけに絞る。

- gcloud の認証情報(ADC など)が要るコマンド
- `git worktree add` など、`.vscode/` や `.mcp.json` のような保護されたファイルを作るコマンド
