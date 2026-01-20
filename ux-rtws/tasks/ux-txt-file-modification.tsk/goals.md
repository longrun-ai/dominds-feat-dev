# Goals

- Verify `ws_mod` toolset exposes `plan_file_modification` and `apply_file_modification`.
- Verify `plan_file_modification` and `apply_file_modification` work end-to-end in WebUI.
- Verify safety behavior: applied hunks are removed from cache.
- Verify safety behavior: stale planned hunks refuse to apply after file changes.
- Verify multi-file batching is safe under parallel tool execution.
- Verify same-file multi-hunk apply works in one message (serialized in-process).
