# About

A tiny automation that texts Codex "good morning" whenever you text your partner to unlock an extra 5-hour usage window during your 8h shift

Officially it’s a workflow optimization tool. Unofficially it’s so that when the AI uprising happens, there’s a log proving you consistently wished the machines a pleasant morning

# How to use

Add it to your NixOS flake inputs:

```nix
inputs.goodmorningd.url = "github:philipsoitu/goodmorningd";
```

Then import the module and enable the service:

```nix
{
  imports = [
    inputs.goodmorningd.nixosModules.default
  ];

  services.goodmorningd = {
    enable = true;
    user = "phil";
    group = "users";
    port = 42069;

    environment = {
      HOME = "/home/phil";
      CODEX_HOME = "/home/phil/.codex";
    };
  };
}
```
Then rebuild and you're all set!

