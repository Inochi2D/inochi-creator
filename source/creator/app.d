/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.app;
public import gtk.Widget;
import gtk.MainWindow;
import gtk.HeaderBar;
import gtk.Stack;

import creator.widgets.header;
import creator.view;
import core.itime;
import core.project;
import core.utils;

/**
    An instance of this app
*/
InochiCreator AppInstance;

/**
    The Inochi editor window
*/
class InochiCreator : MainWindow {
private:
    InochiHeader header;
    Project project;

    Widget body_;

    // Loads the start page
    void loadStartPage() {
        body_ = new StartPage();
        this.add(body_);
    }

public:
    this() {
        super("Inochi Creator");

        AppInstance = this;

        // Open a reasonable window size
        this.setDefaultSize(640, 480);
        
        // Sets dark mode and adds the app stylesheet
        this.setDarkMode(true);
        this.addStylesheet(import("app.css"));

        // Set a headerbar
        header = new InochiHeader();
        this.setTitlebar(header);

        // Load start page
        this.loadStartPage();

        // Show all the content in the window.
        this.showAll();

        // Make sure delta time tick happens
        this.registerUpdateTick();

        loadProject(new Project);
    }

    /**
        Loads a project
    */
    void loadProject(Project project) {
        this.project = project;

        // We want to make sure to remove the welcome screen
        this.remove(body_);

        // Prepare the views
        Stack views = new Stack();
        views.addToStack(new RigView);
        views.addToStack(new AnimView);

        // Set the top bar stack
        header.setViews(views);
        body_ = views;
        this.add(views);

        this.showAll();
    }

    /**
        Unload project, sending app back to start screen
    */
    void unloadProject() {

        // Unload the project
        project = null;
        header.unloadViews();
        this.remove(body_);

        // Load start page
        this.loadStartPage();
    }

    /**
        Get the currently active project
        Returns null if there's no active project
    */
    Project getActiveProject() {
        return project;
    }

    /**
        Adds stylesheet code
    */
    final void addStylesheet(string code) {
        this.getStyleContext().addProviderForScreen(this.getScreen(), code.styleFromString(), STYLE_PROVIDER_PRIORITY_USER);
    }

    /**
        Sets the app's dark mode setting
    */
    final void setDarkMode(bool darkMode) {
        this.getSettings().setProperty("gtk-application-prefer-dark-theme", darkMode);
    }
}
