/* exceptions.d - contains all the exceptions.
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

module org.golo.exceptions;

private {
    import std.conv;
    
    import org.golo.source;
}

template ExceptionDescendant(string child, string parent="Exception") {
    enum ExceptionDescendant 
         = "class "~child~" : "~parent~" {"
         ~"this(string m,string f=__FILE__,size_t l=__LINE__,Throwable n=null){"
         ~"   super(m, f, l, n);"
         ~"} }"
         ;
} 

mixin(ExceptionDescendant!("GoloException"));
/*
public class GoloException : Exception {
    public this(string msg) {
        super(msg);
    }
}
*/
public class LocationException : GoloException {
    public this(string msg, Source src, ulong linenum) {
        super(src.getFileName()~"("~to!string(linenum)~"): "~msg);
    }
}

