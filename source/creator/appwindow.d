module creator.appwindow;
import gtk.MainWindow;
public import gtk.Widget;
import gtk.HeaderBar;

class InochiWindow : MainWindow {
private:

public:
    this() {
        super("Inochi2D Creator");

        // Open a reasonable window size
        this.setDefaultSize(640, 480);

        import gtk.Label : Label;
        this.add(new Label("Placeholder"));

        // Set a headerbar
        HeaderBar header = new HeaderBar();
        header.setShowCloseButton(true);
        header.setTitle(this.getTitle());
        header.setSubtitle("Prototype");
        this.setTitlebar(header);
    }
}
