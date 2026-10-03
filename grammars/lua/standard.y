%expect-unused unmatched "UNMATCHED"
%start block
%epp AND "and"
%epp BREAK "break"
%epp DO "do"
%epp ELSE "else"
%epp ELSEIF "elseif"
%epp END "end"
%epp FALSE "false"
%epp FOR "for"
%epp FUNCTION "function"
%epp GOTO "goto"
%epp IF "if"
%epp IN "in"
%epp LOCAL "local"
%epp NIL "nil"
%epp NOT "not"
%epp OR "or"
%epp REPEAT "repeat"
%epp RETURN "return"
%epp THEN "then"
%epp TRUE "true"
%epp UNTIL "until"
%epp WHILE "while"
%epp NAME "<Name>"
%epp PLUS "+"
%epp MINUS "-"
%epp STAR "*"
%epp FSLASH "/"
%epp MOD "%"
%epp CARET "^"
%epp HASH "#"
%epp AMP "&"
%epp TILDE "~"
%epp PIPE "|"
%epp LTLT "<<"
%epp GTGT ">>"
%epp FSFS "//"
%epp EQEQ "=="
%epp NOTEQ "~="
%epp LE "<="
%epp GE ">="
%epp LT "<"
%epp GT ">"
%epp EQ "="
%epp LBRACKET "("
%epp RBRACKET ")"
%epp LCURLY "{"
%epp RCURLY "}"
%epp LSQUARE "["
%epp RSQUARE "]"
%epp COLCOL "::"
%epp SEMICOL ";"
%epp COL ":"
%epp COMMA ","
%epp SHORT_STR '"<String>"'
%epp LONG_STR "[=[<String>]=]"
%epp NUMERAL "<Numeral>"
%epp DOT "."
%epp DOTDOT ".."
%epp DOTDOTDOT "..."
%expect 51
%expect-rr 1
%%
block -> Result<String, ()>
    : statlist retstatopt { Ok(String::from("\n") + &$1? + &$2?) };
statlist -> Result<String, ()>
    : stat statlist { Ok($1? + "\n" + &$2?) }
    | stat { Ok($1? + "\n") }
    ;
stat -> Result<String, ()>
    : "SEMICOL" { Ok(String::from(";")) }
    | varlist "EQ" explist { Ok($1? + "=" + &$3?) }
    | functioncall { Ok($1?) }
    | label { Ok($1?) }
    | "BREAK" { Ok(String::from("break")) }
    | "GOTO" "NAME" { Ok(String::from("goto") + &name($2, $lexer)) }
    | "DO" block "END" { Ok(String::from("do\n") + &$2? + "\nend") }
    | "WHILE" exp "DO" block "END" { Ok(String::from("while ") + &$2? + "\ndo\n" + &$4? + "\nend") }
    | "REPEAT" block "UNTIL" exp { Ok(String::from("repeat") + &$2? + "\nuntil " + &$4?) }
    | "IF" exp "THEN" block elselistopt elseopt "END" { Ok(String::from("if ") + &$2? + " then" + &$4? + &$5? + &$6? + "\nend") }
    | "FOR" "NAME" "EQ" exp "COMMA" explist "DO" block "END" { Ok(String::from("for") + &name($2, $lexer) + "=" + &$4? + "," + &$6? + "\ndo" + &$8? + "end") }
    | "FOR" namelist "IN" explist "DO" block "END" { Ok(String::from("for") + &$2? + " in " + &$4? + "\ndo" + &$6? + "end") }
    | "FUNCTION" funcname funcbody { Ok(String::from("function") + &$2? + &$3?) }
    | "LOCAL" "FUNCTION" "NAME" funcbody { Ok(String::from("local") + " function" + &name($3, $lexer) + &$4?) }
    | "LOCAL" attnamelist eqexplistopt { Ok(String::from("local") + &$2? + &$3?) }
    ;
attnamelist -> Result<String, ()>
    : attnamelist "COMMA" NAME attrib { Ok($1? + "," + &name($3, $lexer) + &$4?) }
    | NAME attrib { Ok(name($1, $lexer) + &$2?) }
    ;
attrib -> Result<String, ()>
    : "LT" "NAME" "GT" { Ok(String::from("<") + &name($2, $lexer) + ">") }
    | { Ok(String::from("")) }
    ;
retstatopt -> Result<String, ()>
    : "RETURN" explistopt semicolonopt { Ok(String::from("return ") + &$2? + &$3? + "\n") }
    | { Ok(String::from("")) }
    ;
label -> Result<String, ()>
    : "COLCOL" "NAME" "COLCOL" { Ok(String::from("\n::") + &name($2, $lexer) + "::\n") }
    ;
funcname -> Result<String, ()>
    : "NAME" funcnamelist { Ok(name($1, $lexer) + &$2?) }
    | "NAME" funcnamelist "COL" "NAME" { Ok(name($1, $lexer) + &$2? + ":" + &name($4, $lexer)) }
    ;
funcnamelist -> Result<String, ()>
    : funcnamelist "DOT" "NAME" { Ok($1? + "." + &name($3, $lexer)) }
    | { Ok(String::from("")) }
    ;
varlist -> Result<String, ()>
    : varlist "COMMA" var { Ok($1? + "," + &$3?) }
    | var { Ok($1?) }
    ;
var  -> Result<String, ()>: "NAME" { Ok(name($1, $lexer)) }
    | prefixexp "LSQUARE" exp "RSQUARE" { Ok($1? + "[" + &$3? + "]") }
    | prefixexp "DOT" "NAME" { Ok($1? + "." + &name($3, $lexer)) }
    ;
explist -> Result<String, ()>
    : explist "COMMA" exp { Ok($1? + "," + &$3?) }
    | exp { Ok($1?) }
    ;
explistopt -> Result<String, ()>
    : explist { Ok($1?) }
    | { Ok(String::from("")) }
    ;
eqexplistopt -> Result<String, ()>
    : "EQ" explist { Ok(String::from("=") + &$2?) }
    | { Ok(String::from("")) }
    ;
elselistopt -> Result<String, ()>
    : elselist { Ok($1?) }
    | { Ok(String::from("")) }
    ;
elselist -> Result<String, ()>
    : elselist "ELSEIF" exp "THEN" block { Ok($1? + " elseif" + &$3? + " then" + &$5?) }
    | "ELSEIF" exp "THEN" block { Ok(String::from(" elseif") + &$2? + " then" + &$4?) }
    ;
elseopt -> Result<String, ()>
    : "ELSE" block { Ok(String::from(" else") + &$2?) }
    | { Ok(String::from("")) }
    ;
semicolonopt -> Result<String, ()>
    : "SEMICOL" { Ok(String::from(";")) }
    | { Ok(String::from("")) }
    ;
namelist -> Result<String, ()>
    : namelist "COMMA" "NAME"{ Ok($1? + "," + &name($3, $lexer)) }
    | "NAME" { Ok(name($1, $lexer)) }
    ;
// Lua has 12 precedence levels which we encode as exp[0-11] (where "exp0" is,
// for convenience, simply called "exp").
exp -> Result<String, ()>
    : "NIL" { Ok(String::from("nil")) }
    | "FALSE" { Ok(String::from("false")) }
    | "TRUE" { Ok(String::from("true")) }
    | "NUMERAL" { Ok(number($1, $lexer)) }
    | literalstring { Ok($1?) }
    | "DOTDOTDOT" { Ok(String::from("...")) }
    | functiondef { Ok($1?) }
    | prefixexp { Ok($1?) }
    | tableconstructor { Ok($1?) }
    | exp binop exp { Ok($1? + &$2? + &$3?) }
    | unop exp { Ok($1? + &$2?) }
    ;
binop -> Result<String, ()>
    : "STAR" { Ok(String::from("*")) }
    | "FSLASH" { Ok(String::from("/")) }
    | "FSFS" { Ok(String::from("//")) }
    | "MOD" { Ok(String::from("%")) }
    | "CARET" { Ok(String::from("^")) }
    | "PLUS" { Ok(String::from("+")) }
    | "MINUS" { Ok(String::from("-")) }
    | "DOTDOT" { Ok(String::from(" .. ")) }
    | "LTLT" { Ok(String::from("<<")) }
    | "GTGT" { Ok(String::from(">>")) }
    | "AMP" { Ok(String::from("&")) }
    | "TILDE" { Ok(String::from("~")) }
    | "PIPE" { Ok(String::from("|")) }
    | "LT" { Ok(String::from("<")) }
    | "GT" { Ok(String::from(">")) }
    | "LE" { Ok(String::from("<=")) }
    | "GE" { Ok(String::from(">=")) }
    | "NOTEQ" { Ok(String::from("~=")) }
    | "EQEQ" { Ok(String::from("==")) }
    | "AND" { Ok(String::from(" and ")) }
    | "OR" { Ok(String::from(" or ")) }
    ;
unop -> Result<String, ()>
    : "NOT" { Ok(String::from(" not ")) }
    | "HASH" { Ok(String::from("#")) }
    | "MINUS" { Ok(String::from("-")) }
    | "TILDE" { Ok(String::from("~")) }
    ;
prefixexp -> Result<String, ()>
    : var { Ok($1?) }
    | functioncall { Ok($1?) }
    | "LBRACKET" exp "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    ;
functioncall -> Result<String, ()>
    : prefixexp args { Ok($1? + &$2?) }
    | functioncall args { Ok($1? + &$2?) }
    | prefixexp "COL" "NAME" args { Ok($1? + ":" + &name($3, $lexer) + &$4?) }
    ;
args -> Result<String, ()>: "LBRACKET" explistopt "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | tableconstructor { Ok($1?) }
    | literalstring { Ok($1?) }
    ;
functiondef -> Result<String, ()>
    : "FUNCTION" funcbody { Ok(String::from(" function") + &$2?) }
    ;
funcbody -> Result<String, ()>
    : "LBRACKET" parlist "RBRACKET" block "END" { Ok(String::from("(") + &$2? + ")" + &$4? + " end\n") }
    ;
parlist -> Result<String, ()>
    : namelist "COMMA" "DOTDOTDOT" { Ok($1? + "," + "...") }
    | namelist { Ok($1?) }
    | "DOTDOTDOT" { Ok(String::from("...")) }
    | { Ok(String::from("")) }
    ;
tableconstructor -> Result<String, ()>
    : "LCURLY" fieldlistopt "RCURLY" { Ok(String::from("{") + &$2? + "}") }
    ;
fieldlistopt -> Result<String, ()>
    : fieldlist fieldsepopt { Ok($1? + &$2?) }
    | { Ok(String::from("")) }
    ;
fieldlist -> Result<String, ()>
    : fieldlist fieldsep field { Ok($1? + &$2? + &$3?) }
    | field { Ok($1?) }
    ;
field -> Result<String, ()>
    : "LSQUARE" exp "RSQUARE" "EQ" exp { Ok(String::from("[") + &$2? + "]" + "=" + &$5?) }
    | "NAME" "EQ" exp { Ok(name($1, $lexer) + "=" + &$3?) }
    | exp { Ok($1?) }
    ;
fieldsep -> Result<String, ()>
    : "COMMA" { Ok(String::from(",")) }
    | "SEMICOL" { Ok(String::from(";")) }
    ;
fieldsepopt -> Result<String, ()>
    : fieldsep { Ok($1?) }
    | { Ok(String::from("")) }
    ;
literalstring -> Result<String, ()>
    : "SHORT_STR" { Ok(short_string($1, $lexer)) }
    | "LONG_STR" { Ok(long_string($1, $lexer)) }
    ;
unmatched -> ():
  "UNMATCHED" { } 
  ;
%%

use rand::Rng;

fn name<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from(" ") + i_lexer.span_str(val.span()),
        Err(_) => String::from(" var_y")
  }
}

fn number<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("") + &rand::thread_rng().gen_range(-100.9..100.9).to_string()
  }
}

fn short_string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\"abc\"")
  }
}

fn long_string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("[==[abc]==]")
  }
}
