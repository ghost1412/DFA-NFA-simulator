all: mylex

lex.yy.c: mylex.l 
	lex mylex.l

mylex: lex.yy.c specification.txt
	g++ lex.yy.c -ll -o mylex 

clean : 
	rm lex.yy.c mylex
