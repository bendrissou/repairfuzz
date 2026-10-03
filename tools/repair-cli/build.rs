use cfgrammar::yacc::YaccKind;
use lrlex::CTLexerBuilder;

fn main() {
    // Recorded in the binary so `repair-cli --help` can say which grammar it
    // was built from. Set by scripts/build-repair-cli.sh.
    let grammar = std::env::var("REPAIRFUZZ_GRAMMAR").unwrap_or_else(|_| "unknown".to_string());
    println!("cargo:rustc-env=REPAIRFUZZ_GRAMMAR={grammar}");
    println!("cargo:rerun-if-env-changed=REPAIRFUZZ_GRAMMAR");

    CTLexerBuilder::new()
        .lrpar_config(|ctp| {
            ctp.yacckind(YaccKind::Grmtools)
                .grammar_in_src_dir("grammar.y")
                .unwrap()
        })
        .lexer_in_src_dir("grammar.l")
        .unwrap()
        .build()
        .unwrap();
}
