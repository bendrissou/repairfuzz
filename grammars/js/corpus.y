%expect-unused unmatched "UNMATCHED"
%right ASSIGNMENT
%right MULTIPLICATION_ASSIGNMENT
%right DIVISION_ASSIGNMENT
%right MODULUS_ASSIGNMENT
%right ADDITION_ASSIGNMENT
%right SUBTRACTION_ASSIGNMENT
%right LEFT_SHIFT_ASSIGNMENT
%right SIGNED_RIGHT_SHIFT_ASSIGNMENT
%right UNSIGNED_RIGHT_SHIFT_ASSIGNMENT
%right BITWISE_AND_ASSIGNMENT
%right BITWISE_XOR_ASSIGNMENT
%right BITWISE_OR_ASSIGNMENT

%nonassoc "RIGHT_BRACE"
%nonassoc "IF"
%nonassoc "ELSE"

%expect-rr 1
%expect 131
%%

Program -> Result<String, ()>
    : { Ok(String::from("")) }
    | Element Program { Ok($1? + "\n" + &$2?) }
    ;
Element -> Result<String, ()>
    : Statement { Ok($1?) }
    ;
ParameterListOpt -> Result<String, ()>
    : { Ok(String::from("")) }
    | ParameterList { Ok($1?) }
    ;
ParameterList -> Result<String, ()>
    : Identifier { Ok($1?) }
    | Identifier "COMMA" ParameterList { Ok($1? + ", " + &$3?) }
    ;
CompoundStatement -> Result<String, ()>
    : "LEFT_BRACE" Statements "RIGHT_BRACE" { Ok(String::from("{\n") + &$2? + "}") }
    | "LEFT_BRACE" semicolon "RIGHT_BRACE" { Ok(String::from("{") + &$2? + "}") }
    ;
Statements -> Result<String, ()>
    : Statement { Ok($1? + "\n") }
    | Statement Statements { Ok($1? + "\n" + &$2?) }
    ;
Statement -> Result<String, ()>
    : "SEMICOLON" { Ok(String::from(";")) }
    | "VAR" Identifier "ASSIGNMENT" "FUNCTION" "LEFT_PAREN" ParameterListOpt "RIGHT_PAREN" CompoundStatement { Ok(String::from("var ") + &$2? + " = " + "function(" + &$6? + ") " + &$8?) }
    | ShortFuncDef { Ok($1?) }
    | "IF" Condition Statement %prec "IF" { Ok(String::from("if ") + &$2? + &$3?) }
    | "IF" Condition Statement "ELSE" Statement { Ok(String::from("if ") + &$2? + &$3? + "\nelse " + &$5?) }
    | "WHILE" Condition Statement { Ok(String::from("while ") + &$2? + &$3?) }
    | ForParen semicolon ExpressionOpt semicolon ExpressionOpt "RIGHT_PAREN" Statement { Ok($1? + &$2? + &$3? + &$4? + &$5? + ") " + &$7?) }
    | ForBegin semicolon ExpressionOpt semicolon ExpressionOpt "RIGHT_PAREN" Statement { Ok($1? + &$2? + &$3? + &$4? + &$5? + ") " + &$7?) }
    | ForBegin "IN" Expression "RIGHT_PAREN" Statement { Ok($1? + " in " + &$3? + ") " + &$5?) }
    | "BREAK" semicolon { Ok(String::from("break") + &$2?) }
    | "CONTINUE" semicolon { Ok(String::from("continue") + &$2?) }
    | "WITH" "LEFT_PAREN" Expression "RIGHT_PAREN" Statement { Ok(String::from("with (") + &$3? + ") " + &$5?) }
    | "RETURN" ExpressionOpt semicolon { Ok(String::from("return ") + &$2? + &$3?) }
    | CompoundStatement { Ok($1?) }
    | VariablesOrExpression semicolon { Ok($1? + &$2?) }
    ;
semicolon -> Result<String, ()>
    : "SEMICOLON" { Ok(String::from(";")) }
    | { Ok(String::from("")) }
    ;
ShortFuncDef -> Result<String, ()>
    :"FUNCTION" Identifier "LEFT_PAREN" ParameterListOpt "RIGHT_PAREN" CompoundStatement { Ok(String::from("function ") + &$2? + "(" + &$4? + ") " + &$6?) }
    ;
Condition -> Result<String, ()>
    : "LEFT_PAREN" Expression "RIGHT_PAREN" { Ok(String::from("(") + &$2? + ") ") }
    ;
ForParen -> Result<String, ()>
    : "FOR" "LEFT_PAREN" { Ok(String::from("for (")) }
    ;
ForBegin -> Result<String, ()>
    : ForParen VariablesOrExpression { Ok($1? + &$2?) }
    ;
VariablesOrExpression -> Result<String, ()>
    : "VAR" Variables { Ok(String::from("var ") + &$2?) }
    | "LET" Variables { Ok(String::from("let ") + &$2?) }
    | Expression { Ok($1?) }
    ;
Variables -> Result<String, ()>
    : Variable { Ok($1?) }
    | Variable "COMMA" Variables { Ok($1? + ", " + &$3?) }
    ;
Variable -> Result<String, ()>
    : Identifier { Ok($1?) }
    | Identifier "ASSIGNMENT" AssignmentExpression { Ok($1? + " = " + &$3?) }
    ;
ExpressionOpt -> Result<String, ()>
    : { Ok(String::from("")) }
    | Expression { Ok($1?) }
    ;
Expression -> Result<String, ()>
    : AssignmentExpression { Ok($1?) }
    | AssignmentExpression "COMMA" Expression { Ok($1? + ", " + &$3?) }
    ;
AssignmentExpression -> Result<String, ()>
    : ConditionalExpression %prec "ASSIGNMENT" { Ok($1?) }
    | Identifier "ARROW" Statement { Ok($1? + " => " + &$3?) }
    | ConditionalExpression AssignmentOperator AssignmentExpression { Ok($1? + " " + &$2? + " " + &$3?) }
    ;
ConditionalExpression -> Result<String, ()>
    : OrExpression { Ok($1?) }
    | OrExpression "QUESTION_MARK" AssignmentExpression "COLON" AssignmentExpression { Ok($1? + "? " + &$3? + " : " + &$5?) }
    ;
OrExpression -> Result<String, ()>
    : AndExpression { Ok($1?) }
    | AndExpression "LOGICAL_OR" OrExpression { Ok($1? + " || " + &$3?) }
    ;
AndExpression -> Result<String, ()>
    : BitwiseOrExpression { Ok($1?) }
    | BitwiseOrExpression "LOGICAL_AND" AndExpression { Ok($1? + " && " + &$3?) }
    ;
BitwiseOrExpression -> Result<String, ()>
    : BitwiseXorExpression { Ok($1?) }
    | BitwiseXorExpression "BITWISE_OR" BitwiseOrExpression { Ok($1? + " | " + &$3?) }
    ;
BitwiseXorExpression -> Result<String, ()>
    : BitwiseAndExpression { Ok($1?) }
    | BitwiseAndExpression "BITWISE_XOR" BitwiseXorExpression { Ok($1? + " ^ " + &$3?) }
    ;
BitwiseAndExpression -> Result<String, ()>
    : EqualityExpression { Ok($1?) }
    | EqualityExpression "BITWISE_AND" BitwiseAndExpression { Ok($1? + " & " + &$3?) }
    ;
EqualityExpression -> Result<String, ()>
    : RelationalExpression { Ok($1?) }
    | EqualityExpression "EQUAL" RelationalExpression { Ok($1? + " == " + &$3?) }
    | EqualityExpression "NOT_EQUAL" RelationalExpression { Ok($1? + " != " + &$3?) }
    | EqualityExpression "EXACTLY_EQUAL" RelationalExpression { Ok($1? + " === " + &$3?) }
    | EqualityExpression "NOT_EXACTLY_EQUAL" RelationalExpression { Ok($1? + " !== " + &$3?) }
    ;
RelationalExpression -> Result<String, ()>
    : ShiftExpression { Ok($1?) }
    | RelationalExpression "LESS_THAN" ShiftExpression { Ok($1? + " < " + &$3?) }
    | RelationalExpression "GREATER_THAN" ShiftExpression { Ok($1? + " > " + &$3?) }
    | RelationalExpression "LESS_THAN_OR_EQUAL" ShiftExpression { Ok($1? + " <= " + &$3?) }
    | RelationalExpression "GREATER_THAN_OR_EQUAL" ShiftExpression { Ok($1? + " >= " + &$3?) }
    | RelationalExpression "INSTANCEOF" ShiftExpression { Ok($1? + " instanceof " + &$3?) }
    ;
ShiftExpression -> Result<String, ()>
    : AdditiveExpression { Ok($1?) }
    | ShiftExpression "LEFT_SHIFT" AdditiveExpression { Ok($1? + " << " + &$3?) }
    | ShiftExpression "SIGNED_RIGHT_SHIFT" AdditiveExpression { Ok($1? + " >> " + &$3?) }
    | ShiftExpression "UNSIGNED_RIGHT_SHIFT" { Ok($1? + " >>> ") }
    ;
AdditiveExpression -> Result<String, ()>
    : MultiplicativeExpression { Ok($1?) }
    | MultiplicativeExpression "ADD" AdditiveExpression { Ok($1? + " + " + &$3?) }
    | MultiplicativeExpression "SUBTRACT" AdditiveExpression { Ok($1? + " - " + &$3?) }
    ;
MultiplicativeExpression -> Result<String, ()>
    : UnaryExpression { Ok($1?) }
    | UnaryExpression MultiplicativeOperator MultiplicativeExpression { Ok($1? + " " + &$2? + " " + &$3?) }
    ;
UnaryExpression -> Result<String, ()>
    : MemberExpression { Ok($1?) }
    | UnaryOperator UnaryExpression { Ok($1? + &$2?) }
    | IncrementOperator MemberExpression { Ok($1? + &$2?) }
    | MemberExpression IncrementOperator { Ok($1? + &$2?) }
    | "NEW" Constructor { Ok(String::from("new ") + &$2?) }
    | "DELETE" MemberExpression { Ok(String::from("delete ") + &$2?) }
    ;
Constructor -> Result<String, ()>
    : "THIS" "DOT" ConstructorCall { Ok(String::from("this.") + &$3?) }
    | ConstructorCall { Ok($1?) }
    ;
ConstructorCall -> Result<String, ()>
    : Identifier { Ok($1?) }
    | Identifier "LEFT_PAREN" ArgumentListOpt "RIGHT_PAREN" { Ok($1? + "(" + &$3? + ")") }
    | Identifier "DOT" ConstructorCall { Ok($1? + "." + &$3?) }
    ;
MemberExpression -> Result<String, ()>
    : PrimaryExpression { Ok($1?) }
    | MemberExpression "DOT" MemberExpression { Ok($1? + "." + &$3?) }
    | PrimaryExpression "LEFT_BRACKET" Expression "RIGHT_BRACKET" { Ok($1? + "[" + &$3? + "]") }
    | PrimaryExpression "LEFT_BRACKET" Expression "RIGHT_BRACKET" "LEFT_BRACKET" Expression "RIGHT_BRACKET" { Ok($1? + "[" + &$3? + "]" + "[" + &$6? + "]") }
    | PrimaryExpression "LEFT_PAREN" ArgumentListOpt "RIGHT_PAREN" { Ok($1? + "(" + &$3? + ")") }
    ;
ArgumentListOpt -> Result<String, ()>
    : { Ok(String::from("")) }
    | ArgumentList { Ok($1?) }
    ;
ArgumentList -> Result<String, ()>
    : AssignmentExpression { Ok($1?) }
    | AssignmentExpression "COMMA" ArgumentList { Ok($1? + ", " + &$3?) }
    ;
Identifier -> Result<String, ()>
    : "IDENTIFIER" { Ok(identifier($1, $lexer)) }
    | "DELETE" { Ok(String::from("delete")) }
    | "FUNCTION" { Ok(String::from("function")) }
    ;
UnaryOperator -> Result<String, ()>
    : "ADD" { Ok(String::from("+")) }
    | "SUBTRACT" { Ok(String::from("-")) }
    | "LOGICAL_NOT" { Ok(String::from("!")) }
    | "BITWISE_NOT" { Ok(String::from("~")) }
    | "TYPEOF" { Ok(String::from("typeof ")) }
    | "VOID" { Ok(String::from("void ")) }
    ;
IncrementOperator -> Result<String, ()>
    : "UNARY_ADD" { Ok(String::from("++")) }
    | "UNARY_SUBTRACT" { Ok(String::from("--")) }
    ;
PrimaryExpression -> Result<String, ()>
    : "LEFT_PAREN" Expression "RIGHT_PAREN" { Ok(String::from("(") + &$2? + ")") }
    | "LEFT_PAREN" ShortFuncDef "RIGHT_PAREN" { Ok(String::from("(") + &$2? + ")") }
    | Identifier { Ok($1?) }
    | Literal { Ok($1?) }
    | ArrayLiteral { Ok($1?) }
    | ObjectLiteral { Ok($1?) }
    ;
Literal -> Result<String, ()>
    : "VALUE_INTEGER" { Ok(integer($1, $lexer)) }
    | "VALUE_DOUBLE" { Ok(double($1, $lexer)) }
    | "VALUE_HEX" { Ok(double($1, $lexer)) }
    | "VALUE_STRING" { Ok(string($1, $lexer)) }
    | "LITERAL_FALSE" { Ok(String::from("false")) }
    | "LITERAL_TRUE" { Ok(String::from("true")) }
    | "LITERAL_NULL" { Ok(String::from("null")) }
    | "THIS" { Ok(String::from("this")) }
    ;
ArrayLiteral -> Result<String, ()>
    : "LEFT_BRACKET" "RIGHT_BRACKET" { Ok(String::from("[]")) }
    | "LEFT_BRACKET" Elision "RIGHT_BRACKET" { Ok(String::from("[") + &$2? + "]") }
    | "LEFT_BRACKET" ElementList "RIGHT_BRACKET" { Ok(String::from("[") + &$2? + "]") }
    | "LEFT_BRACKET" ElementList COMMA Elision "RIGHT_BRACKET" { Ok(String::from("[") + &$2? + ", " + &$4? + "]") }
    | "LEFT_BRACKET" ElementList COMMA "RIGHT_BRACKET" { Ok(String::from("[") + &$2? + "," + "]") }
    ;
ElementList -> Result<String, ()>
    : Elision AssignmentExpression { Ok($1? + &$2?) }
    | AssignmentExpression { Ok($1?) }
    | Elision SpreadElement { Ok($1? + &$2?) }
    | SpreadElement { Ok($1?) }
    | ElementList COMMA Elision AssignmentExpression { Ok($1? + ", " + &$3? + &$4?) }
    | ElementList COMMA AssignmentExpression  { Ok($1? + ", " + &$3?) }
    | ElementList COMMA Elision SpreadElement { Ok($1? + ", " + &$3? + &$4?) }
    | ElementList COMMA SpreadElement { Ok($1? + ", " + &$3?) }
    ;
Elision -> Result<String, ()>
    : COMMA { Ok(String::from(",")) }
    | Elision COMMA { Ok($1? + ",") }
    ;
SpreadElement -> Result<String, ()>
    : "DOTDOTDOT" AssignmentExpression { Ok(String::from("...") + &$2?) }
    ;
ObjectLiteral -> Result<String, ()>
    : "LEFT_BRACE" "RIGHT_BRACE" { Ok(String::from("{}")) }
    | "LEFT_BRACE" PropertyDefinitionList "RIGHT_BRACE" { Ok(String::from("{") + &$2? + "}") }
    | "LEFT_BRACE" PropertyDefinitionList COMMA "RIGHT_BRACE" { Ok(String::from("{") + &$2? + "," + "}") }
    ;
PropertyDefinitionList -> Result<String, ()>
    : PropertyDefinition { Ok($1?) }
    | PropertyDefinitionList COMMA PropertyDefinition { Ok($1? + ", " + &$3?) }
    ;
PropertyDefinition -> Result<String, ()>
    : PropertyName COLON AssignmentExpression { Ok($1? + ": " + &$3?) }
    ;
PropertyName -> Result<String, ()>
    : LiteralPropertyName { Ok($1?) }
    | ComputedPropertyName { Ok($1?) }
    ;
LiteralPropertyName -> Result<String, ()>
    : Identifier { Ok($1?) }
    | "VALUE_INTEGER" { Ok(integer($1, $lexer)) }
    | "VALUE_DOUBLE" { Ok(double($1, $lexer)) }
    | "VALUE_HEX" { Ok(double($1, $lexer)) }
    | "VALUE_STRING" { Ok(string($1, $lexer)) }
    ;
ComputedPropertyName -> Result<String, ()>
    : LEFT_BRACKET AssignmentExpression RIGHT_BRACKET { Ok(String::from("[") + &$2? + "]") }
    ;
AssignmentOperator -> Result<String, ()>
    : ASSIGNMENT { Ok(String::from("=")) }
    | "MULTIPLICATION_ASSIGNMENT" { Ok(String::from("*=")) }
    | "DIVISION_ASSIGNMENT" { Ok(String::from("/=")) }
    | "MODULUS_ASSIGNMENT" { Ok(String::from("%=")) }
    | "ADDITION_ASSIGNMENT" { Ok(String::from("+=")) }
    | "SUBTRACTION_ASSIGNMENT" { Ok(String::from("-=")) }
    | "LEFT_SHIFT_ASSIGNMENT" { Ok(String::from("<<=")) }
    | "SIGNED_RIGHT_SHIFT_ASSIGNMENT" { Ok(String::from(">>=")) }
    | "UNSIGNED_RIGHT_SHIFT_ASSIGNMENT" { Ok(String::from(">>>=")) }
    | "BITWISE_AND_ASSIGNMENT" { Ok(String::from("&=")) }
    | "BITWISE_XOR_ASSIGNMENT" { Ok(String::from("^=")) }
    | "BITWISE_OR_ASSIGNMENT" { Ok(String::from("|=")) }
    ;
MultiplicativeOperator -> Result<String, ()>
    : "MULTIPLY" { Ok(String::from("*")) }
    | "DIVIDE" { Ok(String::from("/")) }
    | "MODULO" { Ok(String::from("%")) }
    ;
unmatched -> ():
  "UNMATCHED" { } 
  ;
%%


fn double<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("0.0")
  }
}

fn integer<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("0")
  }
}

fn string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\"abc\"")
  }
}

fn identifier<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("ident")
  }
}
