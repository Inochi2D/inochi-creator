module creator.view.anim;
import creator.view;

class AnimView : View!("AnimView", "Animation") {
    this() {
        import gtk.Label;
        this.add(new Label("Hello, world!"));
        
        this.showAll();
    }
}