# nix-darwin-remove-ai

A [nix-darwin](https://github.com/LnL7/nix-darwin) module that turns off Apple
Intelligence features and deletes the on-device models to get the disk space back.

Inspired by [RemoveMacAI](https://github.com/omlahore/RemoveMacAI), which covers
far more ground (profiles, undo history, a GUI). This module is the declarative subset.

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

## Options

| Option | Effect |
|---|---|
| `features.siri` | Siri and the Siri menu bar item |
| `features.mail` | Mail summaries and smart replies |
| `features.notificationSummaries` | Notification summaries |
| `features.messagesSummaries` | Messages summaries |
| `features.inlinePredictions` | Inline text predictions |
| `features.spatialPhotos` | Spatial Photos |
| `models.foundation` | Foundation models (largest, ~12 GB) |
| `models.visual` | Image Playground and Genmoji models |
| `models.code` | Xcode code completion models |
| `models.cleanUp` | Photos Clean Up models |
| `models.spatialPhotos` | Spatial Photos models |

Features are written through `system.defaults.CustomUserPreferences`. Models are
removed from `/System/Library/AssetsV2` in a post-activation step.

## Limitations

- Restrictions like `allowWritingTools` need a configuration profile and are not covered.
- macOS may download the models again after an update or if a feature is re-enabled.
- Deletion is `rm -rf` on the asset directories, not a call to Apple's asset service.
- Apple silicon, recent macOS only. Only the preference keys and asset paths are
  taken from RemoveMacAI; they may change between releases.
