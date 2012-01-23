
module org.golo.source;

private {
	import std.file;
	
	import org.golo.prefs;
}

public:

/// This encapsulates a source file.
class Source {
	
	public this(string fname, Prefs p) {
		filename = fname;
		prefs = p;
		
		contents = std.file.readText!(dstring)(fname);
	}

	public void compile() {
		// TODO
	}
	
	string filename;
	Prefs prefs;
	
	dstring contents;
}
