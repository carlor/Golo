/* parse.d - turns the source code into tokens.
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

/++
 + Contains the ModuleParser class, which turns a stream of tokens into an 
 + abstract syntax tree, which can be accessed with the call getAST().
 +
 + See_Also: org.golo.ast
 +/

module org.golo.parser;

private {
    import std.utf;
    
    import org.golo.ast;
    import org.golo.exceptions;
    import org.golo.lexer;
    import org.golo.lookahead;
    import org.golo.prefs;
    import org.golo.source;
}

/// See_Also: org.golo.parser
public class ModuleParser {
    
    /++
     + This constructor is the method that creates the AST.
     + Params:
     +     lex = the Lexer whose tokens are used to create the AST.
     +     p   = command-line Prefs.
     + Returns: a ModuleParser that has already done its duty.
     +/
    public this(Lexer lex, Prefs p) {
        // makes sure this isn't an empty file
        Token[] tks = lex.getTokens();
        if (tks.length == 0) {
            error(lex.getSource().getFileName()~" has no tokens!");
        }
        
        // creates the terminator token
        Token lastToken = tks[$-1];
        createTermin(lastToken);
        
        // creates the lookahead
        tokens = new Lookahead!Token(tks, termin);
        
        // alerts that we are parsing file when in verbatim mode
        prefs = p;
        prefs.msg("Parsing "~lex.getSource().getFileName());
        
        // ready, set, go!
        parse();
    }
    
    // constructed from the last token, creates termin, which is to be
    // encountered when the lookahead reaches the end
    private void createTermin(Token lastToken) {
        termin = new Token();
        termin.type = TT.EOF;
        termin.src = lastToken.src;
        termin.line = lastToken.line;
        termin.str = "__EOF__"d;
    }
    
    // until it encounters EOF, it adds modular declerations
    private void parse() {
        while (tokens.get(0) !is termin) {
        	mdecs ~= modularDec();
        }
    }
    
    // creates a module decleration
    private ModuleDecleration modularDec() {
        Attributes atts = readAttributes();
    	switch (tokens.get(0).type) {
    	    case TT.KwIMPORT:
    	        return importDecleration(atts);
    	        break;
	        default:
	            std.stdio.writeln(tokens.get(0).type);
	            error(`"`~toUTF8(tokens.get(0).str)~`"`~
	                  " does not start a valid module decleration");
	            assert(0);
    	} 
    }
    
    // reads an import decleration, with the alrady-parsed attributes
    private ImportDecleration importDecleration(Attributes atts) {
        assert(tokens.get(0).type == TT.KwIMPORT);
        tokens.consume(1);
        FullyQualifiedId fqid = fullyQualifiedId("import statement");
        semicolon("import statement");
        return new ImportDecleration(atts, fqid);
    }
    
    // reads a fully qualified id
    private FullyQualifiedId fullyQualifiedId(string before) {
        FullyQualifiedId r;
        
        // at least one identifier
        assume(TT.IDENTIFIER, "identifier", before);
        r ~= tokens.get(0).str;
        tokens.consume(1);
        
        // the rest
        while(tokens.get(0) !is termin) {
            if (tokens.get(0).type == TT.OpDOT) {
                tokens.consume(1);
                assume(TT.IDENTIFIER, 
                      "identifier", 
                      "fully-qualified identifier");
                r ~= tokens.get(0).str;
                tokens.consume(1);
            } else {
                break;
            }
        }
        return r;
    }
    
    // reads attributes until it encounters a non-attribute keyword
    private Attributes readAttributes() {
        Attributes r;
        outer:
        while (true) {
            switch(tokens.get(0).type) {
                case TT.KwPUBLIC:
                    r.Public = true;
                    tokens.consume(1);
                    break;
                case TT.KwPRIVATE:
                    r.Private = true;
                    tokens.consume(1);
                    break;
                case TT.KwPROTECTED:
                    r.Protected = true;
                    tokens.consume(1);
                    break;
                case TT.KwSTATIC:
                    r.Static = true;
                    tokens.consume(1);
                    break;
                default:
                    // it's not an attribute, so we're done!
                    break outer;
            }
        }
        return r;
    } 
    
    // makes sure there's a semicolon next, error if not, consumes if so
    private void semicolon(string before) {
        assume(TT.OpSEMICOLON, "semicolon", before);
    }
    
    // if the token type is coming up, return it and consume, else error message
    // containg after, before
    private Token assume(TokenType tt, string after, string before) {
        if (!comingUp(tt)) {
            error(after~" expected after "~before);
            assert(0);
        } else {
            Token r = tokens.get(0);
            return r;
        }
    }
    
    // whether an identifier is coming up
    private bool comingUp(TokenType tt) {
        return tokens.get(0).type == tt;
    }
    
    // throws an error with the lookahead location and msg
    private void error(string msg) {
        Token t = tokens.get(0);
        throw new LocationException(msg, t.src, t.line);
    }
    
    private Lookahead!Token tokens;
    private Prefs prefs;
    private Token termin;
    private ModuleDecleration[] mdecs;
    
}
