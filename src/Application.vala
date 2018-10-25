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
        Gtk.InfoBar infobar;
        Gtk.Label info_label;
        Gtk.Button clear_completed_button;
        Gtk.Image clear_completed_icon;
        Gtk.Button download_all_button;
        Gtk.Image download_all_icon;
        Gtk.MenuButton settings_button;
        SettingsPopover settings_popover;

        Granite.Widgets.AlertView list_placeholder;

        List<DownloadRow> downloads;
        public static GLib.Settings settings;

        public MyApp () {
            Object (
                application_id: "com.github.cryptowyrm.copypastegrab",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            downloads = new List<DownloadRow> ();

            infobar = new Gtk.InfoBar ();
            infobar.no_show_all = true;
            infobar.show_close_button = true;

            info_label = new Gtk.Label ("");
            info_label.ellipsize = Pango.EllipsizeMode.END;
            Gtk.Container info_content = infobar.get_content_area ();
            info_content.add (info_label);
            info_label.show();

            add_url_icon = new Gtk.Image ();
            add_url_icon.gicon = new ThemedIcon ("insert-link");
            add_url_icon.pixel_size = 24;

            paste_url_icon = new Gtk.Image ();
            paste_url_icon.gicon = new ThemedIcon ("edit-paste");
            paste_url_icon.pixel_size = 24;

            clear_completed_icon = new Gtk.Image ();
            clear_completed_icon.gicon = new ThemedIcon ("edit-clear");
            clear_completed_icon.pixel_size = 24;

            download_all_icon = new Gtk.Image ();
            download_all_icon.gicon = new ThemedIcon ("media-playback-start");
            download_all_icon.pixel_size = 24;

            download_all_button = new Gtk.Button ();
            download_all_button.relief = Gtk.ReliefStyle.NONE;
            download_all_button.set_image (download_all_icon);
            download_all_button.tooltip_text = "Start all downloads";

            clear_completed_button = new Gtk.Button ();
            clear_completed_button.relief = Gtk.ReliefStyle.NONE;
            clear_completed_button.set_image (clear_completed_icon);
            clear_completed_button.tooltip_text = "Clear all completed downloads";

            add_url_button = new Gtk.MenuButton ();
            add_url_button.use_popover = true;
            add_url_button.relief = Gtk.ReliefStyle.NONE;
            add_url_button.set_image (add_url_icon);
            add_url_button.tooltip_text = "Enter a video URL to download";
            add_url_popover = new Gtk.Popover (add_url_button);
            add_url_button.popover = add_url_popover;

            settings_button = new Gtk.MenuButton ();
            settings_button.use_popover = true;
            settings_button.relief = Gtk.ReliefStyle.NONE;
            settings_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
            settings_button.tooltip_text = "Settings";
            settings_popover = new SettingsPopover ();
            settings_button.popover = settings_popover;

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
            entry.has_focus = true;

            header = new Gtk.HeaderBar ();
            header.set_show_close_button (true);
            header.pack_start (add_url_button);
            header.pack_start (paste_url_button);
            header.pack_end (settings_button);
            header.pack_end (clear_completed_button);
            header.pack_end (download_all_button);

            var main_window = new Gtk.ApplicationWindow (this);
            main_window.set_titlebar (header);
            main_window.default_height = 300;
            main_window.default_width = 600;
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

            layout.add (infobar);
            layout.add (scrolled);

            main_window.add (layout);

            // load and apply settings for video download path
            settings = new GLib.Settings ("com.github.cryptowyrm.copypastegrab");
            string video_download_path = settings.get_string ("video-download-path");
            if (video_download_path.length == 0) {
                video_download_path = GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS);
            }
            MyApp.settings.set_string ("video-download-path", video_download_path);
            MyApp.settings.bind ("video-download-path", settings_popover, "video_path_url_filename", GLib.SettingsBindFlags.DEFAULT);

            infobar.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.CLOSE) {
                    infobar.hide ();
                }
            });

            button.clicked.connect (() => {
                add_url_clicked ();
            });

            entry.activate.connect (() => {
                add_url_clicked ();
            });

            paste_url_button.clicked.connect (() => {
                Gdk.Display display = main_window.get_display ();
                Gtk.Clipboard clipboard = Gtk.Clipboard.get_default (display);
                string text = clipboard.wait_for_text ().strip ();
                if (validade_url (text)) {
                    // TODO: Check if URL is already added to download list
                    add_download (text);
                } else {
                    infobar.message_type = Gtk.MessageType.WARNING;
                    info_label.label = "Not a valid URL";
                    infobar.show ();
                }
            });

            clear_completed_button.clicked.connect(() => {
                clear_completed ();
            });

            download_all_button.clicked.connect(() => {
                download_all ();
            });

            main_window.show_all ();
        }

        private bool validade_url (string url) {
            if (url.length == 0)
                return false;
            return true;
        }

        private void add_url_clicked () {
            add_url_button.popover.popdown ();
            string url = entry.get_text().strip ();
            if (validade_url (url)) {
                add_download (url);
                entry.set_text ("");
            } else {
                infobar.message_type = Gtk.MessageType.WARNING;
                info_label.label = "Not a valid URL";
                infobar.show ();
            }
        }

        private void add_download (string url) {
            DownloadRow download = new DownloadRow (url);
            downloads.append (download);
            list_box.add (download.layout);
            list_box.show_all ();

            download.error.connect ((msg) => {
                infobar.message_type = Gtk.MessageType.ERROR;
                info_label.label = msg;
                infobar.show ();
            });
        }

        private void clear_completed () {
            downloads.foreach((download) => {
                if (download.video_download.status >= DownloadStatus.DONE) {
                    list_box.remove (download.layout.get_parent ());
                    downloads.remove (download);
                }
            });
        }

        private void download_all () {
            downloads.foreach((download) => {
                if (download.video_download.status == DownloadStatus.PAUSED || download.video_download.status == DownloadStatus.READY) {
                    download.start ();
                }
            });
        }

        public static int main (string[] args) {
            var app = new MyApp ();
            return app.run (args);
        }
    }
}
