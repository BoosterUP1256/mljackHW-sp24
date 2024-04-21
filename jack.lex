(* jack.lex -- lexer spec *)

type pos = int
type svalue = Tokens.svalue
type ('a, 'b) token = ('a, 'b) Tokens.token
type lexresult = (svalue, pos) token
val pos = ref 1
val error = fn x => TextIO.output(TextIO.stdErr, x ^ "\n")
val eof = fn () => Tokens.EOF(!pos, !pos)
fun sval([], r) = r
  | sval(a::s, r) = sval (s, r*10+(ord(a) - ord(#"0")));

%%

%header (functor jackLexFun(structure Tokens : jack_TOKENS));
alpha=[A-Za-z];
alphanumeric=[A-Za-z0-9_];
digit=[0-9];
ws=[\ \t\013];

%%

\/\/.*\n => (pos := (!pos) + 1; lex());
(\/\*)(\*)?([^\*] | \*[^\/])*(\*\/) => (lex());
\n  => (pos := (!pos) + 1; lex());
{ws}+  => (lex());
"\"".*"\"" => (Tokens.String(substring(yytext,1,(size yytext)-2),!pos,!pos));
"("  => (Tokens.LParen(!pos,!pos));
")"  => (Tokens.RParen(!pos,!pos));
"+"  => (Tokens.Plus(!pos,!pos));
"*"  => (Tokens.Times(!pos,!pos));
"/"  => (Tokens.Div(!pos,!pos));
"-"  => (Tokens.Minus(!pos,!pos));
"{"  => (Tokens.LCurly(!pos,!pos));
"}"  => (Tokens.RCurly(!pos,!pos));
"["  => (Tokens.LSquare(!pos,!pos));
"]"  => (Tokens.RSquare(!pos,!pos));
"."  => (Tokens.Period(!pos,!pos));
","  => (Tokens.Comma(!pos,!pos));
";"  => (Tokens.SemiColon(!pos,!pos));
"&"  => (Tokens.Amp(!pos,!pos));
"|"  => (Tokens.Parallel(!pos,!pos));
"<"  => (Tokens.LessThan(!pos,!pos));
">"  => (Tokens.GreaterThan(!pos,!pos));
"="  => (Tokens.Equal(!pos,!pos));
"~"  => (Tokens.Tilde(!pos,!pos));
{digit}+  => (Tokens.Integer(sval(explode yytext,0),!pos,!pos));
{alpha}{alphanumeric}* =>
   (let val tok = String.implode (List.map (Char.toLower) 
             (String.explode yytext))
    in
      if      tok="class" then Tokens.Class(!pos,!pos)
      else if tok="constructor" then Tokens.Constructor(!pos,!pos)
      else if tok="function" then Tokens.Function(!pos,!pos)
      else if tok="method" then Tokens.Method(!pos,!pos)
      else if tok="field" then Tokens.Field(!pos,!pos)
      else if tok="static" then Tokens.Static(!pos,!pos)
      else if tok="var" then Tokens.Var(!pos,!pos)
      else if tok="char" then Tokens.Char(!pos,!pos)
      else if tok="int" then Tokens.Int(!pos,!pos)
      else if tok="boolean" then Tokens.Boolean(!pos,!pos)
      else if tok="void" then Tokens.Void(!pos,!pos)
      else if tok="true" then Tokens.True(!pos,!pos)
      else if tok="false" then Tokens.False(!pos,!pos)
      else if tok="null" then Tokens.Null(!pos,!pos)
      else if tok="this" then Tokens.This(!pos,!pos)
      else if tok="let" then Tokens.Let(!pos,!pos)
      else if tok="do" then Tokens.Do(!pos,!pos)
      else if tok="if" then Tokens.If(!pos,!pos)
      else if tok="else" then Tokens.Else(!pos,!pos)
      else if tok="while" then Tokens.While(!pos,!pos)
      else if tok="return" then Tokens.Return(!pos,!pos)
	else Tokens.Identifier(yytext,!pos,!pos)
    end);
.  => (error ("error: bad token "^yytext); lex());
