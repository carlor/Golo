#!bin/golo

/* helloworld.golo - a hello world program
 * blame K&R for the tradition
 */


import std.app; // the Application class

class MyApp : Application {
    public void main() {
        stdout.println("Hello, World!");
    }
}
