# nix-darwin-remove-ai

A [nix-darwin](https://github.com/LnL7/nix-darwin) module that turns off Apple
Intelligence features and stops macOS from downloading the on-device models.

Inspired by [RemoveMacAI](https://github.com/omlahore/RemoveMacAI), which covers
far more ground (undo history, a GUI, model deletion). This module is the declarative subset.

## Usage

```nix
{
  inputs.remove-ai.url = "github:<you>/nix-darwin-remove-ai";

  outputs = { darwin, remove-ai, ... }: {
    darwinConfigurations.mac = darwin.lib.darwinSystem {
      modules = [
        remove-ai.darwinModules.default
        { programs.removeAppleIntelligence.enable = true; }
      ];
    };
  };
}
```

Everything is on by default. Opt out of anything you use:

```nix
programs.removeAppleIntelligence = {
  enable = true;
  features.siri = false;
  models.code = false;
};
```

After the first switch, open the generated profile and approve it in
System Settings > General > Device Management:

```sh
open /etc/remove-ai/RemoveAppleIntelligence.mobileconfig
```

## Options

`features.<name>` turns a feature off. `models.<name>` blocks that model set from downloading.

| Feature | Mechanism |
|---|---|
| `siri`, `mail` | profile restriction and preference |
| `writingTools`, `genmoji`, `imagePlayground`, `chatgpt`, `safariSummaries`, `notesSummaries` | profile restriction |
| `notificationSummaries`, `messagesSummaries`, `inlinePredictions`, `spatialPhotos` | preference |

| Model | Size set |
|---|---|
| `foundation` | foundation models (largest, ~12 GB) |
| `visual` | Image Playground and Genmoji |
| `code` | Xcode code completion |
| `cleanUp` | Photos Clean Up |
| `spatialPhotos` | Spatial Photos |

Preferences go through `system.defaults.CustomUserPreferences`. Restrictions and
download blocks go in the profile, which nix-darwin cannot install itself.

## Limitations

- **Models are not deleted.** SIP blocks `rm` on `/System/Library/AssetsV2`, even as root.
  RemoveMacAI deletes through Apple's private asset service, which this module does not call.
- The profile needs manual approval.
- Blocking uses an unofficial key (`DownloadServerBaseURLOverride-*`) from pared and RemoveMacAI.
- Apple silicon, recent macOS only. Keys and asset names may change between releases.
