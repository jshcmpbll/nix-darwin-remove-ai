{ config, lib, ... }:

let
  cfg = config.programs.removeAppleIntelligence;

  features = {
    siri = {
      description = "Siri and the Siri status menu";
      restrictions = [ "allowAssistant" ];
      prefs = {
        "com.apple.assistant.support"."Assistant Enabled" = false;
        "com.apple.Siri" = {
          StatusMenuVisible = false;
          VoiceTriggerUserEnabled = false;
        };
      };
    };
    writingTools = {
      description = "Writing Tools";
      restrictions = [ "allowWritingTools" ];
    };
    genmoji = {
      description = "Genmoji";
      restrictions = [ "allowGenmoji" ];
    };
    imagePlayground = {
      description = "Image Playground";
      restrictions = [ "allowImagePlayground" ];
    };
    chatgpt = {
      description = "ChatGPT and other external AI integrations";
      restrictions = [
        "allowExternalIntelligenceIntegrations"
        "allowExternalIntelligenceIntegrationsSignIn"
      ];
    };
    mail = {
      description = "Mail summaries and smart replies";
      restrictions = [ "allowMailSummary" "allowMailSmartReplies" ];
      prefs."group.com.apple.mail" = {
        DisableAutomaticMessageSummarization = true;
        PersonalizedSmartReplies = false;
      };
    };
    safariSummaries = {
      description = "Safari summaries";
      restrictions = [ "allowSafariSummary" ];
    };
    notesSummaries = {
      description = "Notes transcription summaries";
      restrictions = [ "allowNotesTranscriptionSummary" ];
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
  blockedModels = lib.filterAttrs (name: _: cfg.models.${name}) models;

  restrictions = lib.concatMap (f: f.restrictions or [ ]) (lib.attrValues enabledFeatures);

  identifier = "io.github.nix-darwin-remove-ai";

  uuid = name:
    let h = builtins.hashString "sha256" name;
    in lib.concatStringsSep "-" [
      (builtins.substring 0 8 h)
      (builtins.substring 8 4 h)
      "4${builtins.substring 13 3 h}"
      "8${builtins.substring 17 3 h}"
      (builtins.substring 20 12 h)
    ];

  payload = type: suffix: name: {
    PayloadType = type;
    PayloadVersion = 1;
    PayloadIdentifier = "${identifier}.${suffix}";
    PayloadUUID = uuid "${identifier}.${suffix}";
    PayloadDisplayName = name;
  };

  restrictionPayload = payload "com.apple.applicationaccess" "restrictions" "Restrictions"
    // lib.genAttrs restrictions (_: false);

  blockPayload = payload "com.apple.ManagedClient.preferences" "downloads" "Blocked model downloads"
    // {
      PayloadContent."com.apple.MobileAsset".Forced = [{
        mcx_preference_settings = lib.mapAttrs' (_: m:
          lib.nameValuePair "DownloadServerBaseURLOverride-${m.assetType}" cfg.blockedUrl
        ) blockedModels;
      }];
    };

  profile = {
    PayloadType = "Configuration";
    PayloadVersion = 1;
    PayloadIdentifier = identifier;
    PayloadUUID = uuid identifier;
    PayloadDisplayName = "Remove Apple Intelligence";
    PayloadOrganization = "nix-darwin-remove-ai";
    PayloadScope = "System";
    PayloadRemovalDisallowed = false;
    PayloadContent =
      lib.optional (restrictions != [ ]) restrictionPayload
      ++ lib.optional (blockedModels != { }) blockPayload;
  };

  profilePath = "remove-ai/RemoveAppleIntelligence.mobileconfig";
in
{
  options.programs.removeAppleIntelligence = {
    enable = lib.mkEnableOption "disabling Apple Intelligence and blocking its model downloads";

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
        description = "Block macOS from downloading ${m.description}.";
      }) models;

    blockedUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://127.0.0.1:9/remove-ai-blocked/";
      description = "Address the asset service is pointed at for blocked models.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.CustomUserPreferences =
      lib.mkMerge (lib.mapAttrsToList (_: f: f.prefs or { }) enabledFeatures);

    environment.etc.${profilePath}.text = lib.generators.toPlist { escape = true; } profile;

    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "Apple Intelligence restrictions need a profile: open /etc/${profilePath}" >&2
      echo "then approve it in System Settings > General > Device Management." >&2
    '';
  };
}
