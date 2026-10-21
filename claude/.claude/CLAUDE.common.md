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

* 迂回するのは、sandbox の拒否で失敗したそのコマンド1回だけにしてください。別のコマンドが拒否されたことを理由に、先回りして迂回しないでください。
* `gh` や `docker` など `sandbox.excludedCommands` にあるコマンドは、パイプ・`;`・`> file`・複数行などを付けず単独で実行してください。付けると sandbox 内で動いて失敗します。
* 拒否を踏んだら、迂回する前に `sandbox-tuning` Skill の `working-in-sandbox.md` を見てください。

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
