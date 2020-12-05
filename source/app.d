import std.stdio;
import creator.appwindow;
import gtk.Main;

void main(string[] args)
{
	Main.init(args);
	(new InochiWindow).showAll();
	Main.run();
}
