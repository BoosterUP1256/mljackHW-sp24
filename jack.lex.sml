functor jackLexFun(structure Tokens : jack_TOKENS)  = struct

    structure yyInput : sig

        type stream
	val mkStream : (int -> string) -> stream
	val fromStream : TextIO.StreamIO.instream -> stream
	val getc : stream -> (Char.char * stream) option
	val getpos : stream -> int
	val getlineNo : stream -> int
	val subtract : stream * stream -> string
	val eof : stream -> bool
	val lastWasNL : stream -> bool

      end = struct

        structure TIO = TextIO
        structure TSIO = TIO.StreamIO
	structure TPIO = TextPrimIO

        datatype stream = Stream of {
            strm : TSIO.instream,
	    id : int,  (* track which streams originated 
			* from the same stream *)
	    pos : int,
	    lineNo : int,
	    lastWasNL : bool
          }

	local
	  val next = ref 0
	in
	fun nextId() = !next before (next := !next + 1)
	end

	val initPos = 2 (* ml-lex bug compatibility *)

	fun mkStream inputN = let
              val strm = TSIO.mkInstream 
			   (TPIO.RD {
			        name = "lexgen",
				chunkSize = 4096,
				readVec = SOME inputN,
				readArr = NONE,
				readVecNB = NONE,
				readArrNB = NONE,
				block = NONE,
				canInput = NONE,
				avail = (fn () => NONE),
				getPos = NONE,
				setPos = NONE,
				endPos = NONE,
				verifyPos = NONE,
				close = (fn () => ()),
				ioDesc = NONE
			      }, "")
	      in 
		Stream {strm = strm, id = nextId(), pos = initPos, lineNo = 1,
			lastWasNL = true}
	      end

	fun fromStream strm = Stream {
		strm = strm, id = nextId(), pos = initPos, lineNo = 1, lastWasNL = true
	      }

	fun getc (Stream {strm, pos, id, lineNo, ...}) = (case TSIO.input1 strm
              of NONE => NONE
	       | SOME (c, strm') => 
		   SOME (c, Stream {
			        strm = strm', 
				pos = pos+1, 
				id = id,
				lineNo = lineNo + 
					 (if c = #"\n" then 1 else 0),
				lastWasNL = (c = #"\n")
			      })
	     (* end case*))

	fun getpos (Stream {pos, ...}) = pos

	fun getlineNo (Stream {lineNo, ...}) = lineNo

	fun subtract (new, old) = let
	      val Stream {strm = strm, pos = oldPos, id = oldId, ...} = old
	      val Stream {pos = newPos, id = newId, ...} = new
              val (diff, _) = if newId = oldId andalso newPos >= oldPos
			      then TSIO.inputN (strm, newPos - oldPos)
			      else raise Fail 
				"BUG: yyInput: attempted to subtract incompatible streams"
	      in 
		diff 
	      end

	fun eof s = not (isSome (getc s))

	fun lastWasNL (Stream {lastWasNL, ...}) = lastWasNL

      end

    datatype yystart_state = 
INITIAL
    structure UserDeclarations = 
      struct

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



      end

    datatype yymatch 
      = yyNO_MATCH
      | yyMATCH of yyInput.stream * action * yymatch
    withtype action = yyInput.stream * yymatch -> UserDeclarations.lexresult

    local

    val yytable = 
Vector.fromList []
    fun mk yyins = let
        (* current start state *)
        val yyss = ref INITIAL
	fun YYBEGIN ss = (yyss := ss)
	(* current input stream *)
        val yystrm = ref yyins
	(* get one char of input *)
	val yygetc = yyInput.getc
	(* create yytext *)
	fun yymktext(strm) = yyInput.subtract (strm, !yystrm)
        open UserDeclarations
        fun lex 
(yyarg as ()) = let 
     fun continue() = let
            val yylastwasn = yyInput.lastWasNL (!yystrm)
            fun yystuck (yyNO_MATCH) = raise Fail "stuck state"
	      | yystuck (yyMATCH (strm, action, old)) = 
		  action (strm, old)
	    val yypos = yyInput.getpos (!yystrm)
	    val yygetlineNo = yyInput.getlineNo
	    fun yyactsToMatches (strm, [],	  oldMatches) = oldMatches
	      | yyactsToMatches (strm, act::acts, oldMatches) = 
		  yyMATCH (strm, act, yyactsToMatches (strm, acts, oldMatches))
	    fun yygo actTable = 
		(fn (~1, _, oldMatches) => yystuck oldMatches
		  | (curState, strm, oldMatches) => let
		      val (transitions, finals') = Vector.sub (yytable, curState)
		      val finals = List.map (fn i => Vector.sub (actTable, i)) finals'
		      fun tryfinal() = 
		            yystuck (yyactsToMatches (strm, finals, oldMatches))
		      fun find (c, []) = NONE
			| find (c, (c1, c2, s)::ts) = 
		            if c1 <= c andalso c <= c2 then SOME s
			    else find (c, ts)
		      in case yygetc strm
			  of SOME(c, strm') => 
			       (case find (c, transitions)
				 of NONE => tryfinal()
				  | SOME n => 
				      yygo actTable
					(n, strm', 
					 yyactsToMatches (strm, finals, oldMatches)))
			   | NONE => tryfinal()
		      end)
	    in 
let
fun yyAction0 (strm, lastMatch : yymatch) = (yystrm := strm;
      (pos := (!pos) + 1; lex()))
fun yyAction1 (strm, lastMatch : yymatch) = (yystrm := strm; (lex()))
fun yyAction2 (strm, lastMatch : yymatch) = (yystrm := strm;
      (pos := (!pos) + 1; lex()))
fun yyAction3 (strm, lastMatch : yymatch) = (yystrm := strm; (lex()))
fun yyAction4 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.String(substring(yytext,1,(size yytext)-2),!pos,!pos))
      end
fun yyAction5 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.LParen(!pos,!pos)))
fun yyAction6 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.RParen(!pos,!pos)))
fun yyAction7 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Plus(!pos,!pos)))
fun yyAction8 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Times(!pos,!pos)))
fun yyAction9 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Div(!pos,!pos)))
fun yyAction10 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Minus(!pos,!pos)))
fun yyAction11 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.LCurly(!pos,!pos)))
fun yyAction12 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.RCurly(!pos,!pos)))
fun yyAction13 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.LSquare(!pos,!pos)))
fun yyAction14 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.RSquare(!pos,!pos)))
fun yyAction15 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Period(!pos,!pos)))
fun yyAction16 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Comma(!pos,!pos)))
fun yyAction17 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.SemiColon(!pos,!pos)))
fun yyAction18 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Amp(!pos,!pos)))
fun yyAction19 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Parallel(!pos,!pos)))
fun yyAction20 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.LessThan(!pos,!pos)))
fun yyAction21 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.GreaterThan(!pos,!pos)))
fun yyAction22 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Equal(!pos,!pos)))
fun yyAction23 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.Tilde(!pos,!pos)))
fun yyAction24 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (Tokens.Integer(sval(explode yytext,0),!pos,!pos))
      end
fun yyAction25 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
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
    end)
      end
fun yyAction26 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (error ("error: bad token "^yytext); lex())
      end
fun yyQ25 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction23(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction23(strm, yyNO_MATCH)
      (* end case *))
fun yyQ24 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction12(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction12(strm, yyNO_MATCH)
      (* end case *))
fun yyQ23 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction19(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction19(strm, yyNO_MATCH)
      (* end case *))
fun yyQ22 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction11(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction11(strm, yyNO_MATCH)
      (* end case *))
fun yyQ21 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction14(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction14(strm, yyNO_MATCH)
      (* end case *))
fun yyQ20 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction13(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction13(strm, yyNO_MATCH)
      (* end case *))
fun yyQ26 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction25(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"["
              then yyAction25(strm, yyNO_MATCH)
            else if inp < #"["
              then if inp = #":"
                  then yyAction25(strm, yyNO_MATCH)
                else if inp < #":"
                  then if inp <= #"/"
                      then yyAction25(strm, yyNO_MATCH)
                      else yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
                else if inp <= #"@"
                  then yyAction25(strm, yyNO_MATCH)
                  else yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
            else if inp = #"`"
              then yyAction25(strm, yyNO_MATCH)
            else if inp < #"`"
              then if inp = #"_"
                  then yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
                  else yyAction25(strm, yyNO_MATCH)
            else if inp <= #"z"
              then yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
              else yyAction25(strm, yyNO_MATCH)
      (* end case *))
fun yyQ19 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction25(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"["
              then yyAction25(strm, yyNO_MATCH)
            else if inp < #"["
              then if inp = #":"
                  then yyAction25(strm, yyNO_MATCH)
                else if inp < #":"
                  then if inp <= #"/"
                      then yyAction25(strm, yyNO_MATCH)
                      else yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
                else if inp <= #"@"
                  then yyAction25(strm, yyNO_MATCH)
                  else yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
            else if inp = #"`"
              then yyAction25(strm, yyNO_MATCH)
            else if inp < #"`"
              then if inp = #"_"
                  then yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
                  else yyAction25(strm, yyNO_MATCH)
            else if inp <= #"z"
              then yyQ26(strm', yyMATCH(strm, yyAction25, yyNO_MATCH))
              else yyAction25(strm, yyNO_MATCH)
      (* end case *))
fun yyQ18 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction21(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction21(strm, yyNO_MATCH)
      (* end case *))
fun yyQ17 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction22(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction22(strm, yyNO_MATCH)
      (* end case *))
fun yyQ16 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction20(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction20(strm, yyNO_MATCH)
      (* end case *))
fun yyQ15 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction17(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction17(strm, yyNO_MATCH)
      (* end case *))
fun yyQ27 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction24(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"0"
              then yyQ27(strm', yyMATCH(strm, yyAction24, yyNO_MATCH))
            else if inp < #"0"
              then yyAction24(strm, yyNO_MATCH)
            else if inp <= #"9"
              then yyQ27(strm', yyMATCH(strm, yyAction24, yyNO_MATCH))
              else yyAction24(strm, yyNO_MATCH)
      (* end case *))
fun yyQ14 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction24(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"0"
              then yyQ27(strm', yyMATCH(strm, yyAction24, yyNO_MATCH))
            else if inp < #"0"
              then yyAction24(strm, yyNO_MATCH)
            else if inp <= #"9"
              then yyQ27(strm', yyMATCH(strm, yyAction24, yyNO_MATCH))
              else yyAction24(strm, yyNO_MATCH)
      (* end case *))
fun yyQ30 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction0(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction0(strm, yyNO_MATCH)
      (* end case *))
fun yyQ29 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"\n"
              then yyQ30(strm', lastMatch)
              else yyQ29(strm', lastMatch)
      (* end case *))
fun yyQ35 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction1(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction1(strm, yyNO_MATCH)
      (* end case *))
fun yyQ34 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"/"
              then yyQ35(strm', lastMatch)
              else yyQ31(strm', lastMatch)
      (* end case *))
and yyQ31 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"*"
              then yyQ34(strm', lastMatch)
              else yyQ31(strm', lastMatch)
      (* end case *))
fun yyQ33 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction1(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"*"
              then yyQ34(strm', yyMATCH(strm, yyAction1, yyNO_MATCH))
              else yyQ31(strm', yyMATCH(strm, yyAction1, yyNO_MATCH))
      (* end case *))
fun yyQ32 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"+"
              then yyQ31(strm', lastMatch)
            else if inp < #"+"
              then if inp = #"*"
                  then yyQ32(strm', lastMatch)
                  else yyQ31(strm', lastMatch)
            else if inp = #"/"
              then yyQ33(strm', lastMatch)
              else yyQ31(strm', lastMatch)
      (* end case *))
fun yyQ28 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"*"
              then yyQ32(strm', lastMatch)
              else yyQ31(strm', lastMatch)
      (* end case *))
fun yyQ13 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction9(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"+"
              then yyAction9(strm, yyNO_MATCH)
            else if inp < #"+"
              then if inp = #"*"
                  then yyQ28(strm', yyMATCH(strm, yyAction9, yyNO_MATCH))
                  else yyAction9(strm, yyNO_MATCH)
            else if inp = #"/"
              then yyQ29(strm', yyMATCH(strm, yyAction9, yyNO_MATCH))
              else yyAction9(strm, yyNO_MATCH)
      (* end case *))
fun yyQ12 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction15(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction15(strm, yyNO_MATCH)
      (* end case *))
fun yyQ11 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction10(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction10(strm, yyNO_MATCH)
      (* end case *))
fun yyQ10 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction16(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction16(strm, yyNO_MATCH)
      (* end case *))
fun yyQ9 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction7(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction7(strm, yyNO_MATCH)
      (* end case *))
fun yyQ8 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction8(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction8(strm, yyNO_MATCH)
      (* end case *))
fun yyQ7 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction6(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction6(strm, yyNO_MATCH)
      (* end case *))
fun yyQ6 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction5(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction5(strm, yyNO_MATCH)
      (* end case *))
fun yyQ5 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction18(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction18(strm, yyNO_MATCH)
      (* end case *))
fun yyQ37 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction4(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"\v"
              then yyQ36(strm', yyMATCH(strm, yyAction4, yyNO_MATCH))
            else if inp < #"\v"
              then if inp = #"\n"
                  then yyAction4(strm, yyNO_MATCH)
                  else yyQ36(strm', yyMATCH(strm, yyAction4, yyNO_MATCH))
            else if inp = #"\""
              then yyQ37(strm', yyMATCH(strm, yyAction4, yyNO_MATCH))
              else yyQ36(strm', yyMATCH(strm, yyAction4, yyNO_MATCH))
      (* end case *))
and yyQ36 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"\v"
              then yyQ36(strm', lastMatch)
            else if inp < #"\v"
              then if inp = #"\n"
                  then yystuck(lastMatch)
                  else yyQ36(strm', lastMatch)
            else if inp = #"\""
              then yyQ37(strm', lastMatch)
              else yyQ36(strm', lastMatch)
      (* end case *))
fun yyQ4 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction26(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"\v"
              then yyQ36(strm', yyMATCH(strm, yyAction26, yyNO_MATCH))
            else if inp < #"\v"
              then if inp = #"\n"
                  then yyAction26(strm, yyNO_MATCH)
                  else yyQ36(strm', yyMATCH(strm, yyAction26, yyNO_MATCH))
            else if inp = #"\""
              then yyQ37(strm', yyMATCH(strm, yyAction26, yyNO_MATCH))
              else yyQ36(strm', yyMATCH(strm, yyAction26, yyNO_MATCH))
      (* end case *))
fun yyQ3 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction2(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction2(strm, yyNO_MATCH)
      (* end case *))
fun yyQ38 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction3(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"\r"
              then yyQ38(strm', yyMATCH(strm, yyAction3, yyNO_MATCH))
            else if inp < #"\r"
              then if inp = #"\t"
                  then yyQ38(strm', yyMATCH(strm, yyAction3, yyNO_MATCH))
                  else yyAction3(strm, yyNO_MATCH)
            else if inp = #" "
              then yyQ38(strm', yyMATCH(strm, yyAction3, yyNO_MATCH))
              else yyAction3(strm, yyNO_MATCH)
      (* end case *))
fun yyQ2 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction3(strm, yyNO_MATCH)
        | SOME(inp, strm') =>
            if inp = #"\r"
              then yyQ38(strm', yyMATCH(strm, yyAction3, yyNO_MATCH))
            else if inp < #"\r"
              then if inp = #"\t"
                  then yyQ38(strm', yyMATCH(strm, yyAction3, yyNO_MATCH))
                  else yyAction3(strm, yyNO_MATCH)
            else if inp = #" "
              then yyQ38(strm', yyMATCH(strm, yyAction3, yyNO_MATCH))
              else yyAction3(strm, yyNO_MATCH)
      (* end case *))
fun yyQ1 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE => yyAction26(strm, yyNO_MATCH)
        | SOME(inp, strm') => yyAction26(strm, yyNO_MATCH)
      (* end case *))
fun yyQ0 (strm, lastMatch : yymatch) = (case (yygetc(strm))
       of NONE =>
            if yyInput.eof(!(yystrm))
              then UserDeclarations.eof(yyarg)
              else yystuck(lastMatch)
        | SOME(inp, strm') =>
            if inp = #"/"
              then yyQ13(strm', lastMatch)
            else if inp < #"/"
              then if inp = #"#"
                  then yyQ1(strm', lastMatch)
                else if inp < #"#"
                  then if inp = #"\r"
                      then yyQ2(strm', lastMatch)
                    else if inp < #"\r"
                      then if inp = #"\n"
                          then yyQ3(strm', lastMatch)
                        else if inp < #"\n"
                          then if inp = #"\t"
                              then yyQ2(strm', lastMatch)
                              else yyQ1(strm', lastMatch)
                          else yyQ1(strm', lastMatch)
                    else if inp = #"!"
                      then yyQ1(strm', lastMatch)
                    else if inp < #"!"
                      then if inp = #" "
                          then yyQ2(strm', lastMatch)
                          else yyQ1(strm', lastMatch)
                      else yyQ4(strm', lastMatch)
                else if inp = #"*"
                  then yyQ8(strm', lastMatch)
                else if inp < #"*"
                  then if inp = #"'"
                      then yyQ1(strm', lastMatch)
                    else if inp < #"'"
                      then if inp = #"&"
                          then yyQ5(strm', lastMatch)
                          else yyQ1(strm', lastMatch)
                    else if inp = #"("
                      then yyQ6(strm', lastMatch)
                      else yyQ7(strm', lastMatch)
                else if inp = #"-"
                  then yyQ11(strm', lastMatch)
                else if inp < #"-"
                  then if inp = #"+"
                      then yyQ9(strm', lastMatch)
                      else yyQ10(strm', lastMatch)
                  else yyQ12(strm', lastMatch)
            else if inp = #"\\"
              then yyQ1(strm', lastMatch)
            else if inp < #"\\"
              then if inp = #"="
                  then yyQ17(strm', lastMatch)
                else if inp < #"="
                  then if inp = #";"
                      then yyQ15(strm', lastMatch)
                    else if inp < #";"
                      then if inp = #":"
                          then yyQ1(strm', lastMatch)
                          else yyQ14(strm', lastMatch)
                      else yyQ16(strm', lastMatch)
                else if inp = #"A"
                  then yyQ19(strm', lastMatch)
                else if inp < #"A"
                  then if inp = #">"
                      then yyQ18(strm', lastMatch)
                      else yyQ1(strm', lastMatch)
                else if inp = #"["
                  then yyQ20(strm', lastMatch)
                  else yyQ19(strm', lastMatch)
            else if inp = #"|"
              then yyQ23(strm', lastMatch)
            else if inp < #"|"
              then if inp = #"a"
                  then yyQ19(strm', lastMatch)
                else if inp < #"a"
                  then if inp = #"]"
                      then yyQ21(strm', lastMatch)
                      else yyQ1(strm', lastMatch)
                else if inp = #"{"
                  then yyQ22(strm', lastMatch)
                  else yyQ19(strm', lastMatch)
            else if inp = #"~"
              then yyQ25(strm', lastMatch)
            else if inp = #"}"
              then yyQ24(strm', lastMatch)
              else yyQ1(strm', lastMatch)
      (* end case *))
in
  (case (!(yyss))
   of INITIAL => yyQ0(!(yystrm), yyNO_MATCH)
  (* end case *))
end
            end
	  in 
            continue() 	  
	    handle IO.Io{cause, ...} => raise cause
          end
        in 
          lex 
        end
    in
    fun makeLexer yyinputN = mk (yyInput.mkStream yyinputN)
    fun makeLexer' ins = mk (yyInput.mkStream ins)
    end

  end
