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
public interface Lookahead(Param) {
    
    public:
    static if (isInputRange!Param) {
        alias Param R;
        alias ElementType!Param T;
    } else {
        alias Param[] R;
        alias Param T;
    }
    
    /// Consumes howmuch of the buffer.
    void consume(size_t howmuch=1);
    
    /// Loads in the buffer and gets howmuch of it, or the sentinel. 
    T get(size_t howmuch=0);
    
    /// Creates a new lookahead from the range that gives sentinel on empty.
    static Lookahead!Param create(R range, T sentinel = T.init) {
        static if (isDynamicArray!R) {
            return new class Lookahead!(Param) {
                private this() {
                    _array = range;
                    _sentinel = sentinel;
                }
                
                public void consume(size_t howmuch=1) {
                    if (howmuch < _array.length) {
                        _array = _array[howmuch .. $];
                    } else {
                        _array = [];
                    }
                }
                
                public T get(size_t howmuch=0) {
                    if (howmuch < _array.length) {
                        return _array[howmuch];
                    } else {
                        return _sentinel;
                    }
                }
                
                private T[] _array;
                private T _sentinel;
            };
        } else {
            return new class Lookahead!(Param) {
                private this() {
                    _range = range;
                    _buffer = [];
                    _sentinel = sentinel;
                }
                
                public void consume(size_t howmuch=1) {
                    if (howmuch < _buffer.length) {
                        _buffer = _buffer[howmuch .. $];
                    } else {
                        howmuch -= _buffer.length;
                        _buffer = [];
                        while(howmuch-- && !_range.empty) {
                            _range.popFront();
                        }
                    }
                }
                
                public T get(size_t howmuch=0) {
                    if (howmuch >= _buffer.length) {
                        updateBuffer(howmuch+1);
                    }
                    if (_buffer.length <= howmuch) {
                        return sentinel;
                    } else {
                        return _buffer[howmuch];
                    }
                }
                
                private void updateBuffer(size_t howmuch) {
                    howmuch -= _buffer.length;
                    while(howmuch && !_range.empty) {
                        _buffer ~= _range.front;
                        _range.popFront();
                        howmuch--;
                    }           
                }     
                
                private R _range;
                private T[] _buffer;
                private T _sentinel;                           
            };
        }
    }
}
/+

    static if (isDynamicArray!R)
     public class Lookahead {
        /// Initializes a lookahead for range that gives sentinel once the 
        /// range is empty.
        public this(R range, T sentinel = T.init) {
            this.array = range;
            this.sentinel = sentinel;
        }
        
        /// Consumes howmuch of the buffer.
        public void consume(size_t howmuch=1) {
            if (howmuch < array.length) {
                array = array[howmuch .. $];
            } else {
                array = [];
            }
        }
        
        /// Loads in the buffer and gets howmuch of it, or the sentinel.    
        public void get(size_t howmuch=0) {
            if (howmuch < array.length) {
                return array[howmuch];
            } else {
                return sentinel;
            }
        }
        
        private T[] array;
        private T sentinel;
    }
    
    else
     public class Lookahead {
        /// Initializes a lookahead for range that gives sentinel once the 
        /// range is empty.
        public this(R range, T sentinel = T.init) {
            this.array = range;
            this.buffer = [];
            this.sentinel = sentinel;
        }
        
        /// Consumes howmuch of the buffer.
        public void consume(size_t howmuch=1) {
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
        
        /// Loads in the buffer and gets howmuch of it, or the sentinel.    
        public void get(size_t howmuch=0) {
            if (howmuch >= buffer.length) {
                updateBuffer(howmuch+1);
            }
            if (buffer.length <= howmuch) {
                return sentinel;
            } else {
                return buffer[howmuch];
            }
        }
        
        private void updateBuffer(size_t howmuch) {
            howmuch -= buffer.length;
            while(howmuch && !range.empty) {
                buffer ~= range.front;
                range.popFront();
                howmuch--;
            }           
        }
        
        private R range;
        private T[] buffer;
        private T sentinel;
    }

}
+/
unittest {
    string[] arr = ["hi", "bye", "foo", "bar", "baz"];
    Lookahead!(string[]) lah = Lookahead!(string[]).create(arr, "__END__");
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
    Lookahead!(NumberRange) ns = Lookahead!(NumberRange).create(nr);
    assert(ns.get(3) == 3);
    assert(ns.get(20) == 20);
    ns.consume(5);
    assert(ns.get(3) == 8);
    assert(ns.get(20) == 25);
}


