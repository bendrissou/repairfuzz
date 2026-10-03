#!/usr/bin/env bash
#
# Run RepairFuzz: AFL++ driven by a grammar-based repair mutator.
#
#   ./scripts/run-repairfuzz.sh -m <mutator.so> -i <seeds> -o <outdir> [options] -- <sut> [args] @@
#
# This is a thin, documented wrapper around afl-fuzz. Everything it does can be
# done by hand; see "Running by hand" in README.md.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MUTATOR=""
SEEDS=""
OUTDIR=""
PROBABILITY="1.0"
DURATION=""
TIMEOUT_MS="3000"
MAP_SIZE="1048576"
STATS=""
FUZZER_NAME=""

die() { printf '\033[1;91m[-]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {   # usage [exit-code]
    cat >&2 <<'EOF'
Usage: run-repairfuzz.sh -m <mutator.so> -i <seeds> -o <outdir> [options] -- <sut> [args] @@

Required:
  -m, --mutator PATH     repair mutator .so (from scripts/build-mutator.sh)
  -i, --seeds DIR        directory of valid seed inputs
  -o, --out DIR          AFL++ output directory

Options:
  -p, --probability P    repair probability, 0.0-1.0   (default 1.0)
                           1.0 = RepairFuzz-Full, 0.5 = RepairFuzz-Partial,
                           0.0 = plain AFL++ (no repair)
  -V, --duration SECS    stop after SECS seconds       (default: run forever)
  -t, --timeout MS       per-execution timeout in ms   (default 3000)
      --map-size N       AFL_MAP_SIZE                  (default 1048576)
      --stats FILE       hourly repair-statistics log  (default <outdir>/repair-stats.log)
  -S, --name NAME        AFL++ secondary-instance name (for parallel runs)
  -h, --help             this message

The '@@' placeholder in the target command is replaced by AFL++ with the path
of the current input file, exactly as in plain afl-fuzz.

Example:
  ./scripts/run-repairfuzz.sh \
      -m build/mutators/lib_repair_lua_corpus.so \
      -i /path/to/seeds -o /tmp/out -p 1.0 -V 3600 \
      -- /path/to/luajit @@
EOF
    exit "${1:-1}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -m|--mutator)     MUTATOR="$2"; shift 2 ;;
        -i|--seeds)       SEEDS="$2"; shift 2 ;;
        -o|--out)         OUTDIR="$2"; shift 2 ;;
        -p|--probability) PROBABILITY="$2"; shift 2 ;;
        -V|--duration)    DURATION="$2"; shift 2 ;;
        -t|--timeout)     TIMEOUT_MS="$2"; shift 2 ;;
        --map-size)       MAP_SIZE="$2"; shift 2 ;;
        --stats)          STATS="$2"; shift 2 ;;
        -S|--name)        FUZZER_NAME="$2"; shift 2 ;;
        -h|--help)        usage 0 ;;
        --)               shift; break ;;
        *)                die "unknown option: $1 (use --help)" ;;
    esac
done

[ $# -gt 0 ]      || { echo "error: no target command given after '--'" >&2; usage; }
[ -n "$SEEDS" ]   || { echo "error: -i/--seeds is required" >&2; usage; }
[ -n "$OUTDIR" ]  || { echo "error: -o/--out is required" >&2; usage; }
[ -d "$SEEDS" ]   || die "seed directory not found: $SEEDS"

AFL_FUZZ="$(command -v afl-fuzz || true)"
[ -n "$AFL_FUZZ" ] || AFL_FUZZ="$REPO_ROOT/third_party/AFLplusplus/afl-fuzz"
[ -x "$AFL_FUZZ" ] || die "afl-fuzz not found -- run ./scripts/setup.sh first."

mkdir -p "$OUTDIR"
[ -n "$STATS" ] || STATS="$OUTDIR/repair-stats.log"

# AFL++ needs crashes delivered as signals, not piped to a crash handler.
if [ -r /proc/sys/kernel/core_pattern ] && grep -q '^|' /proc/sys/kernel/core_pattern 2>/dev/null; then
    cat >&2 <<'EOF'
[-] /proc/sys/kernel/core_pattern pipes core dumps to an external handler,
    which makes AFL++ misreport crashes as hangs. On the *host* (not inside a
    container) run:

        echo core | sudo tee /proc/sys/kernel/core_pattern

    This must be repeated after every reboot.
EOF
    exit 1
fi

# ASAN settings used throughout the paper's experiments.
export ASAN_OPTIONS="${ASAN_OPTIONS:-detect_leaks=0:abort_on_error=1:symbolize=0:allocator_may_return_null=1}"
export AFL_MAP_SIZE="$MAP_SIZE"

AFL_ARGS=(-t "$TIMEOUT_MS" -a text -i "$SEEDS" -o "$OUTDIR")
[ -n "$DURATION" ]    && AFL_ARGS+=(-V "$DURATION")
[ -n "$FUZZER_NAME" ] && AFL_ARGS+=(-S "$FUZZER_NAME")

# probability 0 means "no repair at all": run stock AFL++ as a baseline.
if [ "$PROBABILITY" = "0" ] || [ "$PROBABILITY" = "0.0" ]; then
    echo "[*] repair disabled (probability 0) -- running stock AFL++"
    unset AFL_CUSTOM_MUTATOR_LIBRARY
else
    [ -n "$MUTATOR" ] || { echo "error: -m/--mutator is required unless -p 0" >&2; usage; }
    [ -f "$MUTATOR" ] || die "mutator not found: $MUTATOR (run ./scripts/build-mutator.sh)"
    export AFL_CUSTOM_MUTATOR_LIBRARY="$(cd "$(dirname "$MUTATOR")" && pwd)/$(basename "$MUTATOR")"
    export REPAIR_PROBABILITY="$PROBABILITY"
    export FILENAME_REPAIR_STATS="$STATS"
    echo "[*] mutator            : $AFL_CUSTOM_MUTATOR_LIBRARY"
    echo "[*] REPAIR_PROBABILITY : $REPAIR_PROBABILITY"
    echo "[*] repair stats log   : $FILENAME_REPAIR_STATS"
fi

echo "[*] exec: $AFL_FUZZ ${AFL_ARGS[*]} -- $*"
exec "$AFL_FUZZ" "${AFL_ARGS[@]}" -- "$@"
