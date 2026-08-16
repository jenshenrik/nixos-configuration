{
	description = "A Flake.";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-26.05";
		noctalia = {
			url = "github:noctalia-dev/noctalia-shell";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, ... }@inputs: 
	let
		lib = nixpkgs.lib;
	in
	{
		nixosConfigurations = {
			nixbox = lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = { inherit inputs; };
				modules = [ ./configuration.nix ];
			};
		};
	};
}
