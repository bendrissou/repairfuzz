/*
   +----------------------------------------------------------------------+
   | Zend Engine                                                          |
   +----------------------------------------------------------------------+
   | Copyright (c) 1998-2018 Zend Technologies Ltd. (http://www.zend.com) |
   +----------------------------------------------------------------------+
   | This source file is subject to version 2.00 of the Zend license,     |
   | that is bundled with this package in the file LICENSE, and is        |
   | available through the world-wide-web at the following url:           |
   | http://www.zend.com/license/2_00.txt.                                |
   | If you did not receive a copy of the Zend license and are unable to  |
   | obtain it through the world-wide-web, please send a note to          |
   | license@zend.com so we can mail you a copy immediately.              |
   +----------------------------------------------------------------------+
   | Authors: Andi Gutmans <andi@php.net>                                 |
   |          Zeev Suraski <zeev@php.net>                                 |
   |          Nikita Popov <nikic@php.net>                                |
   +----------------------------------------------------------------------+
*/
%expect-unused unmatched "UNMATCHED"
%left T_INCLUDE T_INCLUDE_ONCE T_EVAL T_REQUIRE T_REQUIRE_ONCE
%left ','
%left T_LOGICAL_OR
%left T_LOGICAL_XOR
%left T_LOGICAL_AND
%right T_PRINT
%right T_YIELD
%right T_DOUBLE_ARROW
%right T_YIELD_FROM
%left '=' T_PLUS_EQUAL T_MINUS_EQUAL T_MUL_EQUAL T_DIV_EQUAL T_CONCAT_EQUAL T_MOD_EQUAL T_AND_EQUAL T_OR_EQUAL T_XOR_EQUAL T_SL_EQUAL T_SR_EQUAL T_POW_EQUAL
%left '?' ':'
%right T_COALESCE
%left T_BOOLEAN_OR
%left T_BOOLEAN_AND
%left '|'
%left '^'
%left '&'
%left T_SL T_SR
%left '+' '-' '.'
%left '*' '/' '%'
%right '!'
%right '~' T_INC T_DEC T_INT_CAST T_DOUBLE_CAST T_STRING_CAST T_ARRAY_CAST T_OBJECT_CAST T_BOOL_CAST T_UNSET_CAST '@'
%right T_POW
%right '['
%left T_ELSEIF
%left T_ELSE
%left T_ENDIF
%right T_STATIC T_ABSTRACT T_FINAL T_PRIVATE T_PROTECTED T_PUBLIC

%token T_LNUMBER
%token T_DNUMBER
%token T_STRING
%token T_VARIABLE
%token T_CONSTANT_ENCAPSED_STRING

%token T_INCLUDE
%token T_INCLUDE_ONCE
%token T_EVAL
%token T_REQUIRE
%token T_REQUIRE_ONCE
%token T_LOGICAL_OR
%token T_LOGICAL_XOR
%token T_LOGICAL_AND
%token T_PRINT
%token T_YIELD
%token T_YIELD_FROM
%token T_PLUS_EQUAL
%token T_MINUS_EQUAL
%token T_MUL_EQUAL
%token T_DIV_EQUAL
%token T_CONCAT_EQUAL
%token T_MOD_EQUAL
%token T_AND_EQUAL
%token T_OR_EQUAL
%token T_XOR_EQUAL
%token T_SL_EQUAL
%token T_SR_EQUAL
%token T_BOOLEAN_OR
%token T_BOOLEAN_AND
%token T_IS_EQUAL
%token T_IS_NOT_EQUAL
%token T_IS_IDENTICAL
%token T_IS_NOT_IDENTICAL
%token T_IS_SMALLER_OR_EQUAL
%token T_IS_GREATER_OR_EQUAL
%token T_SPACESHIP
%token T_SL
%token T_SR
%token T_INSTANCEOF
%token T_INC
%token T_DEC
%token T_INT_CAST
%token T_DOUBLE_CAST
%token T_STRING_CAST
%token T_ARRAY_CAST
%token T_OBJECT_CAST
%token T_BOOL_CAST
%token T_UNSET_CAST
%token T_NEW
%token T_CLONE
%token T_EXIT
%token T_IF
%token T_ELSEIF
%token T_ELSE
%token T_ENDIF
%token T_ECHO
%token T_DO
%token T_WHILE
%token T_ENDWHILE
%token T_FOR
%token T_ENDFOR
%token T_FOREACH
%token T_ENDFOREACH
%token T_DECLARE
%token T_ENDDECLARE
%token T_AS
%token T_SWITCH
%token T_ENDSWITCH
%token T_CASE
%token T_DEFAULT
%token T_BREAK
%token T_CONTINUE
%token T_GOTO
%token T_FUNCTION
%token T_CONST
%token T_RETURN
%token T_TRY
%token T_CATCH
%token T_FINALLY
%token T_THROW
%token T_USE
%token T_INSTEADOF
%token T_GLOBAL
%token T_STATIC
%token T_ABSTRACT
%token T_FINAL
%token T_PRIVATE
%token T_PROTECTED
%token T_PUBLIC
%token T_VAR
%token T_UNSET
%token T_ISSET
%token T_EMPTY
%token T_HALT_COMPILER
%token T_CLASS
%token T_TRAIT
%token T_INTERFACE
%token T_EXTENDS
%token T_IMPLEMENTS
%token T_OBJECT_OPERATOR
%token T_DOUBLE_ARROW
%token T_LIST
%token T_ARRAY
%token T_CALLABLE
%token T_LINE
%token T_FILE
%token T_DIR
%token T_CLASS_C
%token T_TRAIT_C
%token T_METHOD_C
%token T_FUNC_C
%token T_PAAMAYIM_NEKUDOTAYIM
%token T_NAMESPACE
%token T_NS_C
%token T_NS_SEPARATOR
%token T_ELLIPSIS
%token T_COALESCE
%token T_POW
%token T_POW_EQUAL

// Not supported by lrpar
// %left T_NOELSE
// %token T_NOELSE (used to resolve dangling else problem)
// %token T_INLINE_HTML (inlined HTML)
// %token T_ENCAPSED_AND_WHITESPACE (currently lexed into T_CONSTANT_ENCAPSED_STRING)
// %token T_STRING_VARNAME (strings with variables inside)
// %token T_NUM_STRING (string containing numbers?)
// %token T_START_HEREDOC (multiline strings)
// %token T_END_HEREDOC

// Not needed by the grammar
// %token T_COMMENT
// %token T_OPEN_TAG
// %token T_OPEN_TAG_WITH_ECHO
// %token T_DOC_COMMENT
// %token T_CLOSE_TAG
%expect 842

%% /* Rules */

start -> Result<String, ()>
    :   "T_PHP_OPEN" top_statement_list "T_PHP_CLOSE" { Ok(String::from("<?php\n") + &$2? + "\n?>") }
;

reserved_non_modifiers -> Result<String, ()>
    :   T_INCLUDE { Ok(String::from("include")) }
    |   T_INCLUDE_ONCE { Ok(String::from("include_once")) }
    |   T_EVAL { Ok(String::from("eval")) }
    |   T_REQUIRE { Ok(String::from("require")) }
    |   T_REQUIRE_ONCE { Ok(String::from("require_once")) }
    |   T_LOGICAL_OR { Ok(String::from("or")) }
    |   T_LOGICAL_XOR { Ok(String::from("xor")) }
    |   T_LOGICAL_AND { Ok(String::from("and")) }
    |   T_INSTANCEOF { Ok(String::from("instanceof")) }
    |   T_NEW { Ok(String::from("new")) }
    |   T_CLONE { Ok(String::from("clone")) }
    |   T_EXIT { Ok(String::from("exit")) }
    |   T_IF { Ok(String::from("if")) }
    |   T_ELSEIF { Ok(String::from("elseif")) }
    |   T_ELSE { Ok(String::from("else")) }
    |   T_ENDIF { Ok(String::from("endif")) }
    |   T_ECHO { Ok(String::from("echo")) }
    |   T_DO { Ok(String::from("do")) }
    |   T_WHILE { Ok(String::from("while")) }
    |   T_ENDWHILE { Ok(String::from("endwhile")) }
    |   T_FOR { Ok(String::from("for")) }
    |   T_ENDFOR { Ok(String::from("endfor")) }
    |   T_FOREACH { Ok(String::from("foreach")) }
    |   T_ENDFOREACH { Ok(String::from("endforeach")) }
    |   T_DECLARE { Ok(String::from("declare")) }
    |   T_ENDDECLARE { Ok(String::from("enddeclare")) }
    |   T_AS { Ok(String::from("as")) }
    |   T_TRY { Ok(String::from("try")) }
    |   T_CATCH { Ok(String::from("catch")) }
    |   T_FINALLY { Ok(String::from("finally")) }
    |   T_THROW { Ok(String::from("throw")) }
    |   T_USE { Ok(String::from("use")) }
    |   T_INSTEADOF { Ok(String::from("insteadof")) }
    |   T_GLOBAL { Ok(String::from("global")) }
    |   T_VAR { Ok(String::from("var")) }
    |   T_UNSET { Ok(String::from("unset")) }
    |   T_ISSET { Ok(String::from("isset")) }
    |   T_EMPTY { Ok(String::from("empty")) }
    |   T_CONTINUE { Ok(String::from("continue")) }
    |   T_GOTO { Ok(String::from("goto")) }
    |   T_FUNCTION { Ok(String::from("function")) }
    |   T_CONST { Ok(String::from("const")) }
    |   T_RETURN { Ok(String::from("return")) }
    |   T_PRINT { Ok(String::from("print")) }
    |   T_YIELD { Ok(String::from("yield")) }
    |   T_LIST { Ok(String::from("list")) }
    |   T_SWITCH { Ok(String::from("switch")) }
    |   T_ENDSWITCH { Ok(String::from("endswitch")) }
    |   T_CASE { Ok(String::from("case")) }
    |   T_DEFAULT { Ok(String::from("default")) }
    |   T_BREAK { Ok(String::from("break")) }
    |   T_ARRAY { Ok(String::from("array")) }
    |   T_CALLABLE { Ok(String::from("callable")) }
    |   T_EXTENDS { Ok(String::from("extends")) }
    |   T_IMPLEMENTS { Ok(String::from("implements")) }
    |   T_NAMESPACE { Ok(String::from("namespace")) }
    |   T_TRAIT { Ok(String::from("trait")) }
    |   T_INTERFACE { Ok(String::from("interface")) }
    |   T_CLASS { Ok(class($1, $lexer)) }
    |   T_CLASS_C { Ok(String::from("__CLASS__")) }
    |   T_TRAIT_C { Ok(String::from("__TRAIT__")) }
    |   T_FUNC_C { Ok(String::from("__FUNCTION__")) }
    |   T_METHOD_C { Ok(String::from("__METHOD__")) }
    |   T_LINE { Ok(String::from("__LINE__")) }
    |   T_FILE { Ok(String::from("__FILE__")) }
    |   T_DIR { Ok(String::from("__DIR__")) }
    |   T_NS_C { Ok(String::from("__NAMESPACE__")) }
;

semi_reserved -> Result<String, ()>
    :   reserved_non_modifiers { Ok($1?) }
    |   T_STATIC { Ok(String::from("static")) }
    |   T_ABSTRACT { Ok(String::from("abstract")) }
    |   T_FINAL { Ok(String::from("final")) }
    |   T_PRIVATE { Ok(String::from("private")) }
    |   T_PROTECTED { Ok(String::from("protected")) }
    |   T_PUBLIC { Ok(String::from("public")) }
;

identifier -> Result<String, ()>
    :   T_STRING { Ok(string($1, $lexer)) }
    |   semi_reserved { Ok($1?) }
;

top_statement_list -> Result<String, ()>
    :   top_statement_list top_statement { Ok($1? + "\n" + &$2?) }
    |   { Ok(String::from("")) }
;

namespace_name -> Result<String, ()>
    :   T_STRING { Ok(string($1, $lexer)) }
    |   namespace_name T_NS_SEPARATOR T_STRING { Ok($1? + "\\" + &string($3, $lexer)) }
;

name -> Result<String, ()>
    :   namespace_name { Ok($1?) }
    |   T_NAMESPACE T_NS_SEPARATOR namespace_name { Ok(String::from("namespace \\") + &$3?) }
    |   T_NS_SEPARATOR namespace_name { Ok(String::from("\\") + &$2?) }
;

top_statement -> Result<String, ()>
    :   statement { Ok($1?) }
    |   function_declaration_statement { Ok($1?) }
    |   class_declaration_statement { Ok($1?) }
    |   trait_declaration_statement { Ok($1?) }
    |   interface_declaration_statement { Ok($1?) }
    |   T_HALT_COMPILER '(' ')' ';' { Ok(String::from("__halt_compiler();")) }

    |   T_NAMESPACE namespace_name ';' { Ok(String::from("namespace ") + &$2? + ";") }

    |   T_NAMESPACE namespace_name '{' top_statement_list '}' { Ok(String::from("namespace ") + &$2? + "{" + &$4? + "}") }

    |   T_NAMESPACE '{' top_statement_list '}' { Ok(String::from("namespace ") + "{" + &$3? + "}") }

    |   T_USE mixed_group_use_declaration ';' { Ok(String::from("use ") + &$2? + ";") }
    |   T_USE use_type group_use_declaration ';' { Ok(String::from("use ") + &$2? + " " + &$3? + ";") }
    |   T_USE use_declarations ';' { Ok(String::from("use ") + &$2? + ";") }
    |   T_USE use_type use_declarations ';' { Ok(String::from("use ") + &$2? + " " + &$3? + ";") }
    |   T_CONST const_list ';' { Ok(String::from("const ") + &$2? + ";") }
;

use_type -> Result<String, ()>
    :   T_FUNCTION { Ok(String::from("function")) }
    |   T_CONST { Ok(String::from("const")) }
;

group_use_declaration -> Result<String, ()>
    :   namespace_name T_NS_SEPARATOR '{' unprefixed_use_declarations possible_comma '}' { Ok($1? + "\\{" + &$4? + &$5? + "}") }

    |   T_NS_SEPARATOR namespace_name T_NS_SEPARATOR '{' unprefixed_use_declarations possible_comma '}' { Ok(String::from("\\") + &$2? + "\\{" + &$5? + &$6? + "}") }

;

mixed_group_use_declaration -> Result<String, ()>
    :   namespace_name T_NS_SEPARATOR '{' inline_use_declarations possible_comma '}' { Ok($1? + "\\{" + &$4? + &$5? + "}") }

    |   T_NS_SEPARATOR namespace_name T_NS_SEPARATOR '{' inline_use_declarations possible_comma '}' { Ok(String::from("\\") + &$2? + "\\{" + &$5? + &$6? + "}") }

;

possible_comma -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   ',' { Ok(String::from(",")) }
;

inline_use_declarations -> Result<String, ()>
    :   inline_use_declarations ',' inline_use_declaration { Ok($1? + ", " + &$3?) }

    |   inline_use_declaration { Ok($1?) }

;

unprefixed_use_declarations -> Result<String, ()>
    :   unprefixed_use_declarations ',' unprefixed_use_declaration { Ok($1? + ", " + &$3?) }


    |   unprefixed_use_declaration { Ok($1?) }

;

use_declarations -> Result<String, ()>
    :   use_declarations ',' use_declaration { Ok($1? + ", " + &$3?) }

    |   use_declaration { Ok($1?) }

;

inline_use_declaration -> Result<String, ()>
    :   unprefixed_use_declaration { Ok($1?) }
    |   use_type unprefixed_use_declaration { Ok($1? + " " + &$2?) }
;

unprefixed_use_declaration -> Result<String, ()>
    :   namespace_name { Ok($1?) }

    |   namespace_name T_AS T_STRING { Ok($1? + " as " + &string($3, $lexer)) }

;

use_declaration -> Result<String, ()>
    :   unprefixed_use_declaration { Ok($1?) }
    |   T_NS_SEPARATOR unprefixed_use_declaration { Ok(String::from("\\") + &$2?) }
;

const_list -> Result<String, ()>
    :   const_list ',' const_decl { Ok($1? + ", " + &$3?) }
    |   const_decl { Ok($1?) }
;

inner_statement_list -> Result<String, ()>
    :   inner_statement_list inner_statement { Ok($1? + &$2? + "\n") }
    |   { Ok(String::from("\n")) }

;

inner_statement -> Result<String, ()>
    :   statement { Ok($1?) }
    |   function_declaration_statement { Ok($1?) }
    |   class_declaration_statement { Ok($1?) }
    |   trait_declaration_statement { Ok($1?) }
    |   interface_declaration_statement { Ok($1?) }
    |   T_HALT_COMPILER '(' ')' ';' { Ok(String::from("__halt_compiler();")) }

;


statement -> Result<String, ()>
    :   '{' inner_statement_list '}' { Ok(String::from("{") + &$2? + "}") }
    |   if_stmt { Ok($1?) }
    |   alt_if_stmt { Ok($1?) }
    |   T_WHILE '(' expr ')' while_statement { Ok(String::from("while (") + &$3? + ")\n" + &$5?) }

    |   T_DO statement T_WHILE '(' expr ')' ';' { Ok(String::from("do\n") + &$2? + "\nwhile (" + &$5? + ");") }

    |   T_FOR '(' for_exprs ';' for_exprs ';' for_exprs ')' for_statement { Ok(String::from("for (") + &$3? + "; " + &$5? + "; " + &$7? + ")\n" + &$9?) }

    |   T_SWITCH '(' expr ')' switch_case_list { Ok(String::from("switch (") + &$3? + ")\n" + &$5?) }

    |   T_BREAK optional_expr ';' { Ok(String::from("break ") + &$2? + ";") }
    |   T_CONTINUE optional_expr ';' { Ok(String::from("continue ") + &$2? + ";") }
    |   T_RETURN optional_expr ';' { Ok(String::from("return ") + &$2? + ";") }
    |   T_GLOBAL global_var_list ';' { Ok(String::from("global ") + &$2? + ";") }
    |   T_STATIC static_var_list ';' { Ok(String::from("static ") + &$2? + ";") }
    |   T_ECHO echo_expr_list ';' { Ok(String::from("echo ") + &$2? + ";") }
    |   expr ';' { Ok($1? + ";") }
    |   T_UNSET '(' unset_variables possible_comma ')' ';' { Ok(String::from("unset(") + &$3? + &$4? + ");") }
    |   T_FOREACH '(' expr T_AS foreach_variable ')' foreach_statement { Ok(String::from("foreach (") + &$3? + " as " + &$5? + ")\n" + &$7?) }

    |   T_FOREACH '(' expr T_AS foreach_variable T_DOUBLE_ARROW foreach_variable ')' foreach_statement { Ok(String::from("foreach (") + &$3? + " as " + &$5? + "=>" + &$7? + ")\n" + &$9?) }

    |   T_DECLARE '(' const_list ')' declare_statement { Ok(String::from("declare (") + &$3? + ")" + &$5?) }
    |   ';' /* empty statement */ { Ok(String::from(";")) }
    |   T_TRY '{' inner_statement_list '}' catch_list finally_statement { Ok(String::from("try {") + &$3? + "}\n" + &$5? + &$6?) }

    |   T_THROW expr ';' { Ok(String::from("throw ") + &$2? + ";") }
    |   T_GOTO T_STRING ';' { Ok(String::from("goto ") + &string($2, $lexer) + ";") }
    |   T_STRING ':' { Ok(string($1, $lexer) + ":") }
;

catch_list -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   catch_list T_CATCH '(' catch_name_list T_VARIABLE ')' '{' inner_statement_list '}' { Ok($1? + "catch (" + &$4? + &variable($5, $lexer) + ") {\n" + &$8? + "}") }
;

catch_name_list -> Result<String, ()>
    :   name { Ok($1?) }
    |   catch_name_list '|' name { Ok($1? + "|" + &$3?) }
;

finally_statement -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   T_FINALLY '{' inner_statement_list '}' { Ok(String::from("finally {") + &$3? + "}") }
;

unset_variables -> Result<String, ()>
    :   unset_variable { Ok($1?) }
    |   unset_variables ',' unset_variable { Ok($1? + ", " + &$3?) }
;

unset_variable -> Result<String, ()>
    :   variable { Ok($1?) }
;

function_declaration_statement -> Result<String, ()>
    :   function returns_ref T_STRING '(' parameter_list ')' return_type
    '{' inner_statement_list '}' 
    { Ok($1? + " " + &$2? + " " + &string($3, $lexer) + " (" + &$5? + ") " + &$7? + " {" + &$9? + "}") }
;

is_reference -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   '&' { Ok(String::from("&")) }
;

is_variadic -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   T_ELLIPSIS { Ok(String::from("...")) }
;

class_declaration_statement -> Result<String, ()>
    :   class_modifiers T_CLASS
        T_STRING extends_from implements_list '{' class_statement_list '}' 
        { Ok($1? + " " + &class($2, $lexer) + " " + &string($3, $lexer) + " " + &$4? + " " + &$5? + " {" + &$7? + "}") }

    |   T_CLASS
        T_STRING extends_from implements_list '{' class_statement_list '}' 
        { Ok(class($1, $lexer) + " " + &string($2, $lexer) + " " + &$3? + " " + &$4? + " {" + &$6? + "}") }

;

class_modifiers -> Result<String, ()>
    :   class_modifier { Ok($1?) }
    |   class_modifiers class_modifier { Ok($1? + " " + &$2?) }
;

class_modifier -> Result<String, ()>
    :   T_ABSTRACT { Ok(String::from("abstract")) }
    |   T_FINAL { Ok(String::from("final")) }
;

trait_declaration_statement -> Result<String, ()>
    :   T_TRAIT
        T_STRING '{' class_statement_list '}' 
        { Ok(String::from("trait ") + &string($2, $lexer) + "{" + &$4? + "}") }
;

interface_declaration_statement -> Result<String, ()>
    :   T_INTERFACE
        T_STRING interface_extends_list '{' class_statement_list '}' 
        { Ok(String::from("interface ") + &string($2, $lexer) + &$3? + " {" + &$5? + "}") }

;

extends_from -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   T_EXTENDS name { Ok(String::from("extends ") + &$2?) }
;

interface_extends_list -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   T_EXTENDS name_list { Ok(String::from(" extends ") + &$2?) }
;

implements_list -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   T_IMPLEMENTS name_list { Ok(String::from("implements ") + &$2?) }
;

foreach_variable -> Result<String, ()>
    :   variable { Ok($1?) }
    |   '&' variable { Ok(String::from("&") + &$2?) }
    |   T_LIST '(' array_pair_list ')' { Ok(String::from("list(") + &$3? + ")") }
    |   '[' array_pair_list ']' { Ok(String::from("[") + &$2? + "]") }
;

for_statement -> Result<String, ()>
    :   statement { Ok($1?) }
    |   ':' inner_statement_list T_ENDFOR ';' { Ok(String::from(":") + &$2? + "\nendfor;") }
;

foreach_statement -> Result<String, ()>
    :   statement { Ok($1?) }
    |   ':' inner_statement_list T_ENDFOREACH ';' { Ok(String::from(":") + &$2? + "\nendforeach;") }
;

declare_statement -> Result<String, ()>
    :   statement { Ok($1?) }
    |   ':' inner_statement_list T_ENDDECLARE ';' { Ok(String::from(":") + &$2? + "\nenddeclare;") }
;

switch_case_list -> Result<String, ()>
    :   '{' case_list '}' { Ok(String::from("{") + &$2? + "}") }
    |   '{' ';' case_list '}' { Ok(String::from("{;") + &$3? + "}") }
    |   ':' case_list T_ENDSWITCH ';' { Ok(String::from(":") + &$2? + "\nendswitch;") }
    |   ':' ';' case_list T_ENDSWITCH ';' { Ok(String::from(":;") + &$3? + "\nendswitch;") }
;

case_list -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   case_list T_CASE expr case_separator inner_statement_list { Ok($1? + " case " + &$3? + "\n" + &$4?) }
    |   case_list T_DEFAULT case_separator inner_statement_list { Ok($1? + " default " + &$3? + "\n" + &$4?) }

;

case_separator -> Result<String, ()>
    :   ':' { Ok(String::from(":")) }
    |   ';' { Ok(String::from(";")) }
;


while_statement -> Result<String, ()>
    :   statement { Ok($1?) }
    |   ':' inner_statement_list T_ENDWHILE ';' { Ok(String::from(":") + &$2? + "\nendwhile;") }
;


if_stmt_without_else -> Result<String, ()>
    :   T_IF '(' expr ')' statement { Ok(String::from("if (") + &$3? + ")\n" + &$5?) }

    |   if_stmt_without_else T_ELSEIF '(' expr ')' statement { Ok($1? + "\nelseif (" + &$4? + ")\n" + &$6?) }

;

if_stmt -> Result<String, ()>
    :   if_stmt_without_else { Ok($1?) } // %prec T_NOELSE
    |   if_stmt_without_else T_ELSE statement { Ok($1? + "\nelse\n" + &$3?) }

;

alt_if_stmt_without_else -> Result<String, ()>
    :   T_IF '(' expr ')' ':' inner_statement_list { Ok(String::from("if (") + &$3? + "):" + &$6?) }

    |   alt_if_stmt_without_else T_ELSEIF '(' expr ')' ':' inner_statement_list { Ok($1? + "\nelseif (" + &$4? + "):\n" + &$7?) }

;

alt_if_stmt -> Result<String, ()>
    :   alt_if_stmt_without_else T_ENDIF ';' { Ok($1? + " endif;") }
    |   alt_if_stmt_without_else T_ELSE ':' inner_statement_list T_ENDIF ';' { Ok($1? + "\nelse:\n" + &$4? + "\nendif;") }

;

parameter_list -> Result<String, ()>
    :   non_empty_parameter_list { Ok($1?) }
    |   { Ok(String::from("")) }
;


non_empty_parameter_list -> Result<String, ()>
    :   parameter { Ok($1?) }
    |   non_empty_parameter_list ',' parameter { Ok($1? + ", " + &$3?) }

;

parameter -> Result<String, ()>
    :   optional_type is_reference is_variadic T_VARIABLE { Ok($1? + " " + &$2? + " " + &$3? + " " + &variable($4, $lexer)) }

    |   optional_type is_reference is_variadic T_VARIABLE '=' expr { Ok($1? + " " + &$2? + " " + &$3? + " " + &variable($4, $lexer) + " = " + &$6?) }

;


optional_type -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   type_expr { Ok($1?) }
;

type_expr -> Result<String, ()>
    :   type { Ok($1?) }
    |   '?' type { Ok(String::from("?") + &$2?) }
;

type -> Result<String, ()>
    :   T_ARRAY { Ok(String::from("array")) }
    |   T_CALLABLE { Ok(String::from("callable")) }
    |   name { Ok($1?) }
;

return_type -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   ':' type_expr { Ok(String::from(":") + &$2?) }
;

argument_list -> Result<String, ()>
    :   '(' ')' { Ok(String::from("()")) }
    |   '(' non_empty_argument_list possible_comma ')' { Ok(String::from("(") + &$2? + &$3? + ")") }
;

non_empty_argument_list -> Result<String, ()>
    :   argument { Ok($1?) }
    |   non_empty_argument_list ',' argument { Ok($1? + ", " + &$3?) }

;

argument -> Result<String, ()>
    :   expr { Ok($1?) }
    |   T_ELLIPSIS expr { Ok(String::from("...") + &$2?) }
;

global_var_list -> Result<String, ()>
    :   global_var_list ',' global_var { Ok($1? + ", " + &$3?) }
    |   global_var { Ok($1?) }
;

global_var -> Result<String, ()>
    :   simple_variable { Ok($1?) }

;


static_var_list -> Result<String, ()>
    :   static_var_list ',' static_var { Ok($1? + ", " + &$3?) }
    |   static_var { Ok($1?) }
;

static_var -> Result<String, ()>
    :   T_VARIABLE { Ok(variable($1, $lexer)) }
    |   T_VARIABLE '=' expr { Ok(variable($1, $lexer) + " = " + &$3?) }
;


class_statement_list -> Result<String, ()>
    :   class_statement_list class_statement { Ok($1? + " " + &$2?) }

    |   { Ok(String::from("")) }

;


class_statement -> Result<String, ()>
    :   variable_modifiers property_list ';' { Ok($1? + " " + &$2? + ";") }

    |   method_modifiers T_CONST class_const_list ';' { Ok($1? + " const " + &$3? + ";") }

    |   T_USE name_list trait_adaptations { Ok(String::from("use ") + &$2? + " " + &$3?) }

    |   method_modifiers function returns_ref identifier '(' parameter_list ')'
        return_type method_body 
        { Ok($1? + " " + &$2? + " " + &$3? + " " + &$4? + " (" + &$6? + ") " + &$8? + " " + &$9?) }

;

name_list -> Result<String, ()>
    :   name { Ok($1?) }
    |   name_list ',' name { Ok($1? + ", " + &$3?) }
;

trait_adaptations -> Result<String, ()>
    :   ';' { Ok(String::from(";")) }
    |   '{' '}' { Ok(String::from("{}")) }
    |   '{' trait_adaptation_list '}' { Ok(String::from("{") + &$2? + "}") }
;

trait_adaptation_list -> Result<String, ()>
    :   trait_adaptation { Ok($1?) }

    |   trait_adaptation_list trait_adaptation { Ok($1? + " " + &$2?) }

;

trait_adaptation -> Result<String, ()>
    :   trait_precedence ';' { Ok($1? + ";") }
    |   trait_alias ';' { Ok($1? + ";") }
;

trait_precedence -> Result<String, ()>
    :   absolute_trait_method_reference T_INSTEADOF name_list { Ok($1? + " insteadof " + &$3?) }

;

trait_alias -> Result<String, ()>
    :   trait_method_reference T_AS T_STRING { Ok($1? + " as " + &string($3, $lexer)) }

    |   trait_method_reference T_AS reserved_non_modifiers { Ok($1? + " as " + &$3?) }
    |   trait_method_reference T_AS member_modifier identifier { Ok($1? + " as " + &$3? + " " + &$4?) }

    |   trait_method_reference T_AS member_modifier { Ok($1? + " as " + &$3?) }

;

trait_method_reference -> Result<String, ()>
    :   identifier { Ok($1?) }

    |   absolute_trait_method_reference { Ok($1?) }
;

absolute_trait_method_reference -> Result<String, ()>
    :   name T_PAAMAYIM_NEKUDOTAYIM identifier { Ok($1? + "::" + &$3?) }

;

method_body -> Result<String, ()>
    :   ';' /* abstract method */ { Ok(String::from(";")) }
    |   '{' inner_statement_list '}' { Ok(String::from("{") + &$2? + "}") }
;

variable_modifiers -> Result<String, ()>
    :   non_empty_member_modifiers { Ok($1?) }
    |   T_VAR { Ok(String::from("var")) }
;

method_modifiers -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   non_empty_member_modifiers { Ok($1?) }
;

non_empty_member_modifiers -> Result<String, ()>
    :   member_modifier { Ok($1?) }
    |   non_empty_member_modifiers member_modifier { Ok($1? + " " + &$2?) }
;

member_modifier -> Result<String, ()>
    :   T_PUBLIC { Ok(String::from("public")) }
    |   T_PROTECTED { Ok(String::from("protected")) }
    |   T_PRIVATE { Ok(String::from("private")) }
    |   T_STATIC { Ok(String::from("static")) }
    |   T_ABSTRACT { Ok(String::from("abstract")) }
    |   T_FINAL { Ok(String::from("final")) }
;

property_list -> Result<String, ()>
    :   property_list ',' property { Ok($1? + ", " + &$3?) }
    |   property { Ok($1?) }
;

property -> Result<String, ()>
    :   T_VARIABLE { Ok(variable($1, $lexer)) }

    |   T_VARIABLE '=' expr { Ok(variable($1, $lexer) + "=" + &$3?) }

;

class_const_list -> Result<String, ()>
    :   class_const_list ',' class_const_decl { Ok($1? + ", " + &$3?) }
    |   class_const_decl { Ok($1?) }
;

class_const_decl -> Result<String, ()>
    :   identifier '=' expr { Ok($1? + "=" + &$3?) }
;

const_decl -> Result<String, ()>
    :   T_STRING '=' expr { Ok(string($1, $lexer) + "=" + &$3?) }
;

echo_expr_list -> Result<String, ()>
    :   echo_expr_list ',' echo_expr { Ok($1? + ", " + &$3?) }
    |   echo_expr { Ok($1?) }
;
echo_expr -> Result<String, ()>
    :   expr { Ok($1?) }
;

for_exprs -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   non_empty_for_exprs { Ok($1?) }
;

non_empty_for_exprs -> Result<String, ()>
    :   non_empty_for_exprs ',' expr { Ok($1? + ", " + &$3?) }
    |   expr { Ok($1?) }
;

anonymous_class -> Result<String, ()>
    :   T_CLASS ctor_arguments
        extends_from implements_list '{' class_statement_list '}' 
        { Ok(class($1, $lexer) + " " + &$2? + " " + &$3? + " " + &$4? + " {" + &$6? + "}") }
;

new_expr -> Result<String, ()>
    :   T_NEW class_name_reference ctor_arguments { Ok(String::from("new ") + &$2? + " " + &$3?) }

    |   T_NEW anonymous_class { Ok(String::from("new ") + &$2?) }

;

expr -> Result<String, ()>
    :   variable { Ok($1?) }

    |   T_LIST '(' array_pair_list ')' '=' expr { Ok(String::from("list(") + &$3? + ") = " + &$6?) }
    |   '[' array_pair_list ']' '=' expr { Ok(String::from("[") +  &$2? + "] = " + &$5?) }
    |   variable '=' expr { Ok($1? + " = " + &$3?) }

    |   variable '=' '&' variable { Ok($1? + " =& " + &$4?) }

    |   T_CLONE expr { Ok(String::from("clone ") + &$2?) }
    |   variable T_PLUS_EQUAL expr { Ok($1? + " += " + &$3?) }

    |   variable T_MINUS_EQUAL expr { Ok($1? + " -= " + &$3?) }

    |   variable T_MUL_EQUAL expr { Ok($1? + " *= " + &$3?) }

    |   variable T_POW_EQUAL expr { Ok($1? + " **= " + &$3?) }

    |   variable T_DIV_EQUAL expr { Ok($1? + " /= " + &$3?) }

    |   variable T_CONCAT_EQUAL expr { Ok($1? + " .= " + &$3?) }

    |   variable T_MOD_EQUAL expr { Ok($1? + " %= " + &$3?) }

    |   variable T_AND_EQUAL expr { Ok($1? + " &= " + &$3?) }

    |   variable T_OR_EQUAL expr { Ok($1? + " |= " + &$3?) }

    |   variable T_XOR_EQUAL expr { Ok($1? + " ^= " + &$3?) }

    |   variable T_SL_EQUAL expr { Ok($1? + " <<= " + &$3?) }

    |   variable T_SR_EQUAL expr { Ok($1? + " >>= " + &$3?) }

    |   variable T_INC { Ok($1? + "++") }
    |   T_INC variable { Ok(String::from("++") + &$2?) }
    |   variable T_DEC { Ok($1? + "--") }
    |   T_DEC variable { Ok(String::from("--") + &$2?) }
    |   expr T_BOOLEAN_OR expr { Ok($1? + " || " + &$3?) }

    |   expr T_BOOLEAN_AND expr { Ok($1? + " && " + &$3?) }

    |   expr T_LOGICAL_OR expr { Ok($1? + " or " + &$3?) }

    |   expr T_LOGICAL_AND expr { Ok($1? + " and " + &$3?) }

    |   expr T_LOGICAL_XOR expr { Ok($1? + " xor " + &$3?) }

    |   expr '|' expr { Ok($1? + " | " + &$3?) }
    |   expr '&' expr { Ok($1? + " & " + &$3?) }
    |   expr '^' expr { Ok($1? + " ^ " + &$3?) }
    |   expr '.' expr { Ok($1? + " . " + &$3?) }
    |   expr '+' expr { Ok($1? + " + " + &$3?) }
    |   expr '-' expr { Ok($1? + " - " + &$3?) }
    |   expr '*' expr { Ok($1? + " * " + &$3?) }
    |   expr T_POW expr { Ok($1? + " ** " + &$3?) }
    |   expr '/' expr { Ok($1? + " / " + &$3?) }
    |   expr '%' expr { Ok($1? + " % " + &$3?) }
    |   expr T_SL expr { Ok($1? + " << " + &$3?) }
    |   expr T_SR expr { Ok($1? + " >> " + &$3?) }
    |   '+' expr %prec T_INC { Ok(String::from("+") + &$2?) }
    |   '-' expr %prec T_INC { Ok(String::from("-") + &$2?) }
    |   '!' expr { Ok(String::from("!") + &$2?) }
    |   '~' expr { Ok(String::from("~") + &$2?) }
    |   expr T_IS_IDENTICAL expr { Ok($1? + " === " + &$3?) }

    |   expr T_IS_NOT_IDENTICAL expr { Ok($1? + " !== " + &$3?) }

    |   expr T_IS_EQUAL expr { Ok($1? + " == " + &$3?) }

    |   expr T_IS_NOT_EQUAL expr { Ok($1? + " != " + &$3?) }

    |   expr '<' expr { Ok($1? + " < " + &$3?) }

    |   expr T_IS_SMALLER_OR_EQUAL expr { Ok($1? + " <= " + &$3?) }

    |   expr '>' expr { Ok($1? + " > " + &$3?) }

    |   expr T_IS_GREATER_OR_EQUAL expr { Ok($1? + " >= " + &$3?) }

    |   expr T_SPACESHIP expr { Ok($1? + " <=> " + &$3?) }

    |   expr T_INSTANCEOF class_name_reference { Ok($1? + " instanceof " + &$3?) }

    |   '(' expr ')' { Ok(String::from("(") + &$2? + ")") }
    |   new_expr { Ok($1?) }
    |   expr '?' expr ':' expr { Ok($1? + " ? " + &$3? + " : " + &$5?) }

    |   expr '?' ':' expr { Ok($1? + " ? : " + &$4?) }

    |   expr T_COALESCE expr { Ok($1? + " ?? " + &$3?) }

    |   internal_functions_in_yacc { Ok($1?) }
    |   T_INT_CAST expr { Ok(String::from("(int) ") + &$2?) }
    |   T_DOUBLE_CAST expr { Ok(String::from("(double) ") + &$2?) }
    |   T_STRING_CAST expr { Ok(String::from("(string) ") + &$2?) }
    |   T_ARRAY_CAST expr { Ok(String::from("(array) ") + &$2?) }
    |   T_OBJECT_CAST expr { Ok(String::from("(object) ") + &$2?) }
    |   T_BOOL_CAST expr { Ok(String::from("(bool) ") + &$2?) }
    |   T_UNSET_CAST expr { Ok(String::from("(unset) ") + &$2?) }
    |   T_EXIT exit_expr { Ok(String::from("(exit) ") + &$2?) }
    |   '@' expr { Ok(String::from("@") + &$2?) }
    |   scalar { Ok($1?) }
    |   '`' backticks_expr '`' { Ok(String::from("`") + &$2? + "`") }
    |   T_PRINT expr { Ok(String::from("print ") + &$2?) }
    |   T_YIELD { Ok(String::from("yield")) }
    |   T_YIELD expr { Ok(String::from("yield ") + &$2?) }
    |   T_YIELD expr T_DOUBLE_ARROW expr { Ok(String::from("yield ") + &$2? + " => " + &$4?) }
    |   T_YIELD_FROM expr { Ok(String::from("yield from ") + &$2?) }
    |   function returns_ref '(' parameter_list ')' lexical_vars return_type
        '{' inner_statement_list '}' 
        { Ok($1? + " " + &$2? + " (" + &$4? + ") " + &$6? + " " + &$7? + " {" + &$9? + "}") }
    |   T_STATIC function returns_ref '(' parameter_list ')' lexical_vars
        return_type '{' inner_statement_list '}' 
        { Ok(String::from("static ") + &$2? + " " + &$3? + " (" + &$5? + ") " + &$7? + " " + &$8? + " {" + &$10? + "}") }
;

function -> Result<String, ()>
    :   T_FUNCTION { Ok(String::from("function")) }
;

returns_ref -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   '&' { Ok(String::from("&")) }
;

lexical_vars -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   T_USE '(' lexical_var_list ')' { Ok(String::from("use (") + &$3? + ")") }
;

lexical_var_list -> Result<String, ()>
    :   lexical_var_list ',' lexical_var { Ok($1? + ", " + &$3?) }
    |   lexical_var { Ok($1?) }
;

lexical_var -> Result<String, ()>
    :   T_VARIABLE { Ok(variable($1, $lexer)) }
    |   '&' T_VARIABLE { Ok(String::from("&") + &variable($1, $lexer)) }
;

function_call -> Result<String, ()>
    :   name argument_list { Ok($1? + &$2?) }

    |   class_name T_PAAMAYIM_NEKUDOTAYIM member_name argument_list { Ok($1? + "::" + &$3? + &$4?) }

    |   variable_class_name T_PAAMAYIM_NEKUDOTAYIM member_name argument_list { Ok($1? + "::" + &$3? + &$4?) }

    |   callable_expr argument_list  { Ok($1? + &$2?) }

;

class_name -> Result<String, ()>
    :   T_STATIC { Ok(String::from("static")) }
    |   name { Ok($1?) }
;

class_name_reference -> Result<String, ()>
    :   class_name { Ok($1?) }
    |   new_variable { Ok($1?) }
;

exit_expr -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   '(' optional_expr ')' { Ok(String::from("(") + &$2? + ")") }
;

backticks_expr -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   encaps_list { Ok($1?) }
;


ctor_arguments -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   argument_list { Ok($1?) }
;


dereferencable_scalar -> Result<String, ()>
    :   T_ARRAY '(' array_pair_list ')' { Ok(String::from("array(") + &$3? + ")") }
    |   '[' array_pair_list ']' { Ok(String::from("[") + &$2? + "]") }
    |   T_CONSTANT_ENCAPSED_STRING { Ok(encpased_string($1, $lexer)) }
;

scalar -> Result<String, ()>
    :   T_LNUMBER { Ok(lnumber($1, $lexer)) }
    |   T_DNUMBER { Ok(dnumber($1, $lexer)) }
    |   T_LINE { Ok(String::from("__LINE__")) }
    |   T_FILE { Ok(String::from("__FILE__")) }
    |   T_DIR { Ok(String::from("__DIR__")) }
    |   T_TRAIT_C { Ok(String::from("__TRAIT__")) }
    |   T_METHOD_C { Ok(String::from("__METHOD__")) }
    |   T_FUNC_C { Ok(String::from("__FUNCTION__")) }
    |   T_NS_C { Ok(String::from("__NAMESPACE__")) }
    |   T_CLASS_C { Ok(String::from("__CLASS__")) }
    |   '"' encaps_list '"' { Ok(String::from("\"") + &$2? + "\"") }
    |   dereferencable_scalar { Ok($1?) }
    |   constant { Ok($1?) }
;

constant -> Result<String, ()>
    :   name { Ok($1?) }
    |   class_name T_PAAMAYIM_NEKUDOTAYIM identifier { Ok($1? + "::" + &$3?) }

    |   variable_class_name T_PAAMAYIM_NEKUDOTAYIM identifier { Ok($1? + "::" + &$3?) }

;

optional_expr -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   expr { Ok($1?) }
;

variable_class_name -> Result<String, ()>
    :   dereferencable { Ok($1?) }
;

dereferencable -> Result<String, ()>
    :   variable { Ok($1?) }
    |   '(' expr ')' { Ok(String::from("(") + &$2? + ")") }
    |   dereferencable_scalar { Ok($1?) }
;

callable_expr -> Result<String, ()>
    :   callable_variable { Ok($1?) }
    |   '(' expr ')' { Ok(String::from("(") + &$2? + ")") }
    |   dereferencable_scalar { Ok($1?) }
;

callable_variable -> Result<String, ()>
    :   simple_variable { Ok($1?) }

    |   dereferencable '[' optional_expr ']' { Ok($1? + "[" + &$3? + "]") }

    |   constant '[' optional_expr ']' { Ok($1? + "[" + &$3? + "]") }

    |   dereferencable '{' expr '}' { Ok($1? + "{" + &$3? + "}") }

    |   dereferencable T_OBJECT_OPERATOR property_name argument_list { Ok($1? + "->" + &$3? + &$4?) }

    |   function_call { Ok($1?) }
;

variable -> Result<String, ()>
    :   callable_variable { Ok($1?) }
    |   static_member { Ok($1?) }
    |   dereferencable T_OBJECT_OPERATOR property_name { Ok($1? + "->" + &$3?) }

;

simple_variable -> Result<String, ()>
    :   T_VARIABLE { Ok(variable($1, $lexer)) }
    |   '$' '{' expr '}' { Ok(String::from("\u{0024}{") + &$3? + "}") }
    |   '$' simple_variable { Ok(String::from("\u{0024}") + &$2?) }
;

static_member -> Result<String, ()>
    :   class_name T_PAAMAYIM_NEKUDOTAYIM simple_variable { Ok($1? + "::" + &$3?) }

    |   variable_class_name T_PAAMAYIM_NEKUDOTAYIM simple_variable { Ok($1? + "::" + &$3?) }

;

new_variable -> Result<String, ()>
    :   simple_variable { Ok($1?) }
    |   new_variable '[' optional_expr ']' { Ok($1? + "[" + &$3? + "]") }

    |   new_variable '{' expr '}' { Ok($1? + "{" + &$3? + "}") }

    |   new_variable T_OBJECT_OPERATOR property_name { Ok($1? + "->" + &$3?) }

    |   class_name T_PAAMAYIM_NEKUDOTAYIM simple_variable { Ok($1? + "::" + &$3?) }

    |   new_variable T_PAAMAYIM_NEKUDOTAYIM simple_variable { Ok($1? + "::" + &$3?) }

;

member_name -> Result<String, ()>
    :   identifier { Ok($1?) }
    |   '{' expr '}' { Ok(String::from("{") + &$2? + "}") }
    |   simple_variable { Ok($1?) }
;

property_name -> Result<String, ()>
    :   T_STRING { Ok(string($1, $lexer)) }
    |   '{' expr '}' { Ok(String::from("{") + &$2? + "}") }
    |   simple_variable { Ok($1?) }
;

array_pair_list -> Result<String, ()>
    :   non_empty_array_pair_list { Ok($1?) }
;

possible_array_pair -> Result<String, ()>
    :   { Ok(String::from("")) }
    |   array_pair { Ok($1?) }
;

non_empty_array_pair_list -> Result<String, ()>
    :   non_empty_array_pair_list ',' possible_array_pair { Ok($1? + ", " + &$3?) }

    |   possible_array_pair { Ok($1?) }

;

array_pair -> Result<String, ()>
    :   expr T_DOUBLE_ARROW expr { Ok($1? + "=>" + &$3?) }

    |   expr { Ok($1?) }

    |   expr T_DOUBLE_ARROW '&' variable { Ok($1? + "=>&" + &$4?) }

    |   '&' variable { Ok(String::from("&") + &$2?) }

    |   expr T_DOUBLE_ARROW T_LIST '(' array_pair_list ')' { Ok($1? + "=>list(" + &$5? + ")") }
    |   T_LIST '(' array_pair_list ')' { Ok(String::from("list(") + &$3? + ")") }
;

encaps_list -> Result<String, ()>
    :   encaps_list encaps_var { Ok($1? + &$2?) }
    |   encaps_var { Ok($1?) }
;

encaps_var -> Result<String, ()>
    :   T_VARIABLE { Ok(variable($1, $lexer)) }

    |   T_VARIABLE '[' encaps_var_offset ']' { Ok(variable($1, $lexer) + "[" +&$3? + "]") }

    |   T_VARIABLE T_OBJECT_OPERATOR T_STRING { Ok(variable($1, $lexer) + "->" + &string($3, $lexer)) }

    |   '{' '$' variable '}' { Ok(String::from("{\u{0024}") + &$3? + "}") }
;

encaps_var_offset -> Result<String, ()>
    :   T_STRING { Ok(string($1, $lexer)) }
    |   T_VARIABLE { Ok(variable($1, $lexer)) }
;


internal_functions_in_yacc -> Result<String, ()>
    :   T_ISSET '(' isset_variables possible_comma ')' { Ok(String::from("isset(") + &$3? + &$4? + ")") }
    |   T_EMPTY '(' expr ')' { Ok(String::from("empty(") + &$3? + ")") }
    |   T_INCLUDE expr { Ok(String::from("include ") + &$2?) }

    |   T_INCLUDE_ONCE expr { Ok(String::from("include_once ") + &$2?) }

    |   T_EVAL '(' expr ')' { Ok(String::from("eval(") + &$3? + ")") }

    |   T_REQUIRE expr { Ok(String::from("require ") + &$2?) }

    |   T_REQUIRE_ONCE expr { Ok(String::from("require_once ") + &$2?) }

;

isset_variables -> Result<String, ()>
    :   isset_variable { Ok($1?) }
    |   isset_variables ',' isset_variable { Ok($1? + ", " + &$3?) }

;

isset_variable -> Result<String, ()>
    :   expr { Ok($1?) }
;

unmatched -> ():
  "UNMATCHED" { } 
  ;

%%

use rand::seq::SliceRandom;

static CLASSES: [&str; 2] = ["class", "Class"];

fn class<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => {
            // Select a random keyword
            let mut rng = rand::thread_rng();
            let keyword = CLASSES.choose(&mut rng).unwrap_or(&"error");
            keyword.to_string()
        }
  }
}

fn string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("abc")
  }
}

fn encpased_string<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("'abc'")
  }
}

fn variable<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("\u{0024}abc")
  }
}

fn lnumber<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("123")
  }
}

fn dnumber<'lexer, 'input: 'lexer, E>(s: Result<lrlex::defaults::DefaultLexeme, E>, i_lexer: &'lexer dyn ::lrpar::NonStreamingLexer<'input, lrlex::defaults::DefaultLexerTypes>) -> String {
  
  match s {
        Ok(val) => String::from("") + i_lexer.span_str(val.span()),
        Err(_) => String::from("120.123e99F")
  }
}