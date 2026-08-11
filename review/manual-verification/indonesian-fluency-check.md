# Manual Verification — Indonesian Answer-Language Fluency Check

**For:** Kv, to execute on the physical device ("Kahfi's Phone," iPhone 17) — not something a
task-runner subagent can do (no tooling for interactive on-device typing in Indonesian or
judging natural-language output quality).

**Task:** T3 (`tasks/task-graph.md`). **Backlog item:** #3 (`planning/engineering-plan.md`).
**Informs (contingent on the result below):** `memory/decisions.md`'s 2026-08-10 "Answer-language
mirroring (English/Indonesian) implemented as assumed; Indonesian support still
runtime-unverified" entry — recorded/updated in T5, not by running this script itself.

This document is self-contained. You should not need to open `planning/engineering-plan.md` or
`tasks/task-graph.md` to run it.

## Why this check exists

Apin's Ask flow is meant to mirror the language of the question — answer in Indonesian when
asked in Indonesian, English when asked in English (defaulting to English if detection is
ambiguous). This behavior has only ever been *implemented as assumed*: no one has confirmed that
the on-device `FoundationModels` model, running on Kv's actual iPhone 17 hardware, genuinely
produces fluent, coherent Indonesian output rather than something stilted, code-switched, or
partially untranslated. This script is that hands-on check.

**A note on scope — technical vs. product:** this script only tests *technical fluency* — can the
on-device model produce usable Indonesian text at all. It does **not** decide the separate,
still-open *product* question (`planning/engineering-plan.md`'s Open Questions #2 / spec open
question #5's product half): *should* Apin mirror English/Indonesian in the first place, versus
being English-only by design. That product call is Kv's to make and isn't resolved by this
checklist. That said, the two are related — a fluency fail here makes the case for shrinking
scope to English-only stronger, while a fluency pass doesn't by itself confirm mirroring is the
right product choice. When you report back, mention both angles (the technical result below, and
whether you still want mirroring as a product) so whoever records the outcome (T5) can capture
both, not just the technical one.

## What you're testing

The Ask flow: opening Apin, typing a question in Indonesian into the "Ask Apin something…" field,
tapping the "Ask" button, and reading the on-device model's full, completed answer. This is the
app's only screen (no tab bar/navigation to worry about — the app opens directly into it).

Run all five questions below in a single session if you can — one pass/fail judgment per
question, then one overall pass/fail for the check as a whole (see "Pass / fail" below).

---

## Questions to ask

Type each of these into the Ask field (in Indonesian, exactly as written or close to it) and tap
**Ask**. Wait through the full response — "Thinking…", then the streaming partial-answer text,
until the text stops updating (final answered state) — before judging it.

1. **Factual question:** "Apa ibu kota Indonesia?"
   (*"What is the capital of Indonesia?"* — simple, single-fact, easy to judge correctness and
   coherence against.)

2. **Factual question, personal-data-adjacent:** "Berapa banyak entri jurnal yang sudah saya
   tulis minggu ini?"
   (*"How many journal entries have I written this week?"* — tests whether the model can produce
   a fluent Indonesian answer when it's also pulling from real journal data, not just general
   knowledge.)

3. **Conversational question:** "Apa kabar? Ada saran supaya aku lebih semangat menulis jurnal
   hari ini?"
   (*"How's it going? Any advice to help me feel more motivated to journal today?"* — casual
   register, tests whether the model can hold a conversational tone in Indonesian rather than
   sounding like a stiff translation.)

4. **Longer / more complex question:** "Aku lagi coba bangun kebiasaan menulis jurnal setiap
   malam sebelum tidur, tapi sering lupa atau keburu ketiduran. Menurutmu apa yang bisa aku
   lakukan supaya kebiasaan ini lebih nempel, dan apa saja alasan biasanya orang gagal
   membangun kebiasaan baru?"
   (*"I'm trying to build a habit of journaling every night before bed, but I often forget or
   fall asleep first. What do you think I could do to make this habit stick, and what are the
   usual reasons people fail to build new habits?"* — multi-part, longer input; tests whether
   fluency holds up as answer length and structural complexity increase, not just on short
   replies.)

5. **Rephrased factual question (different phrasing from #1, same general difficulty):**
   "Coba jelaskan, kota apa yang jadi ibu kota negara Indonesia?"
   (*"Can you explain which city is the capital city of the country of Indonesia?"* — same fact
   as #1 but phrased more indirectly/conversationally, to check consistency of fluency across
   phrasing rather than one lucky/unlucky result.)

If you want to add more questions beyond these five, feel free — this is a floor, not a ceiling.

---

## What "fluent / usable" looks like vs. not

Judge each answer against these concrete criteria. Don't use a vague "sounds good" gut check —
walk through each point below for every answer.

**Looks like a pass:**
- The answer is written in Indonesian throughout (not a mix where entire sentences or the bulk of
  the response are in English while only a fragment is Indonesian).
- Sentences are grammatically coherent Indonesian — correct word order, proper conjugation/affixes
  (e.g. `menulis` not a broken stem like `tulis-ing`), not a literal word-for-word English
  translation that reads unnaturally.
- The answer is on-topic — it actually addresses what was asked, not a generic non-answer.
- Vocabulary is real, standard Indonesian (formal or casual register is fine) — not invented
  words, not English words merely spelled/pronounced as if Indonesian.
- If there's a factual claim (questions 1, 2, 5), it's correct.

**Looks like a fail:**
- Untranslated English fragments dropped mid-sentence (e.g. a sentence that starts in Indonesian
  and switches to English mid-way for a clause or phrase, not as a deliberate/natural loanword).
- Grammatically broken Indonesian — word salad, wrong affixes, sentence structure that doesn't
  parse as valid Indonesian even loosely.
- The answer is in English (or another language) despite the question being asked in Indonesian,
  with no Indonesian at all.
- The answer is technically "in Indonesian" but incoherent or off-topic to the point that a
  native/fluent Indonesian reader wouldn't consider it a usable answer to the question asked.
- The model errors out, hangs, or fails to produce a completed answer for an Indonesian-language
  question specifically (as opposed to a general Ask-flow failure unrelated to language — if
  that happens, note it, but judge it separately from a fluency fail).

---

## Pass / fail

**Per-question:** for each of the 5 questions, mark it fluent-pass or fluent-fail using the
criteria above.

**Overall:**
- **Pass:** All 5 questions are individually fluent-pass.
- **Fail:** Any one of the 5 questions is fluent-fail.

If the overall result is **Fail**, do not treat that as a signal to auto-shrink scope to
English-only yourself — that is explicitly not this checklist's call to make. Instead, **surface
the result back to Kv** (i.e., you, reading this later, or whoever is reporting the outcome) as a
scope decision: whether to invest in improving Indonesian fluency further, ship as-is with a
known limitation, or shrink the mirror-language feature to English-only. Record what you observed
in the Result section below in enough detail (which question(s) failed, and how — untranslated
fragment, broken grammar, wrong language entirely, etc.) that the scope decision can be made from
your notes without re-running the check.

---

## Result

- **Date run:** 11 August 2026
- **Per-question results (fluent-pass / fluent-fail, with a one-line note each):**
  1. Q1 (ibu kota — factual): fail, answered in English
  2. Q2 (entri jurnal minggu ini — factual, personal data): fail, still added a sentence with English and cannot fetch data
  3. Q3 (semangat menulis jurnal — conversational): fail, still added a sentence with English
  4. Q4 (kebiasaan menulis jurnal — longer/complex): fail, couldn't get an anser because of unsupported language
  5. Q5 (ibu kota, rephrased — factual consistency): fail, answered in English and didn't explain
- **Overall Pass / Fail:** 0/5
- **Notes (specific failure details if any — untranslated fragments, broken grammar, wrong
  language, factual errors, etc.):** mixed up Indonesian and English sentence, cannot fetch journal data, and if long, cannot answer because language not supported
- **Your read on the separate product question (should Apin mirror English/Indonesian at all,
  independent of today's technical result) — optional, but helpful for whoever records this in
  `memory/decisions.md`:** i think only English is enough
