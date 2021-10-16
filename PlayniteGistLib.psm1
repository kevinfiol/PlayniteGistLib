function OnApplicationStarted()
{
}

function OnApplicationStopped()
{
}

function OnLibraryUpdated()
{
    SyncLibrary
}

function OnGameStarting()
{
    param(
        $game
    )
}

function OnGameStarted()
{
    param(
        $game
    )
}

function OnGameStopped()
{
    param(
        $game,
        $elapsedSeconds
    )
}

function OnGameInstalled()
{
    param(
        $game
    )
}

function OnGameUninstalled()
{
    param(
        $game
    )
}

function OnGameSelected()
{
    param(
        $gameSelectionEventArgs
    )
}

function SyncLibrary()
{
    param($getMainMenuItemsArgs)
    $configPath = Join-Path -Path $CurrentExtensionInstallPath -ChildPath "gist_config.json"
    $isConfigPathValid = Test-Path -Path $configPath

    if ($isConfigPathValid) {
        try {
            $config = (Get-Content $configPath -Raw) | ConvertFrom-Json

            if ($config.access_token) {
                $token = $config.access_token

                $client = [System.Net.Http.HttpClient]::new()
                $request = [System.Net.Http.HttpRequestMessage]::new()

                $request.Headers.Add("User-Agent", "Playnite-App")
                $request.Headers.Add("Accept", "application/vnd.github.v3+json")
                $request.Headers.Add("Authorization", "token $token")

                if ($config.gist_id) {
                    $__logger.Info("PlayniteGistLib: Gist already exists!")
                    $gist_id = $config.gist_id

                    $request.Method = "GET"
                    $request.RequestUri = "https://api.github.com/gists/${gist_id}"

                    $clientResultMessage = $client.SendAsync($request).
                        GetAwaiter().
                        GetResult()

                    $result = $clientResultMessage.
                        Content.
                        ReadAsStringAsync().
                        GetAwaiter().
                        GetResult()

                    $resultData = $result | ConvertFrom-Json
                    if ($resultData.files) {
                        $files = $resultData.files
                        if ($files."library.json") {
                            $content = $files."library.json".content | ConvertFrom-Json
                            $count = $content.count

                            # create payload
                            $rawGames = $PlayniteApi.Database.Games
                            [System.Collections.ArrayList]$games = @()

                            $builtInExtensions = [Playnite.SDK.BuiltinExtensions]::new()
                            $libEnums = [Playnite.SDK.BuiltinExtension]::new()

                            foreach ($game in $rawGames) {
                                $source = switch([Playnite.SDK.BuiltinExtensions]::GetExtensionFromId($game.PluginId)) {
                                    [Playnite.SDK.BuiltinExtension]::AmazonGamesLibrary { "Amazon" }
                                    [Playnite.SDK.BuiltinExtension]::BattleNetLibrary { "Battle.net" }
                                    [Playnite.SDK.BuiltinExtension]::BethesdaLibrary { "Bethesda" }
                                    [Playnite.SDK.BuiltinExtension]::SteamLibrary { "Steam" }
                                    [Playnite.SDK.BuiltinExtension]::EpicLibrary { "Epic" }
                                    [Playnite.SDK.BuiltinExtension]::OriginLibrary { "Origin" }
                                    [Playnite.SDK.BuiltinExtension]::UplayLibrary { "Uplay" }
                                    [Playnite.SDK.BuiltinExtension]::GogLibrary { "GOG" }
                                    [Playnite.SDK.BuiltinExtension]::ItchioLibrary { "itch.io" }
                                    [Playnite.SDK.BuiltinExtension]::HumbleLibrary { "Humble" }
                                    [Playnite.SDK.BuiltinExtension]::PSNLibrary { "PSN" }
                                    [Playnite.SDK.BuiltinExtension]::TwitchLibrary { "Twitch" }
                                    [Playnite.SDK.BuiltinExtension]::XboxLibrary { "Xbox" }
                                    default { $game.Source.Name }
                                }

                                if ($source) {
                                    $urlPattern = switch($source) {
                                        "Bethesda" { "https://bethesda.net/en/game/" }
                                        "Steam" { "https://store.steampowered.com/app/" }
                                        "Epic" { "https://www.epicgames.com/store/" }
                                        "Origin" { "https://www.origin.com/store/" }
                                        "GOG" { "https://www.gog.com/game/" }
                                        "itch.io" { "itch.io" }
                                        "Humble" { "https://www.humblebundle.com/store/" }
                                        default { $null }
                                    }

                                    $url = $null
                                    if ($source -and $urlPattern -and $game.Links) {
                                        if ($game.Links.Count -gt 0) {
                                            $link = $game.Links | Where-Object { $_.Url -match $urlPattern }
                                            if ($link) {
                                                $url = $link.Url
                                            }
                                        }
                                    }

                                    $gameObj = @{
                                        "name" = $game.Name
                                        "store" = $source
                                    }

                                    if ($url) {
                                        $gameObj["url"] = $url
                                    }

                                    $games.Add($gameObj)
                                }
                            }

                            $games = $games | Sort-Object { $_.name }

                            $payload = @{
                                "count" = $games.Count
                                "games" = $games
                            }

                            # check if we need to update gist
                            # i just check if the game count has changed
                            if ($payload["count"] -ne $count) {
                                $json = $payload | ConvertTo-Json -Compress

                                $dateTime = Get-Date
                                $body = @{
                                    "description" = "PlayniteGistLib. Updated: ${dateTime}"
                                    "files" = @{
                                        "library.json" = @{
                                            "filename" = "library.json"
                                            "content" = $json
                                        }
                                    }
                                } | ConvertTo-Json -Compress

                                $patchRequest = [System.Net.Http.HttpRequestMessage]::new()

                                $patchRequest.Headers.Add("User-Agent", "Playnite-App")
                                $patchRequest.Headers.Add("Accept", "application/vnd.github.v3+json")
                                $patchRequest.Headers.Add("Authorization", "token $token")

                                $patchRequest.Content = [System.Net.Http.StringContent]::new(
                                    $body,
                                    [System.Text.Encoding]::UTF8,
                                    "application/json"
                                )

                                $patchRequest.Method = "PATCH"
                                $patchRequest.RequestUri = "https://api.github.com/gists/${gist_id}"

                                $clientResultMessage = $client.SendAsync($patchRequest).
                                    GetAwaiter().
                                    GetResult()

                                $result = $clientResultMessage.
                                    Content.
                                    ReadAsStringAsync().
                                    GetAwaiter().
                                    GetResult()

                                $__logger.Info("PlayniteGistLib: Updated Gist!")
                            }
                            else {
                                $__logger.Info("PlayniteGistLib: Gist is already up to date")
                            }
                        }
                        else {
                            throw "PlayniteGistLib: Gist does not contain library.json"
                        }
                    }
                    else {
                        throw "PlayniteGistLib: gist_id is invalid; Gist does not exist. Remove the gist_id from your gist_config.json to generate a new Gist."
                    }
                }
                else {
                    $rawGames = $PlayniteApi.Database.Games
                    [System.Collections.ArrayList]$games = @()

                    foreach ($game in $rawGames) {
                        $source = switch([Playnite.SDK.BuiltinExtensions]::GetExtensionFromId($game.PluginId)) {
                            [Playnite.SDK.BuiltinExtension]::AmazonGamesLibrary { "Amazon" }
                            [Playnite.SDK.BuiltinExtension]::BattleNetLibrary { "Battle.net" }
                            [Playnite.SDK.BuiltinExtension]::BethesdaLibrary { "Bethesda" }
                            [Playnite.SDK.BuiltinExtension]::SteamLibrary { "Steam" }
                            [Playnite.SDK.BuiltinExtension]::EpicLibrary { "Epic" }
                            [Playnite.SDK.BuiltinExtension]::OriginLibrary { "Origin" }
                            [Playnite.SDK.BuiltinExtension]::UplayLibrary { "Uplay" }
                            [Playnite.SDK.BuiltinExtension]::GogLibrary { "GOG" }
                            [Playnite.SDK.BuiltinExtension]::ItchioLibrary { "itch.io" }
                            [Playnite.SDK.BuiltinExtension]::HumbleLibrary { "Humble" }
                            [Playnite.SDK.BuiltinExtension]::PSNLibrary { "PSN" }
                            [Playnite.SDK.BuiltinExtension]::TwitchLibrary { "Twitch" }
                            [Playnite.SDK.BuiltinExtension]::XboxLibrary { "Xbox" }
                            default { $game.Source.Name }
                        }

                        if ($source) {
                            $urlPattern = switch($source) {
                                "Bethesda" { "https://bethesda.net/en/game/" }
                                "Steam" { "https://store.steampowered.com/app/" }
                                "Epic" { "https://www.epicgames.com/store/" }
                                "Origin" { "https://www.origin.com/store/" }
                                "GOG" { "https://www.gog.com/game/" }
                                "itch.io" { "itch.io" }
                                "Humble" { "https://www.humblebundle.com/store/" }
                                default { $null }
                            }

                            $url = $null
                            if ($source -and $urlPattern -and $game.Links) {
                                if ($game.Links.Count -gt 0) {
                                    $link = $game.Links | Where-Object { $_.Url -match $urlPattern }
                                    if ($link) {
                                        $url = $link.Url
                                    }
                                }
                            }

                            $gameObj = @{
                                "name" = $game.Name
                                "store" = $source
                            }

                            if ($url) {
                                $gameObj["url"] = $url
                            }

                            $games.Add($gameObj)
                        }
                    }

                    $games = $games | Sort-Object { $_.name }

                    $payload = @{
                        "count" = $games.Count
                        "games" = $games
                    }

                    $json = $payload | ConvertTo-Json -Compress

                    $dateTime = Get-Date
                    $body = @{
                        "description" = "PlayniteGistLib. Updated: ${dateTime}"
                        "public" = $True
                        "files" = @{
                            "library.json" = @{
                                "filename" = "library.json"
                                "content" = $json
                            }
                        }
                    } | ConvertTo-Json -Compress

                    $request.Content = [System.Net.Http.StringContent]::new(
                        $body,
                        [System.Text.Encoding]::UTF8,
                        "application/json"
                    )

                    $request.Method = "POST"
                    $request.RequestUri = "https://api.github.com/gists"

                    $clientResultMessage = $client.SendAsync($request).
                        GetAwaiter().
                        GetResult()

                    $result = $clientResultMessage.
                        Content.
                        ReadAsStringAsync().
                        GetAwaiter().
                        GetResult()

                    $resultData = $result | ConvertFrom-Json

                    if ($resultData.id) {
                        $configJson = @{
                            "access_token" = $config.access_token
                            "gist_id" = $resultData.id
                        } | ConvertTo-Json

                        $configJson | Out-File $configPath
                    }
                    else {
                        # not able to create
                        throw $result
                    }
                }
            } else {
                $errorMsg = "PlayniteGistLib: ${configPath} does not contain 'access_token'. Please go to https://github.com/settings/tokens/new to create a new 'access_token' with the 'gist' scope checked, and copy it to your 'gist_config.json'."
                $PlayniteApi.Dialogs.ShowMessage($errorMsg)
                throw $errorMsg
            }
        }
        catch {
            $__logger.Info($_)
        }
    }
    else {
        $msg = "PlayniteGistLib: gist_config.json was not found. Please make sure gist_config.json exists in the same directory as PlayniteGistLib.ps1"
        $PlayniteApi.Dialogs.ShowMessage($msg)
        $__logger.Info("PlayniteGistLib: gist_config.json was not found. Please make sure gist_config.json exists in the same directory as PlayniteGistLib.ps1")
    }
}

function GetMainMenuItems()
{
    param($getMainMenuItemsArgs)
    $menuItem = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem.Description = "Sync Library with Gist"
    $menuItem.FunctionName = "SyncLibrary"
    $menuItem.MenuSection = "@"
    return $menuItem
}
