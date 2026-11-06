---
name: herdr-handoff
description: herdr で 1 タスク 1 workspace を作り、新しい Claude Code のセッションを起動して、利用者の指示をそのまま渡す。git に commit する作業なら、herdr の worktree として作業場所を切ってから渡す。渡したら結果は待たず、どこに渡したかだけ報告する。
when_to_use: 「この作業を別のセッションにやらせて」「herdr で workspace を作って渡して」のように、タスクを別のセッションに任せるよう頼まれたとき。herdr の中で動いているとき(HERDR_ENV=1)に限る。
---

# herdr で別のセッションにタスクを渡す

指示役のセッション(このセッション)は、タスクの中身に関与しない。作業場所を用意し、エージェントを起動し、指示を渡すところまでを受け持つ。

同じディレクトリに `machine.md` があれば、最初に読む。マシンごとの作業場所の決め方(どの話題をどのリポジトリで扱うか、など)が書いてある。

## 前提を確かめる

```bash
test "${HERDR_ENV:-}" = 1
```

失敗したら、herdr の中にいないと伝えて止める。

herdr のコマンドの細かい使い方は `herdr --skill` と `herdr <group>`(`herdr agent`、`herdr workspace`、`herdr worktree` など)で確かめる。引数を省いて変更系のコマンドを試さない。素の `herdr` は TUI を起動するので実行しない。

**sandbox の内側では herdr の操作コマンドが失敗することがある。** herdr は `HERDR_SOCKET_PATH` の Unix ソケットに繋ぐので、そのソケットが sandbox で許されていなければ Operation not permitted で落ちる。そのときは失敗したコマンドだけを sandbox の外で実行し直す。

## 1. 作業場所を決める

**1 タスク 1 workspace にする。** 隣の pane ではなく、タスクごとに workspace を作る。

タスクが git に commit する作業かどうかで分ける。

- **commit しない作業**(調べて説明する、読んでまとめる、など): その作業に合うディレクトリで workspace を作る。

  ```bash
  herdr workspace create --cwd <ディレクトリ> --label <短いラベル> --no-focus
  ```

- **commit する作業**: 親の working tree を汚さないよう、worktree を切ってそこで作業させる。`herdr worktree create` は worktree を作り、それを開いた workspace も作る。

  ```bash
  herdr worktree create --cwd <リポジトリ> --branch <ブランチ名> --base <起点> --path <worktree の置き場所> --label <短いラベル> --no-focus
  ```

  - リポジトリのローカルパスと worktree の配置の形は、探し回る前に `how-to-use-local-wiki` スキルで local-wiki を引く。`--path` は、その配置の形に合わせる。
  - リポジトリの CLAUDE.md がブランチを切らずに作業するよう指示しているなら、worktree は切らない。commit しない作業と同じく、そのディレクトリで workspace を作る。
  - ブランチ名は、そのリポジトリの慣習に従う。分からなければ利用者に聞く。

どちらも、応答の JSON から workspace の ID と root pane の ID(`.result.root_pane.pane_id`)を読む。ID を推測しない。

## 2. エージェントを起動する

```bash
herdr agent start <名前> --kind claude --pane <root pane の ID>
```

名前は `[a-z][a-z0-9_-]{0,31}` で、動いているエージェントの間で一意にする。タスクが分かる名前にする(`pr4530`、`slack-explain` など)。

起動して `idle` になったことを応答で確かめる。`agent_not_ready` が返ったら、`herdr agent read <名前>` で画面を見て、利用者に伝える。

## 3. 指示を渡す

**利用者の指示は、文面をそのまま渡す。** 要約や言い換えをしない。指示役のセッションは、指示の中身を読んで作業を始めない。

ただし、「<URL> これを担当するセッション作って」のように、指示が指示役のセッションへの依頼の形をしていることがある。そのまま渡すと、渡した先がさらにセッションを作ろうとする。このときは、依頼の部分を外し、タスクの部分だけを文面のまま渡す(例: `<URL> これを担当して`)。報告では、どう変えて渡したかを伝える。

作業場所を決めるために、Slack のスレッドなどを読んでリポジトリを確かめるのはよい。読むのは、作業場所と commit の要否が分かるところまでにする。

```bash
herdr agent prompt <名前> "<利用者の指示>" --wait --until working --timeout 30000
```

`--until working` で、エージェントが作業を始めたところまでを確かめる。終わるまでは待たない。`agent_blocked` や `agent_prompt_stalled` が返ったら、`herdr agent read <名前>` で画面を見て、利用者に伝える。承認ダイアログには代わりに答えない。

## 4. 報告する

結果は待たない。利用者は渡した先の workspace で直接やりとりする。報告するのは次だけ。

- workspace のラベルと ID、worktree を切ったならそのパスとブランチ
- エージェントの名前と状態
- 指示を文面のまま渡したこと(依頼の部分を外したなら、渡した文面)
- 報告は利用者との会話の言語(日本語)で書く
- フォーカスは移していないこと(画面を切り替えるときは herdr でその workspace を選ぶ)
- 様子を知りたいときは「様子を見て」と言えばよいこと

「様子を見て」と言われたら、`herdr agent read <名前>` で画面を読み、要約して伝える。

## 後片付け

workspace や worktree は、利用者が言うまで閉じない。閉じるよう頼まれたら、未 commit の変更や未 push の commit が無いかを確かめてから、`herdr worktree remove` や `herdr workspace close` を使う。
