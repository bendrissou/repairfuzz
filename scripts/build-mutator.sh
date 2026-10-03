#!/usr/bin/env bash
#
# Build a RepairFuzz custom mutator for one (language, grammar) pair.
#
#   ./scripts/build-mutator.sh <lang> [grammar]
#
#     lang     lua | ruby | js | php | json
#     grammar  which grammar under grammars/<lang>/ to repair against.
#              Defaults to "corpus". For json the only grammar is "json".
#
# The selected grammar is copied into mutator/<lang>_repair/src/<lang>.{l,y}
# (grmtools' build.rs compiles the LR tables from there), the crate is built,
# and the resulting shared object is copied to:
#
#     build/mutators/lib_repair_<lang>_<grammar>.so
#
# Point AFL_CUSTOM_MUTATOR_LIBRARY at that file to fuzz with it.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\033[1;94m[*]\033[0m %s\n' "$*"; }
die() { printf '\033[1;91m[-]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat >&2 <<EOF
Usage: $0 <lang> [grammar]

  lang     lua | ruby | js | php | json
  grammar  grammar variant under grammars/<lang>/ (default: corpus)

Available grammars:
EOF
    for d in "$REPO_ROOT"/grammars/*/; do
        l=$(basename "$d")
        printf '  %-6s %s\n' "$l" "$(cd "$d" && ls ./*.y 2>/dev/null | sed 's|^\./||;s|\.y$||' | tr '\n' ' ')" >&2
    done
    exit 1
}

[ $# -ge 1 ] || usage
LANG_NAME="$1"
GRAMMAR="${2:-corpus}"
[ "$LANG_NAME" = "json" ] && GRAMMAR="${2:-json}"

CRATE="$REPO_ROOT/mutator/${LANG_NAME}_repair"
GRAMMAR_L="$REPO_ROOT/grammars/$LANG_NAME/$GRAMMAR.l"
GRAMMAR_Y="$REPO_ROOT/grammars/$LANG_NAME/$GRAMMAR.y"

[ -d "$CRATE" ]      || { echo "no such mutator: mutator/${LANG_NAME}_repair" >&2; usage; }
[ -f "$GRAMMAR_L" ]  || { echo "no such grammar: grammars/$LANG_NAME/$GRAMMAR.l" >&2; usage; }
[ -f "$GRAMMAR_Y" ]  || { echo "no such grammar: grammars/$LANG_NAME/$GRAMMAR.y" >&2; usage; }

[ -d "$REPO_ROOT/third_party/grmtools" ] \
    || die "third_party/grmtools is missing -- run ./scripts/setup.sh first."
[ -d "$REPO_ROOT/third_party/AFLplusplus/custom_mutators/rust/custom_mutator" ] \
    || die "third_party/AFLplusplus is missing -- run ./scripts/setup.sh first."

log "Selecting grammar grammars/$LANG_NAME/$GRAMMAR.{l,y}"
cp "$GRAMMAR_L" "$CRATE/src/$LANG_NAME.l"
cp "$GRAMMAR_Y" "$CRATE/src/$LANG_NAME.y"

log "Building ${LANG_NAME}_repair (release)"
( cd "$CRATE" && cargo build --release )

SO_SRC="$CRATE/target/release/librepair_${LANG_NAME}.so"
[ -f "$SO_SRC" ] || die "expected $SO_SRC to exist after a successful build"

OUT_DIR="$REPO_ROOT/build/mutators"
OUT="$OUT_DIR/lib_repair_${LANG_NAME}_${GRAMMAR}.so"
mkdir -p "$OUT_DIR"
cp "$SO_SRC" "$OUT"

log "Done."
echo
echo "  mutator: $OUT"
echo
echo "Use it with:"
echo "  export AFL_CUSTOM_MUTATOR_LIBRARY=$OUT"
echo "  export REPAIR_PROBABILITY=1.0     # 1.0 = RepairFuzz-Full, 0.5 = RepairFuzz-Partial"
