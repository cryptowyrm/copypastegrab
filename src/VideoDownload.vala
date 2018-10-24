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
        READY,
        DONE,
        ERROR
    }

    public class VideoDownload : Object {
        public signal void progress (double value, string msg);
        public signal void video_info (VideoInfo info);
        public signal void error (string msg);

        public DownloadStatus status {
            get; private set; default = DownloadStatus.INITIAL;
        }

        public VideoInfo video {
            get; private set;
        }

        private ShellCommand video_info_command;
        private ShellCommand video_download_command;

        public VideoDownload(string video_url) {
            this.video = new VideoInfo ();
            this.video.url = video_url;

            video_info_command = new ShellCommand (
                get_tmp_dir ().get_path (),
                {
                    "youtube-dl",
                    "--newline",
                    "--write-thumbnail",
                    "--write-info-json",
                    "--no-playlist",
                    "--skip-download",
                    video_url
                }
            );

            video_info_command.stdout.connect ((line) => {
                parse_line (line);
            });

            video_info_command.stderr.connect ((line) => {
                if (status != DownloadStatus.ERROR) {
                    if (line.index_of ("ERROR: Unsupported URL:") > -1) {
                        error ("Unsupported website");
                        status = DownloadStatus.ERROR;
                    } else if (line.has_prefix ("ERROR:") && line.index_of ("is not a valid URL.") > -1) {
                        error ("Not a valid URL");
                        status = DownloadStatus.ERROR;
                    } else if (line.has_prefix ("ERROR:")) {
                        error (line);
                        status = DownloadStatus.ERROR;
                    }
                }
                
            });

            video_info_command.done.connect (() => {
                if (status == DownloadStatus.ERROR) {
                    return;
                }

                parse_json (this.video.json);
                video_info (this.video);

                status = DownloadStatus.READY;
            });
        }

        public void stop() {
            status = DownloadStatus.PAUSED;
            video_download_command.stop ();
        }

        public void start_info () {
            video_info_command.start ();
        }

        public void start_download () {
            video_download_command = new ShellCommand (
                MyApp.settings.get_string ("video-download-path"),
                {
                    "youtube-dl",
                    "--newline",
                    "--no-playlist",
                    "--load-info-json",
                    this.video.json,
                    this.video.url
                }
            );

            video_download_command.stdout.connect ((line) => {
                parse_line (line);
            });

            video_download_command.done.connect (() => {
                if (status != DownloadStatus.PAUSED) {
                    status = DownloadStatus.DONE;
                }
            });

            video_download_command.start ();
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
                            this.video.title = video_title;
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

                this.video.thumbnail = get_tmp_dir ().get_child (thumbnail_file).get_path ();

                return;
            }

            // check if downloading JSON
            string json_search = "Writing video description metadata as JSON to: ";
            int json_index = line.index_of (json_search);
            if(json_index > -1) {
                string json_file = line.substring (json_index + json_search.length).strip ();

                this.video.json = get_tmp_dir ().get_child (json_file).get_path ();

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
                    
                    double progress_value = double.parse(line.slice(line.index_of(" "), line.index_of("%")).strip());
                    string progress_msg = line.substring (line.index_of (" "));

                    if (progress_value >= 0.0) {
                        progress (
                            progress_value,
                            progress_msg
                        );
                    }
                    break;
                case "[ffmpeg]":
                    if(status != DownloadStatus.CONVERTING) {
                        status = DownloadStatus.CONVERTING;
                    }
                    break;
                case "[youtube:channel]":
                    video_info_command.stop ();
                    status = DownloadStatus.ERROR;
                    error ("Downloading channels isn't implemented yet");
                    break;
                case "[youtube:playlist]":
                    if (line.index_of ("Downloading just video") == -1) {
                        video_info_command.stop ();
                        status = DownloadStatus.ERROR;
                        error ("Downloading playlists isn't implemented yet");
                    }
                    break;
            }
        }
    }
}
