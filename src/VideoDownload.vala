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
                parse_progress (line);
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

		private void parse_progress(string line) {
            if (line.length == 0) {
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
