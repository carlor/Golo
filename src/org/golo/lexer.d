/* lexer.d - turns the source code into tokens.
 * Copyright (C) 2012 Nathan M. Swan
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


module org.golo.lexer;

private {
	import std.stdio;
	import std.uni;
	import std.utf;
	import core.vararg;
	
	import org.golo.exceptions;
	import org.golo.lookahead;
	import org.golo.prefs;
	import org.golo.source;
}

private enum KeywordsToTypes = [
	"import"d : TT.KwIMPORT
];

public class Lexer {
	
	public this(Source src, Prefs p) {
		source = src;
		prefs = p;
		characters = new Lookahead!dchar(src.getCharacters(), END);
		prefs.msg("Tokenizing "~src.getFileName()~"...");
		tokenize();
	}
	
	private void tokenize() {
		while (notdone) {
			readchar();
		}
	}
	
	private void readchar() {
		switch (characters.get()) {
			// -- whitespace --
			case ' ': case '\t':
				characters.consume();
				break;
			case '\r':
				if (characters.get(1) == '\n') {
					characters.consume();
				}
			case '\n':
				characters.consume();
				linenum++;
				break;
			// -- comments --
			case '/': case '#':
				maybecomment();
				break;
			// -- end --
			case END:
				notdone = false;
				break;
			// -- the rest --
			default:
				maybetoken();
		}
	}
	
	private void maybecomment() {
		dchar c1 = characters.get();
		assert(c1 == '/' || c1 == '#');
		if (c1 == '/') {
			dchar c2 = characters.get(1);
			if (c2 == '/') {
				singleLineComment();
			} else if (c2 == '*') {
				multiLineComment();
			} else {
				unrecognized([c1, c2]);
			}
		} else {
			shebangComment();
		}
	}
	
	private void singleLineComment() {
		characters.consume(2);
		while (true) {
			dchar c = characters.get();
			if (c == '\n' || c == '\r' || c == END) {
				break;
			} else {
				characters.consume();
			}
		}
	}
	
	private void multiLineComment() {
		characters.consume(2);
		while (true) {
			dchar c = characters.get();
			if (c == END) {
				error("comment unclosed");
			} else if (c == '*') {
				c = characters.get(1);
				characters.consume(2);
				if (c == '/') {
					break;
				}
			} else if (c == '\n' || c == '\r') {
				newline();
			} else {
				characters.consume();
			}
		}
	}
	
	private void shebangComment() {
		if (linenum == 1) {
			singleLineComment();
		} else {
			error("hash comments are only allowed on the first line");
		}
	}
	
	private void maybetoken() {
		dchar c = characters.get();
		if (isAlpha(c) || c == '_') {
			keywordOrIdentifier();
		} else if (c == '"')  {
			stringLiteral();
		} else if (c == '\'') {
			charLiteral();
		} else if (isNumber(c)) {
			numLiteral();
		} else {
			operatorOrInvalid();
		}
	}
	
	private void keywordOrIdentifier() {
		dstring str = [characters.get()];
		characters.consume();
		while(true) {
			dchar c = characters.get();
			if (isAlpha(c) || isNumber(c) || c == '_') {
				str ~= c;
				characters.consume();
			} else {
				break;
			}
		}
		if (str in KeywordsToTypes) {
			add(KeywordsToTypes[str], str);
		} else if (str == "__EOF__") {
			notdone = false;
		} else {
			add(TT.IDENTIFIER, str);
		}
	}
	
	private void stringLiteral() {
		dstring lit = [characters.get()];
		characters.consume();
		while (true) {
			dchar c = characters.get();
			if (c == '\\') {
				characters.consume(2);
				continue;
			} else if (c == END) {
				error("String is unfinished");
			} else {
				lit ~= c;
				characters.consume();
				if (c == '"') break;
			}
		}
		add(TT.LtSTRING, lit);
	}
	
	private void charLiteral() {
		todo = "char literals";
	}
	
	private void numLiteral() {
		todo = "num literals";
	}
	
	private void operatorOrInvalid() {
		dchar c = characters.get();
		switch (c) {
			// -- arithmetic ops --
			case '+':
				testForThese("++"d,TT.OpINC, "+="d,TT.OpADDEQ, "+"d,TT.OpADD);
				break;
			case '-':
				testForThese("--"d,TT.OpDEC, "-="d,TT.OpDIFEQ, "-"d,TT.OpDIF); 
				break;
			case '*':
				testForThese("*="d, TT.OpMULEQ, "*"d, TT.OpMUL);
				break;
			case '/':
				testForThese("/="d, TT.OpDIVEQ, "/"d, TT.OpDIV);
				break;
			case '%':
				testForThese("%="d, TT.OpMODEQ, "%"d, TT.OpMOD);
				break;
				
			// -- comparison ops --
			case '<':
				testForThese("<="d, TT.OpLE, "<"d, TT.OpLT);
				break;
			case '>':
				testForThese(">="d, TT.OpGE, ">"d, TT.OpGT);
				break;
			case '!':
				testForThese("!="d, TT.OpNE);
				break;
				
			// -- grouping --
			case '(':
				scop(c, TT.OpOPPAREN);
				break;
			case ')':
				scop(c, TT.OpCLPAREN);
				break;
			case '{':
				scop(c, TT.OpOPBLOCK);
				break;
			case '}':
				scop(c, TT.OpCLBLOCK);
				break;
			case '[':
				scop(c, TT.OpOPBRACK);
				break;
			case ']':
				scop(c, TT.OpCLBRACK);
				break;
				
			// -- misc --
			case '=':
				testForThese("==="d, TT.OpEEE, "=="d, TT.OpEE, "="d, TT.OpSET);
				break;
			case ',':
				scop(c, TT.OpCOMMA);
				break;
			case ':':
				scop(c, TT.OpCOLON);
				break;
			case ';':
				scop(c, TT.OpSTSEP);
				break;
			case '.':
				scop(c, TT.OpDOT);
				break;
			case '@':
				scop(c, TT.OpATT);
				break;
			
			default:
				unrecognized([c]);
		}
	}
	
	private dstring newline() {
		dchar c1 = characters.get(0);
		dchar c2 = characters.get(1);
		if (c1 == '\n') {
			linenum++;
			characters.consume(1);
			return [c1];
		} else {
			linenum++;
			if (c2 == '\n') {
				characters.consume(2);
				return [c1, c2];
			} else {
				characters.consume(1);
				return [c1];
			}
		}
	}
	
	
	private void testForThese(T...)(dstring str, TokenType tt, T args) {
		foreach(i, c; str) {
			if (characters.get(i) != c) {
				static if (args.length == 0) {
					unrecognized([characters.get(0)]);
				} else {
					testForThese!(T[2 .. $])(args);
				}
				return;
			}
		}
		add(tt, str);
		characters.consume(str.length);
	}
	
	private void scop(dchar c, TokenType tt) {
		add(tt, [c]);
		characters.consume();
	}
	
	private void add(TokenType tt, dstring str) {
		Token r = new Token();
		r.line = linenum;
		r.src = source;
		r.type = tt;
		r.str = str;
		tokens ~= r;
		writeln(str);
	}
	
	@property private void todo() {
		error("Program requires something as-of-yet unimplemented."d);
	}
	
	@property private void todo(string msg) {
		error(toUTF32(msg) ~ " have yet to be implemented");
	}
	
	private void unrecognized(dstring badtoken) {
		error("Unrecognized character sequence \""~badtoken~"\"");
	}
	
	private void error(dstring msg) {
		throw new LocationException(toUTF8(msg), source, linenum);
	}
	
	private Source source;
	private Prefs prefs;
	
	private Lookahead!dchar characters;
	private Token[] tokens;
	
	private ulong linenum = 1;
	private bool notdone = true;
	
	private enum END = cast(dchar)-1;
}

/// By convention, TokenType is a type, TT.CONST is the value
public enum TokenType {
	IDENTIFIER,
	
	KwIMPORT,
	
	LtSTRING,
	
	OpADD,
	OpDIF,
	OpMUL,
	OpDIV,
	OpMOD,
	
	OpADDEQ,
	OpDIFEQ,
	OpMULEQ,
	OpDIVEQ,
	OpMODEQ,
	
	OpINC,
	OpDEC,
	
	OpLT,
	OpLE,
	OpGT,
	OpGE,
	
	OpEEE,
	OpEE,
	OpNE,
	
	OpOPPAREN,
	OpCLPAREN,
	OpOPBLOCK,
	OpCLBLOCK,
	OpOPBRACK,
	OpCLBRACK,
	
	OpSET,
	OpSTSEP,
	OpDOT,
	OpCOLON,
	OpCOMMA,
}

alias TokenType TT;

public class Token {
	TokenType type;
	dstring str;
	ulong line;
	Source src;
}
