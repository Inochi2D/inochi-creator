/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import creator.appwindow;
import gtk.Main;

void main(string[] args)
{
	Main.init(args);
	(new InochiWindow).showAll();
	Main.run();
}
