{ config, lib, ... }:

let
  cfg = config.programs.removeAppleIntelligence;
in
{
  options.programs.removeAppleIntelligence = {
    enable = lib.mkEnableOption "disabling Apple Intelligence and removing its downloaded models";
  };

  config = lib.mkIf cfg.enable { };
}
