// repair-cli -- run RepairFuzz's repair step on files, without any fuzzing.
//
//   repair-<lang>-<grammar> FILE...        repair each file, print the result
//   repair-<lang>-<grammar> --check DIR    report how many files the grammar accepts
//
// Useful for two things:
//   * checking that a grammar accepts the seed corpus you intend to fuzz with
//     (RepairFuzz silently rewrites any seed the grammar rejects);
//   * seeing exactly what the repair step does to a given input.
//
// The grammar is chosen at build time: scripts/build-repair-cli.sh copies
// grammars/<lang>/<grammar>.{l,y} to src/grammar.{l,y} before building.

use lrlex::lrlex_mod;
use lrpar::lrpar_mod;
use std::fs;
use std::path::Path;
use std::process::ExitCode;

lrlex_mod!("grammar.l");
lrpar_mod!("grammar.y");

const GRAMMAR: &str = env!("REPAIRFUZZ_GRAMMAR");

fn read_lossy(path: &Path) -> Option<String> {
    fs::read(path)
        .ok()
        .map(|b| String::from_utf8_lossy(&b).to_string())
}

/// Parse `input`; return (parsed_without_errors, repaired_text_if_any).
fn repair(lexerdef: &lrlex::LRNonStreamingLexerDef<lrlex::defaults::DefaultLexerTypes>,
          input: &str,
          show: bool) -> (bool, Option<String>) {
    let lexer = lexerdef.lexer(input);
    let (res, errs) = grammar_y::parse(&lexer);
    if errs.is_empty() {
        return (true, res.and_then(|r| r.ok()));
    }
    if show {
        for e in &errs {
            println!("{}", e.pp(&lexer, &grammar_y::token_epp));
        }
    }
    (false, res.and_then(|r| r.ok()))
}

fn usage() -> ExitCode {
    eprintln!(
        "repair-cli (grammar: {GRAMMAR})\n\
         \n\
         Usage:\n  \
           repair-cli FILE...        repair each file and print the result\n  \
           repair-cli --check DIR    report how many files in DIR the grammar accepts\n"
    );
    ExitCode::from(2)
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.is_empty() || args[0] == "-h" || args[0] == "--help" {
        return usage();
    }
    let lexerdef = grammar_l::lexerdef();

    // ------------------------------------------------- corpus-acceptance check
    if args[0] == "--check" {
        let Some(dir) = args.get(1) else { return usage() };
        let Ok(entries) = fs::read_dir(dir) else {
            eprintln!("cannot read directory: {dir}");
            return ExitCode::FAILURE;
        };
        let (mut total, mut accepted) = (0usize, 0usize);
        let mut rejected: Vec<String> = Vec::new();
        for e in entries.flatten() {
            let p = e.path();
            if !p.is_file() {
                continue;
            }
            let Some(text) = read_lossy(&p) else { continue };
            total += 1;
            if repair(&lexerdef, &text, false).0 {
                accepted += 1;
            } else {
                rejected.push(p.display().to_string());
            }
        }
        if total == 0 {
            eprintln!("no files found in {dir}");
            return ExitCode::FAILURE;
        }
        println!("grammar : {GRAMMAR}");
        println!("corpus  : {dir}");
        println!("accepted: {accepted}/{total} ({:.1}%)",
                 100.0 * accepted as f64 / total as f64);
        if !rejected.is_empty() {
            println!("\nrejected (RepairFuzz would rewrite these before fuzzing):");
            for r in rejected.iter().take(20) {
                println!("  {r}");
            }
            if rejected.len() > 20 {
                println!("  ... and {} more", rejected.len() - 20);
            }
        }
        return if accepted == total { ExitCode::SUCCESS } else { ExitCode::FAILURE };
    }

    // -------------------------------------------------------- repair each file
    let mut failures = 0;
    for (i, arg) in args.iter().enumerate() {
        if args.len() > 1 {
            if i > 0 {
                println!();
            }
            println!("=== {arg} ===");
        }
        let Some(text) = read_lossy(Path::new(arg)) else {
            eprintln!("cannot read file: {arg}");
            failures += 1;
            continue;
        };
        match repair(&lexerdef, &text, true) {
            (true, _) => println!("Input already parses; no repair needed."),
            (false, Some(out)) => println!("\nResult:\n{out}"),
            (false, None) => {
                eprintln!("\nUnable to repair within the time budget.");
                failures += 1;
            }
        }
    }
    if failures > 0 { ExitCode::FAILURE } else { ExitCode::SUCCESS }
}
