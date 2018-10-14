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
        Gtk.ListBox list_box;
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
            header = new Gtk.HeaderBar ();
            header.set_show_close_button (true);

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

            var topbar = new Gtk.Grid ();
            topbar.orientation = Gtk.Orientation.HORIZONTAL;
            topbar.row_spacing = 10;
            topbar.column_spacing = 10;

            button = new Gtk.Button.with_label ("Add");
            entry = new Gtk.Entry ();
            label = new Gtk.Label ("URL:");
            list_box = new Gtk.ListBox ();

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.expand = true;
            scrolled.shadow_type = Gtk.ShadowType.IN;
            scrolled.add (list_box);

            topbar.add (label);
            topbar.add (entry);
            topbar.add (button);

            layout.add (topbar);
            layout.add (scrolled);

            main_window.add (layout);

            //main_window.destroy.connect (Gtk.main_quit);
            // shows error so probably not needed when using ApplicationWindow

            button.clicked.connect (() => {
                //button.sensitive = false;
                DownloadRow download = new DownloadRow (entry.get_text());
                entry.set_text ("");
                download.download_finished.connect(() => {
                    print ("Download finished!\n");
                });
                downloads.append_val (download);
                list_box.add (download.layout);
                list_box.show_all ();
            });

            main_window.show_all ();
        }

        public static int main (string[] args) {
            var app = new MyApp ();
            return app.run (args);
        }
    }
}
