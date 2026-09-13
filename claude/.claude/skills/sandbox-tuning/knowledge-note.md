# sandbox 設定値の根拠

`claude/.claude/settings.common.json` の各項目が、なぜその値になっているかの記録。
診断手順と罠の一覧は [SKILL.md](SKILL.md) を参照。

設定を変更するときは、ここに理由を追記する。**理由が書けない項目は、そもそも要らない可能性が高い。**

**値の正本は `settings.common.json`。** この文書に載っている値は説明のための引用で、古い場合がある。判断の前に現物を確認すること。

## この文書の書き方

1. **ドキュメントを根拠にしたら出典 URL を併記する。** 「公式にそう書いてある」は、リンクがなければ後から検証できない

   **出典は該当する項目の中に直接書く。末尾に一覧を作らない。** 同じ出典を複数の項目で参照するなら、**そのつど書く**。一覧に集約すると、項目を読んだだけでは何が根拠か分からず、項目を消したときに出典だけ残る
2. **判断には「何が変われば再考するか」を書く。** 値の理由だけでは、前提が変わったときに誰も見直せない
3. **却下した案も理由付きで残す。** 同じ提案が繰り返し浮上する
4. **最終確認日を項目ごとに記録する。** その事実がいつ時点のものかを示すためで、次回の期限ではない。何かを確認したらその行の日付を更新する
5. ⚠️ **この dotfiles は公開リポジトリ。書いたものは公開される。** 下記を守ること

**見直しは日付ではなくトリガーで行う。** 全体を定期的に精査するのは現実的でないため、[決定ログ](#決定ログ)の「再考のトリガー」が起きたときに、その行だけを見直す。

### 書いてはいけないもの

**この dotfiles は公開リポジトリで、`.gitignore` しない限りすべて公開される。** 以下は書かないこと。[SKILL.md](SKILL.md) と [pitfalls.md](pitfalls.md) にも同じ制約がかかる。

| 対象 | 代わりに |
| :-- | :-- |
| **プライベートリポジトリの名前** | 「作業しているリポジトリ」。**私用 PC か仕事用 PC かを問わない。プライベートなら書かない** |
| プライベートリポジトリの内部構造(パッケージ名、ディレクトリ構成、ファイルパス) | 症状の再現に必要な最小限の一般化(「GCS クライアントの生成を伴うパッケージ」など) |
| 資格情報(トークン、パスワード、プロキシの認証付き URL) | 形式だけ示す。値は伏せる |
| 個体を識別する値(`/var/folders/<hash>` のハッシュ部分、GPG 鍵 ID、メールアドレス) | `<hash>` などのプレースホルダ |
| ホームディレクトリの絶対パス | `~/` 表記 |

**判断に迷ったら、その情報が知見の再利用に必要かを問う。** リポジトリ名や内部構造は、たいてい不要。

なお `id -u` の `501` や `/tmp/claude-501` は**書いてよい**。macOS の最初のユーザーに割り当てられる標準の uid で個体を識別せず、かつ「501 はセッション ID ではなく uid」という説明自体が知見の核心。

---

## permissions.ask

```json
"ask": ["Bash(git add *)", "Bash(git commit *)", "Bash(git push *)"]
```

ユーザーの要望で、git の書き込み操作には必ず承認を挟む。

コンテンツスコープの ask ルールを使っているのは、これが**サンドボックス化されたコマンドにも、`auto` / `bypassPermissions` モードにも効く**ため。ベアな `Bash` ask ルールはサンドボックス化されたコマンドではスキップされるので、同じ目的には使えない。

## env.SSL_CERT_FILE

```json
"env": { "SSL_CERT_FILE": "/etc/ssl/cert.pem" }
```

sandbox 内で `go` の TLS 検証が `x509: OSStatus -26276` で失敗する問題への対処。

macOS では Security.framework 経由の証明書検証が trustd への XPC を必要とし、sandbox がこれを塞いでいる。`SSL_CERT_FILE` を指定すると Go は PEM バンドルを直読みするようになり、trustd を経由しなくなる。

**`excludedCommands` に `go *` を入れる案を採らなかった理由**は、`go test` / `go run` / `go generate` がプロジェクトのコードをコンパイルして実行するため。依存更新のような「信頼度の低い新規コードを取り込む場面」でこそサンドボックスが要る。環境変数なら go をサンドボックス内に留めたまま直せる。

副作用として、macOS キーチェーンに後から追加した CA が Go から見えなくなる。社内 MITM プロキシを導入する場合はこの設定を見直すこと。

`mise` と `gh` には効かない(実測)。これらは platform verifier を直接呼ぶため。

## sandbox.enabled / failIfUnavailable / allowUnsandboxedCommands

```json
"enabled": true,
"failIfUnavailable": true,
"allowUnsandboxedCommands": false
```

`failIfUnavailable` — 依存不足やプラットフォーム非対応のとき、既定では警告だけ出してサンドボックスなしで実行される。それを起動失敗に変える。**サンドボックスが黙って無効化されている状態を作らない**ため。

`allowUnsandboxedCommands: false` — モデルが `dangerouslyDisableSandbox` でサンドボックス外に逃げる経路を塞ぐ。この結果、**`~/` 配下を触る操作は Claude Code 内から一切できない**(`!` プレフィックス経由も同じサンドボックスを通る)。`ln.sh`、`apply-settings.sh`、`~/.claude` の掃除はすべて Claude Code 外のターミナルで行う運用になっている。

## excludedCommands

**除外は最終手段。** 除外対象を1つでも含む呼び出しは全体がサンドボックス外で実行される(実測)ため、パターンを広げるほど穴が大きくなる。

| エントリ | 理由 |
| :-- | :-- |
| `fork *` | Fork(git GUI クライアント)の起動。サンドボックスは既定で Apple Events を塞ぐため GUI アプリを起動できない |
| `docker *` | docker はサンドボックスと非互換。公式ドキュメントも `excludedCommands` を案内している |
| `gh *` | Seatbelt 下で TLS 検証が失敗する。`SSL_CERT_FILE` が効かないことを実測済み |
| `mise ls-remote *` 他3件 | 同じ TLS 検証の問題。mise は Rust 製で platform verifier を直接叩くため環境変数が効かない |

`fork *` について、公式ドキュメントは Apple Events の問題への対処として `allowAppleEvents: true` と `excludedCommands` の二択を挙げている。**前者は採らない。** 有効にするとサンドボックス化されたコマンドが他のアプリを制限なく起動でき、実行中のアプリに AppleScript を送れるようになり、コード実行の分離が失われるため。GUI を起動したいコマンドだけを除外する方が範囲が狭い。

**`mise run` を意図的に含めていない。** タスク実行はプロジェクトのコードを走らせる経路なので、サンドボックス内に留める。ネットワーク取得系のサブコマンドだけを除外している。

**`git *` は一度入れたが外した。** `.gitconfig` の `url.ssh://git@github.com/.insteadOf https://github.com/` をコメントアウトして git が HTTPS を使うようになり、サンドボックス内でネットワーク操作が通るようになったため、除外の必要がなくなった。除外を外したことで穴が1つ減っている。

## filesystem.allowWrite

既定では作業ディレクトリと `$TMPDIR` しか書けない。ここに並んでいるのは**実際にビルドやテストが詰まって、実測で必要性を確認したものだけ**。

| エントリ | 理由 |
| :-- | :-- |
| `/private/tmp` | macOS の `/tmp` は `/private/tmp` への symlink で、Seatbelt は解決後のパスで判定する。`/tmp` だけでは効かない(実測) |
| `/tmp` | 上記のとおり冗長。明示の意味で残している |
| `~/work/gopath/pkg/mod` | `GOMODCACHE`。新規依存や toolchain 取得時のロックファイル作成に必要 |
| `~/work/gopath/pkg/sumdb` | `mod` の兄弟ディレクトリ。`sum.golang.org` の署名付きツリーヘッドのキャッシュ |
| `~/Library/Caches/go-build` | `GOCACHE`。これがないと `go build` / `go test` が全パッケージで落ちる |
| `~/Library/Caches/mise` | mise のキャッシュ |
| `~/Library/Caches/golangci-lint` | goanalysis のファクトキャッシュ。なくても lint は完走するが、毎回再計算になりパッケージ数ぶんの warning で出力が埋まる |
| `~/.npm/_logs` `~/.npm/_cacache` | npm のログとキャッシュ。認証トークンは `~/.npmrc` にあり、ここには含まれない |
| `~/.local/state/mise/task-sources` | mise のタスクフィンガープリント記録 |

### パス指定の粒度についての方針

**`~/.npm` と `~/Library/Caches` は親ごと開けず、ディレクトリを個別に列挙する**(ユーザーの明示的な方針、2026-08-22)。これらの親には無関係なツールのデータが同居しているため。

一方 `~/Library/Caches/mise` のような**ツール専用ディレクトリは、その単位で開けてよい**。避けるべきは共有の親。

この方針の副作用として、**設定を狭める編集で既存エントリが巻き添えで消えやすい**。実際 `~/Library/Caches/go-build` が一度落ちて `go test` が壊れた。`allowWrite` を編集したら主要パスを `touch` で実測確認すること。

### mise の state と share を混同しないこと

**`~/.local/share/mise` は開けてはいけない。** 配下の `shims` に実行可能な shim が置かれるため、書き込みを許すと**別のセキュリティコンテキストでのコード実行**につながる。公式ドキュメントも `$PATH` 上の実行可能ファイルを含むディレクトリへの書き込み許可を権限昇格の経路として挙げている。

開けてよいのは `~/.local/state/mise` の方。実測で**実行可能ファイル 0 件、PATH 上にもない**ことを確認済み(2026-08-23)。両者は名前が似ているだけの別ツリー。

| パス | 中身 | 扱い |
| :-- | :-- | :-- |
| `~/.local/share/mise` | `shims` `installs` `downloads` `migrations` | **開けない** |
| `~/.local/state/mise` | `task-sources` `task-auto-outputs` `tracked-configs` `trusted-configs` | ツール単位で開けてよい |

### 未解決

`~/.local/state/mise` 配下は `task-sources` しか開けていない。最小再現(`sources` と `outputs` を宣言したタスクを `mise run`)で、まず `trusted-configs` の書き込みに失敗することを確認済み。mise は state を複数のサブディレクトリに分けて使うため、ツール単位で開けるのが妥当。

## filesystem.denyWrite

```json
["/etc", "/usr/local/bin"]
```

**冗長**。既定で作業ディレクトリ外はすべて書き込み禁止なので、これらは元から届かない。`denyWrite` が意味を持つのは `allowWrite` で開けた領域の一部を再度塞ぐときだけ。

明示的な意思表示として残している。

## filesystem.denyRead

```json
["~/.ssh", "~/.config/gh", "~/.netrc", "~/.gnupg/private-keys-v1.d", "~/.docker"]
```

既定では**マシン全体が読める**。認証情報を守るには明示的に塞ぐ必要がある。

| エントリ | 理由 |
| :-- | :-- |
| `~/.ssh` | SSH 秘密鍵。git が HTTPS になったのでサンドボックス内で ssh を使う場面がなく、全体を塞いで問題ない |
| `~/.config/gh` | gh のトークン。`gh` 自体は `excludedCommands` でサンドボックス外なので通常利用に影響しない |
| `~/.netrc` | 認証情報の慣用的な置き場 |
| `~/.gnupg/private-keys-v1.d` | **秘密鍵の実体だけ**。理由は下記 |
| `~/.docker` | レジストリ認証情報。`docker` は除外済みだが、サンドボックス内の親から起動される docker は影響を受ける(要観察) |

### なぜ `~/.gnupg` ごとではないのか

一度 `~/.gnupg` 全体を `denyRead` にしたところ、**署名付き commit が壊れた**(実測)。

- `allowUnixSockets` は `denyRead` を上書きするため、`gpg-connect-agent` の接続と `KEYINFO` は成功する
- しかし gpg は `~/.gnupg/common.conf` を読んで keyboxd を使うか判断する。ディレクトリごと塞ぐとこれが読めず、レガシーな `pubring.kbx` の直読みにフォールバックして落ちる(この環境に `pubring.kbx` は存在しない)

**署名は sandbox 外の gpg-agent が行い、秘密鍵を読むのも agent。** サンドボックス内の gpg が必要とするのは `common.conf`(keyboxd を使う判断)と `public-keys.d`(公開鍵)だけなので、`private-keys-v1.d` を塞げば保護と実用が両立する。

検証結果(2026-08-23):

```
private-keys-v1.d  BLOCKED     公開鍵 public-keys.d  読める
~/.ssh             BLOCKED     common.conf          読める
~/.config/gh       BLOCKED     gpg --clearsign      成功
```

同じ原則が SSH にも当てはまる(鍵ファイルだけ塞いで `config` と `known_hosts` は残す)が、こちらは ssh を使わないので全体を塞いでいる。

コミュニティのガイドでも同じ形が採られている。参照: [The Practical Guide to Locking Down Claude Code](https://anothercoffee.net/the-practical-guide-to-locking-down-claude-code/)

### 採らなかった案: `~/.gnupg` を allowWrite に追加

検索で最も多く見つかる回避策だが、**鍵ディレクトリをサンドボックス内から書き換え可能にする**代償が大きい。

`gpgconf --launch gpg-agent` で agent を外側で起こしておけば write 許可は不要であることを実測済み。write が要るのは agent の**起動**だけで、動いている agent への接続には要らない。

## credentials.files

```json
[{ "path": "~/.config/gcloud", "mode": "deny" },
 { "path": "~/.ssh", "mode": "deny" },
 { "path": "~/.npmrc", "mode": "deny" }]
```

`denyRead` と同じ制限を、認証情報として意図が分かる形でグループ化したもの。`~/.ssh` は `denyRead` と重複しているが、意図の明示として残している。

`~/.npmrc` は npm の認証トークン。`~/.npm`(キャッシュ)とは別物なので、キャッシュを開けても漏れない。

**`~/.config/gcloud` は意図的に閉じたまま。** ADC (`application_default_credentials.json`) が読めないため GCS / Cloud Tasks のクライアント生成を伴うテストは失敗するが、これは Google アカウントのリフレッシュトークンそのもので、外向きのネットワーク経路が開いている以上リスクが大きい。

**回避策があるので緩める必要はない。** ダミーの ADC を用意して `GOOGLE_APPLICATION_CREDENTIALS` で指せば、クライアント生成を伴うテストが通る。

```json
{"type":"authorized_user","client_id":"fake-client-id.apps.googleusercontent.com",
 "client_secret":"fake-client-secret","refresh_token":"fake-refresh-token"}
```

`authorized_user` 形式にするのが要点。`service_account` だと秘密鍵の PEM を構築時にパースするためダミーでは通らない。クライアント生成さえ通ればよく、実際の API 呼び出しはエミュレータ相手のテスト中に発生しない、という構図。

実測(2026-08-23、作業しているリポジトリ): GCS / Cloud Tasks のクライアント生成を伴う3パッケージが `panic: credentials: could not find default credentials` から `ok` になり、26パッケージ全通過。**goldenfile のドリフトはゼロ**(実 API を叩かないため testdata に差分が出ない)。テスト結果を汚さない点が確認できている。

**read を開けても `gcloud` CLI は動かない。** 起動のたびに `~/.config/gcloud/.metricsUUID` を書こうとするため、`allowWrite` も要る。

```
googlecloudsdk.core.util.files.Error: Unable to write file
  [~/.config/gcloud/.metricsUUID]: [Errno 1] Operation not permitted
```

つまり「認証情報は隠したまま gcloud を使う」は成立しない。エミュレータ用途なら REST API を直接叩けば足りる(例: Spanner のインスタンス作成は `localhost:9020` への POST)。これも deny を維持する根拠になる。

### envVars が空の理由

`GITHUB_TOKEN` は `envVars: []` の状態でもサンドボックス内では `unset` になる(実測)。Claude Code が既定でスクラブしているため、追加設定は不要。

一度 `mode: "mask"` を試したが、`network.tlsTerminate` が必要な上に実際にはセンチネル値にならず、実効が `deny` と同じだったため撤去した。

## network.allowUnixSockets

```json
["/var/run/docker.sock", "~/.orbstack/run/docker.sock",
 "~/.gnupg/S.gpg-agent", "~/.gnupg/S.keyboxd"]
```

| エントリ | 理由 |
| :-- | :-- |
| `/var/run/docker.sock` | 一般的な docker ソケットパス |
| `~/.orbstack/run/docker.sock` | **実体パス**。`/var/run/docker.sock` はこれへの symlink で、Seatbelt は解決後のパスで判定するため両方要る |
| `~/.gnupg/S.gpg-agent` | GPG 署名。鍵ディレクトリの write を開けずに署名するための要 |
| `~/.gnupg/S.keyboxd` | 公開鍵の取得 |

**前提: gpg-agent が動いていること。** `allowUnixSockets` が許可するのは動いている agent への接続だけで、起動は許可しない(起動には `~/.gnupg` への write が要る)。`.zshrc` に `gpgconf --launch gpg-agent` を入れてこの前提を満たしている。

## network.allowedDomains

```json
["code.claude.com", "api.github.com", "github.com", "proxy.golang.org",
 "sum.golang.org", "mise-versions.jdx.dev", "registry.npmjs.org", "nodejs.org"]
```

事前許可がないドメインはプロンプトが出る。ここに並んでいるのは頻繁に使うもの。

| エントリ | 用途 |
| :-- | :-- |
| `code.claude.com` | ドキュメント参照 |
| `api.github.com` / `github.com` | gh、git の HTTPS 操作、依存取得 |
| `proxy.golang.org` / `sum.golang.org` | Go モジュールの取得と検証 |
| `mise-versions.jdx.dev` / `nodejs.org` | mise のツール解決 |
| `registry.npmjs.org` | npm |

**ドメイン許可では TLS 検証の問題は直らない。** `api.github.com` は許可済みでも `OSStatus -26276` で落ちる。層が違う。

セッション中に承認したホストはそのセッション限りで、他のセッションには引き継がれない。

## その他のフラグ

| 設定 | 値 | 理由 |
| :-- | :-- | :-- |
| `deniedDomains` | `[]` | 現状不要。広いワイルドカードを許可するときの安全弁として枠だけ残している |
| `allowAllUnixSockets` | `false` | 個別許可で足りている |
| `allowLocalBinding` | `true` | ローカルポートを使う開発サーバーやエミュレータのため |

---

## 設定ファイルに現れない前提

これらが崩れると、設定は正しいのに動かなくなる。

| 前提 | 場所 | 理由 |
| :-- | :-- | :-- |
| gpg-agent が起動している | `.zshrc` の `gpgconf --launch gpg-agent` | サンドボックス内から agent を起動できないため |
| git が HTTPS を使う | `.gitconfig` の `insteadOf` をコメントアウト | サンドボックス内の SSH はプロキシ認証で通らないため([claude-code #33300](https://github.com/anthropics/claude-code/issues/33300)、Closed as not planned)。子プロセスの git も救われる |
| `settings.json` が生成済み | `claude/apply-settings.sh` | 編集するのは `settings.common.json`。**適用しないと反映されない** |

`.gitconfig` の `insteadOf` は元々、osxkeychain の admin 承認プロンプトを避けるために入っていた。外した代わりに Keychain 側で Allow Always にする運用。

Keychain の ACL はバイナリのパスに紐づくため、Homebrew で git を更新するとプロンプトが復活することがある。定着しない場合は `gh auth setup-git` で認証ヘルパーを gh に切り替える手もある。

### custom-gcl が sandbox 内でビルドできない (upstream 側の問題)

`golangci-lint custom` の内部 `git clone` が exit 128 で落ちる。**設定では直せない。**

原因は golangci-lint の `filterGitEnviron` ([PR #6515](https://github.com/golangci/golangci-lint/pull/6515)、`pkg/commands/internal/builder.go`)。`GIT_` で始まる環境変数を許可リストで絞っており、そこに **`GIT_CONFIG_PARAMETERS` が含まれていない**。Claude Code はこの変数で `http.proxyAuthMethod=basic` を渡しているため、サンドボックスの認証必須プロキシに接続できなくなる。

```
git clone --depth 1 -q https://github.com/octocat/Hello-World.git p1   → EXIT=0
env -u GIT_CONFIG_PARAMETERS git clone ... p2                          → EXIT=128
```

`http_proxy` / `https_proxy` は `GIT_` で始まらないため素通りしており、**プロキシ変数の欠落ではない**。両者は同じ exit 128 になるがメッセージが異なる(前者は `Proxy CONNECT aborted` / `Connection reset by peer`、後者は `Could not resolve host`)。golangci-lint が git の stderr を握り潰すため、メッセージでは切り分けられない。

当面はユーザーがターミナルで実行する。upstream には許可リストへの `GIT_CONFIG_PARAMETERS` 追加を提案する(`GIT_CONFIG_COUNT` / `GIT_CONFIG_KEY_*` / `GIT_HTTP_PROXY_AUTHMETHOD` は既に通っているので、単純な漏れに見える)。

### 既知の不整合

`gpg` が 2.5.21 なのに常駐している `keyboxd` が 2.5.20 で、署名のたびに警告が出る(動作には影響しない)。Homebrew で gnupg を更新したがデーモンが古いまま常駐しているため。

解消するにはサンドボックス外のターミナルで以下を実行する。**`gpgconf --kill all` は gpg-agent も落とすので、必ず起動し直すこと**(新しいターミナルを開けば `.zshrc` が起こす)。

```bash
gpgconf --kill all && gpgconf --launch gpg-agent
```

## 意図的に入れていないもの

| 項目 | 理由 |
| :-- | :-- |
| `~/.gnupg` の allowWrite | agent を外で起こせば不要。鍵ディレクトリの改竄を許すことになる |
| `~/.gnupg/trustdb.gpg` の allowWrite | 署名の**作成**には不要。**検証**(`git log --show-signature`)だけが通らないが、検証は外でやれば済む |
| `go *` の excludedCommands | `go test` / `go run` がプロジェクトのコードを実行するため |
| `mise run` の excludedCommands | 同上 |
| `golangci-lint custom*` の excludedCommands | そもそも効かない。`mise run setup:server` → `setup.sh` → `golangci-lint` という入れ子で、トップレベルは `mise` のため。真因は golangci-lint 側(下記) |
| `~/.config/gcloud` の開放 | ADC は Google アカウントのリフレッシュトークン |
| `/var/folders/.../T`(`DARWIN_USER_TEMP_DIR`)の allowWrite | 下記の決定ログを参照。**中身を列挙できず、消費者がサンドボックス外にいる**ため個別に絞る戦術が成立しない |
| `network.tlsTerminate` | 実験的機能。有効にしても mask が動かなかった |
| `.claude/**` の allowWrite | **原理的に不可。** 公式の[保護されたパス](https://code.claude.com/docs/ja/permission-modes#protected-paths)で、安全性チェックが allow ルールより前に評価される。下記の運用で回避する |

## `.claude/` を追跡するリポジトリでの運用

`.claude/skills` `hooks` `agents` `commands` は Claude Code の組み込み保護で書き込み不可。**リポジトリがこれらを追跡していると、git がファイルを更新できずマージやチェックアウトが丸ごと失敗する。**

```
error: unable to unlink old '.claude/skills/xxx/SKILL.md': Operation not permitted
Merge with strategy ort failed.
```

設定では緩められないので、**`git pull` / `git merge` / `git checkout` / `git worktree add` は Claude Code の外のターミナルで実行する**。`ln.sh` や `apply-settings.sh` と同じ扱いになる。

この dotfiles 自身も `claude/.claude/skills/sandbox-tuning/` を追跡しているため対象。別マシンで SKILL.md を更新して pull するときに踏む。

編集自体は Write / Edit ツールなら通る(sandbox を経由しないため)。壊れるのは git 経由の更新だけ。

---

## 決定ログ

**最終確認日は「その事実がいつ時点のものか」を示すもので、次回の期限ではない。** 確認したら更新する。

**見直すのは次の2つの場合。**

1. **その行の「再考のトリガー」が起きたとき。** 上流の Issue は状態が変わっていることがあるので、リンク先を実際に開いて確認する
2. **その制約による不便が積み重なったとき。** トリガーが起きていなくても、外のターミナルに出る回数が増えた、同じ回避策を何度も説明している、といった摩擦が続くなら再考してよい。**「決めたことだから」で我慢し続けない**

どちらでもない項目は放置してよい。動いているものを定期的に掘り返す必要はない。

| 決定 | 最終確認日 | 判断基準・根拠 | 再考のトリガー |
| :-- | :-- | :-- | :-- |
| `.claude/**` を allowWrite しない。git の書き込み操作は外のターミナルで代行 | 2026-08-23 | [保護されたパス](https://code.claude.com/docs/ja/permission-modes#protected-paths)に `.claude` が明記され、安全性チェックが allow ルールより前に評価される。[#53891](https://github.com/anthropics/claude-code/issues/53891) でも実測で否定 | 保護されたパスの仕様が変わる / 上書き手段が追加される / #53891 の重複先(#50505, #52851, #51303)が修正される |
| `denyRead` は `~/.gnupg` 全体ではなく `private-keys-v1.d` のみ | 2026-08-23 | 全体を塞ぐと `common.conf` が読めず keyboxd を選べないため署名が壊れる(実測)。[コミュニティのガイド](https://anothercoffee.net/the-practical-guide-to-locking-down-claude-code/)も同じ形 | gpg が公開鍵の取得経路を変える / 秘密鍵の置き場が増える |
| `~/.gnupg` を allowWrite しない。agent は `.zshrc` で外から起動 | 2026-08-23 | write が要るのは agent の**起動**だけで、動いている agent への接続には不要(実測) | agent が動いていても write を要求するようになる |
| `go *` を excludedCommands に入れず `env.SSL_CERT_FILE` で解決 | 2026-08-23 | [トラブルシューティング](https://code.claude.com/docs/ja/sandboxing#troubleshooting)は excludedCommands を案内するが、`go test` / `go run` がプロジェクトのコードを実行するため採らない | trustd への XPC を許可する設定が追加される / Go が platform verifier を使わなくなる |
| `gh` と `mise` は excludedCommands。環境変数では直せない | 2026-08-23 | `SSL_CERT_FILE` が効かないことを実測(gh は Go 製だが効かない) | 上と同じ / 各ツールが環境変数を見るようになる |
| `excludedCommands` は最小限。`mise run` は含めない | 2026-08-23 | 除外対象を1つでも含む呼び出しは**全体が**サンドボックス外に出る(docker と git で実測)。挙動の報告として [claude-code #22620](https://github.com/anthropics/claude-code/issues/22620) | 除外がコマンド単位で厳密に適用されるようになる / 子プロセスにも継承されるようになる |
| `~/.config/gcloud` は開けない | 2026-08-23 | ADC は Google アカウントのリフレッシュトークン。ダミー ADC の回避策があり、テストは通せる | ダミー ADC が効かなくなる / gcloud が設定と認証情報を別ディレクトリに分ける |
| custom-gcl のビルドは外のターミナル | 2026-08-23 | golangci-lint の [#6515](https://github.com/golangci/golangci-lint/pull/6515) が `GIT_CONFIG_PARAMETERS` を落とす。設定では直せない | upstream が許可リストに追加する / Claude Code が `GIT_CONFIG_COUNT` 形式に切り替える |
| `~/.npm` と `~/Library/Caches` は親ごと開けない | 2026-08-22 | 無関係なツールのデータが同居する(ユーザーの明示的な方針) | 方針変更 |
| `/add-dir` 先を allowWrite に足さない。そのプロジェクトで別セッションを開いて作業を依頼する | 2026-08-29 | サンドボックスは**各セッション自身の cwd** に書き込みを許可するので、セッションを分ければ設定変更なしで解決する。**判断当時の理由(「`/add-dir` は仕様上サンドボックスに反映されない」)は誤り**だった。[公式](https://code.claude.com/docs/en/sandboxing#filesystem-isolation)は `--add-dir` / `/add-dir` 先も書けると明記しており、実測の BLOCKED はバグの可能性がある(設定キー `additionalDirectories` と混同していた)。結論は変えないが、根拠が違う | 実測で書けるようになる(バグが直る) / セッションを分ける手間が積み重なる |
| pnpm のストア(`~/Library/pnpm/store`)を開けない | 2026-08-29 | リポジトリ直下に `.pnpm-store/` ができるのは [pnpm#13525](https://github.com/pnpm/pnpm/issues/13525) のバグで、**サンドボックス側の問題ではない**。修正は破壊的変更のため **v12 のみ**(メンテナ確認済み。v11 に上げても直らないことを実測)。当面は `pnpm_config_store_dir` を明示すればホームストアを読み取り専用のまま使える(`--frozen-store`) | pnpm v12 が出る / `storeDir` 明示で回らない事情が出る |
| `~/.npm/_npx` と `~/Library/Caches/pnpm/dlx` を開けない | 2026-08-29 | ダウンロードしたパッケージを実行時に `.bin` として PATH に載せる領域。実測で `_npx` に684個、`dlx` に17個の実行可能ファイル。書き換えられると後の `npx` / `pnpm dlx` 実行時に走る(サンドボックス外で走ることもある) | 実行可能ファイルを置かない構造に変わる |
| `~/Library/Caches/pnpm` は親を開けて `dlx` だけ `denyWrite` | 2026-08-29 | `metadata-v1.3` のようにバージョン番号付きのディレクトリがあり、個別列挙だと pnpm の更新で壊れる。**`denyWrite` が `allowWrite` の内側で機能することを実測**(この設定で初めて `denyWrite` が意味を持った) | pnpm がキャッシュの構造を変える |
| `~/.cache/uv` を開けない。**サンドボックス専用のキャッシュを `UV_CACHE_DIR` で与える** | 2026-09-05 | キャッシュの主要部分が実行可能物(`environments-v2` の venv、展開済み wheel、ビルド済み wheel、git チェックアウト)。**キャッシュ再利用時にバイト列からのハッシュ再検証が無い**(記録済みダイジェストとの照合＋mtime fast path のみ)。`uvx` / `uv run` は人間がターミナルで叩く典型的なコマンドなので、`~/.npm/_npx` や `pnpm dlx` と発火条件が同型。**読み取り専用キャッシュのモードは uv に無い**([#15934](https://github.com/astral-sh/uv/issues/15934) が open)ので初回代行パターンは使えない。`~/.cache` 親は12以上のツールが同居する共有の親 | uv が read-only キャッシュを実装する / 専用キャッシュの二重持ちが負担になる |
| `~/.local/share/uv` を開けない | 2026-09-05 | `credentials/credentials.toml` が**平文**(native keyring は preview)。`tools/` は `~/.local/bin` へ symlink されて `$PATH` に載る。ここへの書き込み違反が出たら、**許可ではなく原因の除去**で対処する(`uv tool install` / `uv auth login` / managed Python の自動 DL をやろうとしているシグナル) | uv が既定で keyring を使うようになる |
| `~/.quint` を開けない。**初回だけ人間が外のターミナルで実行してキャッシュを満たし、以後は読み取り専用で使う** | 2026-09-05 | 中身は**無検証で実行されるバイナリ**(Rust 評価器、Apalache のランチャと JAR)。0.32.0 の配布物を確認したがチェックサム・署名の検証コードが一切ない。しかも**ファイルが存在すればダウンロードせずそのまま実行する**ため、サンドボックス内で置いて `chmod +x` するだけで成立し、以後永久に再検証されない。`~/.quint` は未作成なので、開けると**最初に作るのがエージェント**になり比較基準が存在しない。`$PATH` には載らないが `quint` 自身が絶対パスで spawn するため、人間がターミナルで `quint run` を一度叩けば発火する | quint が完全性検証を実装する / `QUINT_HOME` 運用が破綻する |
| `DARWIN_USER_TEMP_DIR`(`/var/folders/<xx>/<hash>/T`)を開けない | 2026-09-05 | **ここは自分のターミナルの `$TMPDIR` そのもの**(per-uid、サンドボックス内外の全プロセスが共有)。`xcrun_db`(Xcode 系の実行ファイルパス解決キャッシュ)と JVM が `dlopen` するネイティブライブラリが置かれ、汚染すると**サンドボックス外で実行される**。中身を列挙できないので `denyWrite` で危険な子だけ塞ぐ戦術が成立しない(`~/Library/Caches/pnpm` + `dlx` のパターンが使えない)。パスが user UUID 由来でマシンごとに異なり、そもそも共有設定に書けない。**代わりに `mktemp` の呼び方を直す**(罠12) | 呼び方を直せない third-party ツールが常用の障害になる |
| `~/.local/share/mise` は開けない | 2026-08-23 | `shims` に実行可能ファイルがある。[公式](https://code.claude.com/docs/ja/sandboxing#security-limitations)が `$PATH` 上のディレクトリへの書き込みを権限昇格の経路として挙げている | mise が shims の置き場を変える |

