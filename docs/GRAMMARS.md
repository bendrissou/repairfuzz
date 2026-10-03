# Writing a grammar for RepairFuzz

RepairFuzz repairs inputs with [CPCT+](https://doi.org/10.4230/LIPIcs.ECOOP.2020.6),
which works on **LR parsers**. Grammars are therefore written in Lex/Yacc form
and compiled by [grmtools](https://softdevteam.github.io/grmtools/latest_release/book/)
(`YaccKind::Grmtools`), which gives every production a Rust action.

Writing an LR grammar is more work than an LL/ANTLR one — you have to keep it
unambiguous and free of shift/reduce and reduce/reduce conflicts — but it is a
one-time effort per input format.

## What ships here

```
grammars/
  lua/    standard.{l,y}  custom.{l,y}  corpus.{l,y}
  ruby/   standard.{l,y}  custom.{l,y}  corpus.{l,y}
  js/     standard.{l,y}  custom.{l,y}  corpus.{l,y}
  php/    standard.{l,y}  custom.{l,y}  corpus.{l,y}
  json/   json.{l,y}
```

Three variants ship for each language:

| Variant | What it is |
|---|---|
| **standard** | A full grammar for the language, intended for parsing. Ported from existing Lex/Yacc grammars (Lua, PHP) or converted from published BNF (Ruby, JavaScript). |
| **custom** | Incomplete, bug-finding-oriented grammars that treat specific coding idioms (e.g. calls to key standard-library functions) as first-class constructs. Ported from the [Nautilus](https://github.com/nautilus-fuzz/nautilus/tree/mit-main/grammars) project's grammars. |
| **corpus** | `standard`, modified to accept real-world code: comments are lexed and ignored, missing modern syntax is added, and some rules are refined to resolve ambiguity. **Use this one unless you have a reason not to.** |

One grammar covers a *language*, not an implementation: `lua` works for both
Lua and LuaJIT, `ruby` for both Ruby and mRuby, `js` for JavaScript engines.

## The two repair-specific requirements

A grammar that merely *parses* is not enough. Two things are needed to make a
grammar usable for repair.

### 1. Turn lexing errors into parsing errors

CPCT+ only recovers from **parse** errors. A lexing error makes it bail out
before it ever tries. So the lexer must never fail: add a catch-all rule that
maps any otherwise-invalid character to a token, and — because grmtools
requires every lexer token to appear in the grammar — add an unused production
that references it.

In the `.l` file, as the **last** rule (so it has lowest precedence):

```lex
. "UNMATCHED"
```

In the `.y` file:

```yacc
%expect-unused unmatched "UNMATCHED"
...
%%
...
unmatched -> ():
  "UNMATCHED" { }
  ;
```

`%expect-unused` silences the warning about a production that is unreachable
from the start symbol. Now an unexpected byte becomes an `UNMATCHED` token,
the parser reports an error at that position, and CPCT+ can repair it —
typically by deleting the token.

### 2. Give inserted tokens a concrete value

A repair sequence may *insert* a token. For a literal like `}` or `end` the
text is obvious. For a token class such as `NAME`, `NUMERAL` or `STRING` there
is no text — the parse tree has a hole, and the serialised output needs
something concrete.

Every action therefore has to cope with its lexeme being `Err`, meaning
"CPCT+ inserted me". The Lua grammar does this with small helper functions at
the bottom of the `.y` file:

```rust
fn number<'lexer, 'input: 'lexer, E>(
    s: Result<lrlex::defaults::DefaultLexeme, E>,
    i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>,
) -> String {
    match s {
        Ok(val) => String::from(i_lexer.span_str(val.span())),      // real token: use its text
        Err(_)  => rand::thread_rng().gen_range(-100.9..100.9).to_string(),  // inserted: invent one
    }
}
```

and uses them in productions:

```yacc
| "GOTO" "NAME" { Ok(String::from("goto") + &name($2, $lexer)) }
```

The conventions used throughout these grammars:

| Inserted token | Value produced |
|---|---|
| numbers (`NUM`, `NUMERAL`) | a random number |
| short strings | `"abc"` |
| Lua long strings | `[==[abc]==]` |
| identifiers (`NAME`) | `var_y` |

This is why repaired Lua inputs are full of `[==[abc]==]`, and why repaired
JSON gets values like `{"server": 145757249.29}`. Using a *random* number
rather than a constant keeps some diversity in the repaired inputs.

### Actions serialise, they do not evaluate

Every production returns `Result<String, ()>` and concatenates its children's
strings. The parse tree is serialised straight back into source text — that
text is what the fuzzer feeds to the SUT:

```yacc
stat -> Result<String, ()>
    : "DO" block "END" { Ok(String::from("do\n") + &$2? + "\nend") }
    | varlist "EQ" explist { Ok($1? + "=" + &$3?) }
    ;
```

Keep the output faithful to the input (don't normalise aggressively), or repair
will destroy the diversity that byte-level mutation created. Note that whitespace
and comments are *not* preserved: they are dropped by the lexer and reinserted
by the actions, so a repaired input is a reformatted version of the original.

### `%epp` declarations

`%epp TOKEN "text"` controls how a token is displayed in error and repair
messages. It is cosmetic for fuzzing, but it is what makes `repair-cli` print
readable repair sequences (`Insert )` rather than `Insert RBRACKET`).

## Adding a new language

1. **Write `grammars/<lang>/<variant>.{l,y}`**, following the two rules above.

2. **Create the mutator crate** by copying an existing one — they differ only
   in the module names and a log label:

   ```bash
   cp -r mutator/lua_repair mutator/<lang>_repair
   rm -f mutator/<lang>_repair/src/*.l mutator/<lang>_repair/src/*.y
   ```

   Then in the new crate edit:

   * `Cargo.toml` — `name = "<lang>_repair"`, `[lib] name = "repair_<lang>"`
   * `build.rs` — `grammar_in_src_dir("<lang>.y")`, `lexer_in_src_dir("<lang>.l")`
   * `src/lib.rs` — `lrlex_mod!("<lang>.l")`, `lrpar_mod!("<lang>.y")`,
     `lexerdef: <lang>_l::lexerdef()`, and `<lang>_y::parse(&lexer)`

   [`mutator/json_repair`](../mutator/json_repair) is the smallest example and
   makes a good starting point.

3. **Build and test it:**

   ```bash
   ./scripts/build-mutator.sh <lang> <variant>
   ```

Conflicts reported by `cargo build` come from grmtools' LR table generation and
must be resolved in the grammar before the mutator will build.

## Checking a grammar against a corpus

Before fuzzing, confirm that your grammar actually accepts the seeds you intend
to use — RepairFuzz will "repair" anything it rejects, including valid inputs
the grammar simply does not cover, so a mismatch silently rewrites your corpus
before fuzzing starts.

[`tools/repair-cli`](../tools/repair-cli) builds a standalone binary for any
(language, grammar) pair that does exactly this:

```bash
./scripts/build-repair-cli.sh lua corpus
./build/bin/repair-lua-corpus --check /path/to/your/seeds
```

```
grammar : lua/corpus
corpus  : /path/to/your/seeds
accepted: 25/25 (100.0%)
```

It exits non-zero and lists the offending files if anything is rejected.

The difference between grammar variants can be stark. Checked against the Lua
reference test suite, `lua/corpus` accepts every file while `lua/standard`
accepts **none** — standard grammars do not lex comments, and every file in
that suite has one. That is precisely why the `corpus` variants exist, and why
it is worth running this check before committing to a long campaign.

The same binary is the quickest way to iterate on a grammar: give it a single
file and it prints the repair sequences CPCT+ found and the repaired text.

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

The paper notes that the Ruby LR grammar accepts a strict subset of what
Nautilus and Grammarinator accept, because Ruby's syntax resists unambiguous
LR description — a known limitation rather than a bug.
