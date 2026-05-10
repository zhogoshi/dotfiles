{
  description = "Nix Build for Millennium";

  inputs = {
    nixpkgs.url = "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz";

    millennium-src.url = "https://github.com/SteamClientHomebrew/Millennium/archive/defffd7b6f0cf4d5e53f5a892819966801475704.tar.gz";
    millennium-src.flake = false;

    zlib-src.url = "https://github.com/zlib-ng/zlib-ng/archive/2.2.5.tar.gz";
    luajit-src.url = "https://github.com/SteamClientHomebrew/LuaJIT/archive/v2.1.tar.gz";
    luajson-src.url = "https://github.com/SteamClientHomebrew/LuaJSON/archive/0c1fabf07c42f3907287d1e4f729e0620c1fe6fd.tar.gz";
    minhook-src.url = "https://github.com/TsudaKageyu/minhook/archive/v1.3.4.tar.gz";
    mini-src.url = "https://github.com/metayeti/mINI/archive/0.9.18.tar.gz";
    websocketpp-src.url = "https://github.com/zaphoyd/websocketpp/archive/0.8.2.tar.gz";
    fmt-src.url = "https://github.com/fmtlib/fmt/archive/12.0.0.tar.gz";
    json-src.url = "https://github.com/nlohmann/json/archive/v3.12.0.tar.gz";
    libgit2-src.url = "https://github.com/libgit2/libgit2/archive/v1.9.1.tar.gz";
    minizip-src.url = "https://github.com/zlib-ng/minizip-ng/archive/4.0.10.tar.gz";
    curl-src.url = "https://github.com/curl/curl/archive/curl-8_13_0.tar.gz";
    incbin-src.url = "https://github.com/graphitemaster/incbin/archive/22061f51fe9f2f35f061f85c2b217b55dd75310d.tar.gz";
    asio-src.url = "https://github.com/chriskohlhoff/asio/archive/asio-1-30-0.tar.gz";

    abseil-src.url = "https://github.com/abseil/abseil-cpp/archive/20240722.0.tar.gz";
    re2-src.url = "https://github.com/google/re2/archive/2025-11-05.tar.gz";

    zlib-src.flake = false;
    luajit-src.flake = false;
    luajson-src.flake = false;
    minhook-src.flake = false;
    mini-src.flake = false;
    websocketpp-src.flake = false;
    fmt-src.flake = false;
    json-src.flake = false;
    libgit2-src.flake = false;
    minizip-src.flake = false;
    curl-src.flake = false;
    incbin-src.flake = false;
    asio-src.flake = false;

    abseil-src.flake = false;
    re2-src.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      millennium-src,
      ...
    }@inputs:
    {
      packages.x86_64-linux =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };

          millennium-deps = {
            inherit inputs;
            inherit (packages)
              millennium-shims
              millennium-assets
              millennium-frontend
              ;
          };

          packages = {
            default             = packages.millennium-steam;
            millennium-assets   = pkgs.callPackage ./assets.nix         { inherit millennium-src; };
            millennium-frontend = pkgs.callPackage ./frontend.nix       { inherit millennium-src; };
            millennium-shims    = pkgs.callPackage ./shims.nix          { inherit millennium-src; };
            millennium-32       = pkgs.callPackage ./millennium-32.nix  ( millennium-deps );
            millennium-64       = pkgs.callPackage ./millennium-64.nix  ( millennium-deps );
            millennium          = pkgs.callPackage ./millennium.nix     ( millennium-deps // { inherit (packages) millennium-32 millennium-64; } );
            millennium-steam    = pkgs.callPackage ./steam.nix          { inherit (packages) millennium millennium-shims millennium-assets; };
          };
        in
        packages;

      overlays.default = final: prev: {
        inherit (self.packages.${prev.stdenv.hostPlatform.system}) millennium-steam;
      };
    };
}
