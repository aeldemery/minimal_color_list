int main (string[] args) {
    // Create a new application
    var app = new Gtk.Application ("com.example.GtkApplication", GLib.ApplicationFlags.FLAGS_NONE);

    app.activate.connect (() => {
        // Create a new window
        var window = new Gtk.ApplicationWindow (app);
        window.default_height = 400;
        window.default_width = 600;

        var sw = new Gtk.ScrolledWindow ();
        window.set_child (sw);

        var gridview = new Gtk.GridView ();
        // gridview.set_max_columns(2000);
        with (gridview) {
            hexpand = true;
            vexpand = true;
            add_css_class ("compact");
            // max_columns = 200;
        }

        var color_model = new Gtk4Demo.ColorListModel (4096);
        var factory = new Gtk.SignalListItemFactory ();
        var selection = new Gtk.NoSelection (color_model);
        factory.setup.connect (setup_colorlist_cb);
        gridview.model = selection;
        gridview.factory = factory;

        sw.set_child (gridview);

        window.present ();
    });

    return app.run (args);
}

void setup_colorlist_cb (Gtk.ListItemFactory factory, Gtk.ListItem list_item) {
    var expression = new Gtk.ConstantExpression.for_value (list_item);
    var color_expression = new Gtk.PropertyExpression (typeof (Gtk.ListItem), expression, "item");

    var picture = new Gtk.Picture ();
    picture.set_size_request (32, 32);
    color_expression.bind (picture, "paintable", null);
    list_item.set_child (picture);
}

public class Gtk4Demo.ColorWidget : GLib.Object, Gdk.Paintable {

    public ColorWidget (string name, float r, float g, float b) {
        _color = { r, g, b, 1.0f };
        this.color_name = name;
        this.color = _color;
        // Object(color: _color, color_name: name);
    }

    construct {
    }
    // Properties
    public string color_name { get; set; }

    private Gdk.RGBA _color = { 1f, 1f, 1f, 1f };
    public Gdk.RGBA color {
        get {
            return _color;
        }
        set {
            _color = value;
            double h_local, s_local, v_local;
            rgb_to_hsv (_color, out h_local, out s_local, out v_local);
            _hue = (int) GLib.Math.round (360 * h_local);
            _saturation = (int) GLib.Math.round (100 * s_local);
            _value = (int) GLib.Math.round (100 * v_local);
        }
    }

    public float red {
        get {
            return _color.red;
        }
    }

    public float green {
        get {
            return _color.green;
        }
    }

    public float blue {
        get {
            return _color.blue;
        }
    }

    public int hue {
        get; default = 360;
    }

    public int saturation {
        get; default = 100;
    }

    public int value {
        get; default = 100;
    }

    public void snapshot (Gdk.Snapshot snapshot, double width, double height) {
        ((Gtk.Snapshot)snapshot).append_color (this.color, { { 0, 0 }, { (float) width, (float) height } });
    }

    public int get_intrinsic_height () {
        return 32;
    }

    public int get_intrinsic_width () {
        return 32;
    }

    public static void rgb_to_hsv (Gdk.RGBA rgba, out double h_out, out double s_out, out double v_out) {
        var red = rgba.red;
        var green = rgba.green;
        var blue = rgba.blue;

        double min, max, delta;
        double h = 0.0, s = 0.0, v = 0.0;

        if (red > green) {
            if (red > blue)
                max = red;
            else
                max = blue;

            if (green < blue)
                min = green;
            else
                min = blue;
        } else {
            if (green > blue)
                max = green;
            else
                max = blue;

            if (red < blue)
                min = red;
            else
                min = blue;
        }

        v = max;

        if (max != 0.0)
            s = (max - min) / max;
        else
            s = 0.0;

        if (s == 0.0)
            h = 0.0;
        else {
            delta = max - min;

            if (red == max)
                h = (green - blue) / delta;
            else if (green == max)
                h = 2 + (blue - red) / delta;
            else if (blue == max)
                h = 4 + (red - green) / delta;

            h /= 6.0;

            if (h < 0.0)
                h += 1.0;
            else if (h > 1.0)
                h -= 1.0;
        }

        h_out = h; s_out = s; v_out = v;
    }

    public static string ? get_rgb_markup (ColorWidget ? color) {
        if (color == null) return null;
        return "<b>R:</b> %d <b>G:</b> %d <b>B:</b> %d".printf (
            (int) (color.red * 255),
            (int) (color.green * 255),
            (int) (color.blue * 255)
        );
    }

    public static string ? get_hsv_markup (ColorWidget ? color) {
        if (color == null) return null;
        return "<b>H:</b> %d <b>S:</b> %d <b>V:</b> %d".printf (
            color.hue,
            color.saturation,
            color.value
        );
    }
}


public const int N_COLORS = 256 * 256 * 256;

public class Gtk4Demo.ColorListModel : GLib.Object, GLib.ListModel {

    public ColorListModel (uint size) {
        this.size = size;
    }

    private static ColorWidget[] colors = new ColorWidget[N_COLORS]; /* Internal Data for the ListModel */

    static construct {
        try {
            var data = GLib.resources_lookup_data (
                "/github/aeldemery/gtk4_color_list/color.names.txt",
                GLib.ResourceLookupFlags.NONE
            );

            var lines = ((string) data.get_data()).split ("\n");
            foreach (var line in lines) {
                if ((line.get(0) == '#') || (line.get(0) == '\0')) {
                    continue;
                }
                var fields = line.split (" ");
                var name = fields[1];

                var red = int.parse (fields[3]);
                var green = int.parse (fields[4]);
                var blue = int.parse (fields[5]);

                uint pos = ((red & 0xFF) << 16) | ((green & 0xFF) << 8) | blue;

                if (colors[pos] == null) {
                    colors[pos] = new ColorWidget (name, red / 255f, green / 255f, blue / 255f);
                }
            }
        } catch (GLib.Error error) {
            critical ("Error occured in ColorListModel, error: %s\n", error.message);
        }
    }

    private uint _size = N_COLORS;
    public uint size {
        get {
            return _size;
        }
        set {
            uint old_size = _size;
            _size = value;

            if (_size > old_size) {
                items_changed (old_size, 0, _size - old_size);
            } else if (old_size > _size) {
                items_changed (_size, old_size - _size, 0);
            }

            notify_property ("size");
        }
    }

    public GLib.Object ? get_item (uint position)
    requires (position < size) /* One less than size? */
    {
        var pos = position_to_color (position);

        if (colors[pos] == null) {
            uint red, green, blue;
            red = (pos >> 16) & 0xFF;
            green = (pos >> 8) & 0xFF;
            blue = pos & 0xFF;

            colors[pos] = new ColorWidget ("", red / 255f, green / 255f, blue / 255f);
        }

        return colors[pos];
    }

    public GLib.Type get_item_type () {
        return typeof (ColorWidget);
    }

    public uint get_n_items () {
        return size;
    }

    public uint position_to_color (uint position) {
        var map = new uint[] {
            0xFF0000, 0x00FF00, 0x0000FF,
            0x7F0000, 0x007F00, 0x00007F,
            0x3F0000, 0x003F00, 0x00003F,
            0x1F0000, 0x001F00, 0x00001F,
            0x0F0000, 0x000F00, 0x00000F,
            0x070000, 0x000700, 0x000007,
            0x030000, 0x000300, 0x000003,
            0x010000, 0x000100, 0x000001
        };
        uint i = 0, result = 0;
        foreach (var element in map) {
            if ((position & (1 << i)) > 0) {
                result ^= map[i];
                i++;
            }
        }
        return result;
    }
}
