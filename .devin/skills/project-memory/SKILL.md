---
name: project-memory
description: Use at the start and end of every task in a multi-module project to read and update the compact project map.
---

- At task start read PROJECT_MAP.md first. Do not scan the whole repo; use search/grep to find specific files and open docs/<module>.md only when the task touches that module.
- At task end update PROJECT_MAP.md with new or moved files, changed behaviour, decisions made and status (done / in progress / blocked / next).
- Keep the map under ~150 lines: one line per module, no code, no history. Move detail into docs/<module>.md and link it.
- If the map and the code disagree, trust the code and fix the map.
- Never paste large files into notes; reference paths instead.
