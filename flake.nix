{
	description = "A Flake.";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-25.11";
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
