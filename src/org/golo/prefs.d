
module org.golo.prefs;

private {
    import std.stdio;
}

/// This data structure holds command line preferences.
public struct Prefs {
    
    /// Outputs the message if set to verbatim.
    void msg(string msg) {
        if (verbatim) {
            writeln(msg);
        }
    }
    
    bool verbatim = false;
}
