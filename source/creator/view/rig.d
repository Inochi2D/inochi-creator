module creator.view.rig;
import creator.view;

class RigView : View!("RigView", "Rigging") {
    this() {
        import gtk.Label;
        this.add(new Label("Rigging view"));

        this.showAll();
    }
}