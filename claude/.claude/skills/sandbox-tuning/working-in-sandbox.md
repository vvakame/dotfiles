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
| テストが `could not find default credentials` で落ちる(エミュレータ相手で、クライアントを作れれば足りる) | ダミー ADC を scratchpad に置き、`GOOGLE_APPLICATION_CREDENTIALS` で指す。形式は `authorized_user`(下記)。テストを sandbox 外で走らせない |
| `golangci-lint custom` の内部の `git clone` が exit 128 / リンクで dsymutil が失敗 | `GIT_HTTP_PROXY_AUTHMETHOD=basic` と `GOFLAGS=-ldflags=-w` を付ける。dsymutil のエラーが出ても終了コード 0 なら成功 |

ダミー ADC:

```json
{"type":"authorized_user","client_id":"fake-client-id.apps.googleusercontent.com","client_secret":"fake-client-secret","refresh_token":"fake-refresh-token"}
```

`service_account` 形式は、秘密鍵の PEM を構築時にパースするので通らない。`$TMPDIR` に置くと長いセッションの途中で消えることがある。

## 迂回が正当なもの

sandbox が意図して塞いでいるもの。迂回するのは必要なコマンドだけに絞る。

- 本物の gcloud 認証情報が要るコマンド(本番の Cloud Logging を読む、など)。ダミー ADC で済むテストは含めない
- 保護されたパス(`.git/config`、`.vscode/`、`.mcp.json`)に書く git コマンド。ただし `git worktree add` / `git worktree remove` / `git branch -D` は `excludedCommands` に入っているので迂回は要らない。`.git/config` に書くだけの `git push -u` は、上の表の書き方で避ける

## worktree の作成と削除

`git worktree add` / `git worktree remove` / `git branch -D` は `excludedCommands` に入っている。上の「単独で実行する」に従えば sandbox 外で動く。

- `git -C <dir> worktree add ...` は一致しない。`cd <dir> && git worktree add ...` の形にする。
- 作成先は、リポジトリの親ディレクトリ直下に並べる兄弟ディレクトリだけにする。sandbox 外で動くので、ほかの場所にも作れてしまう。
