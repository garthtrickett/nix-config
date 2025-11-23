# /etc/nixos/modules/home/helix.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 📦 HELIX PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs; [
    nodejs
    nodePackages.pnpm
    dprint
    shfmt
    nodePackages.prettier
    nixpkgs-fmt
    nodePackages.typescript-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    emmet-ls
    nodePackages.intelephense
    bash-language-server
    rust-analyzer
    gopls
    nil
  ];

  # -------------------------------------------------------------------
  # 📝 HELIX CONFIGURATION
  # -------------------------------------------------------------------
  # NOTE: 'theme' is commented out here because the toggle-theme script 
  # handles it in the mutable config file managed by theme.nix
  programs.helix = {
    enable = true;
    settings = {
      # theme = "catppuccin_macchiato"; # Managed by toggle-theme
      theme = "catppuccin_macchiato"; # Default for initial generation
      editor = {
        line-number = "relative";
        cursorline = true;
        bufferline = "multiple";
        mouse = false;
        soft-wrap = { enable = true; };
        cursor-shape = { insert = "bar"; };
      };
      keys = {
        normal = {
          esc = [ "collapse_selection" "keep_primary_selection" ];
          space = {
            c = ":bc";
            r = ":reload-all";
          };
        };
      };
    };
  };

  xdg.configFile."helix/languages.toml".text = ''
    [[language]]
    name = "typescript"
    language-servers = [ "typescript-language-server" ]
    formatter = { command = "dprint", args = ["fmt", "--stdin", "{path}"] }
    auto-format = true

    [[language]]
    name = "tsx"
    language-servers = [ "typescript-language-server", "tailwindcss-language-server", "eslint" ]
    formatter = { command = "dprint", args = ["fmt", "--stdin", "{path}"] }
    auto-format = true

    [[language]]
    name = "javascript"
    language-servers = [ "typescript-language-server", "tailwindcss-language-server", "eslint" ]
    formatter = { command = "dprint", args = ["fmt", "--stdin", "{path}"] }
    auto-format = true

    [[language]]
    name = "json"
    language-servers = [ "vscode-json-language-server", "eslint" ]
    formatter = { command = "dprint", args = ["fmt", "--stdin", "{path}"] }
    indent = { tab-width = 4, unit = "\t" }
    auto-format = true

    [language-server.eslint]
    command = "vscode-eslint-language-server"
    args = ["--stdio"]

    [language-server.eslint.config]
    format = true
    nodePath = ""
    onIgnoredFiles = "off"
    packageManager = "pnpm"
    quiet = false
    rulesCustomizations = []
    run = "onType"
    useESLintClass = false
    validate = "on"
    codeAction = { disableRuleComment = { enable = true, location = "separateLine" }, showDocumentation = { enable = true } }
    codeActionOnSave = { mode = "all" }
    experimental = { }
    problems = { shortenToSingleLine = false }
    workingDirectory = { mode = "auto" }

    [[language]]
    name = "html"
    formatter = { command = "npx", args = ["prettier", "--parser", "html"] }
    language-servers = [ "vscode-html-language-server", "tailwindcss-language-server", "emmet-ls" ]

    [[language]]
    name = "css"
    formatter = { command = "npx", args = ["prettier", "--parser", "css"] }
    language-servers = [ "vscode-css-language-server", "tailwindcss-language-server", "emmet-ls" ]

    [[language]]
    name = "bash"
    file-types = ["sh", "bash"]
    language-servers = ["bash-language-server"]
    formatter = { command = "shfmt", args = ["-i", "4", "-ci"] }
    auto-format = true

    [language-server.bash-language-server]
    command = "bash-language-server"
    args = ["start"]

    [language-server.rust-analyzer.config]
    check = { command = "clippy", features = "all" }
    diagnostics = { experimental = { enable = true } }
    hover = { actions = { enable = true } }
    typing = { autoClosingAngleBrackets = { enable = true } }
    cargo = { allFeatures = true }
    procMacro = { enable = true }

    [[language]]
    name = "rust"
    language-servers = ["rust-analyzer"]

    [[language]]
    name = "go"
    language-servers = ["gopls"]

    [[language]]
    name = "php"
    language-servers = [ "intelephense" ]
    formatter = { command = 'npx', args = ["prettier", "--parser", "php"] }
    auto-format = true
    
    [[language]]
    name = "nix"
    language-servers = ["nil"]
    formatter = { command = "nixpkgs-fmt" }
    auto-format = true
  '';
}
