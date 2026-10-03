# RepairFuzz

**Repair-driven greybox fuzzing** — mutate inputs at the byte level, then
*repair* them with a grammar.

RepairFuzz is a greybox fuzzer built on [AFL++](https://github.com/AFLplusplus/AFLplusplus).
It leaves AFL++'s byte-level mutation operators exactly as they are and adds a
post-mutation step that repairs the (usually now invalid) input back into a
syntactically valid one, using the [CPCT+](https://doi.org/10.4230/LIPIcs.ECOOP.2020.6)
error-recovery algorithm from [grmtools](https://github.com/softdevteam/grmtools).

```
seed ──► AFL++ byte mutation ──► (usually invalid) ──► CPCT+ repair ──► valid ──► target
```

Aggressively *breaking* and then *repairing* an input reaches parts of the
input space that neither byte-level mutation nor idiomatic grammar-based
mutation finds on its own. A worked example — a valid PHP seed:

```php
$a = pack("AAAAAAAAAAAA", 1,2,3,4,5,6,7,8,9,10,11,12);
unpack('h2147483647', $a);
```

An AFL++ havoc mutation duplicates the text `pack(`, leaving the call
unbalanced, so the input no longer parses:

```php
unpack(pack('h2147483647', $a);
```

CPCT+ computes a minimum-cost repair — insert one `)` — and validity is
restored:

```php
unpack(pack('h2147483647', $a));
```

That repaired program triggered a
[signed integer overflow in PHP's `pack()`](https://github.com/php/php-src/issues/18976).
Reaching it meant reusing an identifier already present elsewhere in the input:
something grammar-based mutators, which draw replacements from a fixed
dictionary, are unlikely to do, and something plain byte-level mutation is
unlikely to do *while keeping the input valid*.

> Implements the ISSTA 2026 paper **Repair-Driven Greybox Fuzzing** by Bachir
> Bendrissou, Alastair F. Donaldson and Cristian Cadar
> ([doi:10.1145/3832229](https://doi.org/10.1145/3832229) ·
> [PDF](https://srg.doc.ic.ac.uk/files/papers/repairfuzz-issta-26.pdf)), in
> which it found 13 confirmed previously-unknown bugs across six interpreters,
> 9 of them missed by AFL++, Grammarinator and Nautilus. The paper's full
> experimental artefact — data, pre-built targets, baseline fuzzers — is
> archived separately at
> [doi:10.5281/zenodo.20935256](https://doi.org/10.5281/zenodo.20935256).
> This repository is just the tool.

---

## Contents

| Path | What it is |
|---|---|
| [`mutator/`](mutator) | The repair mutators (Rust), one crate per input language |
| [`grammars/`](grammars) | Lex/Yacc grammars for Lua, Ruby, JavaScript, PHP and JSON |
| [`patches/`](patches) | The changes RepairFuzz makes to AFL++ and grmtools |
| [`tools/repair-cli/`](tools/repair-cli) | Run the repair step on files, without fuzzing |
| [`scripts/`](scripts) | `setup.sh`, `build-mutator.sh`, `build-repair-cli.sh`, `run-repairfuzz.sh` |
| [`examples/quickstart/`](examples/quickstart) | End-to-end demo on LuaJIT |
| [`docs/`](docs) | [Writing grammars](docs/GRAMMARS.md) · [troubleshooting](docs/TROUBLESHOOTING.md) |

AFL++ and grmtools are not vendored: `scripts/setup.sh` fetches them at pinned
commits and applies the patches.

---

## Requirements

Linux, x86-64. Verified on Ubuntu 20.04 (LLVM 10) and Ubuntu 24.04 (LLVM 18).

```bash
sudo apt-get install -y build-essential git make cmake automake flex bison \
    python3-dev llvm llvm-dev clang lld

# Clang's sanitizer runtimes. Bundled with clang on Ubuntu 20.04, but a
# separate package from 22.04 onwards -- without it, linking an
# -fsanitize=address target fails with "cannot find libclang_rt.asan-x86_64.a".
sudo apt-get install -y libclang-rt-dev || true

# Optional, enables AFL++'s gcc_mode. Needs gcc from the first command.
sudo apt-get install -y "gcc-$(gcc -dumpversion | cut -d. -f1)-plugin-dev"

curl https://sh.rustup.rs -sSf | sh -s -- -y     # Rust 1.86 or newer
```

Any reasonably recent LLVM works. On LLVM < 13 AFL++ builds only its *LLVM
basic mode* and prints `LLVM mode could not be built` — expected and harmless,
you still get `afl-clang-fast`, which is all RepairFuzz needs.

---

## Install

```bash
git clone https://github.com/bendrissou/repairfuzz.git
cd repairfuzz
./scripts/setup.sh          # fetch + patch + build AFL++ and grmtools
```

`setup.sh` is idempotent: it clones into `third_party/`, hard-resets to the
pinned commits, applies [`patches/`](patches), builds both projects and runs
AFL++'s `make install`. Set `INSTALL_AFL=0` to skip the install and use
`third_party/AFLplusplus/afl-fuzz` directly.

`make help` lists shortcuts for the common tasks.

One host-level setting is required before any AFL++ run, and must be repeated
after each reboot:

```bash
echo core | sudo tee /proc/sys/kernel/core_pattern
```

Without it the kernel pipes crash reports to an external handler and AFL++
misreports crashes as hangs.

<details>
<summary><b>Optional: Docker</b> — not required; a native build is the normal path</summary>

A [`Dockerfile`](Dockerfile) is provided for convenience, not because
RepairFuzz expects to run in a container. It is useful for a disposable
fuzzing sandbox, a reproducible CI environment, or trying the tool without
installing an LLVM toolchain. It pins Ubuntu 20.04, runs `scripts/setup.sh`,
and pre-builds the four corpus mutators and the Lua repair CLI.

```bash
docker build -t repairfuzz .      # ~10 min, ~6 GB image
docker run -it --rm repairfuzz
```

`core_pattern` still has to be set on the **host** — a container cannot set it.
</details>

---

## Quickstart

See it working end to end in about five minutes. This builds LuaJIT with
`afl-clang-fast`, builds the Lua repair mutator, then fuzzes LuaJIT twice for
the same budget — once with repair, once without — and reports how many
generated inputs are syntactically valid Lua:

```bash
./examples/quickstart/run.sh 60
```

```
  Fuzzer                      Queue entries   Syntactically valid Lua
  --------------------------  -------------   -----------------------
  RepairFuzz-Full                       350             257 (73.4%)
  AFL++ (no repair)                     360              34  (9.4%)
```

Same mutation operators, same budget, same seeds. The only difference is the
repair step. (Exact numbers vary between runs; the gap does not.)

---

## Using RepairFuzz on your own target

### 1. Get an LR grammar for your input format

RepairFuzz repairs against a **Lex/Yacc grammar** in
[grmtools](https://softdevteam.github.io/grmtools/latest_release/book/) format
(`YaccKind::Grmtools`). Grammars for Lua, Ruby, JavaScript, PHP and JSON ship
in [`grammars/`](grammars).

Writing one for a new language is a one-time effort.
[`docs/GRAMMARS.md`](docs/GRAMMARS.md) covers the two requirements specific to
repair — making lexing errors recoverable, and emitting concrete values for
tokens that a repair *inserts*.

### 2. Check the grammar against your seeds

Do this before a long campaign. RepairFuzz repairs anything its grammar
rejects, **including perfectly good seeds**, so a grammar/corpus mismatch
quietly rewrites your inputs before fuzzing even starts.

```bash
./scripts/build-repair-cli.sh lua corpus
./build/bin/repair-lua-corpus --check /path/to/your/seeds
```

```
grammar : lua/corpus
corpus  : /path/to/your/seeds
accepted: 25/25 (100.0%)
```

It exits non-zero and names the offending files if anything is rejected. The
same binary shows what repair does to one input, which is the quickest way to
iterate on a grammar:

```bash
printf 'local x = \nprint(x' > /tmp/broken.lua
./build/bin/repair-lua-corpus /tmp/broken.lua
```

```
Parsing error at line 2 column 8. Repair sequences found:
   1: Insert )

Result:
local x= print( x)
```

### 3. Build the repair mutator

```bash
./scripts/build-mutator.sh <lang> <grammar>      # e.g. lua corpus, php custom
```

This copies the chosen grammar into the crate, compiles the LR tables, and
writes `build/mutators/lib_repair_<lang>_<grammar>.so`.

### 4. Build your target with AFL++ instrumentation

Exactly as for plain AFL++ — nothing RepairFuzz-specific:

```bash
CC=afl-clang-fast CXX=afl-clang-fast++ ./configure --enable-address-sanitizer
make -j"$(nproc)"
```

### 5. Fuzz

```bash
./scripts/run-repairfuzz.sh \
    -m build/mutators/lib_repair_lua_corpus.so \
    -i /path/to/your/seeds \
    -o /tmp/out \
    -p 1.0 \
    -- /path/to/luajit @@
```

`-p` is the repair probability:

| Configuration | `-p` | Behaviour |
|---|---|---|
| **RepairFuzz-Full** | `1.0` | repair every invalid mutant |
| **RepairFuzz-Partial** | `0.5` | repair half, letting multiple validity-breaking mutations accumulate |
| *(baseline)* | `0.0` | no repair — stock AFL++ |

### Running by hand

`run-repairfuzz.sh` only sets environment variables and calls `afl-fuzz`:

```bash
export AFL_CUSTOM_MUTATOR_LIBRARY=$PWD/build/mutators/lib_repair_lua_corpus.so
export REPAIR_PROBABILITY=1.0
export FILENAME_REPAIR_STATS=/tmp/out/repair-stats.log
export AFL_MAP_SIZE=1048576
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:symbolize=0:allocator_may_return_null=1"

afl-fuzz -t 3000 -a text -i /path/to/seeds -o /tmp/out -- /path/to/luajit @@
```

| Variable | Meaning | Default |
|---|---|---|
| `AFL_CUSTOM_MUTATOR_LIBRARY` | absolute path to the repair mutator `.so` | — |
| `REPAIR_PROBABILITY` | probability an invalid mutant is repaired | `0.95` |
| `FILENAME_REPAIR_STATS` | file for hourly repair statistics | a path from the original artefact image that will not exist on your machine — always set this |

The repair **timeout** is a compile-time constant in grmtools
(`RECOVERY_TIME_BUDGET`), set to 10 ms by
[`patches/grmtools/0001-cpctplus-fuzzing-tuning.patch`](patches/grmtools/0001-cpctplus-fuzzing-tuning.patch).
To change it, edit `third_party/grmtools/lrpar/src/lib/parser.rs`, rebuild
grmtools, then rebuild the mutators. The paper also evaluates 1 ms and 100 ms;
shorter budgets found *more* bugs in several cases.

---

## How it works

**In AFL++.** Repair runs through AFL++'s custom-mutator API as an
`afl_custom_post_process` hook, so AFL++'s own mutation operators are
untouched. Four changes to stock AFL++
([`patches/aflplusplus/`](patches/aflplusplus)):

* **`post_process` for the Rust custom-mutator API.** AFL++'s Rust bindings
  did not expose `afl_custom_post_process`; the patch adds it.
* **Run `post_process` after trimming.** Trimming can reintroduce invalid
  inputs, so repair has to run again afterwards.
* **Preserve the original input on queue import**, so an unrepaired copy of a
  test case imported from another instance stays on the queue.
* **`SYNC_INTERVAL` 8 → 1**, so parallel instances exchange findings promptly.

**In grmtools/CPCT+** ([`patches/grmtools/`](patches/grmtools)):

* **Repair budget 500 ms → 10 ms.** CPCT+'s default is tuned for code editors.
  At 10 ms about 72% of repairs still complete, and campaigns spend ~15% of
  their time repairing.
* **Zero-cost `delete`.** Making deletion free rather than cost 1 biases the
  search towards skipping ill-formed tokens before trying grammar-driven
  insertions — a **5.6× average speedup** in repair search.
* **A recursion-depth bound** on repair-sequence traversal, so pathological
  inputs cannot exhaust the stack.

**Inserted tokens.** When a repair inserts a non-literal token, the grammar
action has to produce a concrete value: inserted numbers get a random value,
inserted strings get `"abc"`. This is why repaired Lua is peppered with
`[==[abc]==]`. See [`docs/GRAMMARS.md`](docs/GRAMMARS.md).

---

## Troubleshooting

Common failure modes — seeds that crash during AFL++'s dry run, `core_pattern`,
map sizes, missing sanitizer runtimes, a mutator that will not load, repair
that appears to do nothing — are collected in
[`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

---

## Citing

```bibtex
@article{bendrissou2026repairfuzz,
  author  = {Bendrissou, Bachir and Donaldson, Alastair F. and Cadar, Cristian},
  title   = {Repair-Driven Greybox Fuzzing},
  journal = {Proc. ACM Softw. Eng.},
  volume  = {3},
  number  = {ISSTA},
  article = {ISSTA138},
  year    = {2026},
  doi     = {10.1145/3832229}
}
```

## License

[Apache-2.0](LICENSE). The `custom` grammars are ports of
[Nautilus](https://github.com/nautilus-fuzz/nautilus)'s (MIT); AFL++ and
grmtools are fetched from upstream at build time rather than vendored. See
[`NOTICE`](NOTICE).

## Acknowledgements

RepairFuzz builds on [AFL++](https://github.com/AFLplusplus/AFLplusplus) and on
[grmtools](https://github.com/softdevteam/grmtools) by Lukas Diekmann and
Laurence Tratt, which implements CPCT+.
