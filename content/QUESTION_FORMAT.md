# Question bank format

Source of truth: `content/raw/<part>/batch_NN.json`. Each file is a JSON array of questions.
`python3 tools/build_bank.py` validates every batch and writes the app bundle `assets/data/bank.json`.

## Question object

```json
{
  "id": "u1a-0001",
  "sub": "1.2",
  "level": "core",
  "q": "A car travels 120 m in 8.0 s. What is its average speed?",
  "columns": null,
  "options": ["0.067 m/s", "15 m/s", "112 m/s", "960 m/s"],
  "answer": 1,
  "explain": "average speed = distance / time = 120 / 8.0 = 15 m/s."
}
```

| Field | Rules |
|---|---|
| `id` | `<part>-NNNN`, unique across the whole bank, numbered in order within a part |
| `sub` | syllabus subtopic number from the topic list below, e.g. `"1.5.2"` or `"4.3"` |
| `level` | `"core"` or `"extended"` (Supplement content) |
| `q` | the stem. Plain text; `\n` allowed for line breaks. Describe any diagram in words. |
| `columns` | `null`, or 2–4 column headings for a "Which row is correct?" question. Each option is then the cells joined by ` | ` (same count as columns). |
| `options` | exactly 4 distinct strings (A, B, C, D in order). Never "all of the above", "none of these", "A and B" or anything that refers to another letter. |
| `answer` | index 0–3 of the correct option |
| `explain` | 1–3 sentences: why the answer is right (working for calculations). |

Notation: use plain Unicode — `m/s²`, `Ω`, `Δθ`, `λ`, `°C`, `×10⁸`, subscripts as `²³⁸₉₂U` or "uranium-238". Units SI as in the syllabus; g = 9.8 m/s² (or 10 N/kg only if the stem says so).

## Topics and subtopics (Cambridge IGCSE Chemistry 0620, 2026–2028)

The authoritative list is `TOPICS` in `tools/build_bank.py`, taken from the official syllabus
(section numbers 1–12 and their subsections, e.g. `"2.4"` Ions and ionic bonds, `"11.5"` Alkenes).
Use only those codes in `sub`. Core vs Supplement: an objective in the Supplement column of the
syllabus is Extended content; everything else is Core.
