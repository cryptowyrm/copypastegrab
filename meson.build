# project name and programming language
project('com.github.cryptowyrm.copypastegrab', 'vala', 'c')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src/Application.vala',
    'src/DownloadRow.vala',
    'src/VideoDownload.vala',
    'src/VideoInfo.vala',
    'src/ShellCommand.vala',
    'src/Utility.vala',
    'src/SettingsPopover.vala',
    vala_args: [
        '--pkg=posix'
    ],
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('json-glib-1.0')
    ],
    install: true
)

#Install our .desktop file so the Applications Menu will see it
install_data(
    join_paths('data', meson.project_name() + '.desktop'),
    install_dir: join_paths(get_option('datadir'), 'applications')
)

#Install our .appdata.xml file so AppCenter will see it
install_data(
    join_paths('data', meson.project_name() + '.appdata.xml'),
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

subdir('data')

meson.add_install_script('meson/post_install.py')