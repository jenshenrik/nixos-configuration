{
	description = "A Flake.";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-26.05";
#		noctalia = {
#			url = "github:noctalia-dev/noctalia-shell";
#			inputs.nixpkgs.follows = "nixpkgs";
#		};
	};

	outputs = { self, nixpkgs, ... }: 
	let
		lib = nixpkgs.lib;
	in
	{
		nixosConfigurations = {
			nixbox = lib.nixosSystem {
				system = "x86_64-linux";
				modules = [ ./configuration.nix ];
			};
		};
	};
}
