{
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = [
      # Add your public SSH key here, e.g.:
      # "ssh-ed25519 AAAA..."
    ];
  };

  users.users.danl = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDf6DsAzmGYBJfCJtjZlgYl6EOf2WHHHPj5/716c8dVWmrCg3JaejGMPprg6a1GSdCJ6E7DoDvnv4bfHvvh4aN0SrvGpSh0/8NCupXlXr40y+2tWDzk/u97iexeNEcf5A/6xg3ClpLPziZX+tb+olmN3Ru4kcM1oIhSdJMFSaW5tkPPbTOZ74mfTQBj2I/YXj/0E/r9Rbo/oQzunB+oekd5IQDV/Pf4rHyoFFngbOuZIpdBmd9LA9gKhWMPzKiXX6/41Mt5qb8POQpCcuWxaT9pgfJji++6WcIcdw1IvPExZTZPKUStzl+QZJMQbtocfoUQDtTiZY8I9ht3+Pkr5NHVk4KpUL3p+VoWq/mEz+RL0C4AYIRm6FrvuEeq/28vv2yF4Q3/tTwyilSKtEWAcaGyTd4FSlsiT1CZrZXFgffuHZ66WM38xbA1jcf5FuA/9HFZT9/XSkv8vmmQtizcQstBbi3OcU+Dz8MHC39ApoanH7J1VR11VOiR+ZIYhyjSSGfwX4NXqUzCi0Rvu7F+aiZUYm/P8TzQPDpAYeHDoM2ITvyjvhB+vpd1uXk+Bm6LDUQpQbVE5ivtzAqPyrNCBfgvFCYoFNz8yiTmRCF4+tFzqf0YiGpzUP03mox3J+2OTZ7I0ILifYV4Jc3ksA/wpHZX7HofkEWHLd/ci8Nc8ifcyw== dliebgold@Daves-MacBook-Pro.local"
    ];
  };

  # Allow nixos user to sudo without password
  security.sudo.extraRules = [
    {
      users = [
        "nixos"
        "danl"
      ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
