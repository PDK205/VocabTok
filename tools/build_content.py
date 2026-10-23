#!/usr/bin/env python3
"""Convert the human-friendly course sources in content/course/*.txt into
VocabTok/Resources/Course/*.json and validate them.

Source format (one level per file):

    @level A1
    name: Khởi đầu
    ...
    # UNIT a1-u1
    title: ...
    ## words
    word | /ipa/ | pos | nghĩa | Example. | Ví dụ. | mẹo (tuỳ chọn)
    ## phrases
    English | Tiếng Việt
    ## grammar
    title: ...
    summary: ...
    formula: ...
    point: Tiêu đề | nội dung
    example: English | Tiếng Việt
    mistake: sai | đúng | giải thích
    ex: Câu hỏi ___ | a ; b ; c | đáp án | giải thích
    ## dialogue
    title: ...
    setting: ...
    line: A | Tên | English | Tiếng Việt
    q: Câu hỏi | a ; b ; c | đáp án
    ## reading
    title: ...
    text: ...
    vi: ...
    q: Câu hỏi | a ; b ; c | đáp án
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "content" / "course"
OUT = ROOT / "VocabTok" / "Resources" / "Course"

errors = []


def err(msg):
    errors.append(msg)


def split(line, n_min, n_max, where):
    parts = [p.strip() for p in line.split(" | ")]
    if not (n_min <= len(parts) <= n_max):
        err(f"{where}: expected {n_min}-{n_max} fields, got {len(parts)}: {line[:80]}")
    return parts


def options(raw, answer, where):
    opts = [o.strip() for o in raw.split(" ; ")]
    if answer not in opts:
        err(f"{where}: answer '{answer}' not in options {opts}")
    if len(set(opts)) != len(opts):
        err(f"{where}: duplicate options {opts}")
    if len(opts) < 2:
        err(f"{where}: needs at least 2 options")
    return opts


def parse_file(path):
    level = {"units": []}
    unit = None
    section = None
    for n, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        where = f"{path.name}:{n}"
        if not line or line.startswith("//"):
            continue
        if line.startswith("@level"):
            level["id"] = line.split()[1]
            section = "level"
            continue
        if line.startswith("# UNIT"):
            unit = {
                "id": line.split()[2],
                "words": [],
                "phrases": [],
                "grammar": {"formulas": [], "points": [], "examples": [], "mistakes": [], "exercises": []},
                "dialogue": {"lines": [], "questions": []},
                "reading": {"questions": []},
            }
            level["units"].append(unit)
            section = "unit"
            continue
        if line.startswith("## "):
            section = line[3:].strip()
            continue

        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()

        if section == "level":
            if key == "cando":
                level.setdefault("canDo", []).append(value)
            else:
                level[key] = value
        elif section == "unit":
            unit[key] = value
        elif section == "words":
            p = split(line, 6, 7, where)
            w = {"word": p[0], "ipa": p[1], "pos": p[2], "vi": p[3], "ex": p[4], "exVi": p[5]}
            if len(p) == 7 and p[6]:
                w["tip"] = p[6]
            unit["words"].append(w)
        elif section == "phrases":
            p = split(line, 2, 2, where)
            unit["phrases"].append({"en": p[0], "vi": p[1]})
        elif section == "grammar":
            g = unit["grammar"]
            if key in ("title", "summary"):
                g[key] = value
            elif key == "formula":
                g["formulas"].append(value)
            elif key == "point":
                p = split(value, 2, 2, where)
                g["points"].append({"title": p[0], "body": p[1]})
            elif key == "example":
                p = split(value, 2, 2, where)
                g["examples"].append({"en": p[0], "vi": p[1]})
            elif key == "mistake":
                p = split(value, 3, 3, where)
                g["mistakes"].append({"wrong": p[0], "right": p[1], "note": p[2]})
            elif key == "ex":
                p = split(value, 3, 4, where)
                item = {"q": p[0], "options": options(p[1], p[2], where), "answer": p[2]}
                if len(p) == 4:
                    item["explain"] = p[3]
                g["exercises"].append(item)
            else:
                err(f"{where}: unknown grammar key {key}")
        elif section in ("dialogue", "reading"):
            d = unit[section]
            if key == "line":
                p = split(value, 4, 4, where)
                d["lines"].append({"speaker": p[0], "name": p[1], "en": p[2], "vi": p[3]})
            elif key == "q":
                p = split(value, 3, 4, where)
                item = {"q": p[0], "options": options(p[1], p[2], where), "answer": p[2]}
                if len(p) == 4:
                    item["explain"] = p[3]
                d["questions"].append(item)
            else:
                d[key] = value
        else:
            err(f"{where}: line outside a section")
    return level


def validate(levels):
    seen = {}
    for level in levels:
        for key in ("id", "name", "nameEn", "color", "description"):
            if key not in level:
                err(f"level {level.get('id')}: missing {key}")
        for u in level["units"]:
            uid = u["id"]
            for key in ("title", "titleEn", "emoji", "goal"):
                if key not in u:
                    err(f"{uid}: missing {key}")
            if len(u["words"]) != 12:
                err(f"{uid}: has {len(u['words'])} words (expected 12)")
            for w in u["words"]:
                if not re.fullmatch(r"[A-Za-z]+", w["word"]):
                    err(f"{uid}: word '{w['word']}' must be letters only")
                lw = w["word"].lower()
                if lw in seen:
                    err(f"{uid}: duplicate word '{lw}' (also in {seen[lw]})")
                seen[lw] = uid
                if not w["ipa"].startswith("/"):
                    err(f"{uid}: ipa of {lw} should start with /")
                if not re.search(r"\b" + re.escape(w["word"]) + r"\w*", w["ex"], re.I):
                    print(f"note: {uid}: example of '{w['word']}' does not contain the word (fill-blank disabled)")
            if len(u["phrases"]) < 4:
                err(f"{uid}: needs >= 4 phrases")
            g = u["grammar"]
            for key in ("title", "summary"):
                if key not in g:
                    err(f"{uid}: grammar missing {key}")
            if len(g["exercises"]) < 6:
                err(f"{uid}: grammar needs >= 6 exercises (has {len(g['exercises'])})")
            if len(g["examples"]) < 3:
                err(f"{uid}: grammar needs >= 3 examples")
            for ex in g["exercises"]:
                if "___" not in ex["q"]:
                    print(f"note: {uid}: grammar question without blank: {ex['q']}")
            d = u["dialogue"]
            if len(d["lines"]) < 5:
                err(f"{uid}: dialogue needs >= 5 lines")
            if len(d["questions"]) < 2:
                err(f"{uid}: dialogue needs >= 2 questions")
            r = u["reading"]
            for key in ("title", "text", "vi"):
                if key not in r:
                    err(f"{uid}: reading missing {key}")
            if len(r["questions"]) < 2:
                err(f"{uid}: reading needs >= 2 questions")
    return seen


def main():
    files = sorted(SRC.glob("*.txt"))
    # A level may be split across several files (A1_1.txt, A1_2.txt ...); merge them.
    levels = []
    for f in files:
        part = parse_file(f)
        existing = next((l for l in levels if l["id"] == part["id"]), None)
        if existing:
            existing["units"] += part["units"]
            for k, v in part.items():
                existing.setdefault(k, v)
        else:
            levels.append(part)
    seen = validate(levels)
    if errors:
        print("\n".join(errors))
        print(f"\n{len(errors)} error(s)")
        sys.exit(1)
    OUT.mkdir(parents=True, exist_ok=True)
    for level in levels:
        out = OUT / f"{level['id']}.json"
        out.write_text(json.dumps(level, ensure_ascii=False, indent=1), encoding="utf-8")
    units = sum(len(l["units"]) for l in levels)
    print(f"OK: {len(levels)} levels, {units} units, {len(seen)} words")


if __name__ == "__main__":
    main()
