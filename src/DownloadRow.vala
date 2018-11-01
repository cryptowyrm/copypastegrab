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

    public class DownloadRow : Object {
        public signal void error (string msg);

        public bool is_downloading = false;
        public VideoDownload video_download;

        public Gtk.Grid layout;
        public Gtk.ProgressBar progress_bar;
        Gtk.Label url_label;
        Gtk.Label title_label;
        Gtk.Button start_button;
        Gtk.Image start_icon;
        Gtk.Image stop_icon;
        Granite.AsyncImage thumbnail;

        public DownloadRow(string video_url) {
            start_icon = new Gtk.Image ();
            start_icon.gicon = new ThemedIcon ("media-playback-start");
            start_icon.pixel_size = 16;
            stop_icon = new Gtk.Image ();
            stop_icon.gicon = new ThemedIcon ("media-playback-stop");
            stop_icon.pixel_size = 16;

            progress_bar = new Gtk.ProgressBar ();
            progress_bar.show_text = true;
            progress_bar.visible = false;
            progress_bar.no_show_all = true;
            progress_bar.ellipsize = Pango.EllipsizeMode.END;

            url_label = new Gtk.Label (video_url);
            url_label.tooltip_text = video_url;
            url_label.hexpand = true;
            url_label.halign = Gtk.Align.START;
            url_label.ellipsize = Pango.EllipsizeMode.END;

            title_label = new Gtk.Label ("Downloading video information...");
            title_label.hexpand = true;
            title_label.halign = Gtk.Align.START;
            title_label.ellipsize = Pango.EllipsizeMode.END;

            layout = new Gtk.Grid ();
            layout.row_spacing = 10;
            layout.column_spacing = 10;
            layout.border_width = 10;
            layout.set_row_baseline_position (0, Gtk.BaselinePosition.TOP);
            layout.set_row_baseline_position (1, Gtk.BaselinePosition.TOP);

            start_button = new Gtk.Button.from_icon_name ("media-playback-start");
            start_button.sensitive = false;
            start_button.valign = Gtk.Align.START;

            thumbnail = new Granite.AsyncImage ();
            thumbnail.valign = Gtk.Align.START;

            Gtk.Grid labels = new Gtk.Grid ();
            labels.row_spacing = 10;
            labels.orientation = Gtk.Orientation.VERTICAL;

            labels.add (url_label);
            labels.add (title_label);
            labels.add (progress_bar);

            layout.attach (thumbnail, 0, 0, 1, 2);
            layout.attach (labels, 1, 0, 1, 2);
            layout.attach (start_button, 3, 0, 1, 1);

            start_button.clicked.connect(() => {
                if(is_downloading) {
                    stop();
                } else {
                    start();
                }
            });

            this.video_download = new VideoDownload (video_url);

            this.video_download.notify["status"].connect((s, p) => {
                switch (video_download.status) {
                    case DownloadStatus.DOWNLOADING:
                        progress_bar.text = "Downloading";
                        break;
                    case DownloadStatus.CONVERTING:
                        progress_bar.text = "Converting";
                        break;
                    case DownloadStatus.PAUSED:
                        progress_bar.text = "Stopped";
                        break;
                    case DownloadStatus.DONE:
                        progress_bar.text = "Completed";
                        start_button.destroy ();
                        break;
                }
            });

            this.video_download.progress.connect ((progress, msg) => {
                progress_bar.set_fraction (progress / 100.0);
                string progress_msg;

                if (video_download.video.dual == true) {
                    progress_msg = @"Downloading $(video_download.video.file_count)/2 $(msg)";
                } else {
                    progress_msg = @"Downloading $(msg)";
                }

                progress_bar.text = progress_msg;
            });

            this.video_download.video_info.connect ((info) => {
                if (info.thumbnail != null) {
                    File file = File.new_for_path (info.thumbnail);
                    thumbnail.set_from_file_async.begin (file, 100, 100, true);
                }
                title_label.label = info.title;
                start_button.sensitive = true;
            });

            this.video_download.error.connect ((msg) => {
                title_label.label = msg;
                thumbnail.set_from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
                start_button.destroy ();
                error (msg + ": " + this.video_download.video.url);
            });

            video_download.start_info ();
        }

        public void stop() {
            start_button.set_image (start_icon);
            is_downloading = false;
            video_download.stop ();
        }

        public void start() {
            progress_bar.text = "Downloading";
            start_button.set_image (stop_icon);
            is_downloading = true;
            progress_bar.visible = true;
            video_download.start_download ();
        }
    }
}
