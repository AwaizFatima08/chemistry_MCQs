#!/usr/bin/env python3
"""Validate content/raw/**/batch_*.json and build assets/data/bank.json.

Usage:
  python3 tools/build_bank.py            # validate all parts and write the bundle
  python3 tools/build_bank.py --check u3 # validate one part only, write nothing
"""
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "content", "raw")
OUT = os.path.join(ROOT, "assets", "data", "bank.json")

TOPICS = {
    1: ("States of matter", [
        ("1.1", "Solids, liquids and gases"), ("1.2", "Diffusion")]),
    2: ("Atoms, elements and compounds", [
        ("2.1", "Elements, compounds and mixtures"), ("2.2", "Atomic structure and the Periodic Table"),
        ("2.3", "Isotopes"), ("2.4", "Ions and ionic bonds"), ("2.5", "Simple molecules and covalent bonds"),
        ("2.6", "Giant covalent structures"), ("2.7", "Metallic bonding")]),
    3: ("Stoichiometry", [
        ("3.1", "Formulae"), ("3.2", "Relative masses of atoms and molecules"),
        ("3.3", "The mole and the Avogadro constant")]),
    4: ("Electrochemistry", [
        ("4.1", "Electrolysis"), ("4.2", "Hydrogen–oxygen fuel cells")]),
    5: ("Chemical energetics", [
        ("5.1", "Exothermic and endothermic reactions")]),
    6: ("Chemical reactions", [
        ("6.1", "Physical and chemical changes"), ("6.2", "Rate of reaction"),
        ("6.3", "Reversible reactions and equilibrium"), ("6.4", "Redox")]),
    7: ("Acids, bases and salts", [
        ("7.1", "The characteristic properties of acids and bases"), ("7.2", "Oxides"),
        ("7.3", "Preparation of salts")]),
    8: ("The Periodic Table", [
        ("8.1", "Arrangement of elements"), ("8.2", "Group I properties"),
        ("8.3", "Group VII properties"), ("8.4", "Transition elements"), ("8.5", "Noble gases")]),
    9: ("Metals", [
        ("9.1", "Properties of metals"), ("9.2", "Uses of metals"),
        ("9.3", "Alloys and their properties"), ("9.4", "Reactivity series"),
        ("9.5", "Corrosion of metals"), ("9.6", "Extraction of metals")]),
    10: ("Chemistry of the environment", [
        ("10.1", "Water"), ("10.2", "Fertilisers"), ("10.3", "Air quality and climate")]),
    11: ("Organic chemistry", [
        ("11.1", "Formulae, functional groups and terminology"), ("11.2", "Naming organic compounds"),
        ("11.3", "Fuels"), ("11.4", "Alkanes"), ("11.5", "Alkenes"), ("11.6", "Alcohols"),
        ("11.7", "Carboxylic acids"), ("11.8", "Polymers")]),
    12: ("Experimental techniques and chemical analysis", [
        ("12.1", "Experimental design"), ("12.2", "Acid–base titrations"),
        ("12.3", "Chromatography"), ("12.4", "Separation and purification"),
        ("12.5", "Identification of ions and gases")]),
}
SUBS = {s: t for t, (_, subs) in TOPICS.items() for s, _ in subs}
KEYS = {"id", "sub", "level", "q", "columns", "options", "answer", "explain"}
BANNED = re.compile(r"\b(all|none) of (the )?(above|these)\b|\b(both )?[ABCD] and [ABCD]\b", re.I)


def norm(text):
    # Keep symbols and super/subscripts: "10² Pa" and "10⁸ Pa" are different options.
    return re.sub(r"\s+", " ", text.lower()).strip(" .")


def validate(part_filter=None):
    errors, questions = [], []
    files = sorted(glob.glob(os.path.join(RAW, "*", "batch_*.json")))
    for path in files:
        part = os.path.basename(os.path.dirname(path))
        if part_filter and not part.startswith(part_filter):
            continue
        rel = os.path.relpath(path, ROOT)
        try:
            with open(path, encoding="utf-8") as f:
                items = json.load(f)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{rel}: invalid JSON: {e}")
            continue
        if not isinstance(items, list):
            errors.append(f"{rel}: top level must be a list")
            continue
        for i, q in enumerate(items):
            where = f"{rel}[{i}] {q.get('id', '?') if isinstance(q, dict) else '?'}"
            if not isinstance(q, dict):
                errors.append(f"{where}: not an object")
                continue
            if set(q) != KEYS:
                errors.append(f"{where}: keys {sorted(set(q) ^ KEYS)} wrong")
                continue
            if not re.fullmatch(rf"{re.escape(part)}-\d{{4}}", str(q["id"])):
                errors.append(f"{where}: id must be {part}-NNNN")
            if q["sub"] not in SUBS:
                errors.append(f"{where}: unknown sub {q['sub']}")
            if q["level"] not in ("core", "extended"):
                errors.append(f"{where}: level must be core/extended")
            opts = q["options"]
            if not (isinstance(opts, list) and len(opts) == 4 and all(isinstance(o, str) and o.strip() for o in opts)):
                errors.append(f"{where}: need exactly 4 non-empty options")
                continue
            if len({norm(o) for o in opts}) != 4:
                errors.append(f"{where}: options not distinct")
            if not (isinstance(q["answer"], int) and 0 <= q["answer"] <= 3):
                errors.append(f"{where}: answer must be 0-3")
            if any(BANNED.search(o) for o in opts):
                errors.append(f"{where}: option refers to other options")
            cols = q["columns"]
            if cols is not None:
                if not (isinstance(cols, list) and 2 <= len(cols) <= 4):
                    errors.append(f"{where}: columns must be null or 2-4 headings")
                elif any(len(o.split(" | ")) != len(cols) for o in opts):
                    errors.append(f"{where}: each option needs {len(cols)} cells joined by ' | '")
            if not str(q["q"]).strip() or not str(q["explain"]).strip():
                errors.append(f"{where}: empty q or explain")
            q["_topic"] = SUBS.get(q["sub"])
            q["_file"] = rel
            questions.append(q)

    ids = collections.Counter(q["id"] for q in questions)
    errors += [f"duplicate id {i}" for i, n in ids.items() if n > 1]
    stems = collections.defaultdict(list)
    for q in questions:
        stems[norm(q["q"]) + "|" + "|".join(sorted(norm(o) for o in q["options"]))].append(q["id"])
    errors += [f"duplicate question {v}" for v in stems.values() if len(v) > 1]
    return errors, questions


def report(questions):
    by_topic = collections.Counter(q["_topic"] for q in questions)
    by_sub = collections.Counter(q["sub"] for q in questions)
    answers = collections.Counter(q["answer"] for q in questions)
    levels = collections.Counter(q["level"] for q in questions)
    for t, (name, subs) in TOPICS.items():
        print(f"Topic {t} {name}: {by_topic.get(t, 0)}")
        print("   " + "  ".join(f"{s}:{by_sub.get(s, 0)}" for s, _ in subs))
    total = len(questions) or 1
    print("answers A-D:", " ".join(f"{'ABCD'[k]}={answers.get(k, 0)} ({100 * answers.get(k, 0) // total}%)" for k in range(4)))
    print("levels:", dict(levels), "total:", len(questions))


def main():
    check = sys.argv[2] if len(sys.argv) > 2 and sys.argv[1] == "--check" else None
    errors, questions = validate(check)
    report(questions)
    if errors:
        print(f"\n{len(errors)} ERROR(S):")
        for e in errors[:200]:
            print("  " + e)
        sys.exit(1)
    if check:
        print("OK (check only)")
        return
    order = {s: i for i, s in enumerate(SUBS)}
    questions.sort(key=lambda q: (q["_topic"], order[q["sub"]], q["id"]))
    bundle = {
        "version": 1,
        "topics": [
            {"n": t, "name": name, "subs": [{"code": s, "name": n} for s, n in subs]}
            for t, (name, subs) in TOPICS.items()
        ],
        "questions": [
            {k: q[k] for k in ("id", "sub", "level", "q", "columns", "options", "answer", "explain")} | {"topic": q["_topic"]}
            for q in questions
        ],
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(bundle, f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {os.path.relpath(OUT, ROOT)} ({os.path.getsize(OUT) // 1024} KB)")


if __name__ == "__main__":
    main()
