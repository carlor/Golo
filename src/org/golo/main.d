/* main.d - has the main function, manages the CLI.
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

module org.golo.main;

private {
	import std.stdio;
	import std.getopt;
	import std.array;
	
	import org.golo.exceptions;
	import org.golo.prefs;
	import org.golo.source;
}

public:



int main(string[] args) {
	bool shouldShowHelp = false;
	Prefs p;
	getopt(
		args,
		"help|h", &shouldShowHelp,
		"verbatim|V", &p.verbatim
	);
	if (shouldShowHelp) {
		showHelp(args[0]);
		return 0;
	}
	try {
		if (args.length == 1) {
			showHelp(args[0]);
			return 1;
		}
		foreach (sfile; args) {
			compile(sfile, p);
		}
	} catch (GoloException ge) {
		stderr.writeln(ge.msg);
		return 1;
	}
	return 0;
}

private:

void compile(string fname, Prefs p) {
	p.msg("compiling "~fname~"...");
	Source src = new Source(fname, p);
	src.compile();
}

void showHelp(string pname) {
	writeln(replace(import("USAGE"), "$pname", pname));
}

