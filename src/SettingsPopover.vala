/*
* Copyright (c) 2018 Christoph Budzinski (https://github.com/cryptowyrm/copypastegrab)
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
* Authored by: Christoph Budzinski <cryptowyrm@protonmail.ch>
*/

namespace CopyPasteGrab {

    public class SettingsPopover : Gtk.Popover {
        Gtk.Grid settings_layout;
        Gtk.Label video_path_label;
        public Gtk.FileChooserButton video_path_url;
        public string video_path_url_filename { get; set; }

        public SettingsPopover () {
            settings_layout = new Gtk.Grid ();
            settings_layout.row_spacing = 5;
            settings_layout.column_spacing = 10;
            settings_layout.border_width = 10;

            video_path_label = new Gtk.Label (_("Videos are downloaded to"));
            video_path_url = new Gtk.FileChooserButton (
                _("Select a folder where videos should be downloaded to"),
                Gtk.FileChooserAction.SELECT_FOLDER);

            settings_layout.attach (video_path_label, 0, 0, 2, 1);
            settings_layout.attach (video_path_url, 0, 1, 2, 1);

            settings_layout.show_all ();

            this.add (settings_layout);

            video_path_url.selection_changed.connect(() => {
                this.video_path_url_filename = video_path_url.get_filename ();
            });

            this.notify["video-path-url-filename"].connect (() => {
                if (video_path_url.get_filename () != video_path_url_filename)
                    video_path_url.select_filename (video_path_url_filename);
            });
        }

    }

}