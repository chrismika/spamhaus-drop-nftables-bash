# spamhaus-drop-nftables-bash
Deploy Spamhaus' DROP list on Linux using `bash` and `nftables`.

## Prerequisites
The script `spamhaus-drop-nftables.sh` requires the following commands to be installed on the system:
- `nft`
- `curl`
- `jq`

To use the provided `Makefile`, `make` must also be installed.

## Installation
Use the provided `Makefile` to install the script and enable the `systemd` service and timer:

```bash
sudo make install
```

Since `nftables` rules are not persistent across reboots, the `systemd` service and timer ensure the rules are applied at startup and the set is regularly updated. The service is enabled but not started immediately, meaning the rules won't be applied until the timer triggers.

To apply the rules immediately, manually start the service with:

```bash
sudo systemctl start spamhaus-drop-nftables.service
```

You can also run the script manually from anywhere:

```bash
sudo ./spamhaus-drop-nftables.sh
```

## Uninstallation
To remove the script, service, timer, and related files:

```bash
sudo make uninstall
```

## Usage

```
Usage: ./spamhaus-drop-nftables.sh [options]

Deploy Spamhaus' DROP list to Linux using bash and nftables.

Options:
  -d                        Turn on debug for error messages
  -l                        Log rule matches
  -q                        Suppress final success message
      --curl-cmd PATH       Path to curl executable
                            (default: /usr/bin/curl)
      --log-level LEVEL     Set the filter's log level
                            (default: warn)
      --log-prefix PREFIX   Set the filter's log prefix
                            (default: "DROP_List_Block")
      --jq-cmd PATH         Path to jq executable
                            (default: /usr/bin/jq)
      --max-retry INT       Set the max number of download retries
                            (default: 5)
      --nft-cmd PATH        Path to nft executable
                            (default: /usr/sbin/nft)
      --retry-delay INT     Set the delay between download retries
                            (default: 5)
  -h, --help                Print this help message
```

## Architecture 

The script is a deliberately thin wrapper around nft: it fetches the DROP list, builds a single batch transaction, and executes it. By design there is very little logic outside the `nftables` interaction.

`bash` is a purposeful choice, not a fallback. The set is defined with `flags interval` and `auto-merge` so that overlapping and adjacent CIDRs in the DROP list are squashed by the kernel. This only works when every element is added in one transaction: a single `nft add element ... { ... }` evaluates the full element list at once and merges overlaps in one operation. Some other languages, like Go, use libraries that apply element additions iteratively behind the scenes, so each new element is checked against an already-committed interval set and the overlaps raise a conflict instead of merging.

This script is IPv4-only by design. Spamhaus publishes a separate IPv6 DROP list, but it isn't handled here, so on a dual-stack host, IPv6 traffic to and from listed ranges won't be blocked.

## Disclaimer
The authors of this script are not affiliated with Spamhaus and are providing the script as a convenient wrapper for integrating the publicly available list.

Spamhaus DROP List (c) 2025 The Spamhaus Project SLU
