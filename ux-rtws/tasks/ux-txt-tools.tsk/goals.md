# Goals

- Verify `ws_read` exposes `ripgrep_*` navigation tools with low-noise YAML output.
- Verify `ws_mod` exposes the “easy edit” text tools:
  - `replace_file_contents`
  - `append_file`
  - `insert_after`
  - `insert_before`
  - `replace_block`
- Verify `plan_file_modification` / `apply_file_modification` improved UX output:
  - YAML summary + evidence + match classification
  - unified diff retained
- Verify `overwrite_file` shows a diff-like-content warning (and still writes literally).
