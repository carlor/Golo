/* source.d - a class for managing source code.
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

module org.golo.source;

private {
    import std.file;
    import std.utf;
    
    import org.golo.lexer;
    import org.golo.parser;
    import org.golo.prefs;
}

public:

/// This encapsulates a source file.
class Source {
    
    public this(string fname, Prefs p) {
        filename = fname;
        prefs = p;
        
        contents = toUTF32(readText!(string)(fname));
    }

    public void compile() {
        // TODO
        Lexer lex = new Lexer(this, prefs);
        ModuleParser ps = new ModuleParser(lex, prefs);
    }
    
    public dchar[] getCharacters() {
        return contents.dup;
    }
    
    public string getFileName() {
        return filename;
    }
    
    string filename;
    Prefs prefs;
    
    dstring contents;
}
