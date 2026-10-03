# RepairFuzz custom mutators

One AFL++ custom mutator per input language. Each is a `cdylib` loaded by
`afl-fuzz` through `AFL_CUSTOM_MUTATOR_LIBRARY`.

| Crate | Language | Grammars |
|---|---|---|
| `lua_repair` | Lua (Lua, LuaJIT) | `grammars/lua/` |
| `ruby_repair` | Ruby (Ruby, mRuby) | `grammars/ruby/` |
| `js_repair` | JavaScript (ChakraCore) | `grammars/js/` |
| `php_repair` | PHP | `grammars/php/` |
| `json_repair` | JSON | `grammars/json/` — minimal template for new languages |

Build one with `../scripts/build-mutator.sh <lang> <grammar>`; don't run `cargo
build` directly, since the grammar has to be copied into `src/` first.

## What the mutator does

`afl_custom_fuzz` is a pass-through: AFL++'s own byte-level mutators do the
mutating. All the work is in **`afl_custom_post_process`**, which runs on every
mutated input just before it is written out for the target:

1. Draw a random number; if it exceeds `REPAIR_PROBABILITY`, return the buffer
   untouched (this is what makes RepairFuzz-Partial partial).
2. Lex and parse the buffer with the compiled LR grammar.
3. If there are no parse errors, return it untouched.
4. Otherwise CPCT+ has already computed a minimum-cost repair while parsing;
   serialise the repaired parse tree back to text and return that.
5. If repair did not finish within the 10 ms budget, return an error, which
   makes AFL++ skip this input.

Counters for executions, invalid inputs, successful repairs and total repair
time are accumulated and appended to `FILENAME_REPAIR_STATS` once per hour of
fuzzing.

The four language crates are identical apart from three lines — the
`lrlex_mod!`/`lrpar_mod!` grammar filenames and a label in the statistics log.
They are kept separate because grmtools generates the parser at compile time
from a fixed grammar filename. See `../docs/GRAMMARS.md` to add a language.
