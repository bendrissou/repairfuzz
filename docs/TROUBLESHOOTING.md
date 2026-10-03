# Troubleshooting

Failure modes you are likely to hit, and what they mean.

## Setup and build

### `error: rustc 1.xx is not supported by the following packages`

Something resolved dependencies without the pinned lockfiles. grmtools does not
commit a `Cargo.lock`, so a free resolution pulls in crates that need a newer
`rustc` than you have. `scripts/setup.sh` installs
`patches/grmtools/Cargo.lock` to prevent this; if you cloned grmtools yourself
or set `PIN_GRMTOOLS_DEPS=0`, either restore that lockfile or upgrade your
toolchain (`rustup update stable`).

### `LLVM mode could not be built, please install at least llvm-13`

Expected on Ubuntu 20.04, which ships LLVM 10. AFL++ still builds *LLVM basic
mode*, which provides `afl-clang-fast` and is what the paper's experiments
used. Install LLVM 13+ if you want AFL++'s full LLVM mode.

Check you really did get a compiler:

```bash
ls third_party/AFLplusplus/afl-clang-fast
```

### `Error: cpio is not installed` during the AFL++ build

Harmless. It comes from AFL++'s optional Nyx mode, which this project does not
use; the build continues and the error is explicitly ignored.

### `patch: **** malformed patch` or `Reversed (or previously applied) patch`

`setup.sh` hard-resets the checkout to the pinned commit before patching, so
this normally means a patch was already applied to a tree you modified by hand.
Start clean:

```bash
make distclean && ./scripts/setup.sh
```

### `cannot find libclang_rt.asan-x86_64.a` when building a target

Clang's sanitizer runtimes are a separate package on Ubuntu 22.04 and later
(they ship with clang on 20.04). Install them:

```bash
sudo apt-get install -y libclang-rt-dev        # or libclang-rt-<version>-dev
```

This bites when you build an `-fsanitize=address` target with
`afl-clang-fast`, including the quickstart's LuaJIT build.

### Shift/reduce or reduce/reduce conflicts when building a mutator

These come from grmtools' LR table generation and must be fixed in the grammar
— CPCT+ needs an unambiguous LR grammar. See [GRAMMARS.md](GRAMMARS.md).

### `unreachable code` / `unused import` warnings

Expected. `afl_custom_fuzz` is deliberately a pass-through — all of
RepairFuzz's work happens in `post_process` — and the unreachable code after
that early `return` is an abandoned experiment kept so the sources stay
byte-identical to the published artefact.

## Running

### `PROGRAM ABORT: We need at least one valid input seed that does not crash!`

AFL++ ran every seed during its dry run and all of them crashed the target.
Usually one of:

* **The target itself is broken.** Check it runs standalone first:
  `ASAN_OPTIONS=detect_leaks=0 ./your-target one-of-your-seeds`.
* **The seeds genuinely crash it** — remove them; seeds should be interesting,
  not already-failing.
* **ASan is aborting on something unrelated**, e.g. a leak. The experiments use
  `detect_leaks=0:abort_on_error=1:symbolize=0:allocator_may_return_null=1`,
  which `scripts/run-repairfuzz.sh` sets for you.

### Crashes are reported as hangs, or AFL++ refuses to start over `core_pattern`

On the **host** (this cannot be done from inside a container, and must be
repeated after every reboot):

```bash
echo core | sudo tee /proc/sys/kernel/core_pattern
```

### `Mapsize too small` / coverage looks truncated

Large interpreters need a bigger coverage map than AFL++'s default. All six
SUTs in the paper use `AFL_MAP_SIZE=1048576`, which is
`scripts/run-repairfuzz.sh`'s default; raise it with `--map-size` if AFL++ asks.

### `No free CPU core could be found`

Either free a core or set `AFL_NO_AFFINITY=1`.

### The mutator does not seem to load

AFL++ prints a line on startup when it does:

```
[*] Loading custom mutator library from '.../lib_repair_lua_corpus.so'...
[+] Custom mutator '...' installed successfully.
```

If that is missing, `AFL_CUSTOM_MUTATOR_LIBRARY` is unset or wrong. It must be
an **absolute path** to an existing `.so`.

### Repair does not seem to be doing anything

Check in this order:

1. **Is the grammar the right one for the target?** A Lua mutator against a
   Ruby interpreter will reject and rewrite everything.
2. **Does the grammar accept your seeds?**
   `./build/bin/repair-<lang>-<grammar> --check <seed-dir>` — see
   [GRAMMARS.md](GRAMMARS.md#checking-a-grammar-against-a-corpus).
3. **Is `REPAIR_PROBABILITY` what you think?** It defaults to `0.95` inside the
   mutator, not `1.0`.
4. **Measure it.** Generated inputs should be mostly valid; compare against a
   `-p 0` run, as `examples/quickstart/run.sh` does.

### The repair statistics log is empty

Statistics are written once per hour of fuzzing, starting after the first full
hour. Short runs produce nothing. If `FILENAME_REPAIR_STATS` is unset the
mutator falls back to a path from the artefact image that will not exist on
your machine, and prints a write error hourly — harmless, and
`scripts/run-repairfuzz.sh` always sets the variable.

### Throughput is much lower than plain AFL++

Expected to a degree: repair costs roughly 15% of campaign time at the default
10 ms budget. If it is worse than that, your grammar is probably rejecting
almost everything, so every single execution pays for a repair attempt that
then times out. Check the grammar against your corpus first.

To change the budget, edit `RECOVERY_TIME_BUDGET` in
`third_party/grmtools/lrpar/src/lib/parser.rs`, rebuild grmtools, then rebuild
the mutators. The paper evaluates 1 ms, 10 ms and 100 ms; shorter budgets gave
*better* bug-finding in several cases.

### Repaired inputs have lost their comments and formatting

By design. The grammar's actions serialise the parse tree back to text, and
comments and whitespace are dropped by the lexer. Inserted tokens get
placeholder values — `"abc"` for strings, `var_y` for identifiers, a random
number for numerals — which is why repaired Lua is full of `[==[abc]==]`.
