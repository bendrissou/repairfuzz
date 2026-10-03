#!/usr/bin/env bash
#
# End-to-end RepairFuzz demo, ~10 minutes.
#
#   1. Fetch and build LuaJIT with afl-clang-fast + AddressSanitizer.
#   2. Build the Lua repair mutator from grammars/lua/corpus.{l,y}.
#   3. Fuzz LuaJIT twice for the same wall-clock budget: once with repair
#      (RepairFuzz-Full) and once without (stock AFL++).
#   4. Report how many queue entries of each run are syntactically valid Lua.
#
# The point of step 4 is the core claim of the paper: byte-level mutation
# alone produces mostly invalid inputs, and grammar-based repair turns them
# back into valid programs without giving up the diversity of byte mutation.
#
# Usage: ./examples/quickstart/run.sh [SECONDS]      (default 120)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${WORK:-$REPO_ROOT/build/quickstart}"
DURATION="${1:-120}"

LUAJIT_REPO="https://github.com/LuaJIT/LuaJIT.git"
LUAJIT_COMMIT="v2.1"

log()  { printf '\n\033[1;94m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
die()  { printf '\033[1;91m[-]\033[0m %s\n' "$*" >&2; exit 1; }

[ -d "$REPO_ROOT/third_party/AFLplusplus" ] || die "run ./scripts/setup.sh first"

AFL_CC="$(command -v afl-clang-fast || echo "$REPO_ROOT/third_party/AFLplusplus/afl-clang-fast")"
[ -x "$AFL_CC" ] || die "afl-clang-fast not found -- run ./scripts/setup.sh first"

mkdir -p "$WORK"

# ----------------------------------------------------------- 1. build LuaJIT
if [ ! -x "$WORK/LuaJIT/src/luajit" ]; then
    log "Building LuaJIT with afl-clang-fast + ASan"
    [ -d "$WORK/LuaJIT/.git" ] || git clone --depth 1 -b "$LUAJIT_COMMIT" "$LUAJIT_REPO" "$WORK/LuaJIT"
    (
        cd "$WORK/LuaJIT"
        export ASAN_OPTIONS="detect_leaks=0:abort_on_error=0"
        make clean >/dev/null 2>&1 || true
        make -j"$(nproc)" CC="$AFL_CC" CFLAGS="-fsanitize=address" LDFLAGS="-fsanitize=address"
    )
else
    log "Reusing existing LuaJIT build at $WORK/LuaJIT"
fi
SUT="$WORK/LuaJIT/src/luajit"
[ -x "$SUT" ] || die "LuaJIT build failed"

# ---------------------------------------------------- 2. build repair mutator
MUTATOR="$REPO_ROOT/build/mutators/lib_repair_lua_corpus.so"
if [ ! -f "$MUTATOR" ]; then
    log "Building the Lua repair mutator (grammars/lua/corpus.{l,y})"
    "$REPO_ROOT/scripts/build-mutator.sh" lua corpus
else
    log "Reusing existing mutator $MUTATOR"
fi

# --------------------------------------------------------- 3. two fuzzing runs
SEEDS="$WORK/seeds"
mkdir -p "$SEEDS"
printf 'local x = 1\nprint(x + 2)\n'      > "$SEEDS/a.lua"
printf 'for i = 1, 3 do print(i) end\n'   > "$SEEDS/b.lua"

export AFL_NO_UI=1
export AFL_NO_AFFINITY=1

run_one() {   # run_one <label> <outdir> <probability>
    local label="$1" out="$2" prob="$3"
    rm -rf "$out"
    log "Fuzzing $label for ${DURATION}s"
    "$REPO_ROOT/scripts/run-repairfuzz.sh" \
        -m "$MUTATOR" -i "$SEEDS" -o "$out" -p "$prob" -V "$DURATION" \
        -- "$SUT" @@ 2>&1 | grep -E "corpus items|Custom mutator|ABORT|PROGRAM" || true
}

run_one "RepairFuzz-Full (repair probability 1.0)" "$WORK/out-repair"   1.0
run_one "stock AFL++      (no repair)"             "$WORK/out-baseline" 0.0

# -------------------------------------------------- 4. measure input validity
validity() {   # validity <queue dir> -> "<valid> <total>"
    local dir="$1" tot=0 ok=0 f
    [ -d "$dir" ] || { echo "0 0"; return; }
    for f in "$dir"/id:*; do
        [ -f "$f" ] || continue
        tot=$((tot + 1))
        if ASAN_OPTIONS="detect_leaks=0:abort_on_error=0" \
           "$SUT" -e "assert(loadfile([[$f]]))" >/dev/null 2>&1; then
            ok=$((ok + 1))
        fi
    done
    echo "$ok $tot"
}

log "Measuring syntactic validity of the generated corpora"
read -r R_OK R_TOT <<<"$(validity "$WORK/out-repair/default/queue")"
read -r B_OK B_TOT <<<"$(validity "$WORK/out-baseline/default/queue")"

pct() { [ "$2" -gt 0 ] && awk -v a="$1" -v b="$2" 'BEGIN{printf "%.1f", 100*a/b}' || echo "n/a"; }

cat <<EOF

=== Quickstart results (LuaJIT, ${DURATION}s per run) =======================

  Fuzzer                      Queue entries   Syntactically valid Lua
  --------------------------  -------------   -----------------------
  RepairFuzz-Full             $(printf '%13s' "$R_TOT")   $(printf '%6s' "$R_OK") ($(pct "$R_OK" "$R_TOT")%)
  AFL++ (no repair)           $(printf '%13s' "$B_TOT")   $(printf '%6s' "$B_OK") ($(pct "$B_OK" "$B_TOT")%)

Both fuzzers apply the same AFL++ byte-level mutations. The difference is the
post-mutation CPCT+ repair step, which turns invalid mutants back into valid
Lua before they reach the interpreter.

Corpora are under $WORK/out-repair and $WORK/out-baseline.
EOF
