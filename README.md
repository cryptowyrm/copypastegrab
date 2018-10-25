# Copy Paste Grab

[![Build Status](https://travis-ci.com/cryptowyrm/copypastegrab.svg?branch=master)](https://travis-ci.com/cryptowyrm/copypastegrab)

An [elementary OS](https://elementary.io/) app written in [Vala](https://wiki.gnome.org/Projects/Vala) that provides a GUI frontend for the popular [youtube-dl](https://github.com/rg3/youtube-dl/) command line application to easily download videos from [hundreds of websites](https://rg3.github.io/youtube-dl/supportedsites.html).

![Screenshot](https://i.imgur.com/dn98Oio.png)

## Work in progress

The application should work for the most part but there are still a few features that need to be implemented and a few rough edges that need to be ironed out before release on the elementary OS App Center.

## How to install

**These instructions are for elementary OS 5 Juno.**

You need to install youtube-dl or download it manually and put it on your PATH:

```
sudo apt install youtube-dl
```

Also make sure you have the elementary-sdk installed:

```
sudo apt install elementary-sdk
```

Then do:

```
git clone https://github.com/cryptowyrm/copypastegrab.git
cd copypastegrab
meson build --prefix=/usr
cd build
ninja
sudo ninja install
```

## How to hack on the code

After following the above steps, just execute `ninja` in the build directory after you make changes to recompile, then start the app with `./com.github.cryptowyrm.copypastegrab` or do a `sudo ninja install` again and use the app launcher to start the app.
