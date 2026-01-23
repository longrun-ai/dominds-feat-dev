# Progress

- Verified `append_file` returns low-noise YAML and normalizes newlines (adds leading newline when file lacks trailing NL; adds trailing newline to appended content); confirmed via `scratch/uat-eof-no-nl.txt`.
- Verified `replace_file_contents` resets `scratch/uat-txt-tools.txt` baseline and adds trailing newline normalization.
- Verified `insert_after` (`occurrence=1`, `strict=true`) inserts correct line count and returns YAML with `evidence_preview` and `normalized`.
- Verified `insert_before` (`occurrence=1`, `strict=true`) inserts at correct location and returns YAML with `evidence_preview`.
- Verified `insert_after` without `occurrence` fails with `ANCHOR_AMBIGUOUS` when anchor appears multiple times (good error + guidance).
- Verified `replace_block` (`include_anchors=true`) replaces expected line range and preserves anchors; confirmed via `!!@read_file scratch/uat-txt-tools.txt` showing `L2 anchor: A` then `BLOCK-NEW-1/BLOCK-NEW-2`, then `L4 anchor: B`.
- Verified `plan_file_modification` / `apply_file_modification` UX output: low-noise YAML summary + evidence + match classification (`match/context_match: exact`) and unified diff retained; confirmed by planning `!uat1` and applying it to change line 1 to `L1 HELLO-CHANGED` in `scratch/uat-txt-tools.txt`.
- Verified `overwrite_file` warns on diff-like content and writes literally (diff markers are saved as text).
- Verified `ripgrep_files` / `ripgrep_snippets` / `ripgrep_fixed` / `ripgrep_count` YAML outputs (snippets include `before`/`after` arrays, even when empty).
