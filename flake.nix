{
  description = "nix-darwin module to disable Apple Intelligence and reclaim its disk space";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: {
    darwinModules.default = import ./modules/remove-ai.nix;
    darwinModules.remove-ai = self.darwinModules.default;
  };
}
