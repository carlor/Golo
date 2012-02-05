
module org.golo.parser;

private {
    import org.golo.lexer;
    import org.golo.lookahead;
    import org.golo.prefs;
    import org.golo.source;
}

public class ModuleParser {
    
    public this(Lexer lex, Prefs p) {
        tokens = new Lookahead!Token(lex.getTokens(), null);
        prefs = p;
        prefs.msg("Parsing "~lex.getSource().getFileName());
        parse();
    }
    
    private void parse() {
        while (tokens.get() !is null) {
        	modularDec();
        }
    }
    
    private void modularDec() {
    	// TODO
    }
    
    private Lookahead!Token tokens;
    private Prefs prefs;
    
}
