## Installing

Requires [Twitch Emotes v2](https://www.curseforge.com/wow/addons/twitch-emotes-v2)

Manual instructions:

1. Go to https://github.com/galacticclam/TwitchEmotes_Coomer/releases/latest
1. Extract `TwitchEmotes_Coomer` to your Addons directory.
    * If you're playing retail, it's likely in `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\Addons`
    * Classic is  `C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\Addons`
1. Reload/restart WoW

WowUp:

1. Install https://wowup.io/
1. In WowUp, install from URL with the URL `https://github.com/galacticclam/TwitchEmotes_Coomer`

## Development

### Required programs

* bash, you can get it from [Git](https://git-scm.com/downloads)
* [ImageMagick](https://imagemagick.org/script/download.php), make sure it's on your [$PATH](https://www.java.com/en/download/help/path.html). The installer will do this for you if "Add application directory to your system path" is checked.
* [GitHub CLI](https://cli.github.com/). Log in with `gh auth login`. Only needed for publishing new versions.

Alternatively, install [winget](https://winget.run) and then run this:

```sh
winget install -e --id Git.Git
winget install -e --id GitHub.cli
winget install -e --id ImageMagick.ImageMagick
```

### Testing your changes

1. Run `./build.sh`. A zip file will be created in `/dist`
1. Unzip this file in your Addons directory

### Publishing a new version of this addon

You need to be a contributor on the repo and a member of the [CurseForge project](https://legacy.curseforge.com/wow/addons/coomer-illidan-twitch-emotes) for this to work.

1. Create an empty `.env` file in the repository root.
1. Create a CurseForge API token and enter it in this file: `CURSEFORGE_API_TOKEN=...`
1. Update the version number in `TwitchEmotes_Coomer-Mainline.toc` and `TwitchEmotes_Coomer-Classic.toc`
1. Push the updated version numbers
1. Run `./release.sh release`, or `./release.sh` for testing

### Importing Discord emotes

1. Send an emote in a Discord channel with nothing else, so you get a big version of the emote.
1. Right click the emote and hit "Copy link"
1. Run `./import.sh url emote_name [size]`
    * For example, `./import.sh 'https://cdn.discordapp.com/emojis/1174855519731716208.webp?size=96&quality=lossless' abigail`
    * Size must be a power of 2, otherwise you'll see green squares for your emote
    * The default size is 32. Only go higher for real-life pictures
