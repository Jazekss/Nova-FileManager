---
name: debug-discipline
description: Use whenever a bug fix or change fails twice, or the same area is edited repeatedly without progress.
---

1. Stop editing. Re-read the exact error and the code path it points to.
2. State the root-cause hypothesis in one sentence, then verify it with logs, a minimal reproduction or a test BEFORE changing code.
3. Change one thing at a time. Revert failed attempts; never stack patches.
4. After 2 failed attempts list 2-3 alternative causes and check the cheapest first. After 3, stop and ask the user, summarising what was tried.
5. Prefer the smallest diff. Do not refactor unrelated code while debugging.
6. Confirm the fix by running the actual test or command, not by reasoning.
