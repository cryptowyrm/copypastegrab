# project name and programming language
project('com.github.cryptowyrm.copypastegrab', 'vala', 'c')

# Include the translations module
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

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

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')