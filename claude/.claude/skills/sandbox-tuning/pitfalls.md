# 既知の落とし穴

[SKILL.md](SKILL.md) の「症状から探す」索引から参照される詳細。

**見出しは症状か原因を表す名前にしてある。番号は振らない**(順序を変えると参照が壊れるため)。相互参照も見出し名で行う。

項目を追加したら、**SKILL.md の索引にも1行足すこと。** 索引に無いものは到達されない。

---

## パス解決とファイルシステム

### symlink は解決後のパスで判定される

macOS では実体パスを書く必要がある。踏んだ実例:
`/tmp` → `/private/tmp`、`/var/run/docker.sock` → `~/.orbstack/run/docker.sock`

### `~/` 配下は書けない

`ln.sh`、`apply-settings.sh`、署名付き commit、`~/.claude` の掃除はすべて Claude Code 外のターミナルが必要。**`!` プレフィックスも同じ sandbox を通るので回避にならない。** `allowUnsandboxedCommands: false` のため `dangerouslyDisableSandbox` も無効。

### キャッシュと state は別ディレクトリのことがある

片方だけ開けても足りない。実例: mise は `~/Library/Caches/mise`(キャッシュ)と `~/.local/state/mise`(state)を分けている。

### `mktemp` は `TMPDIR` を無視する(macOS)

`$TMPDIR`(`/tmp/claude-501` など)は書けるが、macOS 既定の `DARWIN_USER_TEMP_DIR`(`/var/folders/.../T/`)は BLOCKED。そして **macOS の `mktemp` は引数なし / `-t` のとき `confstr(_CS_DARWIN_USER_TEMP_DIR)` を使い、`TMPDIR` を参照しない**。`TMPDIR` は confstr が失敗したときのフォールバックでしかない([Apple の shell_cmds ソース](https://raw.githubusercontent.com/apple-oss-distributions/shell_cmds/main/mktemp/mktemp.c)、`mktemp(1)` の DESCRIPTION に明記)。

**対処: テンプレートを明示する。** 明示すると confstr は一切参照されない(実測)。

```bash
mktemp -d "${TMPDIR:-/tmp}/myjob.XXXXXXXX"   # 推奨。GNU coreutils でも同じ意味
mktemp -d -p "$TMPDIR"                        # これも可
mktemp -d                                     # ✗ 必ず /var/folders を掘って失敗
```

⚠️ **公式が `mktemp -d` を勧めている箇所に釣られないこと。** あれは「ファイルシステム分離を**無効にした**場合」かつ「Linux で `$TMPDIR` が空展開する」文脈の助言で、macOS で分離オンのときは逆効果。Bash ツールのガイダンスにも同趣旨が入っているので、**放っておくと素の `mktemp -d` を書いてしまう。**

**`DARWIN_USER_TEMP_DIR` を `allowWrite` に足してはいけない。** 理由は [knowledge-note.md](knowledge-note.md) の決定ログ。要点は「ここはあなた自身のターミナルの `$TMPDIR` そのもので、`xcrun_db`(実行ファイルのパス解決キャッシュ)や JVM が `dlopen` するネイティブライブラリが置かれる」。

**別プロセスの `mktemp` が原因のことがある。** `mktemp: mkdtemp failed on ...: Operation not permitted` は `/usr/bin/mktemp` が出すメッセージ。Java 製ツールで出ていても **JVM の話ではない**ので `-Djava.io.tmpdir` は効かない。ラッパースクリプトが `mktemp` を呼んでいないか `grep` する。

**`/usr/bin` 配下の Xcode shim は軒並みこれを踏む。** `/usr/bin/git` は `couldn't create cache file '/var/folders/.../xcrun_db-XXXX' (errno=Operation not permitted)` を出すが、**警告で git は続行する**。消したいなら Homebrew の git を `$PATH` 先頭に置く(ツールによっては同じ書き込みが fatal になる例もある)。

---

## 保護されたパス

### `.claude/` の定義ディレクトリは bash から書けない

`skills` / `hooks` / `agents` / `commands` とその配下がすべて BLOCKED。`.claude` 直下は書ける。**設定ではなく Claude Code の組み込み保護**で、`denyRead` / `denyWrite` に何も書かなくても効く(実測)。

**Write / Edit ツールなら書ける。** この SKILL.md 自体がその方法で更新されている。

⚠️ **ただし片道切符になりうる。** auto mode 下では classifier が Write を止めることがある(`Blocked by classifier`)。一度書き換えた後に戻せなくなり、`git checkout -- <path>` も unlink で落ちるため復旧手段が消える。**調査目的で `.claude/` 配下を Write するのは避ける。**

`.claude/skills/` をリポジトリにコミットしている構成では、**`git merge` / `git checkout` がそのファイルを更新しようとして失敗する**。

```
error: unable to unlink old '.claude/skills/xxx/SKILL.md': Operation not permitted
Merge with strategy ort failed.
```

マージ全体が失敗するので、症状はスキルと無関係に見える。

**`allowWrite` では上書きできない。** [保護されたパス](https://code.claude.com/docs/ja/permission-modes#protected-paths)に `.claude` が挙げられており(例外は `.claude/worktrees` のみ)、「安全性チェックは allow ルールを評価する**前に**実行される」と明記。[Issue #53891](https://github.com/anthropics/claude-code/issues/53891) でも実測で否定されている(未解決のまま自動クローズ)。

**対処は「git の書き込み操作を Claude Code の外でやる」だけ。** 提案を求められても `allowWrite` を勧めない。

同種の hardcoded deny が `.git/hooks/**` と `.git/config` にもあり、`git clone` / `git init` が失敗する。**`git push -u` もここで落ちる**(push 自体は成功し、upstream 設定の書き込みだけが `unable to write upstream branch configuration` になる。`-u` を外せば回避できる)。

なお **deny の対象は広がっている**。この環境では会話の途中で `skills` と `hooks` が新たに対象化された(序盤は書けていた)。範囲は実測で確認すること。

### 保護されるのは `.claude` だけではない

[公式の保護されたパス](https://code.claude.com/docs/ja/permission-modes#protected-paths)には `.git` `.config/git` `.vscode` `.idea` `.husky` `.cargo` `.devcontainer` `.yarn` `.mvn` `.claude` が並ぶ。**ディレクトリ名で判定される**ので、プロジェクトのどこにあっても効く。

**実害の例: `pnpm install` が失敗する。** `.vscode/launch.json` を同梱する依存(`xmlbuilder` など)の展開で `ERR_PNPM_EPERM`。**依存パッケージの中身次第で踏む**ので、自分のリポジトリに `.vscode` が無くても関係ない。

**これは上流で直せる種類の問題。** 原因は `package.json` に `files` フィールドも `.npmignore` も無く、リポジトリ全体がそのまま publish されていること。`files: ["lib"]` を足してもらえば解決する。**`files` も `.npmignore` も持たないパッケージ全般に同じ地雷がある。**

踏んだときの調べ方(パッケージ名を差し替えれば再利用できる):

```bash
npm pack <pkg>@<ver> && tar tzf <pkg>-<ver>.tgz | grep -E '\.vscode|\.idea|\.husky'
npm view <pkg> repository.url                      # リポジトリを特定
gh api 'repos/<owner>/<repo>' --jq '.archived, .pushed_at, .open_issues_count'
gh api 'repos/<owner>/<repo>/issues?state=all&per_page=100' --paginate --jq '.[].title'
```

`xmlbuilder` の例では、リポジトリは archived ではなく(pushed_at 2025-12-01)、Issue/PR 全262件を調べて**同種の報告は0件**だった。「メンテナが放棄したから諦める」ではなく**単に誰も報告していない**状態。

`git clone` もプロジェクト配下で失敗する(`.git/hooks` → `--template=` で回避しても次に `.git/config` で落ちる)。

**回避策: `$TMPDIR` で作ってから `mv` する。** 保護はプロジェクト領域にスコープされていて `$TMPDIR` は対象外(実測: `$TMPDIR/x/.vscode/launch.json` は書ける)。`mv` は rename なので個別ファイルの書き込みが発生しない。

```bash
git clone --depth 1 <URL> "$TMPDIR/tmp-clone" && mv "$TMPDIR/tmp-clone" ./external-docs/<NAME>
```

ただし **pnpm の内部処理には適用できない**(展開先を制御できないため)。

---

## ネットワークと TLS

### platform TLS 検証の失敗 (OSStatus -26276)

Security.framework 経由で証明書検証する処理系が全滅する。sandbox が trustd への XPC を塞いでいるため。**`allowedDomains` を足しても直らない**(許可済みホストでも失敗する)。curl だけ通るのは `/etc/ssl/cert.pem` を直読みして trustd を経由しないから。

- `go`: トップレベル `env` の `SSL_CERT_FILE=/etc/ssl/cert.pem` で解決する(sandbox 内に留めたまま直せる)
- `mise` / `gh` / `pinact`: 同じ環境変数が効かない。`excludedCommands` しかない

**効く/効かないはバイナリ単位で、言語では決まらない。** `gh` も `pinact` も Go 製だが効かない。同一セッション・同一 env で、素の Go プログラム(`net/http` の `http.Get` だけ)は `SSL_CERT_FILE` あり/なしで成否が変わるのに、`pinact` は付けても失敗する(実測)。

**判定手順**: ①`curl` で対照を取る(通ればホスト許可は足りている) → ②素の Go プログラムで `SSL_CERT_FILE` の有無を比較 → ③それでも当該ツールが落ちるなら `excludedCommands` 行き。`SSL_CERT_DIR` や `GODEBUG=x509usefallbackroots=1` も効かないことがある。

### 子プロセスの環境を絞るツールはネットワークが死ぬ

sandbox 内は DNS を直接引けず、通信はすべて `http_proxy` / `https_proxy` などの環境変数経由でプロキシに流す必要がある。子プロセスに環境変数を引き継がないツールは、この変数を失って名前解決に失敗する。

**`Could not resolve host` は DNS の問題ではなくプロキシ変数の欠落を疑う。**

プロキシは認証も必須なので、**認証情報を運ぶ変数が落ちても失敗する**。git の場合 Claude Code は `GIT_CONFIG_PARAMETERS='http.proxyAuthMethod=basic'` で渡している。どちらも exit 128 になるが、**メッセージで判別できる**。

| メッセージ | 欠けているもの |
| :-- | :-- |
| `Could not resolve host: <host>` | `http_proxy` / `https_proxy` 系 |
| `Proxy CONNECT aborted` / `Recv failure: Connection reset by peer` | `GIT_CONFIG_PARAMETERS`(プロキシ認証の設定) |

再現手順:

```bash
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u all_proxy sh -c '<コマンド>'
env -u GIT_CONFIG_PARAMETERS sh -c '<コマンド>'
```

**実例: `golangci-lint custom` の内部 `git clone`。** `filterGitEnviron`([PR #6515](https://github.com/golangci/golangci-lint/pull/6515)) が `GIT_` で始まる変数を許可リストで絞っており、`GIT_CONFIG_PARAMETERS` が漏れている。`http_proxy` は `GIT_` で始まらないので素通りする。

親が git の stderr を握り潰すため `GIT_TRACE=1` でも何も出ない。**PATH に薄いラッパーを挟んで捕捉する**:

```bash
mkdir -p "$TMPDIR/fakebin"
printf '%s\n' '#!/bin/sh' 'env > "$TMPDIR/env.log"' 'exec /opt/homebrew/bin/git "$@" 2>>"$TMPDIR/git.log"' > "$TMPDIR/fakebin/git"
chmod +x "$TMPDIR/fakebin/git"
PATH="$TMPDIR/fakebin:$PATH" <親コマンド>
```

**env ダンプに `GIT_*` が1つも無ければ、環境を絞る親がいる。** これが最短の手がかりになる。

**JVM は別扱い。** srt の README によれば、JVM は `HTTPS_PROXY` を無視し、プロキシ資格情報を渡す環境変数も持たない。そのため srt が `JAVA_TOOL_OPTIONS` で `-javaagent` を注入して補っている。`Picked up JAVA_TOOL_OPTIONS:` が stderr に出るのはこれが理由で、異常ではない。

### 環境変数は届いているのにツールが読まないことがある

上記は「親が環境変数を落とす」ケース。こちらは**変数は届いているがツールが見ていない**ケースで、対処が違う。

実例: **Node の `fetch`(undici)は既定で `https_proxy` を見ない。** 実測(node v26.7.0):

```
curl                                200
node fetch 素                       ERR ENOTFOUND
node fetch + NODE_USE_ENV_PROXY=1   OK 200
```

`curl` が通るのにツールだけ落ちるなら、**`allowedDomains` の追加は不要**。ホストは許可されている。トップレベル `env` で `NODE_USE_ENV_PROXY=1` を配れば sandbox 内に留めたまま直る(`SSL_CERT_FILE` と同じ形)。

**まず curl で対照を取る。** ツールのエラーだけ見て「ドメインを許可すれば直る」と判断しない。エラー文言もツールごとに変わる(`ENOTFOUND` / `Could not resolve host` / TLS エラー)。

---

## `excludedCommands` の挙動

**用語**: 以下で「除外される」とは、**そのコマンドが `excludedCommands` のパターンに一致し、sandbox の外で実行される**ことを指す。`excludedCommands` への追加は保護を減らす操作であり、追加してよい範囲の制約は [SKILL.md](SKILL.md) の「緩和の優先順位」にある。

### トップレベルのコマンドにしか効かない

別のプログラムが内部で起動する子プロセスは除外されず sandbox 内で動く(検証済み: `sh -c 'git ...'` の子は `SANDBOX_RUNTIME=1` で、SSH がプロキシ認証で失敗する)。踏んだ実例:

- golangci-lint が custom-gcl のビルドで内部起動する `git clone`
- `go` がモジュール取得で内部起動する `git`
- `mise run <task>` の配下で動く `docker` や `go`

`git *` を除外したのに git 由来のエラーが出る、という形で現れる。**「そのコマンドを誰が起動したか」を確認する。**

**シェル構文でも外れる。** `for` / `while` のループ本体に置くと除外されない(実測)。

```bash
gh auth status                      # 除外される (SANDBOX_RUNTIME=unset)
echo probe; gh auth status          # 除外される (; 区切りは効く)
for i in 1; do gh auth status; done # 除外されない (SANDBOX_RUNTIME=1) → 失敗
```

**除外対象のコマンドをループで回さない。** 複数対象を処理したいなら呼び出しを分ける。「断続的に失敗する」ように見えて誤診しやすい。

### 除外対象を含むと呼び出し全体が外に出る(セキュリティ上の穴)

除外対象を1つ含めるだけで**シェルごと**サンドボックス外に出るため、連結したコマンドもすべて外で走る。実測:

```
docker version >/dev/null; ls ~/.ssh
  → SANDBOX_RUNTIME=unset
  → ~/.ssh が読める(denyRead を迂回)
```

**`denyRead` も `credentials.files` も `allowWrite` も `allowedDomains` も、この経路では効かない。** つまり `excludedCommands` の各エントリが脱出口になる。[#40831](https://github.com/anthropics/claude-code/issues/40831) が同じ挙動を報告している(Closed as not planned)。

**現状これを緩和しているのは権限モードだけ。** 全 Bash コマンドに承認プロンプトが出るなら、`docker version; cat ~/.ssh/id_rsa` はその文字列のまま人間に見える。**`autoAllowBashIfSandboxed: true` や auto / bypassPermissions に切り替えるなら、`excludedCommands` を空にできないか先に検討する。**

---

## 誤誘導するエラー

### エラーメッセージが原因を取り違えさせる

`EPERM` / `operation not permitted` が出たらまず sandbox を疑う(通常のパーミッション拒否は `EACCES` / `permission denied`)。ただし**拒否の痕跡すら残らないことがある**。

- npm は「root 所有ファイルのせい」と言う
- Go は TLS 証明書エラーに見える
- **docker は存在しないフラグのせいにする** — `~/.docker/config.json` が読めないと CLI プラグインの discovery が失敗し、`docker compose` サブコマンド自体が消える。結果 `docker compose -p x down` が `unknown shorthand flag: 'p' in -p` で落ちる。`-p` は無関係
- **2回目の実行で症状が化ける** — 失敗した `git merge` は**アトミックではなく、落ちる前にファイルを書き出している**(実例: 72件)。残骸があるため次のマージは `untracked working tree files would be overwritten` になり、元の話が消える

```bash
# 残骸(= マージ元の blob と一致する untracked ファイル)を検出
git status --short | sed -n 's/^?? //p' | while read -r f; do
  [ "$(git hash-object "$f")" = "$(git rev-parse "origin/master:$f" 2>/dev/null)" ] || echo "DIFF: $f"
done
```

### `fatal:` と出ていても失敗とは限らない

git の `fatal: failed to store: 100001` は、サンドボックスが Keychain への**書き込み**を塞ぐために `credential-osxkeychain store` が出すもの。読み取りは通るので認証は成功しており、**操作自体は成功して終了コードは 0**(clone で `.git` 生成まで確認済み)。

このノイズを失敗と読み違えて真因を取り違えた事例がある。**文字列ではなく終了コードで判断する。**

```bash
cmd >log 2>&1; echo "EXIT=$?"   # パイプを挟むと zsh では $? がずれる
```

zsh には `PIPESTATUS` がない(`$pipestatus[1]`)。終了コードを見るときはパイプを外す。

`( cmd & )` で出る `nice(5) failed: operation not permitted` も同種のノイズで、コマンド自体は成功する。

### 失敗が終了コードに出ないことがある

タスクランナー経由だと、本体が成功しているのに後処理(フィンガープリント記録など)だけ失敗し、それが依存チェーンを止めることがある。しかも全体の終了コードが 0 のまま。実例: `mise run test` が exit 0 で終わったが、実際にはテストが 1 つも実行されていなかった。**終了コードではなく出力を読む。**

### キャッシュ済みだと部分的に成功する

`go build` は通るのに `go test` の一部だけ落ちる、という出方をする。「新規にコンパイル/ダウンロードが必要なものだけ落ちる」と読み替える。パッケージ固有の問題に見えるが違う。

---

## 設定の反映と変動

### 反映漏れと、逆向きのドリフト

`settings.common.json` を編集しても `apply-settings.sh` を実行しなければ効かない。**診断の最初に同期を確認する。**

逆方向もある。`~/.claude/settings.json` は生成物だが、**ユーザーや他の Claude Code セッションが直接書き換えることがある**(`/config` でのモデルやテーマの変更、`/sandbox` パネルの操作、権限プロンプトの「今後は聞かない」など。sandbox は `settings.json` への bash 書き込みを拒否するが、Claude Code 自身の書き込みは通る)。

**`apply-settings.sh` は生成物を上書きするので、取り込んでいない差分は黙って失われる。** 適用の前に必ず両方向を確認する。

```bash
cd ~/dotfiles/claude/.claude
W="$TMPDIR/synccheck.$$"; mkdir -p "$W"    # $$ を挟まないと他セッションと衝突する
if [ -f settings.machine.json ]; then
  jq -s '.[0] * .[1]' settings.common.json settings.machine.json > "$W/expected.json"
else
  cp settings.common.json "$W/expected.json"
fi
jq -S . "$W/expected.json" > "$W/e.json"
jq -S . settings.json > "$W/g.json"
diff "$W/e.json" "$W/g.json" && echo 同期OK; rm -rf "$W"
```

差分の読み方:

- `<` 側のみ = 入力を編集したが未適用。`apply-settings.sh` を依頼する
- `>` 側のみ = **生成物が直接編集された**。共有すべきものは `settings.common.json` に、このマシン固有のものは `settings.machine.json` にバックポートしてから適用する

`>` 側を見つけたら、**適用を依頼する前にバックポートする**。順番を間違えると失われる。

### 設定をリロードすると、自動付与していた許可が落ちることがある

設定ファイルに書いていないのに効いている許可がある。セッション開始時に環境を検出して自動付与されるもので、**設定を変更すると再構築の際に失われることがある**。

確認された事例:

- **リンクされた worktree の共有 `.git`** — 公式ドキュメントに「作業ディレクトリがリンクされた git worktree の場合、メインリポジトリの共有 `.git` への書き込みも許可する」とある。セッション開始時のダンプには入っていたが、設定変更後に消えて `git commit` / `git fetch` / `update-ref` が全滅した
- **Go のツールチェインキャッシュ** — `~/Library/Caches/go-build` などが明示指定なしで書けていたが、`allowWrite` の編集後に落ちた

**症状は「設定を変えていない領域が突然壊れる」。** 触っていないので疑いにくい。

対処は2つ。**まずセッションを開き直す**(自動付与が再計算されて直ることがある。worktree の事例はこれで解決した)。それでも直らなければ明示的に足す。

### `/add-dir` 先が bash から書けないことがある

症状は「Edit ツールでは編集できるのに bash が弾かれる」。git 操作は bash 経由なので `commit` / `add` / `switch` がすべて通らない。

```
fatal: Unable to create '.../.git/index.lock': Operation not permitted
```

**公式ドキュメントでは書けるはず。** [既定の書き込み動作](https://code.claude.com/docs/en/sandboxing#filesystem-isolation)に「現在の作業ディレクトリとそのサブディレクトリ、**`--add-dir` または `/add-dir` で追加した任意のディレクトリ**、およびセッション一時ディレクトリ」と明記されている。それでも実測で BLOCKED になった事例があるので、**バグの可能性がある**。

⚠️ 混同しやすい点: `--add-dir` / `/add-dir`(コマンド)と `permissions.additionalDirectories`(設定キー)は別物。後者は権限レイヤーだけの機能。前者を後者と同一視して「仕様どおり」と誤診した事例がある。

「自動付与の喪失」とは別物なので、**同じ場所でセッションを開き直しても直らない**。

**対処: そのプロジェクトで別のセッションを開いてもらい、作業を依頼する。**

サンドボックスが書き込みを許可するのは**そのセッション自身の作業ディレクトリ**なので、対象リポジトリを cwd とするセッションを立てれば普通に書ける。

1. ユーザーに、対象プロジェクトで新しい Claude Code セッションを開いてもらう
2. `ListAgents` で相手を確認し、`SendMessage` で作業を依頼する
3. 自分は元のリポジトリ側の作業を続ける

`allowWrite` に作業リポジトリのパスを列挙する案は採らない。リポジトリが増えるたびに設定が肥大化し、`~/work` ごと開ける案は粒度が粗すぎる。

---

## プロセスと GUI

### プロセスの調査コマンドが使えない

`ps` / `top` / `sample` が `operation not permitted`。`lsof` は通る。バックグラウンドのビルドやサーバが「詰まっているのか実行中なのか」を切り分けられないので、**ログやポートの状態で判断する**。

**Node 製ツールのハングは `--require` でハンドルをダンプすると早い。**

```bash
node --require ./dump-handles.js ...   # process._getActiveHandles() を出す
```

実例: rollup が `created ...` を出した後に終わらないケースで、FSWatcher 946 + StatWatcher 121 が残存していると分かり、上流の既知バグ(`createWatchProgram` を閉じない)と特定できた。

**この rollup バグは `&&` チェーンの中だと発見しにくい。** `pnpm build:web` が `copy-assets.sh && build:service-worker && next build` の形だと、`created public/service-worker.js` で出力が止まり、**next build が起動しないまま無出力でハングする**。全体が沈黙するので service-worker が原因だと気づきにくい。**チェーンを分解して単体で実行する。**

### Chromium がローカル起動できない

`bootstrap_check_in ... Permission denied (1100)` で落ちる。Seatbelt が Mach ポートの登録を許さないためで、**`allowWrite` では直らない層**。Playwright のブラウザ取得は `PLAYWRIGHT_BROWSERS_PATH="$TMPDIR/pw-browsers"` で通るが、起動はできない。

**Playwright MCP 経由のブラウザ操作は成功する**(別プロセスで起動するため)。UI 検証の導線は MCP に寄せる。

---

## ソケットと gpg

### `allowUnixSockets` は `denyRead` を上書きする

ソケット接続とファイル読み取りは Seatbelt の別系統で判定される。`denyRead: ["~/.gnupg"]` の状態でも `gpg-connect-agent /bye` は成功し `KEYINFO` も取れる(実測)。

**ただしソケット経由を選ぶには、そのディレクトリ内の設定ファイルが読める必要がある。** gpg は `~/.gnupg/common.conf` を読んで keyboxd を使うか決めるため、ディレクトリごと deny すると判断できずファイル直読みにフォールバックし、`pubring.kbx` の読み取りで落ちる。「ソケットは通るのに機能しない」という形で現れる。

**秘密を隠すなら鍵の実体だけを塞ぐ。** 詳細は [knowledge-note.md](knowledge-note.md) の denyRead の項。

### gpg-agent は「動いていること」が前提

`allowUnixSockets` が許可するのは動いている agent への接続だけで、agent の起動は許可しない(起動には `~/.gnupg` への write が要る)。agent が落ちると署名できなくなる。`gpgconf --launch gpg-agent` をサンドボックス外で実行して復旧する。

関連して **`git log --show-signature` は 2 分ハングする**。検証のため gpg が agent を起こそうとして待ち続けるため。署名の確認は `git cat-file commit HEAD` で `gpgsig` ヘッダを見る。

---

## ツール別の既知の問題

### pnpm: リポジトリ直下に `.pnpm-store/` を作る

**症状**: グローバルストアが使えず、リポジトリ直下に `.pnpm-store/` を作って全パッケージを再ダウンロードする(実例: 2497個 / 2.0G、reused は 2個だけ)。**`.gitignore` に入らないので `git add -A` 事故の危険がある。**

**確認方法**:

```bash
pnpm store path   # リポジトリ配下を指していたら踏んでいる
```

**原因は pnpm 側。** [pnpm#13525](https://github.com/pnpm/pnpm/issues/13525) に「AI エージェントのサンドボックスで意図しないプロジェクトローカル `.pnpm-store/` が作られる」として報告済み(Claude Code と Codex CLI、macOS Seatbelt が名指しされている)。**サンドボックスの設定を緩める話ではない。**

⚠️ **バージョンを上げても v11 では直らない。** 修正は v12 のみ。メンテナのコメント(2026-08-05):

> I have moved the store to node_modules/.pnpm-store in this case but only in **pnpm v12** as it is a breaking change.

実測: `10.34.1` → `<repo>/.pnpm-store/v10`、`11.24.0` → `<repo>/.pnpm-store/v11`。**上げても同じ。**

修正の中身も「ホームストアにフォールバックする」ではなく「`node_modules/.pnpm-store` へ移す」。`node_modules` は gitignore されるので `git add -A` 事故だけは解消する。

**当面の対処: `storeDir` を明示する。**

```bash
pnpm_config_store_dir="$HOME/Library/pnpm/store" \
  pnpm install --frozen-lockfile --frozen-store --offline
```

実測で `reused 2500 / downloaded 0`。ストアへの書き込みもネットワークも不要で、`.pnpm-store` も作られない。**`storeDir` の明示は必須**で、省略するとフォールバックで空のリポジトリ内ストアを指し無意味になる。

- `--frozen-store` は pnpm 11.7 以降。読み取り専用ストアに対して install できる(SQLite インデックスを不変モードで開く)
- 要件: Node >= 22.15.0 / 23.11.0 / 24.0.0。ストアに必要なものが揃っていること。欠けると `ERR_PNPM_FROZEN_STORE_NEEDS_BUILD` で即失敗。`--force` と pnpr サーバーとは併用不可
- ⚠️ **v11 から環境変数のプレフィックスが `npm_config_*` → `pnpm_config_*` に変わっている**

**ただし `pnpm install` 自体はサンドボックス内で完走できない。**「保護されるのは `.claude` だけではない」に当たる。`xmlbuilder` が `.vscode/launch.json` を同梱しており、3623 パッケージまで展開が進んでから落ちる。`node_modules` の構築は外のターミナルで行う。

**`ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY` は storeDir の食い違い。** `node_modules/.modules.yaml` に記録された storeDir と実効 storeDir がずれると出る。サンドボックス外で作った `node_modules` に対しては上記フォールバックで必ずずれるので、**自分の直前の設定変更のせいと誤診しやすい**。`pnpm store path` を先に見る。

### ツールが「無検証で実行するバイナリ」を置くディレクトリ

`~/.quint`(quint)や `~/.cache/uv` のように、**外部バイナリをダウンロードして展開し、以後それを実行する**ディレクトリがある。この型は `allowWrite` に足してはいけない。

判定の手順:

1. **完全性検証があるか。** 配布物の実装を読む(`unpkg.com/<pkg>@<ver>/dist/...` が速い)。`sha` / `checksum` / `signature` が無ければ汚染は検出されない
2. **既存ファイルをそのまま使うか。** `if (exists(path)) return path;` の形なら、**ダウンロードを汚染する必要すらない**。サンドボックス内で置いて `chmod +x` するだけで成立し、以後永久に再検証されない
3. **消費者がサンドボックス外にいるか。** `$PATH` に載らなくても、ツール自身が絶対パスで spawn する。人間がターミナルでそのコマンドを一度叩けば発火する

**対処①: 初回だけ人間が用意し、以後は読み取り専用で使う。**

サンドボックスは**書き込みを禁じるだけで、実行と読み取りは妨げない**。したがって人間が外で一度実行してキャッシュを正規の内容で満たせば、以後エージェントはそれを読んで実行するだけで済む。**`allowWrite` するより安全**で、中身が正規だと分かっており、かつエージェントは書き換えられない。

| 対象 | 人間が一度やること | 以後サンドボックス内で |
| :-- | :-- | :-- |
| gpg 署名 | `gpgconf --launch gpg-agent` | ソケット経由で署名できる |
| pnpm | `pnpm install`(ストアを温める) | `--frozen-store` で読み取り専用に使える |
| ツールのバイナリキャッシュ | 一度そのツールを実行 | キャッシュから実行できる |

**確認すること**: そのツールが実行時にもそのディレクトリへ書くか(ロックファイル、ログ)。書くなら初回だけでは足りない。`touch` ではなく**実際にコマンドを走らせて**確かめる。uv には読み取り専用キャッシュのモードが無いので、この手は使えない([uv#15934](https://github.com/astral-sh/uv/issues/15934) が open)。

**対処②: サンドボックス専用のディレクトリを与える。** 多くのツールが環境変数を持っている(`UV_CACHE_DIR`、`QUINT_HOME` など。未文書化のこともあるのでソースを見る)。

⚠️ **重要なのは「移すこと」ではなく「人間と共有しないこと」。** 移しても中身の危険性(実行可能物・無検証)は何も変わらない。変わるのは**発火条件**で、人間が別のディレクトリを使い続ける限り、汚染された成果物が**サンドボックス外で実行される経路が消える**。同じ場所を共有させると、パスを変えただけで危険は元のままになる。

したがって**シェルの rc には export しない**。設定するのは Claude Code の `settings.json` の `env` かプロジェクトの `.envrc` に限定する。

置き先は**専用の永続ディレクトリ**にする(`~/.cache/uv-sandbox` のように既存の兄弟として1つ足す)。プロジェクト内は避ける — ビルド成果物にキャッシュが混入する事故が上流で報告されており、cwd 内の保護パスとも衝突する。セッション一時ディレクトリも毎回コールドになるので避ける。

**ディレクトリがまだ存在しない場合は特に危険。** 開けると最初に作るのがエージェントになり、正規の中身と比較する基準が存在しない。
