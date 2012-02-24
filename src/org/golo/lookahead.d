/* lookahead.d - a lookahead class.
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

module org.golo.lookahead;

private {
    import std.array;
    import std.range;
    import std.traits;
}

/++
 + $(D Lookahead!Param) is an infinite lookahead of, if Param is a range, a
 + Param, else an array of Params.
 +/
public class Lookahead(Param) {
    static if (isInputRange!Param) {
        private alias Param R;
        private alias ElementType!Param T;
    } else {
        private alias Param[] R;
        private alias Param T;
    }
    
    /// Initializes a lookahead for range that gives sentinel once the range is
    /// empty.
    public this(R range, T sentinel = T.init) {
        this.range = range;
        this.sentinel = sentinel;
    }
    
    /// Consumes howmuch of the buffer.
    public void consume(size_t howmuch=1) {
        static if (isDynamicArray!R) {
            if (howmuch < range.length) {
                range = range[howmuch .. $];
            } else {
                range = [];
            }
        } else {
            if (howmuch < buffer.length) {
                buffer = buffer[howmuch .. $];
            } else {
                howmuch -= buffer.length;
                buffer = [];
                while(howmuch-- && !range.empty) {
                    range.popFront();
                }
            }
        }
    }
    
    /// Loads in the buffer and gets howmuch of it, or the sentinel.
    public T get(size_t howmuch=0) {
        static if (isDynamicArray!R) {
            if (howmuch < range.length) {
                return range[howmuch];
            } else {
                return sentinel;
            }
        } else {
            if (howmuch >= buffer.length) {
                updateBuffer(howmuch+1);
            }
            
            std.stdio.writeln(buffer);
            if (buffer.length <= howmuch) {
                return sentinel;
            } else {
                return buffer[howmuch];
            }
        }
    }
    
    static if (!isDynamicArray!R)
    private void updateBuffer(size_t howmuch) {
        howmuch -= buffer.length;
        while(howmuch && !range.empty) {
            buffer ~= range.front;
            range.popFront();
            howmuch--;
        }
        
    }
    
    private R range;
    static if (!isDynamicArray!R) private T[] buffer = [];
    private T sentinel;
}

unittest {
    string[] arr = ["hi", "bye", "foo", "bar", "baz"];
    Lookahead!(string[]) lah = new Lookahead!(string[])(arr, "__END__");
    assert(lah.get() == "hi");
    assert(lah.get(1) == "bye");
    lah.consume(4);
    assert(lah.get() == "baz");
    lah.consume();
    assert(lah.get() == "__END__");
    lah.consume(100);
    assert(lah.get() == "__END__");
    
    struct NumberRange {
        uint front = 0;
        enum empty = false;
        void popFront() { front++; }
    }
    
    NumberRange nr;
    Lookahead!(NumberRange) ns = new Lookahead!(NumberRange)(nr);
    assert(ns.get(3) == 3);
    assert(ns.get(20) == 20);
    ns.consume(5);
    assert(ns.get(3) == 8);
    assert(ns.get(20) == 25);
}


