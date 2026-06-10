#!/usr/bin/env python3
# ============================================================
#  build-graph.py — keyword 기반 기억 그래프 생성 (read-only)
#
#  store(~/.claude-memory)의 개별 일기(문서)를 노드로 삼아,
#  document <-> keyword bipartite 그래프 데이터를 만들고,
#  self-contained HTML(데이터 inline, lib은 CDN)을 temp 폴더에 생성한다.
#
#  - 노드: 문서(project별 색) + keyword(여러 프로젝트를 잇는 건 bridge)
#  - 엣지: 문서가 그 keyword 를 가짐
#
#  원칙:
#   - read-only: store 를 절대 수정/commit/push 하지 않는다.
#   - 데이터(노드·엣지)는 네트워크로 내보내지 않는다 (HTML 안에 inline).
#     CDN 에서 오는 건 렌더링 라이브러리(cytoscape/cola)뿐이다.
#   - stdlib 만 사용 (pip 의존성 0).
#   - 마지막 줄에 `OUTPUT=<html 경로>` 를 출력한다. 항상 exit 0.
# ============================================================
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone

STORE = os.environ.get("CLAUDE_MEMORY_STORE") or os.path.expanduser("~/.claude-memory")

KEYWORDS_RE = re.compile(r"^\s*-\s*\*\*keywords\*\*\s*:\s*\[(.*)\]\s*$", re.IGNORECASE)
TITLE_RE = re.compile(r"^#\s+(.+?)\s*$")
BILINGUAL_RE = re.compile(r"^(.*?)\((.+?)\)$")
TS_PREFIX_RE = re.compile(r"^\d{8}-\d{4}-")  # 파일명 앞 타임스탬프 제거용

# 문서 노드 색(프로젝트별로 순서대로 배정). 어두운 배경에서 잘 보이는 톤.
PALETTE = ["#e06c75", "#61afef", "#98c379", "#c678dd", "#e5c07b",
           "#56b6c2", "#d19a66", "#7f9cf5", "#f06595", "#63e6be"]


def normalize(raw):
    """keyword 1개 -> 정규화된 토큰 리스트 (read-time normalization).

    저장 포맷은 건드리지 않고 읽을 때만 정리한다:
    lowercase / trim, 그리고 'korean(english)' 는 둘로 분리해 다른 문서의
    'english' 표기와 자연스럽게 이어지게 한다.
    """
    tokens = []
    raw = raw.strip().strip("\"'`")
    if not raw:
        return tokens
    m = BILINGUAL_RE.match(raw)
    parts = [m.group(1), m.group(2)] if m else [raw]
    for p in parts:
        t = re.sub(r"\s+", " ", p.strip().lower())
        if t:
            tokens.append(t)
    return tokens


def parse_doc(path):
    """문서 1개 -> (title, [keywords]). 못 읽으면 (None, [])."""
    title, keywords = None, []
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                if title is None:
                    tm = TITLE_RE.match(line)
                    if tm:
                        title = tm.group(1)
                km = KEYWORDS_RE.match(line)
                if km:
                    for chunk in km.group(1).split(","):
                        keywords.extend(normalize(chunk))
        keywords = list(dict.fromkeys(keywords))  # 문서 내 중복 제거
    except OSError:
        pass
    return title, keywords


def scan(store):
    """store -> [{project, file, title, keywords}] (keyword 있는 문서만)."""
    docs = []
    if not os.path.isdir(store):
        return docs
    for name in sorted(os.listdir(store)):
        proj_dir = os.path.join(store, name)
        if name.startswith(".") or name.startswith("_") or not os.path.isdir(proj_dir):
            continue
        for fn in sorted(os.listdir(proj_dir)):
            if not fn.endswith(".md") or fn.startswith("_") or fn == "README.md":
                continue  # _digest/_INDEX 등 자동관리 파일 제외
            title, kws = parse_doc(os.path.join(proj_dir, fn))
            if kws:
                full = title or TS_PREFIX_RE.sub("", fn[:-3])
                docs.append({"project": name, "file": fn,
                             "title": full, "label": short_label(full), "keywords": kws})
    return docs


def short_label(s, n=16):
    s = s.strip()
    return s if len(s) <= n else s[: n - 1].rstrip() + "…"


def build_elements(docs):
    nodes, edges = [], []
    projects = sorted({d["project"] for d in docs})
    color_of = {p: PALETTE[i % len(PALETTE)] for i, p in enumerate(projects)}

    # keyword 가 몇 개 '프로젝트'에 걸치는지 (bridge 판정 기준은 프로젝트)
    kw_projects = {}
    for d in docs:
        for kw in d["keywords"]:
            kw_projects.setdefault(kw, set()).add(d["project"])

    for i, d in enumerate(docs):
        nodes.append({"data": {
            "id": "d:%d" % i, "label": d["label"], "title": d["title"], "type": "doc",
            "project": d["project"], "color": color_of[d["project"]],
        }})
    bridges = 0
    for kw, projs in kw_projects.items():
        is_bridge = len(projs) >= 2
        bridges += 1 if is_bridge else 0
        nodes.append({"data": {
            "id": "k:" + kw, "label": kw, "type": "keyword",
            "projects": len(projs), "bridge": is_bridge,
        }})
    eid = 0
    for i, d in enumerate(docs):
        for kw in d["keywords"]:
            edges.append({"data": {"id": "e%d" % eid, "source": "d:%d" % i, "target": "k:" + kw}})
            eid += 1

    top_bridges = sorted(
        ((kw, len(projs)) for kw, projs in kw_projects.items() if len(projs) >= 2),
        key=lambda x: (-x[1], x[0]),
    )
    stats = {
        "documents": len(docs),
        "projects": len(projects),
        "keywords": len(kw_projects),
        "edges": len(edges),
        "bridges": bridges,
        "top_bridges": [{"keyword": k, "projects": n} for k, n in top_bridges[:8]],
        "project_colors": [{"project": p, "color": color_of[p]} for p in projects],
    }
    return nodes, edges, stats


def main():
    docs = scan(STORE)
    nodes, edges, stats = build_elements(docs)
    payload = {
        "generated_at": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "store": STORE,
        "stats": stats,
        "nodes": nodes,
        "edges": edges,
    }

    template_path = os.path.join(os.path.dirname(__file__), "..", "assets", "template.html")
    with open(template_path, encoding="utf-8") as f:
        html = f.read()
    data_js = json.dumps(payload, ensure_ascii=False)
    html = html.replace("/*__GRAPH_DATA__*/null", data_js)

    out_dir = tempfile.mkdtemp(prefix="claude-memory-graph-")
    out_path = os.path.join(out_dir, "index.html")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print("[memory-insight] docs=%d projects=%d keywords=%d edges=%d bridges=%d" % (
        stats["documents"], stats["projects"], stats["keywords"],
        stats["edges"], stats["bridges"]), file=sys.stderr)
    print("OUTPUT=" + out_path)


if __name__ == "__main__":
    main()
