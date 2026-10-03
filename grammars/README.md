# Grammars

Lex/Yacc grammars in [grmtools](https://softdevteam.github.io/grmtools/latest_release/book/)
format (`YaccKind::Grmtools`), used by RepairFuzz both to *validate* a mutated
input and to *repair* it.

```
lua/   standard.{l,y}  custom.{l,y}  corpus.{l,y}     # Lua, LuaJIT
ruby/  standard.{l,y}  custom.{l,y}  corpus.{l,y}     # Ruby, mRuby
js/    standard.{l,y}  custom.{l,y}  corpus.{l,y}     # JavaScript engines
php/   standard.{l,y}  custom.{l,y}  corpus.{l,y}     # PHP
json/  json.{l,y}                                     # minimal example
```

* **corpus** — adapted to accept real-world code (comments, modern syntax,
  fewer ambiguities). **Start here.**
* **standard** — full grammars for parsing the language, but strict; they do
  not lex comments.
* **custom** — incomplete, bug-finding-oriented grammars, ported from Nautilus.

Read **[../docs/GRAMMARS.md](../docs/GRAMMARS.md)** before writing your own:
grammars for repair have two requirements beyond parsing — a catch-all
`UNMATCHED` lexer token, and actions that produce concrete text for tokens a
repair *inserts*.

Check a grammar against your corpus before fuzzing with it:

```bash
./scripts/build-repair-cli.sh lua corpus
./build/bin/repair-lua-corpus --check /path/to/your/seeds
```
