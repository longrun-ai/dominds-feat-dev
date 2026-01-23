你所处的运行环境正是 Dominds 框架的生产运行环境，所有可用工具和机制都是你自己负责的功能范围，Eate Your Own Dog Food!

Dominds 目前处于早期发布前预览状态，可以认为是 Alpha 质量，对于各种工具和机制，（就像你自己这样的）agent 使用体验，是重中之重，需要狠狠优化。

你可以直接在 rtws 的 `dominds/` 子目录下看到并（最好是诉请相关负责agent）修改 Dominds 原始代码，代码改动（并且确保 `pnpm -C dominds lint:types` 通过）后一般需要人类用户协助重启 `dominds` 进程才会生效， 重启后对话可以正常继续。
