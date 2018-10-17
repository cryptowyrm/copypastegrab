/*
* Copyright (c) 2018 CryptoWyrm (https://github.com/cryptowyrm/copypastegrab)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: CryptoWyrm <cryptowyrm@protonmail.ch>
*/

namespace CopyPasteGrab {

    public class MyApp : Gtk.Application {

        Gtk.Button button;
        Gtk.Entry entry;
        Gtk.Label label;
        Gtk.ScrolledWindow scrolled;
        Gtk.HeaderBar header;
        Gtk.Image add_url_icon;
        Gtk.MenuButton add_url_button;
        Gtk.Image paste_url_icon;
        Gtk.Button paste_url_button;
        Gtk.Popover add_url_popover;
        Gtk.ListBox list_box;

        Granite.Widgets.AlertView list_placeholder;

        Array<DownloadRow> downloads;

        //public signal void progress_event (int download_id, double progress);
        

        public MyApp () {
            Object (
                application_id: "com.github.cryptowyrm.copypastegrab",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            downloads = new Array<DownloadRow> ();

            add_url_icon = new Gtk.Image ();
            add_url_icon.gicon = new ThemedIcon ("insert-link");
            add_url_icon.pixel_size = 24;

            paste_url_icon = new Gtk.Image ();
            paste_url_icon.gicon = new ThemedIcon ("edit-paste");
            paste_url_icon.pixel_size = 24;

            add_url_button = new Gtk.MenuButton ();
            add_url_button.use_popover = true;
            add_url_button.relief = Gtk.ReliefStyle.NONE;
            add_url_button.set_image (add_url_icon);
            add_url_button.tooltip_text = "Enter a video URL to download";
            add_url_popover = new Gtk.Popover (add_url_button);
            add_url_button.popover = add_url_popover;

            paste_url_button = new Gtk.Button ();
            paste_url_button.relief = Gtk.ReliefStyle.NONE;
            paste_url_button.set_image (paste_url_icon);
            paste_url_button.tooltip_text = "Paste video URL to download from the clipboard";

            button = new Gtk.Button.with_label ("Add");
            entry = new Gtk.Entry ();
            label = new Gtk.Label ("URL:");
            var topbar = new Gtk.Grid ();
            topbar.orientation = Gtk.Orientation.HORIZONTAL;
            topbar.row_spacing = 10;
            topbar.column_spacing = 10;
            topbar.border_width = 10;
            topbar.add (label);
            topbar.add (entry);
            topbar.add (button);
            add_url_popover.add (topbar);
            topbar.show_all ();

            header = new Gtk.HeaderBar ();
            header.set_show_close_button (true);
            header.pack_start (add_url_button);
            header.pack_start (paste_url_button);

            var main_window = new Gtk.ApplicationWindow (this);
            main_window.set_titlebar (header);
            main_window.default_height = 250;
            main_window.default_width = 500;
            main_window.title = "Copy Paste Grab";

            var layout = new Gtk.Grid ();
            layout.orientation = Gtk.Orientation.VERTICAL;
            layout.row_spacing = 10;
            layout.column_spacing = 10;
            layout.border_width = 10;
            
            list_box = new Gtk.ListBox ();
            list_placeholder = new Granite.Widgets.AlertView (
                "No downloads",
                "Use the add url or paste url buttons in the header bar to add a new video download.",
                "dialog-information"
            );
            list_box.set_placeholder (list_placeholder);
            list_placeholder.show_all();

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.expand = true;
            scrolled.shadow_type = Gtk.ShadowType.IN;
            scrolled.add (list_box);

            layout.add (scrolled);

            main_window.add (layout);

            // testing timeout for hiding infobar msgs after few seconds
            TimeoutSource time = new TimeoutSource (2000);
            time.set_callback (() => {
                print ("Time!\n");
                return false;
            });
            time.attach (null);

            //main_window.destroy.connect (Gtk.main_quit);
            // shows error so probably not needed when using ApplicationWindow

            button.clicked.connect (() => {
                //button.sensitive = false;
                DownloadRow download = new DownloadRow (entry.get_text());
                entry.set_text ("");
                downloads.append_val (download);
                list_box.add (download.layout);
                list_box.show_all ();
            });

            paste_url_button.clicked.connect (() => {
                print ("clicked");
            });

            main_window.show_all ();
        }

        public static int main (string[] args) {
            var app = new MyApp ();
            return app.run (args);
        }
    }
}
