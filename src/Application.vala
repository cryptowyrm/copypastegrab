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

public class MyApp : Gtk.Application {

    Gtk.Button button;
    Gtk.Entry entry;
    Gtk.Label label;
    Gtk.ScrolledWindow scrolled;
    Gtk.TextView view;
    Gtk.HeaderBar header;
    Gtk.ProgressBar progress_bar;

    public MyApp () {
        Object (
            application_id: "com.github.cryptowyrm.copypastegrab",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
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

        button = new Gtk.Button.with_label ("Download");
        entry = new Gtk.Entry ();
        label = new Gtk.Label ("URL:");
        progress_bar = new Gtk.ProgressBar ();
        //progress_bar.height_request = 40;
        progress_bar.text = "Download progress";
        progress_bar.show_text = true;

        scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.shadow_type = Gtk.ShadowType.IN;
        view = new Gtk.TextView ();
        scrolled.add (view);

        topbar.add (label);
        topbar.add (entry);
        topbar.add (button);
        topbar.add (progress_bar);

        layout.add (topbar);
        layout.add (scrolled);

        main_window.add (layout);

        //main_window.destroy.connect (Gtk.main_quit);
        // shows error so probably not needed when using ApplicationWindow

        button.clicked.connect (() => {
            label.label = ("Hello, world!");
            button.sensitive = false;
            shell_command(entry.get_text());
        });

        parse_progress("[Download] 2.0%");

        main_window.show_all ();
    }

    private void parse_progress(string line) {
        //[download] 100.0% of 54.17MiB at  5.45MiB/s ETA 00:00
        //[download] 100% of 54.17MiB in 00:10
        if (line.length == 0) {
            return;
        }

        string[] tokens = line.split_set (" ");

        if (tokens.length == 0) {
            return;
        }

        if (tokens[0] == "[download]") {
            double progress = 0.0;
            // float is %f but double is %lf
            line.scanf ("[download] %lf", &progress);
            progress_bar.set_fraction (progress / 100.0);
        }
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
            view.buffer.text += line;
            parse_progress (line);
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
            });
        } catch (SpawnError e) {
            print ("Error: %s\n", e.message);
        }
    }

    public static int main (string[] args) {
        var app = new MyApp ();
        return app.run (args);
    }
}
