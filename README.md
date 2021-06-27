# Playnite Library Gist Sync

A PowerShell script for [Playnite](https://github.com/JosefNemec/Playnite/) that syncs your latest library data with Github Gists.

## Why?

Playnite is the best digital game launcher I've used. It seamlessly consolidates your entire game library for you using very reliable storefront plugins for Steam, Epic Games Store, itch.io, GOG, etc. However, it doesn't have the quickest start-up time, and often I find myself wanting to search through my library without having to launch Playnite -- or, sometimes I'm away from my gaming PC. Github Gists are ubiquitous, flexible, and easy to use for storing bits of code or data. With my Playnite library exported to a Gist as JSON, I'm able to use that data to create a searchable library page.

[Example Library Page](https://kevinfiol.com/PlayniteGistLib/) ([Source](https://github.com/kevinfiol/PlayniteGistLib/blob/master/index.html))

[Example Gist](https://gist.github.com/kevinfiol/69e5d057ff7e755bb32ba9e834a058e7)

## Caveats

Github Gists have a limit of ~1MB per Gist file. I've tested on a library of `2703` games and found that the file size was under 250KB. If your digital game library is much more massive than this, syncing with Github Gists may not be the best option.

## Usage

1. Download or clone this repository to your Playnite extensions directory, e.g., `$PLAYNITE_DIR/Extensions/PlayniteGistLib/`.

2. Create a Github account if you don't already have one.

3. Create a Github Access Token [here] with the `gist` scope checked. Copy your token and add it to `$PLAYNITE_DIR/Extensions/PlayniteGistLib/gist_config.json` so that your JSON looks like this:

```json
{
    "access_token": "<YOUR_ACCESS_TOKEN_HERE>"
}
```

4. Start/Restart Playnite, and select `Update Game Library > Update All` (or just hit F5). Playnite will update your library, and create a Gist with your library data. Check `https://gist.github.com/<YOUR_GITHUB_USERNAME>` to see your newly created Gist.

If for whatever reason you've run into an error, check the Playnite logs at `$PLAYNITE_DIR/playnite.log` to see what went wrong. Use a tool like [jsonlint.org](https://jsonlint.com/) to make sure your `gist_config.json` is valid JSON.
