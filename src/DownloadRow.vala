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
		public signal void download_finished();

		public string video_url = null;

		public Gtk.Grid layout;
		public Gtk.ProgressBar progress_bar;
		Gtk.Label label;
		Gtk.Button cancel_button;

		public DownloadRow(string video_url) {
			this.video_url = video_url;

			progress_bar = new Gtk.ProgressBar ();
	        progress_bar.text = "Download progress";
	        progress_bar.show_text = true;

	        label = new Gtk.Label (video_url);
	        label.hexpand = true;
	        label.halign = Gtk.Align.START;

	        layout = new Gtk.Grid ();
	        layout.orientation = Gtk.Orientation.HORIZONTAL;
	        layout.row_spacing = 10;
	        layout.column_spacing = 10;
	        layout.border_width = 10;

	        cancel_button = new Gtk.Button.with_label ("Cancel");

	        layout.add (label);
	        layout.add (progress_bar);
	        layout.add (cancel_button);
		}

		public void start() {
			shell_command(this.video_url);
		}

		private double parse_progress(string line) {
            double progress = -1.0;

            if (line.length == 0) {
                return progress;
            }

            string[] tokens = line.split_set (" ");

            if (tokens.length == 0) {
                return progress;
            }

            if (tokens[0] == "[download]") {
                // float is %f but double is %lf
                line.scanf ("[download] %lf", &progress);
            }
            return progress;
        }

        private bool process_line (IOChannel channel, IOCondition condition, string stream_name) {
            if (condition == IOCondition.HUP) {
                print ("%s: The fd has been closed.\n", stream_name);
                return false;
            }

            try {
                string line;
                channel.read_line (out line, null, null);
                print ("%s: %s", stream_name, line);
                double progress = parse_progress (line);
                if(progress >= 0.0) {
                    progress_bar.set_fraction (progress / 100.0);
                }
            } catch (IOChannelError e) {
                print ("%s: IOChannelError: %s\n", stream_name, e.message);
                return false;
            } catch (ConvertError e) {
                print ("%s: ConvertError: %s\n", stream_name, e.message);
                return false;
            }

            return true;
        }

        private void shell_command (string url) {
            try {
                string[] spawn_args = {"youtube-dl", "--newline", url};
                string[] spawn_env = Environ.get ();
                Pid child_pid;

                int standard_input;
                int standard_output;
                int standard_error;

                Process.spawn_async_with_pipes ("/home/chris/Videos",
                    spawn_args,
                    spawn_env,
                    SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                    null,
                    out child_pid,
                    out standard_input,
                    out standard_output,
                    out standard_error);

                // stdout:
                IOChannel output = new IOChannel.unix_new (standard_output);
                output.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                    return process_line (channel, condition, "stdout");
                });

                // stderr:
                IOChannel error = new IOChannel.unix_new (standard_error);
                error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                    return process_line (channel, condition, "stderr");
                });

                ChildWatch.add (child_pid, (pid, status) => {
                    // Triggered when the child indicated by child_pid exits
                    Process.close_pid (pid);
                    download_finished();
                });
            } catch (SpawnError e) {
                print ("Error: %s\n", e.message);
            }
        }
	}
}
