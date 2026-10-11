#!/usr/bin/env bash
# Verify spec/starintel-relations.star for star-relations.
#
# Stage 0: lock sidecar digest matches the .star octets.
# Stage 1: structural checks (closed head set, camelCase fields, typed
#          predicate endpoints, balanced parens) via python3.
# Stage 2: full parse+compile through the local star-lang checkout
#          (network disabled, local path resolution only).
#
# Exit codes: 0 verified, 1 structural failure, 2 compiler rejection,
# 3 compiler unavailable (library then UNVERIFIED-BY-COMPILER).
set -uo pipefail

REPO_ROOT="${STAR_RELATIONS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SPEC="$REPO_ROOT/spec/starintel-relations.star"
LOCK="$REPO_ROOT/lock/starintel-relations.lock.json"
STAR_LANG_ROOT="${STAR_LANG_ROOT:-}"

fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$SPEC" ] || fail "missing $SPEC"
[ -f "$LOCK" ] || fail "missing $LOCK"

# ---------------------------------------------------------------- Stage 0
LOCKED_SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' "$LOCK")"
ACTUAL_SHA="$(sha256sum "$SPEC" | cut -d' ' -f1)"
case "$LOCKED_SHA" in
  sha256:"$ACTUAL_SHA") ;;
  *) fail "lock digest mismatch: lock=$LOCKED_SHA actual=sha256:$ACTUAL_SHA" ;;
esac
echo "stage 0: lock digest ok ($LOCKED_SHA)"

# ---------------------------------------------------------------- Stage 1
python3 - "$SPEC" <<'PYEOF' || exit 1
import re, sys

class Str(str):
    """Double-quoted string literal (distinct from identifiers)."""

def tokenize(text):
    tokens, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c in ' \t\r\n\f':
            i += 1
        elif c == ';':
            while i < n and text[i] != '\n':
                i += 1
        elif c in '()':
            tokens.append(c); i += 1
        elif c == '"':
            i += 1; buf = []
            while i < n and text[i] != '"':
                if text[i] == '\\':
                    i += 1
                    if i >= n: sys.exit("FAIL: unterminated string escape")
                buf.append(text[i]); i += 1
            if i >= n: sys.exit("FAIL: unterminated string literal")
            i += 1
            tokens.append(Str(''.join(buf)))
        else:
            j = i
            while j < n and text[j] not in ' \t\r\n\f;()"':
                j += 1
            tokens.append(text[i:j]); i = j
    return tokens

def parse(tokens):
    pos = 0
    def form():
        nonlocal pos
        tok = tokens[pos]
        if tok == '(':
            pos += 1
            out = []
            while pos < len(tokens) and tokens[pos] != ')':
                out.append(form())
            if pos >= len(tokens):
                sys.exit("FAIL: unbalanced parentheses (missing close)")
            pos += 1
            return out
        if tok == ')':
            sys.exit("FAIL: unbalanced parentheses (stray close)")
        pos += 1
        return tok
    forms = []
    while pos < len(tokens):
        forms.append(form())
    return forms

CAMEL = re.compile(r'^[a-z][A-Za-z0-9]*$')
HEADS = {"spec-library", "import", "scalar", "enum", "document", "predicate", "message"}

spec = sys.argv[1]
forms = parse(tokenize(open(spec, encoding="utf-8").read()))
if len(forms) != 1:
    sys.exit(f"FAIL: expected exactly one top-level form, found {len(forms)}")
lib = forms[0]
if not isinstance(lib, list) or lib[0] != "spec-library":
    sys.exit("FAIL: top-level form must be (spec-library ...)")
if len(lib) < 3 or not isinstance(lib[1], Str):
    sys.exit("FAIL: spec-library needs a string name and options plist")

declarations = lib[3:]
doc_names, names, kind_names = set(), set(), set()
for d in declarations:
    if not isinstance(d, list) or not d or not isinstance(d[0], str) or d[0] not in HEADS:
        sys.exit(f"FAIL: unknown or malformed declaration head: {d[:1]}")
    kind, name = d[0], d[1]
    if not isinstance(name, str) or isinstance(name, Str):
        sys.exit(f"FAIL: {kind} name must be an identifier, got {name!r}")
    key = (kind, name)
    if key in kind_names:
        sys.exit(f"FAIL: duplicate {kind} declaration {name}")
    if kind != "import":
        if name in names:
            sys.exit(f"FAIL: name collision across declarations: {name}")
        names.add(name)
    kind_names.add(key)
    if kind in {"scalar", "enum", "document"}:
        doc_names.add(name)
    if kind == "document":
        opts = d[2] if len(d) > 2 else []
        fields = d[3:] if isinstance(opts, list) else d[2:]
        for f in fields:
            if not isinstance(f, list) or len(f) < 3:
                sys.exit(f"FAIL: malformed field in document {name}: {f!r}")
            if not CAMEL.match(f[0]):
                sys.exit(f"FAIL: field {f[0]!r} in {name} is not ASCII lower camelCase")
            markers = [m for m in f[2:] if isinstance(m, str) and not isinstance(m, Str)]
            if not any(m in (":required", ":optional") for m in markers):
                sys.exit(f"FAIL: field {f[0]!r} in {name} lacks :required/:optional")
    if kind == "enum":
        if len(d) < 3 or not isinstance(d[2], list) or not d[2]:
            sys.exit(f"FAIL: enum {name} needs at least one value")
    if kind == "predicate":
        opts = d[2] if len(d) > 2 else []
        if not isinstance(opts, list):
            sys.exit(f"FAIL: predicate {name} needs an options plist")
        kv = dict(zip(opts[::2], opts[1::2])) if opts else {}
        for endpoint in (":source", ":destination"):
            kindref = kv.get(endpoint)
            if not isinstance(kindref, str) or isinstance(kindref, Str):
                sys.exit(f"FAIL: predicate {name} {endpoint} must be a kind identifier")
            if kindref not in doc_names:
                sys.exit(f"FAIL: predicate {name} {endpoint} references undeclared kind {kindref}")

n_pred = sum(1 for d in declarations if isinstance(d, list) and d and d[0] == "predicate")
n_docs = sum(1 for d in declarations if isinstance(d, list) and d and d[0] == "document")
print(f"stage 1: structural ok ({n_docs} documents, {n_pred} predicates, parens balanced)")
PYEOF

# ---------------------------------------------------------------- Stage 2
if [ -n "${STAR_LANG:-}" ]; then
  # Use the canonical producer executable; cache output stays outside its store.
  compiler_cache=$(mktemp -d)
  trap 'rm -rf -- "$compiler_cache"' EXIT
  if "$STAR_LANG" load "$SPEC" --cache "$compiler_cache"; then
    echo "stage 2: compiler verified org.starintel/relations@1"
    echo "verify-local: PASS"
    exit 0
  fi
  echo "verify-local: FAIL (compiler rejected the library)" >&2
  exit 2
fi
if ! command -v sbcl >/dev/null 2>&1; then
  echo "stage 2: SKIPPED (sbcl not found)" >&2
  echo "UNVERIFIED-BY-COMPILER: install sbcl or run in the star-lang nix shell." >&2
  echo "manual: cd $STAR_LANG_ROOT && sbcl --script prototype/run-star.lisp load $SPEC" >&2
  exit 3
fi
if [ ! -f "$STAR_LANG_ROOT/prototype/run-star.lisp" ]; then
  echo "stage 2: SKIPPED (star-lang checkout not found at $STAR_LANG_ROOT)" >&2
  echo "UNVERIFIED-BY-COMPILER: set STAR_LANG_ROOT to a star-lang checkout." >&2
  exit 3
fi

cd "$STAR_LANG_ROOT" || exit 3
if sbcl --script prototype/run-star.lisp load "$SPEC"; then
  echo "stage 2: compiler verified org.starintel/relations@1"
  echo "verify-local: PASS"
else
  echo "verify-local: FAIL (compiler rejected the library)" >&2
  exit 2
fi
