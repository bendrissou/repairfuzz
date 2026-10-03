%expect-unused unmatched "UNMATCHED"
%start program

%expect-rr 1011
%expect 272

%%
program -> Result<String, ()>
    : compstmt { Ok($1?) }
    ;
compstmt -> Result<String, ()>
    : stmt compstmt { Ok($1? + "\n" + &$2?) }
    | stmt { Ok($1? + "\n") }
    ;
stmt -> Result<String, ()>
    : "UNDEF" identifier { Ok(String::from("undef ") + &$2?) }
    | "INCLUDE" identifier ns_member { Ok(String::from("include ") + &$2?) }
    | "ALIAS" identifier identifier { Ok(String::from("undef ") + &$2? + &$3?) }
    | stmt "IF" expr { Ok($1? + " if " + &$3?) }
    | stmt "WHILE" expr { Ok($1? + " while " + &$3?) }
    | stmt "UNLESS" expr { Ok($1? + " unless " + &$3?) }
    | stmt "UNTILL" expr { Ok($1? + " untill " + &$3?) }
    | "BEGIN" "LCURLY" compstmt "RCURLY" { Ok(String::from("begin ") + "{" + &$3? + "}") }
    | function do block_var_opt compstmt "END" { Ok($1? + &$2? + &$3? + &$4? + "end") }
    | obj_list op_asgn expr do block_var_opt compstmt "END" { Ok($1? + &$2? + &$3? + &$4? + &$5? + &$6? + "end") }
    | obj_list op_asgn expr { Ok($1? + &$2? + &$3?) }
    | identifier array_item op_asgn expr { Ok($1? + &$2? + &$3? + &$4?) }
    | "RETURN" call_args_opt { Ok(String::from("return ") + &$2?) }
    | "YIELD" call_args_opt { Ok(String::from("yield ") + &$2?) }
    | "WHILE" expr compstmt "END" { Ok(String::from("while\n") + &$2? + &$3? + "end") }
    | "LBRACKET" arg "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | function { Ok($1?) }
    | "LOOP" do compstmt "END" { Ok(String::from("loop ") + &$2? + &$3? + "end") }
    | "LOOP" "LCURLY" compstmt "RCURLY" { Ok(String::from("loop {") + &$3? + "}") }
    | "IF" expr then compstmt elseif_rep else_opt "END" { Ok(String::from("if ") + &$2? + &$3? + &$4? + &$5? + &$6? + "end") }
    | "UNLESS" expr then compstmt else_opt "END" { Ok(String::from("unless ") + &$2? + &$3? + &$4? + &$5? + "end") }
    | "UNTILL" expr do compstmt "END" { Ok(String::from("untill ") + &$2? + &$3? + &$4? + "end") }
    | "CASE" compstmt when_rep else_opt "END" { Ok(String::from("case\n") + &$2? + &$3? + &$4? + "end") }
    | "FOR" identifier identifier_rep "IN" expr do compstmt "END" { Ok(String::from("for ") + &$2? + &$3? + " in " + &$5? + &$6? + &$7? + "end") }
    | "BEGIN" compstmt rescue_rep else_opt ensure_opt "END" { Ok(String::from("begin ") + &$2? + &$3? + &$4? + &$5? + "end") }
    | "BEGIN" obj_list op_asgn expr do compstmt rescue_rep else_opt ensure_opt "END" "END" { Ok(String::from("begin ") + &$2? + &$3? + &$4? + &$5? + &$6? + &$7? + &$8? + &$9? + "end" + "\nend") }
    | obj_list op_asgn expr do compstmt rescue_rep else_opt ensure_opt "END" { Ok($1? + &$2? + &$3? + &$4? + &$5? + &$6? + &$7? + &$8? + "end") }
    | "CLASS" identifier ns_member "LT" identifier ns_member compstmt "END" { Ok(String::from("class ") + &$2? + &$3? + " < " + &$5? + &$6? + "\n" + &$7? + "end") }
    | "CLASS" identifier ns_member compstmt "END" { Ok(String::from("class ") + &$2? + &$3? + "\n" + &$4? + "end") }
    | "MODULE" identifier ns_member compstmt "END" { Ok(String::from("module ") + &$2? + &$3? + "\n" + &$4? + "end") }
    | "DEF" identifier argdecl compstmt "END" { Ok(String::from("def ") + &$2? + &$3? + "\n" + &$4? + "end") }
    | "DEF" singleton "DOT" identifier argdecl compstmt "END" { Ok(String::from("def ") + &$2? + "." + &$4? + &$5? + &$6? + "end") }
    | "DEF" singleton "COLCOL" identifier argdecl compstmt "END" { Ok(String::from("def ") + &$2? + "::" + &$4? + &$5? + &$6? + "end") }
    | "REQUIRE" "STRING" { Ok(String::from("require ") + &string($2, $lexer)) }
    ;
function -> Result<String, ()>
    : identifier call_args_brak_opt { Ok($1? + &$2?) }
    | identifier ns_obj_member { Ok($1? + &$2?) }
    | identifier ns_obj_member literal { Ok($1? + &$2? + " " + &$3?) }
    | identifier ns_obj_member "LBRACKET" call_args_opt "RBRACKET" { Ok($1? + &$2? + "(" + &$4? + ")") }
    | identifier ns_obj_member array_item { Ok($1? + &$2? + " " + &$3?) }
    | "SUPER" call_args_brak_opt { Ok(String::from("super ") + &$2?) }
    | "DEFINED" "OPT" "LBRACKET" identifier ns_obj_member "RBRACKET" { Ok(String::from("defined?(") + &$4? + &$5? + ")") }
    | function "LCURLY" block_var_opt compstmt ensure_opt literal_opt "RCURLY" { Ok($1? + " {" + &$3? + &$4? + &$5? + &$6? + "}") }
    | function "LCURLY" literal_opt "RCURLY" { Ok($1? + " {" + &$3? + "}") }
    | array_item "DOT" function { Ok($1? + "." + &$3?) }
    | "LBRACKET" expr "RBRACKET" "DOT" function { Ok(String::from("(") + &$2? + ")." + &$5?) }
    ;
expr -> Result<String, ()>
    : "NOT" expr { Ok(String::from("not ") + &$2?) }
    | expr op_bin expr { Ok($1? + &$2? + &$3?) }
    | function { Ok($1?) }
    | "AT" function { Ok(String::from("@") + &$2?) }
    | literal "DOT" function { Ok($1? + "." + &$3?) }
    | "LCURLY" args_opt "RCURLY" { Ok(String::from("{") + &$2? + "}") }
    | obj { Ok($1?) }
    | literal { Ok($1?) }
    | array_item { Ok($1?) }
    | "LBRACKET" expr "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | expr "OPT" expr "COL" expr { Ok($1? + "?" + &$3? + ":" + &$5?) }
    ;
arg -> Result<String, ()>
    : expr { Ok($1?) }
    | identifier "COL" type { Ok($1? + ":" + &$3?) }
    | "COL" "STAR" { Ok(String::from(":*")) }
    ;
type -> Result<String, ()>
    : "NIL" { Ok(String::from("nil")) }
    | identifier ns_obj_member { Ok($1? + &$2?) }
    | literal { Ok($1?) }
    | function { Ok($1?) }
    ;
obj -> Result<String, ()>
    : identifier ns_obj_member { Ok($1? + &$2?) }
    | varname array_item { Ok($1? + &$2?) }
    | varname { Ok($1?) }
    ;
arg_list -> Result<String, ()>
    : arg "COMMA" arg_list { Ok($1? + "," + &$3?) }
    | arg "COMMA" { Ok($1? + ",") }
    | arg { Ok($1?) }
    ;
obj_list -> Result<String, ()>
    : obj "COMMA" obj_list { Ok($1? + "," + &$3?) }
    | obj "COMMA" { Ok($1? + ",") }
    | obj { Ok($1?) }
    ;
ns_member -> Result<String, ()>
    : "COLCOL" identifier ns_member { Ok(String::from("::") + &$2? + &$3?) }
    | { Ok(String::from("")) }
    ;
ns_obj_member -> Result<String, ()>
    : "DOT" identifier call_args_brak_opt ns_obj_member { Ok(String::from(".") + &$2? + &$3? + &$4?) }
    | "COLCOL" identifier ns_obj_member { Ok(String::from("::") + &$2? + &$3?) }
    | { Ok(String::from("")) }
    ; 
array_item -> Result<String, ()>
    : "LSQUARE" "RSQUARE" { Ok(String::from("[]")) }
    | "LSQUARE" arg_list "RSQUARE" { Ok(String::from("[") + &$2? + "]") }
    ;
call_args -> Result<String, ()>
    : arg_list { Ok($1?) }
    | "STAR" arg amp_arg { Ok(String::from("*") + &$2? + &$3?) }
    | "AMP" arg { Ok(String::from("&") + &$2?) }
    ;
argdecl -> Result<String, ()>
    : "LBRACKET" arglist "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | { Ok(String::from("")) }
    ;
arglist -> Result<String, ()>
    : arg_def arg_def_rep star_id { Ok($1? + &$2? + &$3?) }
    | "STAR" identifier amp_id { Ok(String::from("*") + &$2? + &$3?) }
    | "AMP" identifier { Ok(String::from("&") + &$2?) }
    | { Ok(String::from("")) }
    ;
arg_def -> Result<String, ()>
    : identifier { Ok($1?) }
    | identifier "COL" type { Ok($1? + ":" + &$3?) }
    | identifier "EQ" type { Ok($1? + "=" + &$3?) }
    ;
arg_def_rep -> Result<String, ()>
    : "COMMA" arg_def arg_def_rep { Ok(String::from(",") + &$2? + &$3?) }
    | "COMMA" "AMP" identifier { Ok(String::from(",&") + &$3?) }
    | { Ok(String::from("")) }
    ;
singleton -> Result<String, ()>
    : variable { Ok($1?) }
    | "LBRACKET" expr "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    ;
amp_arg -> Result<String, ()>
    : "COMMA" "AMP" arg { Ok(String::from(",&") + &$3?) }
    | { Ok(String::from("")) }
    ;
star_id -> Result<String, ()>
    : "COMMA" "STAR" identifier { Ok(String::from(",*") + &$3?) }
    | { Ok(String::from("")) }
    ;
amp_id -> Result<String, ()>
    : "COMMA" "AMP" identifier { Ok(String::from(",&") + &$3?) }
    | { Ok(String::from("")) }
    ;
variable -> Result<String, ()>
    : varname { Ok($1?) }
    | "NIL" { Ok(String::from("nil")) }
    | "SELF" { Ok(String::from("self")) }
    ;


/* Auxialaries */

block_var_opt -> Result<String, ()>
    : "VBAR" identifier identifier_rep "VBAR" { Ok(String::from("|") + &$2? + &$3? + "|") }
    | "VBAR" "STAR" identifier "VBAR" { Ok(String::from("|*") + &$3? + "|") }
    | "VBAR" "VBAR" { Ok(String::from("||")) }
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
    : arg_list { Ok($1?) }
    | { Ok(String::from("")) }
    ;
elseif_rep -> Result<String, ()>
    : "ELSEIF" expr then compstmt elseif_rep { Ok(String::from("elsif ") + &$2? + &$3? + &$4? + &$5?) }
    | { Ok(String::from("")) }
    ;
else_opt -> Result<String, ()>
    : "ELSE" compstmt { Ok(String::from(" else\n") + &$2?) }
    | { Ok(String::from("\n")) }
    ;
rescue_rep -> Result<String, ()>
    : "RESCUE" args_opt "DO" compstmt { Ok(String::from("rescue ") + &$2? + " do " + &$4?) }
    | "RESCUE" args_opt "DO" compstmt rescue_rep { Ok(String::from("rescue ") + &$2? + " do " + &$4? + &$5?) }
    | "RESCUE" identifier ns_obj_member rescue_rep { Ok(String::from("rescue ") + &$2? + &$3? + &$4?) }
    | "RESCUE" args_opt { Ok(String::from("rescue ") + &$2?) }
    | { Ok(String::from("")) }
    ;
ensure_opt -> Result<String, ()>
    : "ENSURE" compstmt { Ok(String::from("rescue ") + &$2?) }
    | { Ok(String::from("")) }
    ;
when_rep -> Result<String, ()>
    : "WHEN" expr then compstmt { Ok(String::from("when ") + &$2? + &$3? + &$4?) }
    | "WHEN" expr then compstmt when_rep { Ok(String::from("when ") + &$2? + &$3? + &$4? + &$5?) }
    ;
identifier_rep -> Result<String, ()>
    : "COMMA" identifier identifier_rep { Ok(String::from(",") + &$2? + &$3?) }
    | { Ok(String::from("")) }
    ;
varname -> Result<String, ()>
    : global { Ok($1?) }
    | "AT" identifier { Ok(String::from("@") + &$2?) }
    | "AT" "AT" identifier { Ok(String::from("@@") + &$3?) }
    | "NEG" identifier { Ok(String::from("!") + &$2?) }
    | identifier { Ok($1?) }
    ;

/* Tokens */

op_asgn -> Result<String, ()>
    : "EQ" { Ok(String::from("=")) }
    | "PLUSEQ" { Ok(String::from("+=")) }
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
    | "APPEND" { Ok(String::from("<<")) }
    | "ANDEQ" { Ok(String::from("&&=")) }
    | "OREQ" { Ok(String::from("||=")) }
    ;
op_bin -> Result<String, ()>
    : "DOTDOT" { Ok(String::from("..")) }
    | "EQARROW" { Ok(String::from("=>")) }
    | "AMP" "AMP" { Ok(String::from("&&")) }
    | "VBAR" "VBAR" { Ok(String::from("||")) }
    | "VBAR" { Ok(String::from("|")) }
    | "CIRC" { Ok(String::from("^")) }
    | "AMP" { Ok(String::from("&")) }
    | "DARROW" { Ok(String::from("<=>")) }
    | "EQEQ" { Ok(String::from("==")) }
    | "EQEQEQ" { Ok(String::from("===")) }
    | "NOTEQ" { Ok(String::from("!=")) }
    | "EQAP" { Ok(String::from("=~")) }
    | "NOTAP" { Ok(String::from("!~")) }
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
    | "PLUSAT" { Ok(String::from("+@")) }
    | "MINUSAT" { Ok(String::from("-@")) }
    | "LSQUARE" "RSQUARE" { Ok(String::from("[]")) }
    | "EMPTYSQUAREEQ" { Ok(String::from("[]=")) }
    ;
literal_opt -> Result<String, ()>
    : term literal { Ok($1? + &$2?) }
    | { Ok(String::from("")) }
    ;
literal -> Result<String, ()>
    : "NUMERIC" { Ok(number($1, $lexer)) }
    | "COL" varname { Ok(String::from(":") + &$2?) }
    | "STRING" { Ok(string($1, $lexer)) }
    | "STRING2" { Ok(string($1, $lexer)) }
    | "REGEXP" { Ok(regex($1, $lexer)) }
    | "NIL" { Ok(String::from("nil")) }
    | "SELF" { Ok(String::from("self")) }
    | "FALSE" { Ok(String::from("false")) }
    ;
then -> Result<String, ()>
    : "THEN" { Ok(String::from(" then\n")) }
    ;
do -> Result<String, ()>
    : "DO" { Ok(String::from(" do\n")) }
    | { Ok(String::from("\n")) }
    ;
term -> Result<String, ()>
    : "SEMICOL" { Ok(String::from(";")) }
    | { Ok(String::from("")) }
    ;

global -> Result<String, ()>
    : "DOLLAR" identifier { Ok(dollar($1, $lexer) + &$2?) }
    | "ENV_VAR" { Ok(String::from("A")) }
    | "DOLLAR" "MINUS" "CHAR" { Ok(dollar($1, $lexer) + "-" + "A") }
    ;
identifier -> Result<String, ()>
    : "IDENTIFIER" { Ok(identifier($1, $lexer)) }
    | "IDENTIFIER" "OPT" { Ok(identifier($1, $lexer) + "?") }
    ;
unmatched -> ():
  "UNMATCHED" { } 
  ;

%%

use rand::Rng;

fn identifier<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("var_y")
  }
}

fn number<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("") + &rand::thread_rng().gen_range(-100.9..100.9).to_string()
  }
}

fn string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\"123123ABCASD\"")
  }
}

fn regex<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("/^(#|$)/")
  }
}

fn dollar<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("$")
  }
}