all:
	Makefile.gen;

clean:
	rm jackcomp*
	rm jack.lex.sml
	rm jack.grm.sml
	rm jack.grm.desc
	rm jack.grm.sig
	rm -Rf CM
	rm -Rf .cm
