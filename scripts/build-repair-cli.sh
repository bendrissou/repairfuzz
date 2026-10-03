#!/usr/bin/env bash
#
# Build a standalone repair CLI for one (language, grammar) pair.
#
#   ./scripts/build-repair-cli.sh <lang> [grammar]
#
# Produces build/bin/repair-<lang>-<grammar>, which runs RepairFuzz's repair
# step without any fuzzing:
#
#   repair-<lang>-<grammar> FILE...        repair files, print the result
#   repair-<lang>-<grammar> --check DIR    check a seed corpus against the grammar
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\033[1;94m[*]\033[0m %s\n' "$*"; }
die() { printf '\033[1;91m[-]\033[0m %s\n' "$*" >&2; exit 1; }

[ $# -ge 1 ] || die "usage: $0 <lang> [grammar]   (lang: lua|ruby|js|php|json)"
LANG_NAME="$1"
GRAMMAR="${2:-corpus}"
[ "$LANG_NAME" = "json" ] && GRAMMAR="${2:-json}"

CRATE="$REPO_ROOT/tools/repair-cli"
GRAMMAR_L="$REPO_ROOT/grammars/$LANG_NAME/$GRAMMAR.l"
GRAMMAR_Y="$REPO_ROOT/grammars/$LANG_NAME/$GRAMMAR.y"

[ -f "$GRAMMAR_L" ] || die "no such grammar: grammars/$LANG_NAME/$GRAMMAR.l"
[ -f "$GRAMMAR_Y" ] || die "no such grammar: grammars/$LANG_NAME/$GRAMMAR.y"
[ -d "$REPO_ROOT/third_party/grmtools" ] \
    || die "third_party/grmtools is missing -- run ./scripts/setup.sh first."

log "Selecting grammar grammars/$LANG_NAME/$GRAMMAR.{l,y}"
cp "$GRAMMAR_L" "$CRATE/src/grammar.l"
cp "$GRAMMAR_Y" "$CRATE/src/grammar.y"

log "Building repair-cli for $LANG_NAME/$GRAMMAR"
( cd "$CRATE" && REPAIRFUZZ_GRAMMAR="$LANG_NAME/$GRAMMAR" cargo build --release )

OUT_DIR="$REPO_ROOT/build/bin"
OUT="$OUT_DIR/repair-${LANG_NAME}-${GRAMMAR}"
mkdir -p "$OUT_DIR"
cp "$CRATE/target/release/repair-cli" "$OUT"

log "Done."
echo
echo "  $OUT"
echo
echo "Check a seed corpus against this grammar:"
echo "  $OUT --check /path/to/your/seeds"
