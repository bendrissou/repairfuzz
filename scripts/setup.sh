#!/usr/bin/env bash
#
# Fetch and build RepairFuzz's two dependencies:
#
#   third_party/AFLplusplus  -- AFL++ with the RepairFuzz patches applied
#   third_party/grmtools     -- grmtools/CPCT+ tuned for fuzzing
#
# Both are pinned to the commits used in the ISSTA 2026 paper.
# Re-running this script is safe: existing checkouts are reset to the pinned
# commit and re-patched from scratch.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY="$REPO_ROOT/third_party"

# Pinned upstream revisions, as used in the ISSTA 2026 paper.
AFL_REPO="https://github.com/AFLplusplus/AFLplusplus.git"
AFL_COMMIT="1ffb1b6b2adaedbee7febc9f344c042fd25eae1a"
GRMTOOLS_REPO="https://github.com/softdevteam/grmtools.git"
GRMTOOLS_COMMIT="3997be124682a03f2208bbce35bd85fdf98114da"

INSTALL_AFL="${INSTALL_AFL:-1}"   # set to 0 to skip `make install`
JOBS="${JOBS:-$(nproc)}"

log() { printf '\033[1;94m[*]\033[0m %s\n' "$*"; }
die() { printf '\033[1;91m[-]\033[0m %s\n' "$*" >&2; exit 1; }

for tool in git cargo make patch; do
    command -v "$tool" >/dev/null 2>&1 || die "'$tool' not found in PATH. See README.md > Requirements."
done

mkdir -p "$THIRD_PARTY"

# ---------------------------------------------------------------- grmtools --
log "Preparing grmtools (CPCT+) at $GRMTOOLS_COMMIT"
if [ ! -d "$THIRD_PARTY/grmtools/.git" ]; then
    git clone "$GRMTOOLS_REPO" "$THIRD_PARTY/grmtools"
fi
(
    cd "$THIRD_PARTY/grmtools"
    git fetch --all --quiet
    git checkout --quiet --force "$GRMTOOLS_COMMIT"
    git reset --hard --quiet "$GRMTOOLS_COMMIT"
    git clean -fdq
    log "  applying patches/grmtools/0001-cpctplus-fuzzing-tuning.patch"
    patch -p1 --silent < "$REPO_ROOT/patches/grmtools/0001-cpctplus-fuzzing-tuning.patch"
    # grmtools does not commit a Cargo.lock, so a fresh clone resolves to
    # whatever is newest on crates.io today -- which drifts, and eventually
    # requires a newer rustc than the one the paper used. Pin a known-good set.
    if [ "${PIN_GRMTOOLS_DEPS:-1}" = "1" ]; then
        log "  pinning dependency versions (patches/grmtools/Cargo.lock)"
        cp "$REPO_ROOT/patches/grmtools/Cargo.lock" Cargo.lock
    fi
    log "  building grmtools"
    cargo build --release
)

# -------------------------------------------------------------- AFLplusplus --
log "Preparing AFL++ at $AFL_COMMIT"
if [ ! -d "$THIRD_PARTY/AFLplusplus/.git" ]; then
    git clone "$AFL_REPO" "$THIRD_PARTY/AFLplusplus"
fi
(
    cd "$THIRD_PARTY/AFLplusplus"
    git fetch --all --quiet
    git checkout --quiet --force "$AFL_COMMIT"
    git reset --hard --quiet "$AFL_COMMIT"
    git clean -fdq
    for p in "$REPO_ROOT"/patches/aflplusplus/*.patch; do
        log "  applying patches/aflplusplus/$(basename "$p")"
        patch -p1 --silent < "$p"
    done
    log "  building AFL++ (this takes a few minutes)"
    make source-only -j"$JOBS"
    if [ "$INSTALL_AFL" = "1" ]; then
        log "  installing AFL++ (afl-fuzz, afl-clang-fast, ...)"
        make install
    else
        log "  skipping 'make install' (INSTALL_AFL=0); use $THIRD_PARTY/AFLplusplus/afl-fuzz directly"
    fi
)

log "Done."
echo
echo "  AFL++     : $THIRD_PARTY/AFLplusplus"
echo "  grmtools  : $THIRD_PARTY/grmtools"
echo
echo "Next: build a repair mutator, e.g."
echo "  ./scripts/build-mutator.sh lua corpus"
