# nix-darwin-remove-ai

A [nix-darwin](https://github.com/LnL7/nix-darwin) module that turns off Apple
Intelligence features, deletes the on-device models and stops macOS downloading them again.

Inspired by [RemoveMacAI](https://github.com/omlahore/RemoveMacAI), which covers
far more ground (undo history, a GUI, privacy and storage tweaks). This module is the
declarative subset.

## Usage

```nix
{
  inputs.remove-ai.url = "github:jshcmpbll/nix-darwin-remove-ai";

  outputs = { darwin, remove-ai, ... }: {
    darwinConfigurations.mac = darwin.lib.darwinSystem {
      modules = [
        remove-ai.darwinModules.default
        {
          system.primaryUser = "you";
          programs.removeAppleIntelligence.enable = true;
        }
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

## The profile

Restrictions, forced preferences and the download block go in a configuration profile,
which nix-darwin cannot install itself. The module writes it to
`/etc/remove-ai/RemoveAppleIntelligence.mobileconfig` and, while it is not installed,
opens it on each switch. Approve it in System Settings > General > Device Management.

Preferences are forced through the profile because `defaults write` cannot reach
protected domains such as Messages and Mail. Until the profile is approved, macOS can
download the models again.

## Options

| Option | Default | Effect |
|---|---|---|
| `features.<name>` | `true` | Turn that feature off |
| `models.<name>` | `true` | Delete that model set and block it from downloading |
| `deleteModels` | `true` | Delete the selected models on activation |
| `openProfile` | `true` | Open the profile for approval until it is installed |
| `blockedUrl` | closed local port | Where blocked model downloads are pointed |

`deleteModels` and `openProfile` need `system.primaryUser`.

| Feature | Mechanism |
|---|---|
| `siri`, `mail` | restriction and forced preference |
| `writingTools`, `genmoji`, `imagePlayground`, `chatgpt`, `safariSummaries`, `notesSummaries` | restriction |
| `notificationSummaries`, `messagesSummaries`, `inlinePredictions`, `spatialPhotos` | forced preference |

| Model | Contents |
|---|---|
| `foundation` | Apple Intelligence foundation models (the largest set) |
| `visual` | Image Playground and Genmoji |
| `code` | Xcode code completion |
| `cleanUp` | Photos Clean Up |
| `spatialPhotos` | Spatial Photos |

Models are deleted through Apple's asset service, using the technique mapped by
[pared](https://github.com/4evy/pared).

## Undoing

Set `enable = false`, switch, then remove the profile in System Settings. Models are
not restored; macOS downloads them again once the block is gone and a feature wants them.

## Limitations

- Deletion calls Apple's private asset service through a small helper, so a macOS update can break it.
- macOS frees the files on its own schedule, so Storage settings may keep counting them for a while.
- Models and features are independent: `features.siri = false` does not keep the foundation models.
- The profile needs manual approval, and a changed profile is not reopened once one is installed.
- Blocking uses an unofficial key (`DownloadServerBaseURLOverride-*`) from pared and RemoveMacAI.
- Apple silicon, recent macOS only. Keys and asset names may change between releases.
