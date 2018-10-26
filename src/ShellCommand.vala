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

	public class ShellCommand : Object {
		public signal void stdout (string line);
		public signal void stderr (string line);
		public signal void done ();

		private Pid child_pid;
		private string spawn_dir;
		private string[] spawn_args;
		private bool running;

		public ShellCommand(string spawn_dir, string[] spawn_args) {
			this.running = false;
			this.spawn_dir = spawn_dir;
			this.spawn_args = spawn_args;
		}

		public void stop() {
			if(running) {
				Posix.kill((int) child_pid, Posix.Signal.KILL);
			}
		}

		public void start() {
			running = true;
			execute();
		}

        private bool process_line (IOChannel channel, IOCondition condition, string stream_name) {
            if (condition == IOCondition.HUP) {
                print ("%s: The fd has been closed.\n", stream_name);
                if(running) {
                	running = false;
                	done ();
                }
                return false;
            }

            try {
                string line;
                channel.read_line (out line, null, null);
                print ("%s: %s", stream_name, line);
                switch (stream_name) {
                	case "stdout":
                		stdout (line);
                		break;
                	case "stderr":
                		stderr (line);
                		break;
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

        private void execute () {
            try {
                string[] spawn_env = Environ.get ();

                int standard_input;
                int standard_output;
                int standard_error;

                Process.spawn_async_with_pipes (
                	spawn_dir,
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
	}
}
