git worktree を使っているとき、特に指示がない場合並列にワーキングツリーを配置しています。
また、 `claude` コマンドの起動場所は working tree のルートです。
gitで管理されていない、親ディレクトリで作業するのは禁止です。

```
repo-name
├── main ( parent working tree )
├── foobar ( topic working tree )
└── fizzbuzz ( topic working tree )
```

---

`gh api *` コマンドを使う際、可能な限り `gh api -X GET *` を代わりに使ってください。
`gh api ...` 経由で Read, Write, Delete など様々な操作を行うことができます。
`-X GET` をつけることで Read 系操作に限定することができるため、自動許可などの設定がやりやすくなります。

---

sandbox 外での実行（`dangerouslyDisableSandbox: true`）は許容しますが、回数は少なく保ってください。
以下は 2026-10-21 にセッションログの集計と実測から書いたものです。実態と食い違ったら直してください。

* 迂回するのは、sandbox の拒否で失敗したそのコマンド1回だけにしてください。
  * 迂回した後も、次のコマンドはまず sandbox 内で試します。
  * 別のコマンドが拒否されたからといって、まだ試していないコマンドを先回りして迂回しないでください。これが迂回の最大の発生源でした。
* `~/.claude/settings.json` の `sandbox.excludedCommands` にあるコマンド（`gh`, `docker`, `kubectl get` など）は、そのコマンド1つを単独で実行したときだけ sandbox 外で動きます。
  * 通る形: 引数付きの素の形、`2>&1`、先頭の `cd <dir> &&`
  * 落ちる形: パイプ、`> file`、`;`、別コマンドとの `&&`、改行区切りの複数行、`VAR=x` の前置、`for` ループの中
  * 出力の加工はパイプではなくツールのオプションで行ってください（`gh ... --jq` / `--json` / `--template`、`kubectl -o jsonpath=...`、`docker ... --format`）。
  * 複数回実行するなら、1回ずつ別の Bash 呼び出しにしてください。
  * `open /Users/.../.config/gh/config.yml: operation not permitted` は、上の「落ちる形」になっているサインです。素の形に直して再実行し、それでも落ちたときだけ迂回してください。
* `git push -u` / `--set-upstream` は `.git/config` への書き込みが拒否されて失敗します。`git push origin <branch>` で push してください。`gh pr create` に upstream の設定は要りません。
* `mise exec` / `mise run` がツールを自動インストールしようとすると失敗します。先に `mise install` を素の形で実行してください。
* `ps` / `pkill` / `killall` はプロセス一覧が取れず失敗します。`lsof -ti :<port>` で PID を引き、`kill <pid>` を使ってください。
* 次は sandbox が意図して塞いでいるものなので、迂回は正当です。迂回するのは必要なコマンドだけに絞ってください。
  * gcloud の認証情報（ADC など）が要るコマンド
  * `git worktree add` など、`.vscode/` や `.mcp.json` のような保護されたファイルを作るコマンド

---

コードにコメントを書く場合の指針。
コメントには、後日読んだときに役立つ情報を書くべきです。
具体的に、どういった情報に触れ、どういった意思決定をしたかといった、資料性のある情報を指します。
この変更に至るまでにどういった作業をしたか？と言った内容は資料性に乏しいため、コメントには書きません。
コメントはなるべく短く保つようにして、読者の負担が減るようにします。
特に、参照した資料などの引用は避け、リンクを活用してください。

---

git commit、push、Draft PR の作成までは、指示がなくても作業の一部として行ってください。
人間によるレビューは、下記の Draft PR を Ready for review にする時点で行います。
`master` / `main` に直接 commit せず、ブランチを切ってください。

PRを作成するときは必ず Draft で作成してください。
Draft から Ready for review への変更は人間が行います。これをもって人間によるレビューの完了とします。
そのため `gh pr ready` は実行しないでください。レビューを依頼できる状態になったと判断した場合、その旨を伝えるに留めてください。
