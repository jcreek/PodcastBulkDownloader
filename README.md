![PBD_Logo](img/pdb_logo_small.png)

# Podcast Bulk Downloader

[![Docker Pulls](https://img.shields.io/docker/pulls/cnovel/podcast-bulk-downloader)](https://hub.docker.com/r/cnovel/podcast-bulk-downloader)
[![Release Workflow](https://img.shields.io/github/actions/workflow/status/cnovel/PodcastBulkDownloader/release.yml?branch=main&label=release)](https://github.com/cnovel/PodcastBulkDownloader/actions/workflows/release.yml)
[![Docker CI Workflow](https://img.shields.io/github/actions/workflow/status/cnovel/PodcastBulkDownloader/docker.yml?label=docker%20ci)](https://github.com/cnovel/PodcastBulkDownloader/actions/workflows/docker.yml)

**Podcast Bulk Downloader** is a simple tool that allows you to download all the episodes of a podcast feed into a folder. It can run on Windows, macOS, or in Docker.

## Docker (Recommended)

### Quick Starta

1. Create a `feeds.json` file (see Config Format below)
2. Create a `docker-compose.yml`:

```yaml
services:
  podcast-bulk-downloader:
    image: cnovel/podcast-bulk-downloader:latest
    container_name: podcast-bulk-downloader
    volumes:
      - ./feeds.json:/config/feeds.json:ro
      - ./downloads:/downloads
    environment:
      - SCHEDULE_TIME=03:00
      - RUN_ONCE=false
    restart: unless-stopped
```

3. Run:

```bash
docker-compose up -d
```

The container will check for new episodes daily at the specified time (default: 03:00). By default, it skips episodes already downloaded - just add new feeds and it "just works".

### Environment Variables

| Variable        | Description                   | Default |
| --------------- | ----------------------------- | ------- |
| `SCHEDULE_TIME` | Time to check daily (HH:MM)   | `03:00` |
| `RUN_ONCE`      | Run once instead of scheduled | `false` |

### Config Format

Create a `feeds.json` file:

```json
{
  "feeds": [
    {
      "url": "https://example.com/podcast.rss",
      "subfolder": "my_podcast",
      "prefix": "DATE",
      "last_n": 0,
      "overwrite": false
    }
  ]
}
```

| Field       | Description                    | Default                   |
| ----------- | ------------------------------ | ------------------------- |
| `url`       | RSS feed URL                   | required                  |
| `subfolder` | Subfolder name                 | "default"                 |
| `prefix`    | Filename prefix                | `NO_PREFIX`               |
| `last_n`    | Episodes to download (0 = all) | 1                         |
| `overwrite` | Re-download existing files     | `false` (skip duplicates) |

Config file is mounted at `/config/feeds.json` and downloads are saved to `/downloads` (see volumes in docker-compose).

### Docker Hub

```bash
docker pull cnovel/podcast-bulk-downloader
```

## Windows

⚠️ Several antivirus providers flag Podcast Bulk Downloader as a trojan ([see this issue](https://github.com/cnovel/PodcastBulkDownloader/issues/77)). The issue is being investigated but in the meantime, please flag the exe as false positive to your AV provider. It will greatly help me!

### CLI

Usage: `PodcastBulkDownloaderCLI.exe -f FOLDER --url RSS_URL [--overwrite] [-l LAST_N]`

Arguments:

- `-h`, `--help`: shows this help message and exit
- `--url URL`: URL to inspect for MP3s, local path file is also supported
- `-f FOLDER`, `--folder FOLDER`: Destination folder for MP3 files
- `--overwrite`: Will overwrite existing files
- `-l LAST_N`, `--last LAST_N`: Will only download the last N episodes. If N=0, download all the episodes
- `--prefix [NO_PREFIX, DATE, DATE_TIME]`: Optional, choose if you want to prefix with date or date_time
- `-v`, `--version`: Print version

Example:

```
PodcastBulkDownloaderCLI.exe -f "G:\Musique\RadioKawa\Ta Gueule" --url https://feeds.radiokawa.com/podcast_ta-gueule.xml
```

### GUI Version

![PBD_GUI](img/PBD_GUI_v0.8.png)

It's fairly easy to use: fill the RSS field, click Fetch to inspect the feed.
Then fill the Folder field and click download to download the episodes.
Logs will be displayed in the bottom part and will warn you if the software ran into issues.
Check the overwrite checkbox if you want to redownload all the episodes.
Overwriting is solely based on filename, it doesn't do any checks at the moment.
If you want to download only the last N episodes, check the corresponding box and fill the number of episodes wanted.

### How to build _PBD_

#### Build and run tests

We are supporting Python 3.7 and above. Project may work for earlier version tough it is not guaranteed.

To install dependencies, execute this command in the root folder:

```
pip install .
```

To run tests, execute this command in the root folder:

```
pytest -v
```

#### Creating EXE file

Execute `create_exe.bat`, it will create the exe files in a subdirectory called `dist`.

## MacOS

On macOS, you'll probably need to use Homebrew Python instead of the Apple system Python. Here's the commands to run in the terminal from within this project's folder:

```
brew install python@3.12 python-tk@3.12
python3.12 -m venv .venv
source .venv/bin/activate
pip install .
```

You then have two options to run this on MacOS.

1. Run GUI:

```
python -m src.app
```

2. Run CLI:

```
python -m src.bulk_downloader --help
```

Troubleshooting:

- If you get Tk/macOS version crashes, check that `python` is from your virtualenv and not `/usr/bin/python3`.
- If you get SSL LibreSSL warnings, use Homebrew Python as shown above.
