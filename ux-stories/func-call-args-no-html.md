# Dominds WebUI Regression: func-call arguments 不应渲染为 HTML

目标：当 UI 展示 `func-call-arguments`（JSON 字符串）时，即使参数里包含形如 `<dominds-app>` 的文本，也必须以**纯文本**展示，不能被浏览器解析成真实 DOM / 自定义 Web Component。

## 复现场景

1. 启动 WebUI（rtws 使用 `ux-rtws/`）：

```bash
./dev-server.sh restart
```

2. 打开页面后，让测试对象触发一次 **function/tool call**，并确保 arguments 里包含类似内容（举例）：

```json
{
  "note": "do not render <dominds-app> here",
  "nested": {
    "htmlLike": "<dominds-app></dominds-app>"
  }
}
```

（只要能让 UI 出现 `Function:` 这类区块，且 `func-call-arguments` 区域显示上述 JSON 即可；具体调用哪个 tool 不重要。）

## 期望结果（Pass/Fail）

- Pass：`func-call-arguments` 以纯文本显示 `<dominds-app>`，页面里**不会出现**实际的 `<dominds-app>` DOM 节点，也不会触发任何自定义 element 的副作用。
- Fail：`func-call-arguments` 里出现被解析后的 DOM（例如页面里真的插入了 `<dominds-app>`），或出现异常渲染/崩溃。
