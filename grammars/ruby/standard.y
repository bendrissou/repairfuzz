%expect-unused unmatched "UNMATCHED"
%start program

%left "COMMA"
%left "OR"
%left "AND"
%right "RETURN"
%right "YIELD"

%right "IF" "UNLESS" "UNTIL"
%right "VBAR" "COLCOL" "LSQUARE" "RSQUARE" "LCURLY" "RCURLY" "LBRACKET" "RBRACKET"
%right "EQ" "PLUSEQ" "MINUSEQ" "STAREQ" "DIVEQ" "MODEQ" "DSTAREQ" "AMPEQ" "VBAREQ" "CIRCEQ" "DLTEQ" "DGTEQ" "DAMPEQ" "DVBAREQ"
%right "DOTDOT" "DOTDOTDOT" "PLUS" "MINUS" "STAR" "FSLASH" "MOD" "DSTAR" "CIRC" "AMP" "DARROW" "GT" "GTEQ" "LT" "LTEQ" "EQEQ" "EQEQEQ" "NOTEQ" "EQAP" "NOTAP" "DLT" "DGT" "DAMP" "DVBAR" 

%expect-rr 363
%expect 439

%%
program -> Result<String, ()>
    : compstmt { Ok($1?) }
    ;
compstmt -> Result<String, ()>
    : stmt term_expr_rep term_opt { Ok(String::from("\n") + &$1? + &$2? + &$3? + "\n") }
    ;
stmt -> Result<String, ()>
    : call "DO" block_var_opt compstmt "END" { Ok($1? + " do " + &$3? + &$4? + "end") }
    | "UNDEF" fname { Ok(String::from("undef ") + &$2?) }
    | "ALIAS" fname fname { Ok(String::from("alias ") + &$2? + " " + &$3?) }
    | stmt "IF" expr { Ok($1? + " if " + &$3?) }
    | stmt "WHILE" expr { Ok($1? + " while " + &$3?) }
    | stmt "UNLESS" expr { Ok($1? + " unless " + &$3?) }
    | stmt "UNTIL" expr { Ok($1? + " until " + &$3?) }
    | "BEGIN" "LCURLY" compstmt "RCURLY" { Ok(String::from("begin {") + &$3? + "}") }
    | "END" "LCURLY" compstmt "RCURLY" { Ok(String::from("end {") + &$3? + "}") }
    | lhs "EQ" command block_opt { Ok($1? + " = " + &$3? + &$4?) }
    | expr { Ok($1?) }
    ;
expr -> Result<String, ()>
    : mlhs "EQ" mrhs { Ok($1? + " = " + &$3?) }
    | "RETURN" call_args { Ok(String::from("return ") + &$2?) }
    | "YIELD" call_args { Ok(String::from("yield ") + &$2?) }
    | expr "AND" expr { Ok($1? + " and " + &$3?) }
    | expr "OR" expr { Ok($1? + " or " + &$3?) }
    | "NOT" expr { Ok(String::from("not ") + &$2?) }
    | command { Ok($1?) }
    | "NEG" command { Ok(String::from("! ") + &$2?) }
    | arg { Ok($1?) }
    ;
call -> Result<String, ()>
    : function { Ok($1?) }
    | command { Ok($1?) }
    ;
command -> Result<String, ()>
    : operation call_args { Ok($1? + " " + &$2?) }
    | primary "DOT" operation call_args { Ok($1? + "." + &$3? + " " + &$4?) }
    | primary "COLCOL" operation call_args { Ok($1? + "::" + &$3? + " " + &$4?) }
    | "SUPER" call_args { Ok(String::from("super ") + &$2?) }
    ;
function -> Result<String, ()>
    : operation call_args_brak_opt { Ok($1? + &$2?) }
    | primary "DOT" operation "LBRACKET" call_args_opt "RBRACKET" { Ok($1? + "." + &$3? + "(" + &$5? + ")") }
    | primary "COLCOL" operation "LBRACKET" call_args_opt "RBRACKET" { Ok($1? + "::" + &$3? + "(" + &$5? + ")") }
    | primary "DOT" operation { Ok($1? + "." + &$3?) }
    | primary "COLCOL" operation { Ok($1? + "::" + &$3?) }
    | "SUPER" "LBRACKET" call_args_opt "RBRACKET" { Ok(String::from("super(") + &$3? + ")") }
    | "SUPER" { Ok(String::from("super")) }
    ;
arg -> Result<String, ()>
    : lhs "EQ" arg { Ok($1? + " = " + &$3?) }
    | lhs op_asgn arg { Ok($1? + " " + &$2? + " " + &$3?) }
    | arg op_bin arg { Ok($1? + " " + &$2? + " " + &$3?) }
    | "PLUS" arg { Ok(String::from("+ ") + &$2?) }
    | "MINUS" arg { Ok(String::from("- ") + &$2?) }
    | "NEG" arg { Ok(String::from("! ") + &$2?) }
    | "AP" arg { Ok(String::from("~ ") + &$2?) }
    | "DEFINED" arg { Ok(String::from("defined? ") + &$2?) }
    | primary { Ok($1?) }
    ;
primary -> Result<String, ()>
    : "LBRACKET" compstmt "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | literal { Ok($1?) }
    | variable { Ok($1?) }
    | primary "COLCOL" identifier { Ok($1? + "::" + &$3?) }
    | "COLCOL" identifier { Ok(String::from("::") + &$2?) }
    | primary "LSQUARE" args_opt "RSQUARE" { Ok($1? + "[" + &$3? + "]") }
    | "LSQUARE" args_comma_opt "RSQUARE" { Ok(String::from("[") + &$2? + "]") }
    | "LCURLY" args_assocs_comma_opt "RCURLY" { Ok(String::from("{") + &$2? + "}") }
    | "RETURN" call_args_brak_opt { Ok(String::from("return ") + &$2?) }
    | "YIELD" call_args_brak_opt { Ok(String::from("yield ") + &$2?) }
    | "DEFINED" "LBRACKET" arg "RBRACKET" { Ok(String::from("defined?(") + &$3? + ")") }
    | function { Ok($1?) }
    | function "LCURLY" block_var_opt compstmt "RCURLY" { Ok($1? + "{" + &$3? + &$4? + "}\n") }
    | "IF" expr then compstmt elseif_rep else_opt "END" { Ok(String::from("if ") + &$2? + " " + &$3? + &$4? + &$5? + &$6? + "end\n") }
    | "UNLESS" expr then compstmt else_opt "END" { Ok(String::from("unless ") + &$2? + " " + &$3? + &$4? + &$5? + "end\n") }
    | "WHILE" expr do compstmt "END" { Ok(String::from("while ") + &$2? + " " + &$3? + &$4? + "end\n") }
    | "UNTIL" expr do compstmt "END" { Ok(String::from("until ") + &$2? + " " + &$3? + &$4? + "end\n") }
    | "CASE" compstmt when_rep else_opt "END" { Ok(String::from("case ") + &$2? + &$3? + &$4? + "end\n") }
    | "FOR" block_var "IN" expr do compstmt "END" { Ok(String::from("for ") + &$2? + " in " + &$4? + " " + &$5? + &$6? + "end\n") }
    | "BEGIN" compstmt rescue_rep else_opt ensure_opt "END" { Ok(String::from("begin ") + &$2? + &$3? + &$4? + &$5? + "end\n") }
    | "CLASS" identifier "LT" identifier compstmt "END" { Ok(String::from("class ") + &$2? + " < " + &$4? + &$5? + "end\n") }
    | "CLASS" identifier compstmt "END" { Ok(String::from("class ") + &$2? + &$3? + "end\n") }
    | "MODULE" identifier compstmt "END" { Ok(String::from("module ") + &$2? + &$3? + "end\n") }
    | "DEF" fname argdecl compstmt "END" { Ok(String::from("def ") + &$2? + " " + &$3? + &$4? + "end\n") }
    | "DEF" identifier argdecl compstmt "END" { Ok(String::from("def ") + &$2? + " " + &$3? + &$4? + "end\n") } // redundant with previous rule, but necessary for this grammar.
    | "DEF" singleton "DOT" fname argdecl compstmt "END" { Ok(String::from("def ") + &$2? + "." + &$4? + &$5? + &$6? + "end\n") }
    | "DEF" singleton "COLCOL" fname argdecl compstmt "END" { Ok(String::from("def ") + &$2? + "::" + &$4? + " " + &$5? + &$6? + "end\n") }
    ;
then -> Result<String, ()>
    : term { Ok($1?) }
    | "THEN" { Ok(String::from("then"))}
    | term "THEN" { Ok($1? + " then") }
    ;
do -> Result<String, ()>
    : term { Ok($1?) }
    | "DO" { Ok(String::from("do"))}
    | term "DO" { Ok($1? + " do") }
    ;
block_var -> Result<String, ()>
    : lhs { Ok($1?) }
    | variable { Ok($1?) } // redundant rule with previous rule; forcing Yacc to not ignore it.
    | mlhs { Ok($1?) }
    ;
mlhs -> Result<String, ()>
    : mlhs_item "COMMA" mlhs_items_opt "STAR" lhs { Ok($1? + ", " + &$3? + " * " + &$5?) }
    | mlhs_item "COMMA" mlhs_items_opt "STAR" variable { Ok($1? + ", " + &$3? + " * " + &$5?) } // redundant rule with previous rule; forcing Yacc to not ignore it.
    | mlhs_item "COMMA" mlhs_items_opt "STAR" { Ok($1? + ", " + &$3? + " *") }
    | mlhs_item "COMMA" mlhs_items_opt { Ok($1? + ", " + &$3?) }
    | "STAR" lhs { Ok(String::from("* ") + &$2?)}
    | "STAR" variable { Ok(String::from("* ") + &$2?)} // redundant rule with previous rule; forcing Yacc to not ignore it.
    ;
mlhs_item -> Result<String, ()>
    : lhs { Ok($1?) }
    | "LBRACKET" mlhs "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    ;
lhs -> Result<String, ()>
    : primary "LSQUARE" args_opt "RSQUARE" { Ok($1? + "[" + &$3? + "]") }
    | literal "LSQUARE" args_opt "RSQUARE" { Ok($1? + "[" + &$3? + "]") } // redundant rule with previous rule; forcing Yacc to not ignore it.
    | primary "DOT" identifier { Ok($1? + "." + &$3?) }
    | varname { Ok($1?) } // variable substitued with varname | "NIL" | "SELF", otherwise yacc ignores the rule
    | "NIL" { Ok(String::from("nil")) }
    | "SELF" { Ok(String::from("self")) }
    ;
mrhs -> Result<String, ()>
    : args star_arg { Ok($1? + &$2?) }
    | "STAR" arg { Ok(String::from("* ") + &$2?)}
    ;
call_args -> Result<String, ()>
    : args { Ok($1?) }
    | args assocs_opt star_arg amp_arg { Ok($1? + &$2? + &$3? + &$4?) }
    | assocs star_arg amp_arg { Ok($1? + &$2? + &$3?) }
    | "STAR" arg amp_arg { Ok(String::from("*") + &$2? + &$3?)}
    | "AMP" arg { Ok(String::from("&") + &$2?)}
    | command { Ok($1?) }
    ;
args -> Result<String, ()>
    : arg { Ok($1?) }
    | arg "COMMA" args { Ok($1? + ", " + &$3?) }
    ;
argdecl -> Result<String, ()>
    : "LBRACKET" arglist "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | arglist term { Ok($1? + &$2?) }
    ;
arglist -> Result<String, ()>
    : identifier identifier_rep star_id amp_id { Ok($1? + &$2? + &$3? + &$4?) }
    | "STAR" identifier amp_id { Ok(String::from("*") + &$2? + &$3?)}
    | "AMP" identifier { Ok(String::from("&") + &$2?)}
    | { Ok(String::from("")) }
    ;
singleton -> Result<String, ()>
    : variable { Ok($1?) }
    | "LBRACKET" expr "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    ;
assocs -> Result<String, ()>
    : assoc "COMMA" assocs { Ok($1? + ", " + &$3?) }
    | assoc { Ok($1?) }
    ;
assoc -> Result<String, ()>
    : arg "EQARROW" arg { Ok($1? + "=>" + &$3?) }
    ;
variable -> Result<String, ()>
    : varname { Ok($1?) }
    | "NIL"{ Ok(String::from("nil")) }
    | "SELF"{ Ok(String::from("self")) }
    ;
literal -> Result<String, ()>
    : "NUMERIC" { Ok(numeric($1, $lexer)) }
    | symbol { Ok($1?) }
    | "STRING" { Ok(string($1, $lexer)) }
    | "STRING2" { Ok(string2($1, $lexer)) }
    | here_doc { Ok($1?) }
    | "REGEXP" { Ok(regexp($1, $lexer)) }
    ;

/* Auxialaries */

term_expr_rep -> Result<String, ()>
    : term expr term_expr_rep { Ok($1? + "\n" + &$2? + &$3?) }
    | { Ok(String::from("")) }
    ;
term_opt -> Result<String, ()>
    : term { Ok($1?) }
    | { Ok(String::from("")) }
    ;
block_var_opt -> Result<String, ()>
    : "VBAR" block_var "VBAR" { Ok(String::from("| ") + &$2? + " |") }
    | "VBAR" "VBAR" { Ok(String::from("| |")) }
    | { Ok(String::from("")) }
    ;
block_opt -> Result<String, ()>
    : "DO" block_var_opt compstmt "END" { Ok(String::from(" do ") + &$2? + &$3? + "end") }
    | { Ok(String::from("")) }
    ;
call_args_brak_opt -> Result<String, ()>
    : "LBRACKET" call_args_opt "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | { Ok(String::from("")) }
    ;
call_args_opt -> Result<String, ()>
    : call_args { Ok($1?) }
    | { Ok(String::from("")) }
    ;
args_opt -> Result<String, ()>
    : args { Ok($1?) }
    | { Ok(String::from("")) }
    ;
args_comma_opt -> Result<String, ()>
    : args comma_opt { Ok($1? + &$2?) }
    | { Ok(String::from("")) }
    ;
comma_opt -> Result<String, ()>
    : "COMMA" { Ok(String::from(",")) }
    | { Ok(String::from("")) }
    ;
args_assocs_comma_opt -> Result<String, ()>
    : args { Ok($1?) }
    | assocs comma_opt { Ok($1? + &$2?) }
    | { Ok(String::from("")) }
    ;
elseif_rep -> Result<String, ()>
    : "ELSEIF" expr then compstmt elseif_rep { Ok(String::from("\nelsif ") + &$2? + " " + &$3? + &$4? + &$5?) }
    | { Ok(String::from("")) }
    ;
else_opt -> Result<String, ()>
    : "ELSE" compstmt { Ok(String::from("\nelse") + &$2?) }
    | { Ok(String::from("")) }
    ;
rescue_rep -> Result<String, ()>
    : "RESCUE" args_opt do compstmt rescue_rep { Ok(String::from("\nrescue ") + &$2? + " " + &$3? + &$4? + &$5?) }
    | { Ok(String::from("")) }
    ;
ensure_opt -> Result<String, ()>
    : "ENSURE" compstmt { Ok(String::from("\nensure") + &$2?) }
    | { Ok(String::from("")) }
    ;
when_rep -> Result<String, ()>
    : "WHEN" mrhs then compstmt { Ok(String::from("when ") + &$2? + " " + &$3? + &$4?) }
    | "WHEN" mrhs then compstmt when_rep { Ok(String::from("when ") + &$2? + " " + &$3? + &$4? + &$5?) }
    ;
mlhs_items_opt -> Result<String, ()>
    : mlhs_item_rep { Ok($1?) }
    | { Ok(String::from("")) }
    ;
mlhs_item_rep -> Result<String, ()>
    : mlhs_item { Ok($1?) }
    | mlhs_item "COMMA" mlhs_item_rep { Ok($1? + ", " + &$3?) }
    ;
assocs_opt -> Result<String, ()>
    : "COMMA" assocs { Ok(String::from(", ") + &$2?) }
    | { Ok(String::from("")) }
    ;
star_arg -> Result<String, ()>
    : "COMMA_STAR" arg { Ok(String::from(",*") + &$2?) }
    | { Ok(String::from("")) }
    ;
amp_arg -> Result<String, ()>
    : "COMMA_AMP" arg { Ok(String::from(",&") + &$2?) }
    | { Ok(String::from("")) }
    ;
star_id -> Result<String, ()>
    : "COMMA_STAR" identifier { Ok(String::from(",*") + &$2?) }
    | { Ok(String::from("")) }
    ;
amp_id -> Result<String, ()>
    : "COMMA_AMP" identifier { Ok(String::from(",&") + &$2?) }
    | { Ok(String::from("")) }
    ;
identifier_rep -> Result<String, ()>
    : "COMMA" identifier identifier_rep { Ok(String::from(", ") + &$2? + &$3?) }
    | { Ok(String::from("")) }
    ;
varname -> Result<String, ()>
    : global { Ok($1?) }
    | "AT" identifier { Ok(String::from("@") + &$2?) }
    | identifier { Ok($1?) }
    ;

/* Tokens */

op_asgn -> Result<String, ()>
    : "PLUSEQ" { Ok(String::from("+=")) }
    | "MINUSEQ" { Ok(String::from("-=")) }
    | "STAREQ" { Ok(String::from("*=")) }
    | "DIVEQ" { Ok(String::from("/=")) }
    | "MODEQ" { Ok(String::from("%=")) }
    | "DSTAREQ" { Ok(String::from("**=")) }
    | "AMPEQ" { Ok(String::from("&=")) }
    | "VBAREQ" { Ok(String::from("|=")) }
    | "CIRCEQ" { Ok(String::from("^=")) }
    | "DLTEQ" { Ok(String::from("<<=")) }
    | "DGTEQ" { Ok(String::from(">>=")) }
    | "DAMPEQ" { Ok(String::from("&&=")) }
    | "DVBAREQ" { Ok(String::from("||=")) }
    ;
op_bin -> Result<String, ()>
    : "DOTDOT" { Ok(String::from("..")) }
    | "DOTDOTDOT" { Ok(String::from("...")) }
    | "PLUS" { Ok(String::from("+")) }
    | "MINUS" { Ok(String::from("-")) }
    | "STAR" { Ok(String::from("*")) }
    | "FSLASH" { Ok(String::from("/")) }
    | "MOD" { Ok(String::from("%")) }
    | "DSTAR" { Ok(String::from("**")) }
    | "VBAR" { Ok(String::from("|")) }
    | "CIRC" { Ok(String::from("^")) }
    | "AMP" { Ok(String::from("&")) }
    | "DARROW" { Ok(String::from("<=>")) }
    | "GT" { Ok(String::from(">")) }
    | "GTEQ" { Ok(String::from(">=")) }
    | "LT" { Ok(String::from("<")) }
    | "LTEQ" { Ok(String::from("<=")) }
    | "EQEQ" { Ok(String::from("==")) }
    | "EQEQEQ" { Ok(String::from("===")) }
    | "NOTEQ" { Ok(String::from("!=")) }
    | "EQAP" { Ok(String::from("=~")) }
    | "NOTAP" { Ok(String::from("!~")) }
    | "DLT" { Ok(String::from("<<")) }
    | "DGT" { Ok(String::from(">>")) }
    | "DAMP" { Ok(String::from("&&")) }
    | "DVBAR" { Ok(String::from("||")) }
    ;
fname_op -> Result<String, ()>
    : "DOTDOT" { Ok(String::from("..")) }
    | "VBAR" { Ok(String::from("|")) }
    | "CIRC" { Ok(String::from("^")) }
    | "AMP" { Ok(String::from("&")) }
    | "DARROW" { Ok(String::from("<=>")) }
    | "EQEQ" { Ok(String::from("==")) }
    | "EQEQEQ" { Ok(String::from("===")) }
    | "EQAP" { Ok(String::from("=~")) }
    | "GT" { Ok(String::from(">")) }
    | "GTEQ" { Ok(String::from(">=")) }
    | "LT" { Ok(String::from("<")) }
    | "LTEQ" { Ok(String::from("<=")) }
    | "PLUS" { Ok(String::from("+")) }
    | "MINUS" { Ok(String::from("-")) }
    | "STAR" { Ok(String::from("*")) }
    | "FSLASH" { Ok(String::from("/")) }
    | "MOD" { Ok(String::from("%")) }
    | "DSTAR" { Ok(String::from("**")) }
    | "DLT" { Ok(String::from("<<")) }
    | "DGT" { Ok(String::from(">>")) }
    | "AP" { Ok(String::from("~")) }
    | "PLUSAT" { Ok(String::from("+@")) }
    | "MINUSAT" { Ok(String::from("-@")) }
    | "LSQUARE" "RSQUARE" { Ok(String::from("[]")) }
    | "LSQUARE" "RSQUARE" "EQ" { Ok(String::from("[]=")) }
    ;
term -> Result<String, ()>
    : "SEMICOL" { Ok(String::from(";")) }
    |  { Ok(String::from("\n")) }
    ;
symbol -> Result<String, ()>
    : "COL" fname { Ok(String::from(":") + &$2?) }
    | "COL" varname { Ok(String::from(":") + &$2?) }
    ;
fname -> Result<String, ()>
    : identifier { Ok($1?) }
    | fname_op { Ok($1?) }
    ;
operation -> Result<String, ()>
    : identifier { Ok($1?) }
    | identifier "NEG" { Ok($1? + "!") }
    | identifier "OPT" { Ok($1? + "?") }
    ;

global -> Result<String, ()>
    : "GLOBAL" { Ok(global($1, $lexer)) }
    ;
identifier -> Result<String, ()>
    : "IDENTIFIER" { Ok(identifier($1, $lexer)) }
    ;
here_doc -> Result<String, ()>
    : "DLT" "HEREDOC" { Ok(String::from("<<") + &heredoc($2, $lexer)) }
    ;
unmatched -> ():
  "UNMATCHED" { } 
  ;

%%

fn identifier<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("var_a")
  }
}

fn string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("'abc'")
  }
}

fn string2<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("%Q{123}")
  }
}

fn global<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\u{0024}abc")
  }
}

fn numeric<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("123")
  }
}

fn regexp<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("/hello/i")
  }
}

fn heredoc<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("EOF\nabc\nEOF")
  }
}
