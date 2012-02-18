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

public class Lookahead(T) {
    
    public this(T[] array, T sentinel = T.init) {
        this.array = array;
        this.sentinel = sentinel;
    }
    
    public void consume(size_t howmuch=1) {
        size_t i = 0;
        while (array.length && howmuch--) {
            array = array [1 .. $];
        }
    }
    
    public T get(size_t howmuch=0) {
        if (howmuch < array.length) {
            return array[howmuch];
        } else {
            return sentinel;
        }
    }
    
    private T[] array;
    private T sentinel;
}

unittest {
    string[] arr = ["hi", "bye", "foo", "bar", "baz"];
    Lookahead!string lah = new Lookahead!string(arr, "__END__");
    assert(lah.get() == "hi");
    assert(lah.get(1) == "bye");
    lah.consume(4);
    assert(lah.get() == "baz");
    lah.consume();
    assert(lah.get() == "__END__");
    lah.consume(100);
    assert(lah.get() == "__END__");
}


