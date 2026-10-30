{ config, lib, ... }:

let
  cfg = config.programs.removeAppleIntelligence;

  features = {
    siri = {
      description = "Siri and the Siri status menu";
      prefs = {
        "com.apple.assistant.support"."Assistant Enabled" = false;
        "com.apple.Siri" = {
          StatusMenuVisible = false;
          VoiceTriggerUserEnabled = false;
        };
      };
    };
    mail = {
      description = "Mail summaries and smart replies";
      prefs."group.com.apple.mail" = {
        DisableAutomaticMessageSummarization = true;
        PersonalizedSmartReplies = false;
      };
    };
    notificationSummaries = {
      description = "Notification summaries";
      prefs."group.com.apple.usernoted".summarize_previews = false;
    };
    messagesSummaries = {
      description = "Messages summaries";
      prefs."com.apple.MobileSMS".messageSummarizationEnabled = false;
    };
    inlinePredictions = {
      description = "Inline text predictions";
      prefs.NSGlobalDomain.NSAutomaticInlinePredictionEnabled = false;
    };
    spatialPhotos = {
      description = "Spatial Photos";
      prefs."com.apple.spatialphotosrelive".LocallyDisabled = true;
    };
  };

  models = {
    foundation = {
      description = "the Apple Intelligence foundation models";
      assetType = "com.apple.MobileAsset.UAF.FM.GenerativeModels";
    };
    visual = {
      description = "the image and Genmoji models";
      assetType = "com.apple.MobileAsset.UAF.FM.Visual";
    };
    code = {
      description = "the Xcode code completion models";
      assetType = "com.apple.MobileAsset.UAF.FM.CodeLM";
    };
    cleanUp = {
      description = "the Photos Clean Up models";
      assetType = "com.apple.MobileAsset.UAF.Photos.MagicCleanup";
    };
    spatialPhotos = {
      description = "the Spatial Photos models";
      assetType = "com.apple.MobileAsset.UAF.Photos.SpatialPhotosRelive";
    };
  };

  enabledFeatures = lib.filterAttrs (name: _: cfg.features.${name}) features;
  removedModels = lib.filterAttrs (name: _: cfg.models.${name}) models;

  assetDir = assetType: "/System/Library/AssetsV2/${builtins.replaceStrings [ "." ] [ "_" ] assetType}";
in
{
  options.programs.removeAppleIntelligence = {
    enable = lib.mkEnableOption "disabling Apple Intelligence and removing its downloaded models";

    features = lib.mapAttrs (_: f:
      lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Turn off ${f.description}.";
      }) features;

    models = lib.mapAttrs (_: m:
      lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Delete ${m.description} on activation.";
      }) models;
  };

  config = lib.mkIf cfg.enable {
    system.defaults.CustomUserPreferences =
      lib.mkMerge (lib.mapAttrsToList (_: f: f.prefs) enabledFeatures);

    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "removing Apple Intelligence models..." >&2
      ${lib.concatMapStringsSep "\n" (m: ''
        for dir in ${assetDir m.assetType}*; do
          [ -d "$dir" ] && rm -rf "$dir"
        done
      '') (lib.attrValues removedModels)}
    '';
  };
}
