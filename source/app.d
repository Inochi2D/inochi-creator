import std.stdio;
import creator.appwindow;
import gtk.Main;

void main(string[] args)
{
	Main.init(args);
	InochiWindow win = new InochiWindow;
	win.showAll();
	Main.run();
}
