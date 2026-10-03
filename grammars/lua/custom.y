%expect-unused unmatched "UNMATCHED"
%start program
%epp AND "and"
%epp BREAK "break"
%epp DO "do"
%epp ELSE "else"
%epp END "end"
%epp FALSE "false"
%epp FOR "for"
%epp FUNCTION "function"
%epp GOTO "goto"
%epp IF "if"
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
%expect-rr 13
%expect 127

%%
program -> Result<String, ()>
    : stat program { Ok($1? + "\n" + &$2?) }
    | { Ok(String::from("")) }
    ;
stat -> Result<String, ()>
    : "SEMICOL" { Ok(String::from(";")) }
    | { Ok(String::from("")) }
    | "BREAK" { Ok(String::from("break")) }
    | var "EQ" expr { Ok($1? + " = " + &$3?) }
    | "LOCAL" varlist "EQ" explist { Ok(String::from("local ") + &$2? + " = " + &$4?) }
    | function { Ok($1?) }
    | coroutine { Ok($1?) }
    | conditional { Ok($1?) }
    | loop { Ok($1?) }
    | "RETURN" explist { Ok(String::from("return ") + &$2?) }
    | "GOTO" labelname { Ok(String::from("goto ") + &$2?) }
    | "COLCOL" labelname "COLCOL" { Ok(String::from("::") + &$2? + "::") }
    ;
labelname -> Result<String, ()>
    : "LABELA" { Ok(String::from("labela")) }
    | "LABELB" { Ok(String::from("labelb")) }
    ;
function -> Result<String, ()>
    : funcdef "LBRACKET" function_args "RBRACKET" program "END" { Ok($1? + "(" + &$3? + ")" + &$5? + "\nend") }
    ;
funcdef -> Result<String, ()>
    : "FUNCTION" var "DOT" identifier { Ok(String::from("function ") + &$2? + "." + &$4?) }
    | "FUNCTION" var "COL" identifier { Ok(String::from("function ") + &$2? + ":" + &$4?) }
    | "FUNCTION" identifier { Ok(String::from("function ") + &$2?) }
    ;
lambda -> Result<String, ()>
    : "FUNCTION" "LBRACKET" function_args "RBRACKET" program "END" { Ok(String::from("function (") + &$3? + ") " + &$5? + " end") }
    ;
function_args -> Result<String, ()>
    : { Ok(String::from("")) }
    | function_arglist { Ok($1?) }
    ;
function_arglist -> Result<String, ()>
    : var "COMMA" function_arglist { Ok($1? + ", " + &$3?) }
    | var { Ok($1?) }
    | "DOTDOTDOT" { Ok(String::from("...")) }
    ;
coroutine -> Result<String, ()>
    : var "EQ" "COROUTINE" "DOT" "CREATE" "LBRACKET" lambda "RBRACKET" { Ok($1? + " = coroutine.create(" + &$7? + ")") }
    | var "EQ" "COROUTINE" "DOT" "WRAP" "LBRACKET" lambda "RBRACKET" { Ok($1? + " = coroutine.wrap(" + &$7? + ")") }
    | "COROUTINE" "DOT" "RESUME" "LBRACKET" var "COMMA" args "RBRACKET" { Ok(String::from("coroutine.resume(") + &$5? + ", " + &$7? + ")") }
    | "COROUTINE" "DOT" "YIELD" "LBRACKET" args "RBRACKET" { Ok(String::from("coroutine.yield(") + &$5? + ")") }
    ;
functioncall -> Result<String, ()>
    : identifier args { Ok($1? + " " + &$2?) }
    | expr "COL" identifier args { Ok($1? + ":" + &$3? + " " + &$4?) }
    | expr "DOT" identifier args { Ok($1? + "." + &$3? + " " + &$4?) }
    ;
args -> Result<String, ()>
    : "LBRACKET" explist "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | tableconstructor { Ok($1?) }
    | literalstring { Ok($1?) }
    ;
conditional -> Result<String, ()>
    : "IF" expr "THEN" program "END" { Ok(String::from("if ") + &$2? + " then\n" + &$4? + "\nend") }
    | "IF" expr "THEN" program "ELSE" program "END" { Ok(String::from("if ") + &$2? + " then\n" + &$4? + "\nelse\n" + &$6? + "\nend") }
    ;
loop -> Result<String, ()>
    : "WHILE" "LBRACKET" expr "RBRACKET" "DO" program "END" { Ok(String::from("while (") + &$3? + ")\ndo\n" + &$6? + "\nend") }
    | "FOR" var "EQ" expr "COMMA" expr "COMMA" expr "DO" program "END" { Ok(String::from("for ") + &$2? + "=" + &$4? + ", " + &$6? + ", " + &$8? + "\ndo\n" + &$10? + "\nend") }
    | "REPEAT" program "UNTIL" "LBRACKET" expr "RBRACKET" { Ok(String::from("repeat\n") + &$2? + "\nuntil (" + &$5? + ")") }
    ;
explist -> Result<String, ()>
    : expr "COMMA" explist { Ok($1? + ", " + &$3?) }
    | expr { Ok($1?) }
    ;
expr -> Result<String, ()>
    : "LBRACKET" "NIL" "RBRACKET" { Ok(String::from("(nil)")) }
    | "LBRACKET" "FALSE" "RBRACKET" { Ok(String::from("(false)")) }
    | "LBRACKET" "TRUE" "RBRACKET" { Ok(String::from("(true)")) }
    | "LBRACKET" "NUMERAL" "RBRACKET" { Ok(String::from("(") + &numeral($2, $lexer) + ")") }
    | literalstring { Ok($1?) }
    | tableconstructor { Ok($1?) }
    | "LBRACKET" var "LSQUARE" expr "RSQUARE" "RBRACKET" { Ok(String::from("(") + &$2? + "[" + &$4? +  "])") }
    | "LBRACKET" expr binop expr "RBRACKET" { Ok(String::from("(") + &$2? + &$3? + &$4? +  ")") }
    | "LBRACKET" unop expr "RBRACKET" { Ok(String::from("(") + &$2? + &$3? +  ")") }
    | lambda { Ok($1?) }
    | var { Ok($1?) }
    | functioncall { Ok($1?) }
    | "LBRACKET" expr "RBRACKET" { Ok(String::from("(") + &$2? +  ")") }
    | "DOTDOTDOT" { Ok(String::from("...")) }
    ;
binop -> Result<String, ()>
    : "PLUS" { Ok(String::from("+")) }
    | "MINUS" { Ok(String::from("-")) }
    | "STAR" { Ok(String::from("*")) }
    | "FSLASH" { Ok(String::from("/")) }
    | "FSFS" { Ok(String::from("//")) }
    | "CARET" { Ok(String::from("^")) }
    | "MOD" { Ok(String::from("%")) }
    | "AMP" { Ok(String::from("&")) }
    | "TILDE" { Ok(String::from("~")) }
    | "PIPE" { Ok(String::from("|")) }
    | "GTGT" { Ok(String::from(">>")) }
    | "LTLT" { Ok(String::from("<<")) }
    | "DOTDOT" { Ok(String::from(" .. ")) }
    | "LT" { Ok(String::from("<")) }
    | "LE" { Ok(String::from("<=")) }
    | "GT" { Ok(String::from(">")) }
    | "GE" { Ok(String::from(">=")) }
    | "EQEQ" { Ok(String::from("==")) }
    | "NOTEQ" { Ok(String::from("~=")) }
    | "AND" { Ok(String::from(" and ")) }
    | "OR" { Ok(String::from(" or ")) }
    ;
unop -> Result<String, ()>
    : "MINUS" { Ok(String::from("-")) }
    | "NOT" { Ok(String::from(" not ")) }
    | "HASH" { Ok(String::from("#")) }
    | "TILDE" { Ok(String::from("~")) }
    ;
tableconstructor -> Result<String, ()>
    : "LCURLY" fieldlist "RCURLY" { Ok(String::from("{") + &$2? +  "}") }
    ;
fieldlist -> Result<String, ()>
    : field "COMMA" fieldlist { Ok($1? + "," + &$3?) }
    | field { Ok($1?) }
    ;
field -> Result<String, ()>
    : "LSQUARE" expr "RSQUARE" "EQ" expr { Ok(String::from("[") + &$2? +  "]=" + &$5?) }
    | identifier "EQ" expr { Ok($1? + "=" + &$3?) }
    | expr { Ok($1?) }
    ;
varlist -> Result<String, ()>
    : var "COMMA" varlist { Ok($1? + ", " + &$3?) }
    | var { Ok($1?) }
    ;
var -> Result<String, ()>
    : "VAR" { Ok(var($1, $lexer)) }
    | "COROUTINE" { Ok(String::from("coroutine")) }
    | "VAR_ID" { Ok(var($1, $lexer)) }
    ;
literalstring -> Result<String, ()>
    : "SHORT_STR" { Ok(short_string($1, $lexer)) }
    | "LONG_STR" { Ok(long_string($1, $lexer)) }
    ;
identifier -> Result<String, ()>
    : "IDENTIFIER" { Ok(identifier($1, $lexer)) }
    | "VAR_ID" { Ok(identifier($1, $lexer)) }
    | "COROUTINE" { Ok(String::from("coroutine")) }
    | "CREATE" { Ok(String::from("create")) }
    | "WRAP" { Ok(String::from("wrap")) }
    | "RESUME" { Ok(String::from("resume")) }
    | "YIELD" { Ok(String::from("yield")) }
    ;
unmatched -> ():
  "UNMATCHED" { } 
  ;
%%

use rand::Rng;
use rand::seq::SliceRandom;

static VARIABLES: [&str; 15] = ["a", "b", "c", "d", "e", "coroutine", "debug", "math", "io", "os", "package", "string", "table", "utf8", "self"];
static IDENTIFIERS: [&str; 153] = ["self", "G", "_VERSION", "assert", "collectgarbage", "dofile", "error", "getmetatable", "ipairs", "load", "loadfile", "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawlen", "rawset", "require", "select", "setmetatable", "tonumber", "tostring", "type", "xpcall", "coroutine", "create", "isyieldable", "resume", "running", "status", "wrap", "yield", "debug", "gethook", "getinfo", "getlocal", "getmetatable", "getregistry", "getupvalue", "getuservalue", "sethook", "setlocal", "setmetatable", "setupvalue", "setuservalue", "traceback", "upvalueid", "upvaluejoin", "io", "close", "flush", "input", "lines", "open", "output", "popen", "read", "stderr", "stdin", "stdout", "tmpfile", "math", "abs", "acos", "asin", "atan", "ceil", "cos", "deg", "exp", "floor", "fmod", "huge", "log", "max", "maxinteger", "min", "mininteger", "modf", "pi", "rad", "random", "randomseed", "sin", "sqrt", "tan", "tointeger", "ult", "os", "clock", "date", "difftime", "exit", "getenv", "remove", "rename", "setlocale", "time", "tmpname", "package", "config", "cpath", "loaded", "loadlib", "path", "preload", "searchers", "searchpath", "string", "byte", "char", "dump", "find", "format", "gmatch", "gsub", "len", "lower", "match", "pack", "packsize", "rep", "reverse", "sub", "unpack", "upper", "table", "concat", "insert", "move", "remove", "sort", "utf8", "charpattern", "codepoint", "codes", "offset", "__index", "__newindex", "__add", "__sub", "__mul", "__div", "__mod", "__unm", "__concat", "__eq", "__lt", "__le", "__call", "__tostring"];


fn identifier<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = IDENTIFIERS.choose(&mut rng).unwrap_or(&"error");
            keyword.to_string()
        }
  }
}

fn var<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = VARIABLES.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn numeral<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("") + &rand::thread_rng().gen_range(0.0..1000.9).to_string()
  }
}

fn short_string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\"aaa\"")
  }
}

fn long_string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("[[aaa]]")
  }
}