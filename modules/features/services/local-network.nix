{ lib, ... }:

{
  options.localNetwork = {
    serverAddress = lib.mkOption {
      type = lib.types.str;
      description = "LAN address of the server hosting local services.";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "DNS suffix used for local services and devices.";
    };
  };
}
