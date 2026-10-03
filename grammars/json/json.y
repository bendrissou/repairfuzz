%expect-unused unmatched "UNMATCHED"
%start start
%%
start -> Result<String, ()>:
      value { $1 }
    ;

obj -> Result<String, ()>:
      '{' members '}' { Ok(String::from("{") + &$2? + "}") }
    | '{' '}' { Ok(String::from("{}")) }
    ;

members -> Result<String, ()>:
      pair { Ok($1?) }
    | pair ',' members { Ok($1? + ", " + &$3?) }
    ;

pair -> Result<String, ()>:
      string ':' value {
            Ok( $1? + ": " + &$3? )
      }
    ;

arr -> Result<String, ()>:
      '[' entries ']' { Ok(String::from("[") + &$2? + "]") }
    | '[' ']' { Ok(String::from("[]")) }
    ;

entries -> Result<String, ()>:
      value { Ok($1?) }
    | value ',' entries { Ok($1? + ", " + &$3?) }
    ;

value -> Result<String, ()>:
      'null' { Ok(String::from("null")) }
    | 'true' { Ok(String::from("true")) }
    | 'false' { Ok(String::from("false")) }
    | 'NUM' {
      match $1 {
            Ok(val) => Ok(String::from($lexer.span_str(val.span()))),
            Err(_) => Ok(rand::thread_rng().gen_range(-200000000.9..200000000.9).to_string())
      }
      }
    | string { Ok($1?) }
    | obj { Ok($1?) }
    | arr { Ok($1?) }
    ;

string -> Result<String, ()>:
      'STRING' {
      match $1 {
            Ok(val) => Ok(String::from($lexer.span_str(val.span()))),
            Err(_) => Ok(String::from("\"abc\""))
      }
      }
    ;

unmatched -> ():
  "UNMATCHED" { } 
  ;

%%

// Any functions here are in scope for all the grammar actions above.

// Use rand to insert random integers when repairing
use rand::Rng;
