structure jackAS = 
struct

datatype
    AST = class' of string * (string * string * string list) list * AST list
	| constructor' of string * string * (string * string) list * ((string * string list) list * AST list)
	| function' of string * string * (string * string) list * ((string * string list) list * AST list)
	| method' of string * string * (string * string) list * ((string * string list) list * AST list)
	| letval' of string * AST
	| letarray' of string * AST * AST
	| if' of AST * AST list
	| ifelse' of AST * AST list * AST list
	| while' of AST * AST list
	| do' of AST
	| return' of AST
	| returnvoid'
    | add' of AST * AST
	| sub' of AST * AST
	| prod' of AST * AST
	| div' of AST * AST
	| and' of AST * AST
	| or' of AST * AST
	| lt' of AST * AST
	| gt' of AST * AST
	| equal' of AST * AST
	| integer' of int
	| string' of string
	| true'
	| false'
	| null'
	| this'
	| id' of string
	| idarray' of string * AST
	| negate' of AST
	| not' of AST
	| subcall' of string * AST list
	| subcallq' of string * string * AST list
end;


