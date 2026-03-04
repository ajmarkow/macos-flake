{
  description = "AJ Markow's nix-darwin system configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      nixpkgs-unstable,
      nix-darwin,
      home-manager,
      nixvim,
      nur,
      ...
    }:
    let
      host = "AJ-MARKOW-WORK-MACBOOK-PRO";
      system = "aarch64-darwin";

      # Your existing nix-darwin module (UNCHANGED)
      configuration =
        {
          pkgs,
          pkgs-unstable,
          lib,
          flake,
          ...
        }:
        {
          environment.systemPackages = with pkgs; [
            commitizen
            dasel
            devenv
            direnv
            eza
            figlet
            fira-code
            fira-mono
            firefox
            fzf
            fzf
            gawk
            gh
            gh
            git
            git-filter-repo
            gnupg
            jankyborders
            jq
            kitty
            lego
            mas
            ncdu
            neofetch
            neovim
            nh
            nil
            nixfmt
            obsidian
            pkgs-unstable.lazyssh
            pkgs-unstable.s-search
            pnpm
            postman
            python3Packages.pygments
            ripgrep
            speedtest-cli
            steampipe
            stripe-cli
            tz
            uv
            vscode
            wget
            zellij
            yazi
            zoxide
          ];
          homebrew = {
            enable = true;
            onActivation.cleanup = "uninstall";
            brews = [
              "beszel-agent"
              "organize-tool"
            ];
            masApps = {
              AdGuardHome = 1543143740;
              Bitwarden = 1352778147;
              Itsyhome = 6758070650;
              "KDE Connect" = 1580245991;
              "Keeper Password Manager" = 414781829;
              Kindle = 302584613;
              LanScan = 472226235;
              Slack = 803453959;
              ViewCam = 1608020100;
              Xcode = 497799835;
              "Raycast Companion" = 6738274497;
            };
          };

          environment.shells = [ "${pkgs.zsh}/bin/zsh" ];
          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable support for GUI applications
          programs.zsh.enable = true;
          # Configure system-wide settings
          system.defaults = {
            NSGlobalDomain = {
              AppleShowAllExtensions = true;
              NSDocumentSaveNewDocumentsToCloud = false;
            };
            dock = {
              autohide = true;
              show-recents = false;
            };
            finder = {
              AppleShowAllExtensions = true;
              AppleShowAllFiles = true;
              ShowPathbar = true;
              ShowStatusBar = false;
              NewWindowTarget = "Documents";
              _FXSortFoldersFirst = true;

            };
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Set primary user for system defaults
          system.primaryUser = "ajmarkow";

          # DNS servers and network services to configure (from networksetup -listallnetworkservices)
          networking = {
            dns = [
              "2a10:50c0:c000::1:b32c:4ec1"
              "2a10:50c0:c000::b32c:4ec1"
            ];
            knownNetworkServices = [
              "AX88179A"
              "USB 10/100/1000 LAN"
              "USB 10/100/1G/2.5G LAN"
              "Thunderbolt Bridge"
              "Wi-Fi"
              "iPhone USB"
              "Twingate"
              "UDM Pro"
            ];
          };

          # Disable startup chime
          system.startup.chime = false;

          # Allow unfree packages system-wide
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ nur.overlays.default ];

          # Reload skhd config after rebuild (runs during darwin-rebuild switch activation)
          # Note: nix-darwin only runs hardcoded activation script names; use postActivation
          # with lib.mkAfter to append to the script that actually executes.
          system.activationScripts.postActivation.text = lib.mkAfter ''
            echo "Reloading skhd config"
            su ajmarkow -c '${pkgs.skhd}/bin/skhd -r'
          '';
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # flake-utils.eachDefaultSystem replacement
      systems = [ system ];

      # Non-perSystem outputs go here
      flake = {
        darwinConfigurations.${host} = nix-darwin.lib.darwinSystem {
          inherit system;

          specialArgs = {
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };

          modules = [
            configuration

            home-manager.darwinModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [ nixvim.homeModules.nixvim ];

              home-manager.extraSpecialArgs = {
                inherit nur;
                pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
              };

              home-manager.users.ajmarkow =
                {
                  config,
                  pkgs,
                  lib,
                  pkgs-unstable,
                  ...
                }:
                {
                  # Set home directory explicitly for nix-darwin
                  home.homeDirectory = lib.mkForce "/Users/ajmarkow";
                  home.username = lib.mkForce "ajmarkow";
                  # Suppress home-manager news
                  news.display = "silent";

                  # Set Home Manager release compatibility
                  home.stateVersion = "25.05";

                  # Install user packages
                  home.packages = [ ];

                  # Configure Firefox with Nordic theme and extensions
                  home.file."firefox-nordic-theme" = {
                    target = "Library/Application Support/Firefox/Profiles/default/chrome/firefox-nordic-theme";
                    source = (
                      builtins.fetchTarball {
                        url = "https://github.com/EliverLara/firefox-nordic-theme/archive/refs/heads/master.tar.gz";
                        sha256 = "0pgxrjqqsabnhsq21cgnzdwyfwc4ah06qk0igzwwsf56f2sgs4yv";
                      }
                    );
                  };

                  programs.firefox = {
                    enable = true;
                    profiles.default = {
                      name = "Default";
                      isDefault = true;
                      userChrome = ''
                        /* Nordic Theme for Firefox */
                        @import "firefox-nordic-theme/userChrome.css";
                        @import "firefox-nordic-theme/theme/colors/dark.css";
                      '';
                      settings = {
                        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                        "ui.systemUsesDarkTheme" = true;
                        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
                        "browser.theme.content-theme" = 0;
                        "browser.theme.toolbar-theme" = 0;
                        "browser.startup.homepage" = "https://www.google.com";
                        "browser.startup.page" = 1;
                        "browser.urlbar.placeholderName" = "Google";
                        "browser.urlbar.quicksuggest.enabled" = false;
                        "widget.macos.native-context-menus" = true;
                        "widget.macos.respect-system-appearance" = true;
                      };
                      extraConfig = ''
                        user_pref("extensions.autoDisableScopes", 0);
                        user_pref("extensions.enabledScopes", 15);
                      '';
                    };
                    policies = {
                      Extensions = {
                        Install = [
                          "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi"
                          "https://addons.mozilla.org/firefox/downloads/latest/raindropio/latest.xpi"
                          "https://addons.mozilla.org/firefox/downloads/latest/tabliss/latest.xpi"
                        ];
                        Locked = [
                          "446900e4-71c2-419f-a6a7-df9c091e268b"
                          "uBlock0@raymondhill.net"
                          "{d7742d87-e61d-4b78-b8a1-b469842139fa}"
                          "bb52ecc6-b340-49f6-9342-9740e0f00ec1"
                          "087cab65-8b44-4606-a66d-15598ed2bc5a"
                        ];
                      };
                      ExtensionSettings = {
                        "446900e4-71c2-419f-a6a7-df9c091e268b".default_area = "navbar";
                        "uBlock0@raymondhill.net".default_area = "navbar";
                        "{d7742d87-e61d-4b78-b8a1-b469842139fa}".default_area = "navbar";
                        "bb52ecc6-b340-49f6-9342-9740e0f00ec1".default_area = "navbar";
                        "087cab65-8b44-4606-a66d-15598ed2bc5a".default_area = "navbar";
                      };
                    };
                  };
                  programs.starship = {
                    enable = true;
                    enableBashIntegration = true;
                    enableZshIntegration = true;
                    settings = {
                      add_newline = true;
                      character = {
                        success_symbol = "[---➔](bold green)";
                        error_symbol = "[ ⍉ ](bold red) ";
                      };
                      line_break = {
                        disabled = true;
                      };
                      package = {
                        disabled = true;
                      };
                      cmd_duration = {
                        min_time = 10000;
                        format = "took [$duration]($style) ";
                      };
                      battery = {
                        charging_symbol = "⚡️ ";
                        discharging_symbol = "💀 ";
                        display = [
                          {
                            threshold = 20;
                            style = "bold red";
                          }
                        ];
                      };
                      status = {
                        style = "bg:red";
                        symbol = "💣 ";
                        format = "[\\[$symbol$status\\]]($style) ";
                        disabled = false;
                      };
                    };
                  };

                  # Configure VS Code
                  programs.vscode = {
                    enable = true;
                    profiles.default = {
                      extensions =
                        with pkgs.vscode-extensions;
                        [
                          jnoortheen.nix-ide
                          eamodio.gitlens
                        ]
                        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                          {
                            name = "theme-panda";
                            publisher = "tinkertrain";
                            version = "1.4.0";
                            sha256 = "sha256-3iCKgHVjD2qnVsLtSa7NVHBHnLl2jdHKpuQewO9TZuk=";
                          }
                          {
                            name = "cobaltNext";
                            publisher = "dline";
                            version = "0.4.5";
                            sha256 = "sha256-EaekJNtdvrW8W5l3NL03UF2bNTnwNrmE1aZlmNaHP1w=";
                          }
                          {
                            name = "material-icon-theme";
                            publisher = "PKief";
                            version = "5.25.0";
                            sha256 = "sha256-jkTFfyeFJ4ygsKJj41tWDJ91XitSs2onW4ni3rMNJE8=";
                          }
                          {
                            name = "vscode-favorites";
                            publisher = "howardzuo";
                            version = "1.11.0";
                            sha256 = "sha256-DkUwr5fzvX3kHarFKEorZnOoF9w2XnablXQes9ZQc3U=";
                          }
                        ];
                      # userSettings omitted - managed via writable symlink below to avoid conflict
                    };
                  };

                  # Ensure VS Code settings.json is writable (symlink to file outside Nix store)
                  home.file."Library/Application Support/Code/User/settings.json".source = lib.mkForce (
                    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/vscode-manual-settings.json"
                  );

                  # Render Nix-managed VS Code settings to the writable file on each switch
                  home.activation.renderVSCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      mkdir -p "${config.home.homeDirectory}/.config"
                      cat > "${config.home.homeDirectory}/.config/vscode-manual-settings.json" <<'JSON'
                    ${builtins.toJSON {
                      "workbench.activityBar.location" = "bottom";
                      "workbench.statusBar.visible" = false;
                      "workbench.colorTheme" = "Cobalt Next Minimal";
                      "workbench.iconTheme" = "material-icon-theme";
                      "editor.fontFamily" = "'Fira Code', 'SF Mono', 'Monaco', monospace";
                      "editor.fontLigatures" = true;
                      "editor.formatOnSave" = true;
                      "editor.minimap.enabled" = false;
                      "window.titleBarStyle" = "native";
                      "nix.enableLanguageServer" = true;
                      "nix.serverPath" = "${pkgs.nil}/bin/nil";
                      "nix.serverSettings" = {
                        "nil" = {
                          "formatting" = {
                            "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
                          };
                        };
                      };
                    }}
                    JSON
                  '';

                  # Configure Zsh
                  programs.zsh = {
                    enable = true;
                    enableCompletion = true;
                    autosuggestion.enable = true;
                    syntaxHighlighting.enable = true;
                    # Strip /usr/local zsh site-functions so compinit doesn't error on missing _mullvad
                    envExtra = ''
                      fpath=(''${fpath:#/usr/local/share/zsh/site-functions})
                    '';
                    oh-my-zsh = {
                      enable = true;
                      theme = "agnoster";
                      plugins = [
                        "common-aliases"
                        "git"
                        "macos"
                        "eza"
                      ];
                    };
                    shellAliases = {
                      hsw = "home-manager switch";
                      dsw = "sudo darwin-rebuild switch --flake /etc/nix-darwin#AJ-MARKOW-WORK-MACBOOK-PRO";
                      ls = "eza --long --git --icons --group --header --color=auto";
                      showfiles = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
                      hidefiles = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
                    };
                    sessionVariables = {
                      EDITOR = "nvim";
                    };
                    initContent = ''
                      # Ensure Homebrew paths are always available
                      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
                    '';
                  };

                  # Configure Git
                  programs.git = {
                    enable = true;
                    settings = {
                      user = {
                        name = "AJ Markow";
                        email = "alexanderjmarkow@gmail.com";
                        signingKey = "0E96371A9739318ADA6E6F1ADF9CCC102CBF66CB";
                      };
                      commit = {
                        gpgsign = true;
                      };
                      tag = {
                        gpgsign = true;
                      };
                      gpg = {
                        program = "/nix/var/nix/profiles/system/sw/bin/gpg";
                      };
                    };
                  };

                  # Configure GPG agent
                  services.gpg-agent = {
                    enable = true;
                    enableSshSupport = true;
                    pinentry.package = pkgs.pinentry_mac;
                    defaultCacheTtl = 28800;
                    maxCacheTtl = 86400;
                  };

                  # SKHD for Shortcuts
                  services.skhd = {
                    enable = true;
                    config = ''
                      # Open Raycast with hyprkey
                      hyper - r : open -a "Raycast"
                      # Open Terminal with hyprkey
                      hyper - t : open -a "WezTerm"
                      # Open Apple Music with hyprkey
                      hyper - m : open -a "Music"
                    '';
                  };
                  # Configure Neovim with nixvim
                  programs.nixvim = {
                    enable = true;

                    # Global settings
                    globals = {
                      mapleader = " "; # Set space as leader key
                      maplocalleader = " ";
                      # Disable netrw so oil can take over directory buffers (e.g. `nvim .`)
                      loaded_netrw = 1;
                      loaded_netrwPlugin = 1;
                    };

                    # General options
                    opts = {
                      number = true; # Show line numbers
                      relativenumber = false; # Show relative line numbers
                      tabstop = 2; # Tab width
                      shiftwidth = 2; # Indent width
                      expandtab = true; # Use spaces instead of tabs
                      smartindent = true; # Smart indenting
                      wrap = false; # Don't wrap lines
                      termguicolors = true; # Enable 24-bit RGB colors
                      clipboard = "unnamedplus"; # Use system clipboard
                      autochdir = true; # Auto change directory to the current file's directory
                    };

                    # Colorscheme
                    colorschemes.catppuccin = {
                      enable = true;
                      settings = {
                        style = "frappe";
                        transparent = true;
                        term_colors = true;
                      };
                    };

                    # Plugins
                    plugins = {
                      # LSP Configuration
                      lsp = {
                        enable = true;
                        servers = {
                          # Nix LSP
                          nil_ls = {
                            enable = true;
                            settings = {
                              formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
                            };
                          };
                          # TypeScript/JavaScript LSP
                          ts_ls.enable = true;
                          # Python LSP
                          pylsp.enable = true;
                          # Lua LSP
                          lua_ls.enable = true;
                          # Go LSP
                          gopls.enable = true;
                        };
                      };

                      # oil for file and folder management
                      oil = {
                        enable = true;
                      };

                      # File explorer (neo-tree: https://github.com/nvim-neo-tree/neo-tree.nvim)
                      neo-tree = {
                        enable = true;
                        settings = {
                          window = {
                            position = "left";
                          };
                          filesystem = {
                            hijack_netrw_behavior = "disabled";
                            follow_current_file = {
                              enabled = true;
                              leave_dirs_open = true; # Keep auto-expanded dirs open when following file
                            };
                          };
                          log_to_file = false;
                        };
                      };

                      # Fuzzy finder
                      telescope = {
                        enable = true;
                        keymaps = {
                          "<leader>ff" = "find_files";
                          "<leader>fg" = "live_grep";
                          "<leader>fb" = "buffers";
                          "<leader>fh" = "help_tags";
                        };
                      };
                      # Trouble for better error rendering
                      trouble = {
                        enable = true;
                        settings = {
                          warn_no_results = false; # Don't show warning when no diagnostics
                        };
                      };

                      # Edgy for window layouts (https://github.com/folke/edgy.nvim)
                      edgy = {
                        enable = true;
                        settings = {
                          left = [
                            {
                              title = "Files";
                              ft = "neo-tree";
                              filter = ''
                                function(buf)
                                  return vim.b[buf].neo_tree_source == "filesystem"
                                end
                              '';
                            }
                            {
                              title = "Issues";
                              ft = "Trouble";
                              pinned = true;
                              open = "Trouble diagnostics toggle filter.buf=0";
                            }
                          ];
                        };
                      };
                      # blink-cmp for completions
                      blink-cmp = {
                        enable = true;
                      };
                      # Treesitter for syntax highlighting
                      treesitter = {
                        enable = true;
                        settings = {
                          highlight.enable = true;
                          indent.enable = true;
                        };
                      };

                      # Icons (required by telescope and neo-tree)
                      web-devicons.enable = true;

                      # Git integration
                      gitsigns.enable = true;

                      # Status line
                      lualine = {
                        enable = true;
                        settings = {
                          options = {
                            theme = "catppuccin";
                            globalstatus = true;
                          };
                        };
                      };

                      # Auto-completion
                      cmp = {
                        enable = true;
                        autoEnableSources = true;
                        settings = {
                          sources = [
                            { name = "nvim_lsp"; }
                            { name = "buffer"; }
                            { name = "path"; }
                          ];
                          mapping = {
                            __raw = ''
                              cmp.mapping.preset.insert({
                                ['<Tab>'] = cmp.mapping.select_next_item(),
                                ['<S-Tab>'] = cmp.mapping.select_prev_item(),
                                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                                ['<C-Space>'] = cmp.mapping.complete(),
                              })
                            '';
                          };
                        };
                      };
                    };

                    # Open oil when starting with a directory (e.g. `nvim .`)
                    autoCmd = [
                      {
                        event = "VimEnter";
                        pattern = "*";
                        callback = {
                          __raw = ''
                            function()
                              local path = vim.fn.argv(0)
                              if path ~= "" and vim.fn.isdirectory(path) == 1 then
                                require("oil").open(path)
                              end
                            end
                          '';
                        };
                        once = true;
                      }
                    ];

                    # Key mappings
                    keymaps = [
                      # File explorer
                      {
                        key = "<leader>e";
                        action = ":Neotree toggle<CR>";
                        options.desc = "Toggle file explorer";
                      }
                      # Save file
                      {
                        key = "<leader>w";
                        action = ":w<CR>";
                        options.desc = "Save file";
                      }
                      # Quit
                      {
                        key = "<leader>q";
                        action = ":q<CR>";
                        options.desc = "Quit";
                      }
                    ];
                  };
                };
            }
          ];
        };
      };
    };
}
