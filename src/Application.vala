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

    public MyApp () {
        Object (
            application_id: "com.github.cryptowyrm.copypastegrab",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 300;
        main_window.default_width = 400;
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

        scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.min_content_height = 300;
        view = new Gtk.TextView ();
        scrolled.add (view);

        topbar.add (label);
        topbar.add (entry);
        topbar.add (button);

        layout.add (topbar);
        layout.add (scrolled);

        main_window.add (layout);

        button.clicked.connect (() => {
            label.label = ("Hello, world!");
            button.sensitive = false;
            shell_command(entry.get_text());
        });

        main_window.show_all ();
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
