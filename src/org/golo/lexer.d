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
	import std.utf;
	
	import org.golo.exceptions;
	import org.golo.lookahead;
	import org.golo.prefs;
	import org.golo.source;
}

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
		characters.consume();
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
	KEYWORD,
	INT_LITERAL,
	
}

alias TokenType TT;

public class Token {
	TokenType type;
	dstring str;
	int line;
	Source src;
}
