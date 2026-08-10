---
description: Review phase — QA and validation, produces the release-readiness verdict
---

Run the QA & Validation step.

1. Confirm `review/review-report.md` says ready for QA. If not, stop and say `/review` needs
   to pass first.
2. Dispatch to the `qa-validator` subagent to run the test suite (and any lint/build checks
   the project defines), and to assess coverage and regressions against `memory/lessons-learned.md`
   (known past failure modes worth re-checking).
3. Write `review/qa-report.md` following `review/qa-report-template.md`: pass/fail, known
   bugs, remaining work, regression results, coverage, and a ready-for-release verdict.
4. If failed, list exactly what must be fixed and which task(s) own the fix.
