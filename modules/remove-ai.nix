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

  enabledFeatures = lib.filterAttrs (name: _: cfg.features.${name}) features;
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
  };

  config = lib.mkIf cfg.enable {
    system.defaults.CustomUserPreferences =
      lib.mkMerge (lib.mapAttrsToList (_: f: f.prefs) enabledFeatures);
  };
}
