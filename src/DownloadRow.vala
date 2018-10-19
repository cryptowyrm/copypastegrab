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

	public class DownloadRow : Object {
		public bool is_downloading = false;
		private VideoDownload video_download;

		public Gtk.Grid layout;
		public Gtk.ProgressBar progress_bar;
		Gtk.Label label;
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
			progress_bar.show_text = false;

	        label = new Gtk.Label (video_url);
	        label.hexpand = true;
	        label.halign = Gtk.Align.START;

	        layout = new Gtk.Grid ();
	        layout.orientation = Gtk.Orientation.HORIZONTAL;
	        layout.row_spacing = 10;
	        layout.column_spacing = 10;
	        layout.border_width = 10;

	        start_button = new Gtk.Button.from_icon_name ("media-playback-start");

	        thumbnail = new Granite.AsyncImage ();

	        layout.add (thumbnail);
	        layout.add (label);
	        layout.add (progress_bar);
	        layout.add (start_button);

	        // TODO: Continue download with -c
	        start_button.clicked.connect(() => {
	        	if(is_downloading) {
	        		progress_bar.text = "Canceled";
		        	progress_bar.show_text = true;
		        	start_button.set_image (start_icon);
		        	stop();
        		} else {
        			progress_bar.text = "Downloading";
		        	progress_bar.show_text = true;
		        	start_button.set_image (stop_icon);
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
	        		case DownloadStatus.DONE:
	        			progress_bar.text = "Completed";
	        			break;
	        	}
	        });

	        this.video_download.progress.connect((progress) => {
	        	progress_bar.set_fraction (progress / 100.0);
	        });

	        this.video_download.thumbnail.connect((path) => {
	        	File file = File.new_for_path (path);
	        	thumbnail.set_from_file_async.begin (file, 100, 100, true);
	        });
		}

		public void stop() {
			is_downloading = false;
			video_download.stop ();
		}

		public void start() {
			is_downloading = true;
			video_download.start ();
		}
	}
}
