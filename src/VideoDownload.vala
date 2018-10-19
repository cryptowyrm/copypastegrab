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

	public enum DownloadStatus {
		INITIAL,
		FETCHING_URL,
		DOWNLOADING,
		CONVERTING,
		PAUSED,
		DONE
	}

	public class VideoDownload : Object {
        public signal void progress (double value);
        public signal void thumbnail (string path);
        public signal void title (string value);

		public DownloadStatus status {
			get; private set; default = DownloadStatus.INITIAL;
		}

		public string video_url = null;
        private ShellCommand video_info_command;

		public VideoDownload(string video_url) {
			this.video_url = video_url;

            video_info_command = new ShellCommand (
                GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS),
                {
                    "youtube-dl",
                    "--newline",
                    "--write-thumbnail",
                    "--write-info-json",
                    "--skip-download",
                    video_url
                }
            );

            video_info_command.stdout.connect((line) => {
                parse_line (line);
            });

            video_info_command.done.connect(() => {
                status = DownloadStatus.DONE;
            });
		}

		public void stop() {
			status = DownloadStatus.PAUSED;
			video_info_command.stop();
		}

		public void start() {
			video_info_command.start();
		}

        private void parse_json(string json_path) {
            Json.Parser parser = new Json.Parser ();
            try {
                parser.load_from_file (json_path);
            } catch (Error e) {
                print ("Unable to parse data: %s\n", e.message);
            }

            Json.Node node = parser.get_root ();
            Json.Reader reader = new Json.Reader (node);

            foreach (string member in reader.list_members ()) {
                switch (member) {
                    case "title":
                        if (reader.read_member ("title")) {
                            string video_title = reader.get_string_value ();
                            print ("Video title: %s\n", video_title);
                            title (video_title);
                        }
                        break;
                }
            }
        }

		private void parse_line(string line) {
            if (line.length == 0) {
                return;
            }

            // check if downloading thumbnail
            string thumbnail_search = "Writing thumbnail to: ";
            int thumbnail_index = line.index_of (thumbnail_search);
            if(thumbnail_index > -1) {
                string thumbnail_file = line.substring (thumbnail_index + thumbnail_search.length).strip ();
                string thumbnail_path = string.join ("",
                    GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS),
                    "/",
                    thumbnail_file
                );

                thumbnail (thumbnail_path);
            }

            // check if downloading JSON
            string json_search = "Writing video description metadata as JSON to: ";
            int json_index = line.index_of (json_search);
            if(json_index > -1) {
                string json_file = line.substring (json_index + json_search.length).strip ();
                string json_path = string.join ("",
                    GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS),
                    "/",
                    json_file
                );

                // Timeout for 1 second so that the file had time to be written
                TimeoutSource time = new TimeoutSource (1000);
                time.set_callback (() => {
                    parse_json (json_path);
                    return false;
                });
                time.attach (null);

                return;
            }

            string[] tokens = line.split_set (" ");

            if (tokens.length == 0) {
                return;
            }

            switch (tokens[0]) {
            	case "[download]":
            		if(status != DownloadStatus.DOWNLOADING) {
            		  status = DownloadStatus.DOWNLOADING;
	            	}
	                // float is %f but double is %lf
                    double progress_value = -1.0;
	                line.scanf ("[download] %lf", &progress_value);
                    if (progress_value >= 0.0) {
                        progress (progress_value);
                    }
	                break;
	            case "[ffmpeg]":
	            	if(status != DownloadStatus.CONVERTING) {
	            		status = DownloadStatus.CONVERTING;
	            	}
	            	break;
            }
        }
	}
}
