%expect-unused unmatched "UNMATCHED"
%start complete_program
%expect 113
%expect-rr 674

%%
complete_program -> Result<String, ()>
    : "PREFIX" program { Ok(String::from("var a = [];\nvar b = [];\nvar c = [];\nvar d = [];\n") + &$2?) }
    ;
program -> Result<String, ()>
    : statement program { Ok($1? + "\n" + &$2?) }
    |  { Ok(String::from("")) }
    ;
object -> Result<String, ()>
    : identifier { Ok($1?) }
    | "LCURLY" objmember "RCURLY" { Ok(String::from("{") + &$2? + "}") }
    | "LCURLY" "RCURLY" { Ok(String::from("{}")) }
    ;
objmember -> Result<String, ()>
    : var "COL" literal "COMMA" objmember { Ok($1? + ":" + &$3? + ", " + &$5?) }
    | var "COL" literal { Ok($1? + ":" + &$3?) }
    ;
var -> Result<String, ()>
    : "VAR_A" { Ok(String::from("a")) }
    | "VAR_B" { Ok(String::from("b")) }
    | "VAR_C" { Ok(String::from("c")) }
    | "VAR_D" { Ok(String::from("d")) }
    | "VAR_E" { Ok(String::from("e")) }
    | "VAR_F" { Ok(String::from("f")) }
    | "VAR_G" { Ok(String::from("g")) }
    | "VAR_H" { Ok(String::from("h")) }
    ;
method_name -> Result<String, ()>
    : identifier { Ok($1?) }
    | "HASOWNPROPERTY" { Ok(String::from("hasOwnProperty")) }
    | "METHOD_NAME" { Ok(method_name($1, $lexer)) }
    | "MATCH" { Ok(String::from("match")) }
    | "VOID" { Ok(String::from("void")) }
    | "FROM" { Ok(String::from("from")) }
    | "RETURN" { Ok(String::from("return")) }
    | "DELETE" { Ok(String::from("delete")) }
    | "SPLIT" { Ok(String::from("split")) }
    | simd_function { Ok($1?) }
    | "REPLACE" { Ok(String::from("replace")) }
    | "EXPORTS" { Ok(String::from("exports")) }
    | "SEARCH" { Ok(String::from("search")) }
    ;
simd_function -> Result<String, ()>
    : "TYPE_CONVERSION" { Ok(type_conversion($1, $lexer)) }
    | "SIMD_FUNCTION" { Ok(simd_function($1, $lexer)) }
    | "ADDSATURATE" { Ok(String::from("addSaturate")) }
    | "RECIPROCALSQRTAPPROXIMATION" { Ok(String::from("reciprocalSqrtApproximation")) }
    | "REPLACELANE" { Ok(String::from("replaceLane")) }
    ;
methodcall -> Result<String, ()>
    : object property methodcall1 { Ok($1? + &$2? + &$3?) }
    | identifier args methodcall1 { Ok($1? + &$2? + &$3?) }
    | method_name args methodcall1 { Ok($1? + &$2? + &$3?) }
    | "SIMD" "DOT" "SIMD_TYPE" "DOT" simd_function args methodcall1 { Ok(String::from("simd.") + &simd_type($3, $lexer) + "." + &$5? + &$6? + &$7?) }
    ;
methodcall1 -> Result<String, ()>
    : "DOT" method_name args methodcall1 { Ok(String::from(".") + &$2? + &$3? + &$4?) }
    | "DOT" simd_function args methodcall1 { Ok(String::from(".") + &$2? + &$3? + &$4?) }
    |  { Ok(String::from("")) }
    ;
property -> Result<String, ()>
    : property property_name { Ok($1? + &$2?) }
    |  { Ok(String::from("")) }
    ;
property_name -> Result<String, ()>
    : "DOT" "E_BIG" { Ok(String::from(".E")) }
    | "DOT" "NAN" { Ok(String::from(".NaN")) }
    | "DOT" "PROPERTY" { Ok(String::from(".") + &property($2, $lexer)) }
    | "DOT" "MATCH" { Ok(String::from(".match")) }
    | "DOT" "ARGUMENTS" { Ok(String::from(".arguments")) }
    | "DOT" "SPLIT" { Ok(String::from(".split")) }
    | "DOT" "REPLACE" { Ok(String::from(".replace")) }
    | "DOT" "EXPORTS" { Ok(String::from(".exports")) }
    | "DOT" "SEARCH" { Ok(String::from(".search")) }
    ;
args -> Result<String, ()>
    : "LBRACKET" "RBRACKET" { Ok(String::from("()")) }
    | "LBRACKET" arglist "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    ;
arglist -> Result<String, ()>
    : expr "COMMA" arglist { Ok($1? + ", " + &$3?) }
    | expr { Ok($1?) }
    ;
identifierlist -> Result<String, ()>
    : identifier { Ok($1?) }
    | identifier "COMMA" identifierlist { Ok($1? + ", " + &$3?) }
    | "LBRACKET" identifierlist "RBRACKET" "COMMA" identifierlist { Ok(String::from("(") + &$2? + "), " + &$5?) }
    | "LBRACKET" identifier "RBRACKET" "COMMA" identifierlist { Ok(String::from("(") + &$2? + "), " + &$5?) }
    ;
statement -> Result<String, ()>
    : expr "SEMICOL" { Ok($1? + ";") }
    | expr assignmentoperation "SEMICOL" { Ok($1? + &$2? + ";") }
    | var "COL" { Ok($1? + ":") }
    | declaration { Ok($1?) }
    | "TYPEOF" expr "SEMICOL" { Ok(String::from("typeof ") + &$2? + ";") }
    | "VOID" expr "SEMICOL" { Ok(String::from("void ") + &$2? + ";") }
    | "RETURN" expr "SEMICOL" { Ok(String::from("return ") + &$2? + ";") }
    | classdef { Ok($1?) }
    | functiondef { Ok($1?) }
    | "ASYNC" functiondef { Ok(String::from("async ") + &$2?) }
    | "EXPORT" expr "SEMICOL" { Ok(String::from("export ") + &$2? + ";") }
    | "EXPORT" functiondef { Ok(String::from("export ") + &$2?) }
    | "EXPORT" declaration_type var property "EQ" expr "SEMICOL" { Ok(String::from("export ") + &$2? + &$3? + &$4? + "=" + &$6? + ";") }
    | "EXPORT" var property "EQ" expr "SEMICOL" { Ok(String::from("export ") + &$2? + &$3? + "=" + &$5? + ";") }
    | "EXPORT" declaration_type var "LSQUARE" decimalnumber "RSQUARE" "EQ" expr "SEMICOL" { Ok(String::from("export ") + &$2? + &$3? + "[" + &$5? + "]" + "=" + &$8? + ";") }
    | "EXPORT" declaration_type "LCURLY" args "RCURLY" "EQ" expr "SEMICOL" { Ok(String::from("export ") + &$2? + "{" + &$4? + "}" + "=" + &$7? + ";") }
    | "IMPORT" import_name "AS" method_name "FROM" string { Ok(String::from("import ") + &$2? + " as " + &$4? + " from " + &$6?) }
    ;
declaration -> Result<String, ()>
    : declaration_type var property "EQ" expr "SEMICOL" { Ok($1? + &$2? + &$3? + "=" + &$5? + ";") }
    | declaration_type var "LSQUARE" decimalnumber "RSQUARE" "EQ" expr "SEMICOL" { Ok($1? + &$2? + "[" + &$4? + "]" + "=" + &$7? + ";") }
    | declaration_type "LCURLY" args "RCURLY" "EQ" expr "SEMICOL" { Ok($1? + "{" + &$3? + "}" + "=" + &$6? + ";") }
    ;
declaration_type -> Result<String, ()>
    :  { Ok(String::from("")) }
    | "VAR" { Ok(String::from("var ")) }
    | "LET" { Ok(String::from("let ")) }
    | "CONST" { Ok(String::from("const ")) }
    ;
import_name -> Result<String, ()>
    : "STAR" { Ok(String::from("*")) }
    | method_name { Ok($1?) }
    ;
classdef -> Result<String, ()>
    : "CLASS" identifier "LCURLY" class_content "RCURLY" { Ok(String::from("class ") + &$2? + "{" + &$4? + "}") }
    | "CLASS" identifier "EXTENDS" identifier "LCURLY" class_content "RCURLY" { Ok(String::from("class ") + &$2? + " extends " + &$4? + "{" + &$6? + "}") }
    ;
class_content -> Result<String, ()>
    :  { Ok(String::from("")) }
    | methoddef class_content { Ok($1? + &$2?) }
    ;
functiondef -> Result<String, ()>
    : "FUNCTION" methoddef { Ok(String::from("function ") + &$2?) }
    | identifier "MAP" expr { Ok($1? + " => " + &$3?) }
    | identifier "MAP" "LCURLY" functionbody "RCURLY" { Ok($1? + " => {" + &$4? + "}") }
    | functionargs "MAP" expr { Ok($1? + " => " + &$3?) }
    | functionargs "MAP" "LCURLY" functionbody "RCURLY" { Ok($1? + " => {" + &$4? + "}") }
    ;
methoddef -> Result<String, ()>
    : identifier functionargs "LCURLY" functionbody "RCURLY" { Ok($1? + &$2? + "{" + &$4? + "}") }
    ;
functionbody -> Result<String, ()>
    : program { Ok($1?) }
    ;
functionargs -> Result<String, ()>
    : "LBRACKET" "RBRACKET" { Ok(String::from("()")) }
    | "LBRACKET" identifier "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | "LBRACKET" identifierlist "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    ;
expr -> Result<String, ()>
    : "LBRACKET" expr "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | "LBRACKET" identifier "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | "LCURLY" objmember "RCURLY" { Ok(String::from("{") + &$2? + "}") }
    | "DOTDOTDOT" var { Ok(String::from("...") + &$2?) }
    | "DELETE" expr { Ok(String::from("delete ") + &$2?) }
    | "NEW" identifier args { Ok(String::from("new ") + &$2? + &$3?) }
    | "AWAIT" expr { Ok(String::from("await ") + &$2?) }
    | literal { Ok($1?) }
    | identifier { Ok($1?) }
    | methodcall { Ok($1?) }
    | "LBRACKET" arithmeticoperation "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | "LBRACKET" comparisonoperation "RBRACKET"{ Ok(String::from("(") + &$2? + ")") }
    | "LBRACKET" bytewiseoperation "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | "LBRACKET" logicaloperation "RBRACKET" { Ok(String::from("(") + &$2? + ")") }
    | "LBRACKET" expr "COND" expr "COL" expr "RBRACKET" { Ok(String::from("(") + &$2? + " ? " + &$4? + " : " + &$6? + ")") }
    | expr "LSQUARE" expr "RSQUARE" { Ok($1? + "[" + &$3? + "]") }
    ;
arithmeticoperation -> Result<String, ()>
    : expr "FSLASH" expr { Ok($1? + "/" + &$3?) }
    | expr "STAR" expr { Ok($1? + "*" + &$3?) }
    | expr "PLUS" expr { Ok($1? + "+" + &$3?) }
    | expr "MINUS" expr { Ok($1? + "-" + &$3?) }
    | expr "MOD" expr { Ok($1? + "%" + &$3?) }
    | expr "STAR" "STAR" expr { Ok($1? + "**" + &$4?) }
    | expr "PLUS" "PLUS" { Ok($1? + "++") }
    | "PLUS" "PLUS" expr { Ok(String::from("++") + &$3?) }
    | "MINUS" "MINUS" expr { Ok(String::from("--") + &$3?) }
    | expr "MINUS" "MINUS" { Ok($1? + "--") }
    ;
assignmentoperation -> Result<String, ()>
    : "EQ" expr { Ok(String::from("=") + &$2?) }
    | "PLUS" "EQ" expr { Ok(String::from("+=") + &$3?) }
    | "MINUS" "EQ" expr { Ok(String::from("-=") + &$3?) }
    | "STAR" "EQ" expr { Ok(String::from("*=") + &$3?) }
    | "FSLASH" "EQ" expr { Ok(String::from("/=") + &$3?) }
    | "MOD" "EQ" expr { Ok(String::from("%=") + &$3?) }
    | "STAR" "STAR" "EQ" expr { Ok(String::from("**=") + &$4?) }
    | "LTLT" "EQ" expr { Ok(String::from("<<=") + &$3?) }
    | "GTGT" "EQ" expr { Ok(String::from(">>=") + &$3?) }
    | "GTGT" "GT" "EQ" expr { Ok(String::from(">>>=") + &$4?) }
    | "AMP" "EQ" expr { Ok(String::from("&=") + &$3?) }
    | "CARET" "EQ" expr { Ok(String::from("^=") + &$3?) }
    | "PIPE" "EQ" expr { Ok(String::from("|=") + &$3?) }
    ;
bytewiseoperation -> Result<String, ()>
    : expr "AMP" expr { Ok($1? + "&" + &$3?) }
    | expr "PIPE" expr { Ok($1? + "|" + &$3?) }
    | expr "CARET" expr { Ok($1? + "^" + &$3?) }
    | "TILDE" expr { Ok(String::from("~") + &$2?) }
    | expr "LTLT" expr { Ok($1? + "<<" + &$3?) }
    | expr "GTGT" expr { Ok($1? + ">>" + &$3?) }
    | expr "GTGT" "GT" expr { Ok($1? + ">>>" + &$4?) }
    ;
comparisonoperation -> Result<String, ()>
    : expr "LT" expr { Ok($1? + "<" + &$3?) }
    | expr "GT" expr { Ok($1? + ">" + &$3?) }
    | expr "LE" expr { Ok($1? + "<=" + &$3?) }
    | expr "GE" expr { Ok($1? + ">=" + &$3?) }
    | expr "EQEQ" expr { Ok($1? + "==" + &$3?) }
    | expr "EQEQ" "EQ" expr { Ok($1? + "===" + &$4?) }
    | expr "NOT" "EQ" expr { Ok($1? + "!=" + &$4?) }
    | expr "EQV" expr { Ok($1? + "<=>" + &$3?) }
    ;
logicaloperation -> Result<String, ()>
    : expr "AMP" "AMP" expr { Ok($1? + "&&" + &$4?) }
    | expr "PIPE" "PIPE" expr { Ok($1? + "||" + &$4?) }
    | "NOT" expr { Ok(String::from("!") + &$2?) }
    ;
literal -> Result<String, ()>
    : "NULL" { Ok(String::from("null")) }
    | "TRUE" { Ok(String::from("true")) }
    | "FALSE" { Ok(String::from("false")) }
    | number { Ok($1?) }
    | string { Ok($1?) }
    | array { Ok($1?) }
    | regex { Ok($1?) }
    ;
binarydigits -> Result<String, ()>
    : "ZERO" { Ok(String::from("0")) }
    | "ONE" { Ok(String::from("1")) }
    | "BINARYDIGITS-1" { Ok(String::from("1010")) }
    | "BINARYDIGITS-2" { Ok(String::from("1_11")) }
    | "BINARYDIGITS-3" { Ok(String::from("10_01")) }
    | "BINARYDIGITS-4" { Ok(String::from("1111111111111111111111111111111")) }
    | "BINARYDIGITS-5" { Ok(String::from("101010101110101001011010101")) }
    ;
octaldigits -> Result<String, ()>
    : "ZERO" { Ok(String::from("0")) }
    | "ONE" { Ok(String::from("1")) }
    | "ONE" "TWO" "THREE" { Ok(String::from("123")) }
    | "FIVE" "USCORE" "ZERO" "USCORE" "TWO" { Ok(String::from("5_0_2")) }
    | "THREE" "TWO" "FOUR" { Ok(String::from("324")) }
    | "FIVE" "USCORE" "USCORE" "FOUR" "THREE" "TWO" { Ok(String::from("5__432")) }
    | "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" "SEVEN" { Ok(String::from("7777777777777777777777")) }
    | "ONE" "TWO" "FOUR" "SEVEN" "TWO" "THREE" "SEVEN" "FOUR" "SIX" "FIVE" "TWO" "THREE" "FOUR" { Ok(String::from("1247237465234")) }
    ;
decimaldigits -> Result<String, ()>
    : "ZERO" { Ok(String::from("0")) }
    | "ONE" { Ok(String::from("1")) }
    | "TWO" "ZERO" { Ok(String::from("20")) }
    | "ONE" "TWO" "THREE" "FOUR" { Ok(String::from("1234")) }
    | "SIX" "SIX" { Ok(String::from("66")) }
    | "TWO" "THREE" "FOUR" "USCORE" "NINE" { Ok(String::from("234_9")) }
    | "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" "NINE" { Ok(String::from("99999999999999999999")) }
    | "ONE" "TWO" "THREE" "FOUR" "FIVE" "SIX" "SEVEN" "EIGHT" "ONE" "TWO" "THREE" "FOUR" "FIVE" "SIX" { Ok(String::from("12345678123456")) }
    ;
hexdigits -> Result<String, ()>
    : "ZERO" { Ok(String::from("0")) }
    | "HEX_LONG" { Ok(String::from("ABCFDFE0_1203453abcd")) }
    | "ONE" { Ok(String::from("1")) }
    | "ONE" "TWO" "THREE" "FOUR" { Ok(String::from("1234")) }
    | "HEX_1" { Ok(String::from("1asdf")) }
    | "HEX_2" { Ok(String::from("A1")) }
    | "HEX_3" { Ok(String::from("1F_F")) }
    | "FOUR" "THREE" "FOUR" "SIX" { Ok(String::from("4346")) }
    | "HEX_4" { Ok(String::from("FE_D983")) }
    | "HEX_F" { Ok(String::from("FFFFFFFFFF")) }
    ;
hexnumber -> Result<String, ()>
    : "ZERO" "VAR_B" binarydigits { Ok(String::from("0b") + &$3?) }
    | "ZERO" "B" binarydigits { Ok(String::from("0B") + &$3?) }
    | "ZERO" "X_SMALL" hexdigits { Ok(String::from("0x") + &$3?) }
    | "ZERO" "X" hexdigits { Ok(String::from("0X") + &$3?) }
    ;
exponent -> Result<String, ()>
    : "VAR_E" decimaldigits { Ok(String::from("e") + &$2?) }
    | "VAR_E" "MINUS" decimaldigits { Ok(String::from("e-") + &$3?) }
    | "E_BIG" decimaldigits { Ok(String::from("E") + &$2?) }
    | "E_BIG" "MINUS" decimaldigits { Ok(String::from("E-") + &$3?) }
    ;
decimalnumber -> Result<String, ()>
    : decimaldigits { Ok($1?) }
    | "ZERO" "D" decimaldigits { Ok(String::from("0D") + &$3?) }
    | "ZERO" "VAR_D" decimaldigits { Ok(String::from("0d") + &$3?) }
    ;
octalnumber -> Result<String, ()>
    : "ZERO" "O" octaldigits { Ok(String::from("0O") + &$3?) }
    | "ZERO" "O_SMALL" octaldigits { Ok(String::from("0o") + &$3?) }
    | "ZERO" octaldigits { Ok(String::from("0") + &$2?) }
    ;
floatnumber -> Result<String, ()>
    : decimalnumber "DOT" decimaldigits { Ok($1? + "." + &$3?) }
    | octalnumber "DOT" octaldigits { Ok($1? + "." + &$3?) }
    | hexnumber "DOT" hexdigits { Ok($1? + "." + &$3?) }
    | decimalnumber "DOT" decimaldigits exponent { Ok($1? + "." + &$3? + &$4?) }
    | octalnumber "DOT" octaldigits exponent { Ok($1? + "." + &$3? + &$4?) }
    | hexnumber "DOT" hexdigits exponent { Ok($1? + "." + &$3? + &$4?) }
    ;
number -> Result<String, ()>
    : "ZERO" { Ok(String::from("0")) }
    | "ONE" { Ok(String::from("1")) }
    | "DOT" { Ok(String::from(".")) }
    | "ZERO" "NINE" { Ok(String::from("09")) }
    | "ZERO" "EIGHT" { Ok(String::from("08")) }
    | "MINUS" "ONE" { Ok(String::from("-1")) }
    | "MINUS" "ZERO" { Ok(String::from("-0")) }
    | "PLUS" "ZERO" { Ok(String::from("+0")) }
    | decimalnumber { Ok($1?) }
    | floatnumber { Ok($1?) }
    | octalnumber { Ok($1?) }
    | hexnumber { Ok($1?) }
    | "NUMBER" { Ok(number($1, $lexer)) }
    ;
doublequotedword -> Result<String, ()>
    : naughtystring { Ok($1?) }
    ;
doublequotedstring -> Result<String, ()>
    : doublequotedword { Ok($1?) }
    | number doublequotedstring { Ok($1? + &$2?) }
    | escapedcharacters doublequotedstring { Ok($1? + &$2?) }
    | "HASH" "LCURLY" expr "RCURLY" doublequotedstring { Ok(String::from("#{") + &$3? + "}" + &$5?) }
    | { Ok(String::from("")) }
    ;
templatestring -> Result<String, ()>
    : doublequotedstring "DOLLAR" "LCURLY" expr "RCURLY" templatestring { Ok($1? + "\u{0024}" + "{" + &$4? + "}") }
    | { Ok(String::from("")) }
    ;
string -> Result<String, ()>
    : "DQUOTE" doublequotedstring "DQUOTE" { Ok(String::from("\"") + &$2? + "\"") }
    | "QUOTE" doublequotedstring "QUOTE" { Ok(String::from("'") + &$2? + "'") }
    | "BQUOTE" templatestring "BQUOTE" { Ok(String::from("`") + &$2? + "`") }
    ;
array -> Result<String, ()>
    : "LSQUARE" arraycontent "RSQUARE" { Ok(String::from("[") + &$2? + "]") }
    | "LSQUARE" "RSQUARE" { Ok(String::from("[]")) }
    ;
arraycontent -> Result<String, ()>
    : expr "COMMA" arraycontent { Ok($1? + ", " + &$3?) }
    | expr { Ok($1?) }
    ;
regex -> Result<String, ()>
    : "FSLASH" regexpattern "FSLASH" { Ok(String::from("/") + &$2? + "/") }
    | "FSLASH" regexpattern "FSLASH" "VAR_G" { Ok(String::from("/") + &$2? + "/g") }
    | "FSLASH" regexpattern "FSLASH" "I" { Ok(String::from("/") + &$2? + "/i") }
    | "FSLASH" regexpattern "FSLASH" "M" { Ok(String::from("/") + &$2? + "/m") }
    | "FSLASH" regexpattern "FSLASH" "Y" { Ok(String::from("/") + &$2? + "/y") }
    ;
regexpattern -> Result<String, ()>
    : doublequotedstring { Ok($1?) }
    ;
escapedcharacters -> Result<String, ()>
    : "ESCAPEDCHARACTER" { Ok(escapedcharacters($1, $lexer)) }
    | "UNICODE-4" { Ok(unicode_4($1, $lexer)) }
    | "OCT-CODE" { Ok(oct_code($1, $lexer)) }
    | "HEX-CODE" { Ok(hex_code($1, $lexer)) }
    ;
naughtystring -> Result<String, ()>
    : "UNDEFINED" { Ok(String::from("undefined")) }
    | "HASOWNPROPERTY" { Ok(String::from("hasOwnProperty")) }
    | "DOT" { Ok(String::from(".")) }
    | "MOD" { Ok(String::from("%")) }
    | "MINUS" { Ok(String::from("-")) }
    | "USCORE" { Ok(String::from("_")) }
    | "TRUE" { Ok(String::from("true")) }
    | "FALSE" { Ok(String::from("false")) }
    | "NULL" { Ok(String::from("null")) }
    | "UNICODE-NAUGHTY" { Ok(unicode_naughty($1, $lexer)) }
    | "NAUGHTY_STR_TEST" { Ok(naughty_str_test($1, $lexer)) }
    | "NAUGHTY-STR" { Ok(naughty_str($1, $lexer)) }
    | "NAUGHTY-STR-01" { Ok(String::from("\x01\x02\x03\x04\x05\x06\x07\x08\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\u{007f}")) }
    | "NAUGHTY-STR-02" { Ok(String::from("\u{0080}\u{0081}\u{0082}\u{0083}\u{0084}\u{0086}\u{0087}\u{0088}\u{0089}\u{008a}\u{008b}\u{008c}\u{008d}\u{008e}\u{008f}\u{0090}\u{0091}\u{0092}\u{0093}\u{0094}\u{0095}\u{0096}\u{0097}\u{0098}\u{0099}\u{009a}\u{009b}\u{009c}\u{009d}\u{009e}\u{009f}")) }
    | "NAUGHTY-STR-03" { Ok(String::from("\t\u{000b}\u{000c}\u{0085} \u{1680}\u{2002}\u{2003}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200a}\u{200b}\u{2028}\u{2029}\u{202f}\u{205f}\u{3000}")) }
    | "NAUGHTY-STR-04" { Ok(String::from("\u{00ad}\u{0600}\u{0601}\u{0602}\u{0603}\u{0604}\u{0605}\u{061c}\u{06dd}\u{070f}\u{180e}\u{200b}\u{200c}\u{200d}\u{200e}\u{200f}\u{202a}\u{202b}\u{202c}\u{202d}\u{202e}\u{2060}\u{2061}\u{2062}\u{2063}\u{2064}\u{2066}\u{2067}\u{2068}\u{2069}\u{206a}\u{206b}\u{206c}\u{206d}\u{206e}\u{206f}\u{feff}\u{fff9}\u{fffa}\u{fffb}\u{0110bd}\u{01bca0}\u{01bca1}\u{01bca2}\u{01bca3}\u{01d173}\u{01d174}\u{01d175}\u{01d176}\u{01d177}\u{01d178}\u{01d179}\u{01d17a}\u{0e0001}\u{0e0020}\u{0e0021}\u{0e0022}\u{0e0023}\u{0e0024}\u{0e0025}\u{0e0026}\u{0e0027}\u{0e0028}\u{0e0029}\u{0e002a}\u{0e002b}\u{0e002c}\u{0e002d}\u{0e002e}\u{0e002f}\u{0e0030}\u{0e0031}\u{0e0032}\u{0e0033}\u{0e0034}\u{0e0035}\u{0e0036}\u{0e0037}\u{0e0038}\u{0e0039}\u{0e003a}\u{0e003b}\u{0e003c}\u{0e003d}\u{0e003e}\u{0e003f}\u{0e0040}\u{0e0041}\u{0e0042}\u{0e0043}\u{0e0044}\u{0e0045}\u{0e0046}\u{0e0047}\u{0e0048}\u{0e0049}\u{0e004a}\u{0e004b}\u{0e004c}\u{0e004d}\u{0e004e}\u{0e004f}\u{0e0050}\u{0e0051}\u{0e0052}\u{0e0053}\u{0e0054}\u{0e0055}\u{0e0056}\u{0e0057}\u{0e0058}\u{0e0059}\u{0e005a}\u{0e005b}\u{0e005c}\u{0e005d}\u{0e005e}\u{0e005f}\u{0e0060}\u{0e0061}\u{0e0062}\u{0e0063}\u{0e0064}\u{0e0065}\u{0e0066}\u{0e0067}\u{0e0068}\u{0e0069}\u{0e006a}\u{0e006b}\u{0e006c}\u{0e006d}\u{0e006e}\u{0e006f}\u{0e0070}\u{0e0071}\u{0e0072}\u{0e0073}\u{0e0074}\u{0e0075}\u{0e0076}\u{0e0077}\u{0e0078}\u{0e0079}\u{0e007a}\u{0e007b}\u{0e007c}\u{0e007d}\u{0e007e}\u{0e007f}")) }
    | "NAUGHTY-STR-05" { Ok(String::from("\u{03a9}\u{2248}\u{00e7}\u{221a}\u{222b}\u{02dc}\u{00b5}\u{2264}\u{2265}\u{00f7}")) }
    | "NAUGHTY-STR-06" { Ok(String::from("\u{00e5}\u{00df}\u{2202}\u{0192}\u{00a9}\u{02d9}\u{2206}\u{02da}\u{00ac}\u{2026}\u{00e6}")) }
    | "NAUGHTY-STR-07" { Ok(String::from("\u{0153}\u{2211}\u{00b4}\u{00ae}\u{2020}\u{00a5}\u{00a8}\u{02c6}\u{00f8}\u{03c0}\u{201c}\u{2018}")) }
    | "NAUGHTY-STR-08" { Ok(String::from("\u{00a1}\u{2122}\u{00a3}\u{00a2}\u{221e}\u{00a7}\u{00b6}\u{2022}\u{00aa}\u{00ba}\u{2013}\u{2260}")) }
    | "NAUGHTY-STR-09" { Ok(String::from("\u{00b8}\u{02db}\u{00c7}\u{25ca}\u{0131}\u{02dc}\u{00c2}\u{00af}\u{02d8}\u{00bf}")) }
    | "NAUGHTY-STR-10" { Ok(String::from("\u{00c5}\u{00cd}\u{00ce}\u{00cf}\u{02dd}\u{00d3}\u{00d4}\u{f8ff}\u{00d2}\u{00da}\u{00c6}\u{2603}")) }
    | "NAUGHTY-STR-11" { Ok(String::from("\u{0152}\u{201e}\u{00b4}\u{2030}\u{02c7}\u{00c1}\u{00a8}\u{02c6}\u{00d8}\u{220f}\u{201d}\u{2019}")) }
    | "NAUGHTY-STR-12" { Ok(String::from("`\u{2044}\u{20ac}\u{2039}\u{203a}\u{fb01}\u{fb02}\u{2021}\u{00b0}\u{00b7}\u{201a}\u{2014}\u{00b1}")) }
    | "NAUGHTY-STR-13" { Ok(String::from("\u{215b}\u{215c}\u{215d}\u{215e}")) }
    | "NAUGHTY-STR-14" { Ok(String::from("\u{0401}\u{0402}\u{0403}\u{0404}\u{0405}\u{0406}\u{0407}\u{0408}\u{0409}\u{040a}\u{040b}\u{040c}\u{040d}\u{040e}\u{040f}\u{0410}\u{0411}\u{0412}\u{0413}\u{0414}\u{0415}\u{0416}\u{0417}\u{0418}\u{0419}\u{041a}\u{041b}\u{041c}\u{041d}\u{041e}\u{041f}\u{0420}\u{0421}\u{0422}\u{0423}\u{0424}\u{0425}\u{0426}\u{0427}\u{0428}\u{0429}\u{042a}\u{042b}\u{042c}\u{042d}\u{042e}\u{042f}\u{0430}\u{0431}\u{0432}\u{0433}\u{0434}\u{0435}\u{0436}\u{0437}\u{0438}\u{0439}\u{043a}\u{043b}\u{043c}\u{043d}\u{043e}\u{043f}\u{0440}\u{0441}\u{0442}\u{0443}\u{0444}\u{0445}\u{0446}\u{0447}\u{0448}\u{0449}\u{044a}\u{044b}\u{044c}\u{044d}\u{044e}\u{044f}")) }
    | "NAUGHTY-STR-15" { Ok(String::from("\u{0660}\u{0661}\u{0662}\u{0663}\u{0664}\u{0665}\u{0666}\u{0667}\u{0668}\u{0669}")) }
    | "NAUGHTY-STR-16" { Ok(String::from("\u{2070}\u{2074}\u{2075}")) }
    | "NAUGHTY-STR-17" { Ok(String::from("\u{2080}\u{2081}\u{2082}")) }
    | "NAUGHTY-STR-18" { Ok(String::from("\u{2070}\u{2074}\u{2075}\u{2080}\u{2081}\u{2082}")) }
    | "NAUGHTY-STR-19" { Ok(String::from("\u{0e14}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47} \u{0e14}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47} \u{0e14}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e47}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e49}\u{0e47}\u{0e47}\u{0e47}\u{0e47}")) }
    | "NAUGHTY-STR-20" { Ok(String::from("\u{7530}\u{4e2d}\u{3055}\u{3093}\u{306b}\u{3042}\u{3052}\u{3066}\u{4e0b}\u{3055}\u{3044}")) }
    | "NAUGHTY-STR-21" { Ok(String::from("\u{30d1}\u{30fc}\u{30c6}\u{30a3}\u{30fc}\u{3078}\u{884c}\u{304b}\u{306a}\u{3044}\u{304b}")) }
    | "NAUGHTY-STR-22" { Ok(String::from("\u{548c}\u{88fd}\u{6f22}\u{8a9e}")) }
    | "NAUGHTY-STR-23" { Ok(String::from("\u{90e8}\u{843d}\u{683c}")) }
    | "NAUGHTY-STR-24" { Ok(String::from("\u{c0ac}\u{d68c}\u{acfc}\u{d559}\u{c6d0} \u{c5b4}\u{d559}\u{c5f0}\u{ad6c}\u{c18c}")) }
    | "NAUGHTY-STR-25" { Ok(String::from("\u{cc26}\u{cc28}\u{b97c} \u{d0c0}\u{ace0} \u{c628} \u{d3b2}\u{c2dc}\u{b9e8}\u{acfc} \u{c45b}\u{b2e4}\u{b9ac} \u{b620}\u{bc29}\u{ac01}\u{d558}")) }
    | "NAUGHTY-STR-26" { Ok(String::from("\u{793e}\u{6703}\u{79d1}\u{5b78}\u{9662}\u{8a9e}\u{5b78}\u{7814}\u{7a76}\u{6240}")) }
    | "NAUGHTY-STR-27" { Ok(String::from("\u{c6b8}\u{b780}\u{bc14}\u{d1a0}\u{b974}")) }
    | "NAUGHTY-STR-28" { Ok(String::from("\u{02070e}\u{020731}\u{020779}\u{020c53}\u{020c78}\u{020c96}\u{020ccf}")) }
    | "NAUGHTY-STR-29" { Ok(String::from("\u{30fd}\u{0f3c}\u{0e88}\u{0644}\u{035c}\u{0e88}\u{0f3d}\u{ff89} \u{30fd}\u{0f3c}\u{0e88}\u{0644}\u{035c}\u{0e88}\u{0f3d}\u{ff89} ")) }
    | "NAUGHTY-STR-30" { Ok(String::from("(\u{ff61}\u{25d5} \u{2200} \u{25d5}\u{ff61})")) }
    | "NAUGHTY-STR-31" { Ok(String::from("\u{ff40}\u{ff68}(\u{00b4}\u{2200}\u{ff40}\u{2229}")) }
    | "NAUGHTY-STR-32" { Ok(String::from("\u{30fb}(\u{ffe3}\u{2200}\u{ffe3})\u{30fb}:*:")) }
    | "NAUGHTY-STR-33" { Ok(String::from("\u{ff9f}\u{ff65}\u{273f}\u{30fe}\u{2572}(\u{ff61}\u{25d5}\u{203f}\u{25d5}\u{ff61})\u{2571}\u{273f}\u{ff65}\u{ff9f}")) }
    | "NAUGHTY-STR-34" { Ok(String::from(",\u{3002}\u{30fb}:*:\u{30fb}\u{309c}\u{2019}( \u{263b} \u{03c9} \u{263b} )\u{3002}\u{30fb}:*:\u{30fb}\u{309c}\u{2019}")) }
    | "NAUGHTY-STR-35" { Ok(String::from("(\u{256f}\u{00b0}\u{25a1}\u{00b0}\u{ff09}\u{256f}\u{fe35} \u{253b}\u{2501}\u{253b})")) }
    | "NAUGHTY-STR-36" { Ok(String::from("(\u{ff89}\u{0ca5}\u{76ca}\u{0ca5}\u{ff09}\u{ff89}\u{feff} \u{253b}\u{2501}\u{253b}")) }
    | "NAUGHTY-STR-37" { Ok(String::from("\u{252c}\u{2500}\u{252c}\u{30ce}( \u{00ba} _ \u{00ba}\u{30ce})")) }
    | "NAUGHTY-STR-38" { Ok(String::from("( \u{0361}\u{00b0} \u{035c}\u{0296} \u{0361}\u{00b0})")) }
    | "NAUGHTY-STR-39" { Ok(String::from("\u{01f469}\u{01f3fd}")) }
    | "NAUGHTY-STR-40" { Ok(String::from("\u{01f47e} \u{01f647} \u{01f481} \u{01f645} \u{01f646} \u{01f64b} \u{01f64e} \u{01f64d}")) }
    | "NAUGHTY-STR-41" { Ok(String::from("\u{01f435} \u{01f648} \u{01f649} \u{01f64a}")) }
    | "NAUGHTY-STR-42" { Ok(String::from("\u{2764}\u{fe0f} \u{01f494} \u{01f48c} \u{01f495} \u{01f49e} \u{01f493} \u{01f497} \u{01f496} \u{01f498} \u{01f49d} \u{01f49f} \u{01f49c} \u{01f49b} \u{01f49a} \u{01f499}")) }
    | "NAUGHTY-STR-43" { Ok(String::from("\u{270b}\u{01f3ff} \u{01f4aa}\u{01f3ff} \u{01f450}\u{01f3ff} \u{01f64c}\u{01f3ff} \u{01f44f}\u{01f3ff} \u{01f64f}\u{01f3ff}")) }
    | "NAUGHTY-STR-44" { Ok(String::from("\u{01f6be} \u{01f192} \u{01f193} \u{01f195} \u{01f196} \u{01f197} \u{01f199} \u{01f3e7}")) }
    | "NAUGHTY-STR-45" { Ok(String::from("0\u{fe0f}\u{20e3} 1\u{fe0f}\u{20e3} 2\u{fe0f}\u{20e3} 3\u{fe0f}\u{20e3} 4\u{fe0f}\u{20e3} 5\u{fe0f}\u{20e3} 6\u{fe0f}\u{20e3} 7\u{fe0f}\u{20e3} 8\u{fe0f}\u{20e3} 9\u{fe0f}\u{20e3} \u{01f51f}")) }
    | "NAUGHTY-STR-46" { Ok(String::from("\u{01f1fa}\u{01f1f8}\u{01f1f7}\u{01f1fa}\u{01f1f8} \u{01f1e6}\u{01f1eb}\u{01f1e6}\u{01f1f2}\u{01f1f8}")) }
    | "NAUGHTY-STR-47" { Ok(String::from("\u{01f1fa}\u{01f1f8}\u{01f1f7}\u{01f1fa}\u{01f1f8}\u{01f1e6}\u{01f1eb}\u{01f1e6}\u{01f1f2}")) }
    | "NAUGHTY-STR-48" { Ok(String::from("\u{01f1fa}\u{01f1f8}\u{01f1f7}\u{01f1fa}\u{01f1f8}\u{01f1e6}")) }
    | "NAUGHTY-STR-49" { Ok(String::from("\u{ff11}\u{ff12}\u{ff13}")) }
    | "NAUGHTY-STR-50" { Ok(String::from("\u{0661}\u{0662}\u{0663}")) }
    | "NAUGHTY-STR-51" { Ok(String::from("\u{062b}\u{0645} \u{0646}\u{0641}\u{0633} \u{0633}\u{0642}\u{0637}\u{062a} \u{0648}\u{0628}\u{0627}\u{0644}\u{062a}\u{062d}\u{062f}\u{064a}\u{062f}\u{060c}, \u{062c}\u{0632}\u{064a}\u{0631}\u{062a}\u{064a} \u{0628}\u{0627}\u{0633}\u{062a}\u{062e}\u{062f}\u{0627}\u{0645} \u{0623}\u{0646} \u{062f}\u{0646}\u{0648}. \u{0625}\u{0630} \u{0647}\u{0646}\u{0627}\u{061f} \u{0627}\u{0644}\u{0633}\u{062a}\u{0627}\u{0631} \u{0648}\u{062a}\u{0646}\u{0635}\u{064a}\u{0628} \u{0643}\u{0627}\u{0646}. \u{0623}\u{0647}\u{0651}\u{0644} \u{0627}\u{064a}\u{0637}\u{0627}\u{0644}\u{064a}\u{0627}\u{060c} \u{0628}\u{0631}\u{064a}\u{0637}\u{0627}\u{0646}\u{064a}\u{0627}-\u{0641}\u{0631}\u{0646}\u{0633}\u{0627} \u{0642}\u{062f} \u{0623}\u{062e}\u{0630}. \u{0633}\u{0644}\u{064a}\u{0645}\u{0627}\u{0646}\u{060c} \u{0625}\u{062a}\u{0641}\u{0627}\u{0642}\u{064a}\u{0629} \u{0628}\u{064a}\u{0646} \u{0645}\u{0627}, \u{064a}\u{0630}\u{0643}\u{0631} \u{0627}\u{0644}\u{062d}\u{062f}\u{0648}\u{062f} \u{0623}\u{064a} \u{0628}\u{0639}\u{062f}, \u{0645}\u{0639}\u{0627}\u{0645}\u{0644}\u{0629} \u{0628}\u{0648}\u{0644}\u{0646}\u{062f}\u{0627}\u{060c} \u{0627}\u{0644}\u{0625}\u{0637}\u{0644}\u{0627}\u{0642} \u{0639}\u{0644} \u{0625}\u{064a}\u{0648}.")) }
    | "NAUGHTY-STR-52" { Ok(String::from("\u{05d1}\u{05b0}\u{05bc}\u{05e8}\u{05b5}\u{05d0}\u{05e9}\u{05b4}\u{05c1}\u{05d9}\u{05ea}, \u{05d1}\u{05b8}\u{05bc}\u{05e8}\u{05b8}\u{05d0} \u{05d0}\u{05b1}\u{05dc}\u{05b9}\u{05d4}\u{05b4}\u{05d9}\u{05dd}, \u{05d0}\u{05b5}\u{05ea} \u{05d4}\u{05b7}\u{05e9}\u{05b8}\u{05bc}\u{05c1}\u{05de}\u{05b7}\u{05d9}\u{05b4}\u{05dd}, \u{05d5}\u{05b0}\u{05d0}\u{05b5}\u{05ea} \u{05d4}\u{05b8}\u{05d0}\u{05b8}\u{05e8}\u{05b6}\u{05e5}")) }
    | "NAUGHTY-STR-53" { Ok(String::from("\u{05d4}\u{05b8}\u{05d9}\u{05b0}\u{05ea}\u{05b8}\u{05d4}test\u{0627}\u{0644}\u{0635}\u{0641}\u{062d}\u{0627}\u{062a} \u{0627}\u{0644}\u{062a}\u{0651}\u{062d}\u{0648}\u{0644}")) }
    | "NAUGHTY-STR-54" { Ok(String::from("\u{0645}\u{064f}\u{0646}\u{064e}\u{0627}\u{0642}\u{064e}\u{0634}\u{064e}\u{0629}\u{064f} \u{0633}\u{064f}\u{0628}\u{064f}\u{0644}\u{0650} \u{0627}\u{0650}\u{0633}\u{0652}\u{062a}\u{0650}\u{062e}\u{0652}\u{062f}\u{064e}\u{0627}\u{0645}\u{0650} \u{0627}\u{0644}\u{0644}\u{064f}\u{0651}\u{063a}\u{064e}\u{0629}\u{0650} \u{0641}\u{0650}\u{064a} \u{0627}\u{0644}\u{0646}\u{064f}\u{0651}\u{0638}\u{064f}\u{0645}\u{0650} \u{0627}\u{0644}\u{0652}\u{0642}\u{064e}\u{0627}\u{0626}\u{0650}\u{0645}\u{064e}\u{0629}\u{0650} \u{0648}\u{064e}\u{0641}\u{0650}\u{064a}\u{0645} \u{064a}\u{064e}\u{062e}\u{064f}\u{0635}\u{064e}\u{0651} \u{0627}\u{0644}\u{062a}\u{064e}\u{0651}\u{0637}\u{0652}\u{0628}\u{0650}\u{064a}\u{0642}\u{064e}\u{0627}\u{062a}\u{064f} \u{0627}\u{0644}\u{0652}\u{062d}\u{0627}\u{0633}\u{064f}\u{0648}\u{0628}\u{0650}\u{064a}\u{064e}\u{0651}\u{0629}\u{064f}\u{060c} ")) }
    | "NAUGHTY-STR-55" { Ok(String::from("\u{1e70}\u{033a}\u{033a}\u{0315}o\u{035e} \u{0337}i\u{0332}\u{032c}\u{0347}\u{032a}\u{0359}n\u{031d}\u{0317}\u{0355}v\u{031f}\u{031c}\u{0318}\u{0326}\u{035f}o\u{0336}\u{0319}\u{0330}\u{0320}k\u{00e8}\u{035a}\u{032e}\u{033a}\u{032a}\u{0339}\u{0331}\u{0324} \u{0316}t\u{031d}\u{0355}\u{0333}\u{0323}\u{033b}\u{032a}\u{035e}h\u{033c}\u{0353}\u{0332}\u{0326}\u{0333}\u{0318}\u{0332}e\u{0347}\u{0323}\u{0330}\u{0326}\u{032c}\u{034e} \u{0322}\u{033c}\u{033b}\u{0331}\u{0318}h\u{035a}\u{034e}\u{0359}\u{031c}\u{0323}\u{0332}\u{0345}i\u{0326}\u{0332}\u{0323}\u{0330}\u{0324}v\u{033b}\u{034d}e\u{033a}\u{032d}\u{0333}\u{032a}\u{0330}-m\u{0322}i\u{0345}n\u{0316}\u{033a}\u{031e}\u{0332}\u{032f}\u{0330}d\u{0335}\u{033c}\u{031f}\u{0359}\u{0329}\u{033c}\u{0318}\u{0333} \u{031e}\u{0325}\u{0331}\u{0333}\u{032d}r\u{031b}\u{0317}\u{0318}e\u{0359}p\u{0360}r\u{033c}\u{031e}\u{033b}\u{032d}\u{0317}e\u{033a}\u{0320}\u{0323}\u{035f}s\u{0318}\u{0347}\u{0333}\u{034d}\u{031d}\u{0349}e\u{0349}\u{0325}\u{032f}\u{031e}\u{0332}\u{035a}\u{032c}\u{035c}\u{01f9}\u{032c}\u{034e}\u{034e}\u{031f}\u{0316}\u{0347}\u{0324}t\u{034d}\u{032c}\u{0324}\u{0353}\u{033c}\u{032d}\u{0358}\u{0345}i\u{032a}\u{0331}n\u{0360}g\u{0334}\u{0349} \u{034f}\u{0349}\u{0345}c\u{032c}\u{031f}h\u{0361}a\u{032b}\u{033b}\u{032f}\u{0358}o\u{032b}\u{031f}\u{0316}\u{034d}\u{0319}\u{031d}\u{0349}s\u{0317}\u{0326}\u{0332}.\u{0328}\u{0339}\u{0348}\u{0323}")) }
    | "NAUGHTY-STR-56" { Ok(String::from("\u{0321}\u{0353}\u{031e}\u{0345}I\u{0317}\u{0318}\u{0326}\u{035d}n\u{0347}\u{0347}\u{0359}v\u{032e}\u{032b}ok\u{0332}\u{032b}\u{0319}\u{0348}i\u{0316}\u{0359}\u{032d}\u{0339}\u{0320}\u{031e}n\u{0321}\u{033b}\u{032e}\u{0323}\u{033a}g\u{0332}\u{0348}\u{0359}\u{032d}\u{0359}\u{032c}\u{034e} \u{0330}t\u{0354}\u{0326}h\u{031e}\u{0332}e\u{0322}\u{0324} \u{034d}\u{032c}\u{0332}\u{0356}f\u{0334}\u{0318}\u{0355}\u{0323}\u{00e8}\u{0356}\u{1eb9}\u{0325}\u{0329}l\u{0356}\u{0354}\u{035a}i\u{0353}\u{035a}\u{0326}\u{0360}n\u{0356}\u{034d}\u{0317}\u{0353}\u{0333}\u{032e}g\u{034d} \u{0328}o\u{035a}\u{032a}\u{0361}f\u{0318}\u{0323}\u{032c} \u{0316}\u{0318}\u{0356}\u{031f}\u{0359}\u{032e}c\u{0489}\u{0354}\u{032b}\u{0356}\u{0353}\u{0347}\u{0356}\u{0345}h\u{0335}\u{0324}\u{0323}\u{035a}\u{0354}\u{00e1}\u{0317}\u{033c}\u{0355}\u{0345}o\u{033c}\u{0323}\u{0325}s\u{0331}\u{0348}\u{033a}\u{0316}\u{0326}\u{033b}\u{0362}.\u{031b}\u{0316}\u{031e}\u{0320}\u{032b}\u{0330}")) }
    | "NAUGHTY-STR-57" { Ok(String::from("\u{0317}\u{033a}\u{0356}\u{0339}\u{032f}\u{0353}\u{1e6e}\u{0324}\u{034d}\u{0325}\u{0347}\u{0348}h\u{0332}\u{0301}e\u{034f}\u{0353}\u{033c}\u{0317}\u{0319}\u{033c}\u{0323}\u{0354} \u{0347}\u{031c}\u{0331}\u{0320}\u{0353}\u{034d}\u{0345}N\u{0355}\u{0360}e\u{0317}\u{0331}z\u{0318}\u{031d}\u{031c}\u{033a}\u{0359}p\u{0324}\u{033a}\u{0339}\u{034d}\u{032f}\u{035a}e\u{0320}\u{033b}\u{0320}\u{035c}r\u{0328}\u{0324}\u{034d}\u{033a}\u{0316}\u{0354}\u{0316}\u{0316}d\u{0320}\u{031f}\u{032d}\u{032c}\u{031d}\u{035f}i\u{0326}\u{0356}\u{0329}\u{0353}\u{0354}\u{0324}a\u{0320}\u{0317}\u{032c}\u{0349}\u{0319}n\u{035a}\u{035c} \u{033b}\u{031e}\u{0330}\u{035a}\u{0345}h\u{0335}\u{0349}i\u{0333}\u{031e}v\u{0322}\u{0347}\u{1e19}\u{034e}\u{035f}-\u{0489}\u{032d}\u{0329}\u{033c}\u{0354}m\u{0324}\u{032d}\u{032b}i\u{0355}\u{0347}\u{031d}\u{0326}n\u{0317}\u{0359}\u{1e0d}\u{031f} \u{032f}\u{0332}\u{0355}\u{035e}\u{01eb}\u{031f}\u{032f}\u{0330}\u{0332}\u{0359}\u{033b}\u{031d}f \u{032a}\u{0330}\u{0330}\u{0317}\u{0316}\u{032d}\u{0318}\u{0358}c\u{0326}\u{034d}\u{0332}\u{031e}\u{034d}\u{0329}\u{0319}\u{1e25}\u{035a}a\u{032e}\u{034e}\u{031f}\u{0319}\u{035c}\u{01a1}\u{0329}\u{0339}\u{034e}s\u{0324}.\u{031d}\u{031d} \u{0489}Z\u{0321}\u{0316}\u{031c}\u{0356}\u{0330}\u{0323}\u{0349}\u{031c}a\u{0356}\u{0330}\u{0359}\u{032c}\u{0361}l\u{0332}\u{032b}\u{0333}\u{034d}\u{0329}g\u{0321}\u{031f}\u{033c}\u{0331}\u{035a}\u{031e}\u{032c}\u{0345}o\u{0317}\u{035c}.\u{031f}")) }
    | "NAUGHTY-STR-58" { Ok(String::from("\u{0326}H\u{032c}\u{0324}\u{0317}\u{0324}\u{035d}e\u{035c} \u{031c}\u{0325}\u{031d}\u{033b}\u{034d}\u{031f}\u{0301}w\u{0315}h\u{0316}\u{032f}\u{0353}o\u{031d}\u{0359}\u{0316}\u{034e}\u{0331}\u{032e} \u{0489}\u{033a}\u{0319}\u{031e}\u{031f}\u{0348}W\u{0337}\u{033c}\u{032d}a\u{033a}\u{032a}\u{034d}\u{012f}\u{0348}\u{0355}\u{032d}\u{0359}\u{032f}\u{031c}t\u{0336}\u{033c}\u{032e}s\u{0318}\u{0359}\u{0356}\u{0315} \u{0320}\u{032b}\u{0320}B\u{033b}\u{034d}\u{0359}\u{0349}\u{0333}\u{0345}e\u{0335}h\u{0335}\u{032c}\u{0347}\u{032b}\u{0359}i\u{0339}\u{0353}\u{0333}\u{0333}\u{032e}\u{034e}\u{032b}\u{0315}n\u{035f}d\u{0334}\u{032a}\u{031c}\u{0316} \u{0330}\u{0349}\u{0329}\u{0347}\u{0359}\u{0332}\u{035e}\u{0345}T\u{0356}\u{033c}\u{0353}\u{032a}\u{0362}h\u{034f}\u{0353}\u{032e}\u{033b}e\u{032c}\u{031d}\u{031f}\u{0345} \u{0324}\u{0339}\u{031d}W\u{0359}\u{031e}\u{031d}\u{0354}\u{0347}\u{035d}\u{0345}a\u{034f}\u{0353}\u{0354}\u{0339}\u{033c}\u{0323}l\u{0334}\u{0354}\u{0330}\u{0324}\u{031f}\u{0354}\u{1e3d}\u{032b}.\u{0355}")) }
    | "NAUGHTY-STR-59" { Ok(String::from("Z\u{032e}\u{031e}\u{0320}\u{0359}\u{0354}\u{0345}\u{1e00}\u{0317}\u{031e}\u{0348}\u{033b}\u{0317}\u{1e36}\u{0359}\u{034e}\u{032f}\u{0339}\u{031e}\u{0353}G\u{033b}O\u{032d}\u{0317}\u{032e}")) }
    | "NAUGHTY-STR-60" { Ok(String::from("\u{02d9}\u{0250}nb\u{1d09}l\u{0250} \u{0250}u\u{0183}\u{0250}\u{026f} \u{01dd}\u{0279}olop \u{0287}\u{01dd} \u{01dd}\u{0279}oq\u{0250}l \u{0287}n \u{0287}unp\u{1d09}p\u{1d09}\u{0254}u\u{1d09} \u{0279}od\u{026f}\u{01dd}\u{0287} po\u{026f}sn\u{1d09}\u{01dd} op p\u{01dd}s '\u{0287}\u{1d09}l\u{01dd} \u{0183}u\u{1d09}\u{0254}s\u{1d09}d\u{1d09}p\u{0250} \u{0279}n\u{0287}\u{01dd}\u{0287}\u{0254}\u{01dd}suo\u{0254} '\u{0287}\u{01dd}\u{026f}\u{0250} \u{0287}\u{1d09}s \u{0279}olop \u{026f}nsd\u{1d09} \u{026f}\u{01dd}\u{0279}o\u{02e5}")) }
    | "NAUGHTY-STR-61" { Ok(String::from("00\u{02d9}\u{0196}\u{0024}-")) }
    | "NAUGHTY-STR-62" { Ok(String::from("\u{ff34}\u{ff48}\u{ff45} \u{ff51}\u{ff55}\u{ff49}\u{ff43}\u{ff4b} \u{ff42}\u{ff52}\u{ff4f}\u{ff57}\u{ff4e} \u{ff46}\u{ff4f}\u{ff58} \u{ff4a}\u{ff55}\u{ff4d}\u{ff50}\u{ff53} \u{ff4f}\u{ff56}\u{ff45}\u{ff52} \u{ff54}\u{ff48}\u{ff45} \u{ff4c}\u{ff41}\u{ff5a}\u{ff59} \u{ff44}\u{ff4f}\u{ff47}")) }
    | "NAUGHTY-STR-63" { Ok(String::from("\u{01d413}\u{01d421}\u{01d41e} \u{01d42a}\u{01d42e}\u{01d422}\u{01d41c}\u{01d424} \u{01d41b}\u{01d42b}\u{01d428}\u{01d430}\u{01d427} \u{01d41f}\u{01d428}\u{01d431} \u{01d423}\u{01d42e}\u{01d426}\u{01d429}\u{01d42c} \u{01d428}\u{01d42f}\u{01d41e}\u{01d42b} \u{01d42d}\u{01d421}\u{01d41e} \u{01d425}\u{01d41a}\u{01d433}\u{01d432} \u{01d41d}\u{01d428}\u{01d420}")) }
    | "NAUGHTY-STR-64" { Ok(String::from("\u{01d57f}\u{01d58d}\u{01d58a} \u{01d596}\u{01d59a}\u{01d58e}\u{01d588}\u{01d590} \u{01d587}\u{01d597}\u{01d594}\u{01d59c}\u{01d593} \u{01d58b}\u{01d594}\u{01d59d} \u{01d58f}\u{01d59a}\u{01d592}\u{01d595}\u{01d598} \u{01d594}\u{01d59b}\u{01d58a}\u{01d597} \u{01d599}\u{01d58d}\u{01d58a} \u{01d591}\u{01d586}\u{01d59f}\u{01d59e} \u{01d589}\u{01d594}\u{01d58c}")) }
    | "NAUGHTY-STR-65" { Ok(String::from("\u{01d47b}\u{01d489}\u{01d486} \u{01d492}\u{01d496}\u{01d48a}\u{01d484}\u{01d48c} \u{01d483}\u{01d493}\u{01d490}\u{01d498}\u{01d48f} \u{01d487}\u{01d490}\u{01d499} \u{01d48b}\u{01d496}\u{01d48e}\u{01d491}\u{01d494} \u{01d490}\u{01d497}\u{01d486}\u{01d493} \u{01d495}\u{01d489}\u{01d486} \u{01d48d}\u{01d482}\u{01d49b}\u{01d49a} \u{01d485}\u{01d490}\u{01d488}")) }
    | "NAUGHTY-STR-66" { Ok(String::from("\u{01d4e3}\u{01d4f1}\u{01d4ee} \u{01d4fa}\u{01d4fe}\u{01d4f2}\u{01d4ec}\u{01d4f4} \u{01d4eb}\u{01d4fb}\u{01d4f8}\u{01d500}\u{01d4f7} \u{01d4ef}\u{01d4f8}\u{01d501} \u{01d4f3}\u{01d4fe}\u{01d4f6}\u{01d4f9}\u{01d4fc} \u{01d4f8}\u{01d4ff}\u{01d4ee}\u{01d4fb} \u{01d4fd}\u{01d4f1}\u{01d4ee} \u{01d4f5}\u{01d4ea}\u{01d503}\u{01d502} \u{01d4ed}\u{01d4f8}\u{01d4f0}")) }
    | "NAUGHTY-STR-67" { Ok(String::from("\u{01d54b}\u{01d559}\u{01d556} \u{01d562}\u{01d566}\u{01d55a}\u{01d554}\u{01d55c} \u{01d553}\u{01d563}\u{01d560}\u{01d568}\u{01d55f} \u{01d557}\u{01d560}\u{01d569} \u{01d55b}\u{01d566}\u{01d55e}\u{01d561}\u{01d564} \u{01d560}\u{01d567}\u{01d556}\u{01d563} \u{01d565}\u{01d559}\u{01d556} \u{01d55d}\u{01d552}\u{01d56b}\u{01d56a} \u{01d555}\u{01d560}\u{01d558}")) }
    | "NAUGHTY-STR-68" { Ok(String::from("\u{01d683}\u{01d691}\u{01d68e} \u{01d69a}\u{01d69e}\u{01d692}\u{01d68c}\u{01d694} \u{01d68b}\u{01d69b}\u{01d698}\u{01d6a0}\u{01d697} \u{01d68f}\u{01d698}\u{01d6a1} \u{01d693}\u{01d69e}\u{01d696}\u{01d699}\u{01d69c} \u{01d698}\u{01d69f}\u{01d68e}\u{01d69b} \u{01d69d}\u{01d691}\u{01d68e} \u{01d695}\u{01d68a}\u{01d6a3}\u{01d6a2} \u{01d68d}\u{01d698}\u{01d690}")) }
    | "NAUGHTY-STR-69" { Ok(String::from("\u{24af}\u{24a3}\u{24a0} \u{24ac}\u{24b0}\u{24a4}\u{249e}\u{24a6} \u{249d}\u{24ad}\u{24aa}\u{24b2}\u{24a9} \u{24a1}\u{24aa}\u{24b3} \u{24a5}\u{24b0}\u{24a8}\u{24ab}\u{24ae} \u{24aa}\u{24b1}\u{24a0}\u{24ad} \u{24af}\u{24a3}\u{24a0} \u{24a7}\u{249c}\u{24b5}\u{24b4} \u{249f}\u{24aa}\u{24a2}")) }
    | "NAUGHTY-STR-70" { Ok(String::from("Roses are red, violets are blue. Hope you enjoy terminal hue")) }
    | "NAUGHTY-STR-71" { Ok(String::from("But now...\u{001b}[20Cfor my greatest trick...\u{001b}[8m")) }
    | "NAUGHTY-STR-72" { Ok(String::from("The quic\u{0008}\u{0008}\u{0008}\u{0008}\u{0008}\u{0008}k brown fo\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}\u{0007}x... [Beeeep]")) }
    | "NAUGHTY-STR-73" { Ok(String::from("Power\u{0644}\u{064f}\u{0644}\u{064f}\u{0635}\u{0651}\u{0628}\u{064f}\u{0644}\u{064f}\u{0644}\u{0635}\u{0651}\u{0628}\u{064f}\u{0631}\u{0631}\u{064b} \u{0963} \u{0963}h \u{0963} \u{0963}\u{5197}")) }
    | "NAUGHTY-STR-74" { Ok(String::from("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ")) }
    ;
identifier -> Result<String, ()>
    : "IDENTIFIER" { Ok(identifier($1, $lexer)) }
    | "UNDEFINED" { Ok(String::from("undefined")) }
    | "ARGUMENTS" { Ok(String::from("arguments")) }
    | var { Ok($1?) }
    | "NULL" { Ok(String::from("null")) }
    | "NAN" { Ok(String::from("NaN")) }
    | "RECIPROCALSQRTAPPROXIMATION" { Ok(String::from("reciprocalSqrtApproximation")) }
    ;
unmatched -> ():
  "UNMATCHED" { } 
  ;

%%

use rand::Rng;
use rand::seq::SliceRandom;

static IDENTIFIERS: [&str; 56] = ["WebAssembly.CompileError", "WebAssembly.RuntimeError", "WebAssembly.LinkError", "WebAssembly.Instance", "Intl.DateTimeFormat", "WebAssembly.Memory", "WebAssembly.Module", "Intl.NumberFormat", "Uint8ClampedArray", "WebAssembly.Table", "Intl.PluralRules", "ReferenceError", "asyncGenerator", "AsyncFunction", "Intl.Collator", "Float32Array", "Float64Array", "ArrayBuffer", "SyntaxError", "Uint16Array", "Uint32Array", "WebAssembly", "Int16Array", "Int32Array", "RangeError", "Uint8Array", "EvalError", "Int8Array", "TypeError", "DataView", "Function", "Infinity", "URIError", "Boolean", "Promise", "Reflect", "WeakMap", "WeakSet", "console", "Number", "Object", "RegExp", "String", "Symbol", "Array", "Error", "Proxy", "Date", "Intl", "JSON", "Math", "main", "this", "Map", "Set", "opt"];
static NAUGHTY_STR_TEST: [&str; 5] = ["\u{202a}\u{202a}test\u{202a}", "\u{202b}test\u{202b}", "\u{2029}test\u{2029}", "test\u{2060}test\u{202b}", "\u{2066}test\u{2067}"];
static TYPE_CONVERSION: [&str; 6] = ["fromUint16x8Bits", "fromUint32x4Bits", "fromUint8x16Bits", "fromInt16x8Bits", "fromInt32x4Bits", "fromInt8x16Bits"];
static SIMD_TYPE: [&str; 12] = ["Bool8x16", "Bool16x8", "Bool32x4", "Bool64x2", "Int8x16", "Int16x8", "Int32x4", "Uint8x16", "Uint16x8", "Uint32x4", "Float32x4", "Float64x2"];
static NUMBER: [&str; 36] = ["999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999", "123456789012345678901234567890123456789", "-9223372036854775808/-1", "2.2250738585072011e-308", "0xffffffffffffffff", "-2147483648/-1", "0xabad1dea", "0xffffffff", "100000.000", "1000000.00", "100000000", "0,0/0,0", "0.0/0.0", "1,0/0,0", "1.0/0.0", "1000.00", "-1E+02", "-1.00", "-1E02", "0.0/0", "01000", "1E+02", "+0.0", "-0.0", "-1/2", "-1E2", "0,00", "0.00", "1.00", "1E02", "--1", "0/0", "0x0", "1/0", "1/2", "1E2"];
static SIMD_FUNCTION: [&str; 46] = ["reciprocalApproximation", "greaterThanOrEqual", "shiftLeftByScalar", "lessThanOrEqual", "fromUint32x4", "extractLane", "fromInt32x4", "greaterThan", "subSaturate", "lessThan", "notEqual", "allTrue", "anyTrue", "shuffle", "swizzle", "maxNum", "minNum", "select", "store1", "store2", "store3", "check", "equal", "load1", "load2", "load3", "splat", "store", "load", "shiftRightByScalar", "fromFloat32x4Bits", "fromFloat64x2Bits", "fromFloat32x4", "sqrt", "abs", "add", "and", "div", "max", "min", "mul", "neg", "not", "sub", "xor", "or"];
static PROPERTY: [&str; 52] = ["isConcatSpreadable", "BYTES_PER_ELEMENT", "NEGATIVE_INFINITY", "POSITIVE_INFINITY", "MAX_SAFE_INTEGER", "MIN_SAFE_INTEGER", "__noSuchMethod__", "asyncIterator", "columnNumber", "constructor", "displayName", "hasInstance", "toPrimitive", "toStringTag", "unscopables", "__parent__", "byteLength", "byteOffset", "ignoreCase", "lineNumber", "MAX_VALUE", "MIN_VALUE", "__count__", "__proto__", "multiline", "prototype", "fileName", "iterator", "EPSILON", "SQRT1_2", "compare", "message", "species", "unicode", "LOG10E", "buffer", "callee", "caller", "format", "global", "length", "memory", "source", "sticky", "LOG2E", "SQRT2", "arity", "flags", "LN10", "name", "LN2", "PI"];
//static VARIABLES: [&str; 15] = [""];
static METHOD_NAME: [&str; 256] = ["getOwnPropertyDescriptors", "getOwnPropertyDescriptor", "getOwnPropertySymbols", "instantiateStreaming", "propertyIsEnumerable", "getCanonicalLocales", "getOwnPropertyNames", "decodeURIComponent", "encodeURIComponent", "getUTCMilliseconds", "setUTCMilliseconds", "supportedLocalesOf", "toLocaleDateString", "toLocaleTimeString", "getTimezoneOffset", "preventExtensions", "toLocaleLowerCase", "toLocaleUpperCase", "__defineGetter__", "__defineSetter__", "__lookupGetter__", "__lookupSetter__", "compileStreaming", "defineProperties", "compareExchange", "getMilliseconds", "resolvedOptions", "setMilliseconds", "customSections", "defineProperty", "deleteProperty", "getPrototypeOf", "getUTCFullYear", "setPrototypeOf", "setUTCFullYear", "toLocaleFormat", "toLocaleString", "formatToParts", "fromCodePoint", "getUTCMinutes", "getUTCSeconds", "isPrototypeOf", "isSafeInteger", "localeCompare", "setUTCMinutes", "setUTCSeconds", "toExponential", "fromCharCode", "isExtensible", "toDateString", "toTimeString", "codePointAt", "getFullYear", "getUTCHours", "getUTCMonth", "instantiate", "isGenerator", "lastIndexOf", "reduceRight", "setFullYear", "setUTCHours", "setUTCMonth", "toGMTString", "toISOString", "toLowerCase", "toPrecision", "toUTCString", "toUpperCase", "charCodeAt", "copyWithin", "getFloat32", "getFloat64", "getMinutes", "getSeconds", "getUTCDate", "instanceof", "isLockFree", "parseFloat", "setFloat32", "setFloat64", "setMinutes", "setSeconds", "setUTCDate", "startsWith", "construct", "decodeURI", "encodeURI", "findIndex", "fontcolor", "getUTCDay", "getUint16", "getUint32", "isInteger", "normalize", "setUint16", "setUint32", "stringify", "substring", "toInteger", "trimright", "endsWith", "exchange", "fontsize", "getHours", "getInt16", "getInt32", "getMonth", "getUint8", "includes", "isFinite", "isFrozen", "isSealed", "padStart", "parseInt", "setHours", "setInt16", "setInt32", "setMonth", "setUint8", "toSource", "toString", "transfer", "trimleft", "unescape", "validate", "compile", "entries", "finally", "forEach", "getDate", "getInt8", "getTime", "getYear", "imports", "indexOf", "isArray", "italics", "ownKeys", "resolve", "reverse", "setDate", "setInt8", "setTime", "setYear", "toFixed", "unshift", "unwatch", "valueOf", "anchor", "assign", "charAt", "concat", "create", "escape", "filter", "freeze", "fround", "getDay", "isView", "keyFor", "padEnd", "random", "reduce", "reject", "repeat", "splice", "strcmp", "strike", "substr", "toJSON", "uneval", "values", "acosh", "apply", "asinh", "atan2", "atanh", "blink", "catch", "clear", "close", "clz32", "every", "expm1", "fixed", "floor", "hypot", "isNaN", "log10", "log1p", "parse", "print", "quote", "round", "shift", "slice", "small", "super", "throw", "trunc", "watch", "acos", "asin", "atan", "bind", "bold", "call", "cbrt", "ceil", "cosh", "eval", "exec", "fill", "grow", "imul", "join", "keys", "link", "log2", "move", "next", "push", "race", "seal", "send", "sign", "sinh", "some", "sort", "tanh", "test", "then", "trim", "wait", "wake", "UTC", "all", "big", "cos", "exp", "for", "get", "has", "log", "map", "now", "pop", "pow", "raw", "set", "sin", "sup", "tan", "in", "is", "of"];
static UNICODE_NAUGHTY: [&str; 14] = ["\u{01f60d}", "\u{023a}", "\u{023e}", "\u{1680}", "\u{180e}", "\u{200b}", "\u{2421}", "\u{2422}", "\u{2423}", "\u{3000}", "\u{fdfa}", "\u{fdfd}", "\u{feff}", "\u{fffe}"];
static NAUGHTY_STR: [&str; 36] = ["undef", "en-US", "year", "NULL", "nil", "NIL", "True", "False", "TRUE", "FALSE", "None", ",./;'[]\\\\-=", "<>?:\"{}|_+", "!@#\u{0024}%^&*()`~", "\'\"\'", "\"\'\'\'\'\"\'\"", "\"\'\"\'\"\'\'\'\'\"", "__\u{ff9b}(,_,*)", "--version", "--help", "+++ATH0", "CLOCK\u{0024}", "\u{0024}USER", "COM1", "COM2", "LPT1", "AUX", "CON", "NUL", "PRN", "ZZ:", "A:", "`ls -al /`", "<<< %s(un=\'%s\') = %u", "DCC SEND STARTKEYLOGGER 0 0 0", "http://www.cum.qc.ca/"];

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

fn naughty_str<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = NAUGHTY_STR.choose(&mut rng).unwrap_or(&"error");
            keyword.to_string()
        }
  }
}

fn simd_function<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = SIMD_FUNCTION.choose(&mut rng).unwrap_or(&"error");
            keyword.to_string()
        }
  }
}

fn method_name<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = METHOD_NAME.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn type_conversion<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = TYPE_CONVERSION.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn simd_type<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = SIMD_TYPE.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn property<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = PROPERTY.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn number<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = NUMBER.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn unicode_naughty<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = UNICODE_NAUGHTY.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn naughty_str_test<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = NAUGHTY_STR_TEST.choose(&mut rng).unwrap_or(&"a");
            keyword.to_string()
        }
  }
}

fn escapedcharacters<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\\r")
  }
}

fn oct_code<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\\077")
  }
}

fn hex_code<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\\x08")
  }
}

fn unicode_4<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\\u202a")
  }
}
