# spamhaus-drop-nftables-bash
Deploy Spamhaus' DROP list to Linux using bash and nftables

# Usage
```
Usage: ./spamhaus-drop-nftables.sh [-d|--debug] [-l] [-q] [--log-level] [--log-prefix] [--jq-cmd PATH] [--nft-cmd PATH] [-h|--help]

Options:
  -d, --debug               Turn on debug for error messages
  -l                        Log rule matches
  -q                        Suppress final success message
      --log-level LEVEL     Set the filter's log level
                            (default: warn)
      --log-prefix PREFIX   Set the filter's log prefix
                            (default: "DROP_List_Block")
      --jq-cmd PATH         Path to jq executable
                            (default: /usr/bin/jq)
      --nft-cmd PATH        Path to nft executable
                            (default: /usr/sbin/nft)
  -h, --help                Print this help message
```

## Disclaimer
The authors of this script are not affiliated with Spamhaus and are providing the script as a convenient wrapper for integrating the publicly available list.

Spamhaus DROP List (c) 2025 The Spamhaus Project SLU
