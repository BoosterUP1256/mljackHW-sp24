signature jack_TOKENS =
sig
type ('a,'b) token
type svalue
val Tilde:  'a * 'a -> (svalue,'a) token
val Equal:  'a * 'a -> (svalue,'a) token
val GreaterThan:  'a * 'a -> (svalue,'a) token
val LessThan:  'a * 'a -> (svalue,'a) token
val Parallel:  'a * 'a -> (svalue,'a) token
val Amp:  'a * 'a -> (svalue,'a) token
val SemiColon:  'a * 'a -> (svalue,'a) token
val Comma:  'a * 'a -> (svalue,'a) token
val Period:  'a * 'a -> (svalue,'a) token
val RSquare:  'a * 'a -> (svalue,'a) token
val LSquare:  'a * 'a -> (svalue,'a) token
val RCurly:  'a * 'a -> (svalue,'a) token
val LCurly:  'a * 'a -> (svalue,'a) token
val Return:  'a * 'a -> (svalue,'a) token
val While:  'a * 'a -> (svalue,'a) token
val Else:  'a * 'a -> (svalue,'a) token
val If:  'a * 'a -> (svalue,'a) token
val Do:  'a * 'a -> (svalue,'a) token
val Let:  'a * 'a -> (svalue,'a) token
val This:  'a * 'a -> (svalue,'a) token
val Null:  'a * 'a -> (svalue,'a) token
val False:  'a * 'a -> (svalue,'a) token
val True:  'a * 'a -> (svalue,'a) token
val Void:  'a * 'a -> (svalue,'a) token
val Boolean:  'a * 'a -> (svalue,'a) token
val Int:  'a * 'a -> (svalue,'a) token
val Char:  'a * 'a -> (svalue,'a) token
val Var:  'a * 'a -> (svalue,'a) token
val Static:  'a * 'a -> (svalue,'a) token
val Field:  'a * 'a -> (svalue,'a) token
val Method:  'a * 'a -> (svalue,'a) token
val Function:  'a * 'a -> (svalue,'a) token
val Constructor:  'a * 'a -> (svalue,'a) token
val Class:  'a * 'a -> (svalue,'a) token
val Identifier: (string) *  'a * 'a -> (svalue,'a) token
val String: (string) *  'a * 'a -> (svalue,'a) token
val Integer: (int) *  'a * 'a -> (svalue,'a) token
val Div:  'a * 'a -> (svalue,'a) token
val Times:  'a * 'a -> (svalue,'a) token
val Minus:  'a * 'a -> (svalue,'a) token
val Plus:  'a * 'a -> (svalue,'a) token
val RParen:  'a * 'a -> (svalue,'a) token
val LParen:  'a * 'a -> (svalue,'a) token
val EOF:  'a * 'a -> (svalue,'a) token
end
signature jack_LRVALS=
sig
structure Tokens : jack_TOKENS
structure ParserData:PARSER_DATA
sharing type ParserData.Token.token = Tokens.token
sharing type ParserData.svalue = Tokens.svalue
end
