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

    public GLib.File get_tmp_dir () {
        GLib.File tmp = GLib.File.new_for_path (GLib.Environment.get_tmp_dir ());
        GLib.File app_tmp = tmp.get_child ("com.github.cryptowyrm.copypastegrab");
        if (!GLib.FileUtils.test (app_tmp.get_path (), GLib.FileTest.IS_DIR)) {
            try {
                app_tmp.make_directory ();
            } catch (Error e) {
                print ("Error creating tmp dir: %s\n", e.message);
            }
        }

        return app_tmp;
    }

}
