/* ast.d - structs which represent an nodes of the AST.
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

module org.golo.ast;

private {
    import std.bitmanip;
}

public:
//  [public | private | protected] [static]
struct Attributes {
    mixin(bitfields!(
        bool, "Public", 1,  
        bool, "Private", 1,
        bool, "Protected", 1,
        
        bool, "Static", 1,
        
        uint, "", 4));
}

// <identifiers[0]>[.<identifiers[1]>[...]])
struct FullyQualifiedId {
    dstring[] identifiers;
    alias identifiers this;
}

// <atts> import <fqid>;
class ImportDecleration {
    this(Attributes a, FullyQualifiedId f) { atts = a; fqid = f; }
    Attributes atts;
    FullyQualifiedId fqid;
}

