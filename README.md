# Torrent feeder
Torrent feeder is a very light-weight script for parsing torrent RSS feeds and adding new torrents to torrent clients.
Currently it only supports ShowRSS.info and Transmission connection.

## Setup
- Download files and place them in a desired folder.
- Edit configuration inside the config file. At the very least, add your own RSS feed url
- Setup a Cron Job to run /your/desired/folder/feed file
- That's it!

## Notes
- Torrent feeder was made with very basic tools which should be present in any unix-like system, hopefully. It was made to run on a QNAP TS-431P NAS, but it should really run on any system
- It's very small, so it can be placed pretty much anywhere where there are a few kB of space

## Features
- Add torrents from ShowRSS feeds
- Only add torrents, that haven't been added before


## ToDO
- Organise files in your configured structure
- Cleanup old logs based on your config
- Notifications of added torrents?
