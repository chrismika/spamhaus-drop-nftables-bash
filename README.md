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

## Disclaimer
The authors of this script are not affiliated with Spamhaus and are providing the script as a convenient wrapper for integrating the publicly available list.

Spamhaus DROP List (c) 2025 The Spamhaus Project SLU
