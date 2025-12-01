# spamhaus-drop-nftables-bash
Deploy Spamhaus' DROP list to Linux using bash and nftables

# Prerequisites
spamhaus-drop-nftables.sh requires the `nft`, `curl`, and `jq` commands to be installed on the system.

# Usage
```
Usage: ./spamhaus-drop-nftables.sh [-d] [-l] [-q] [--curl-cmd] [--log-level] [--log-prefix] [--jq-cmd] [--max-retry] [--nft-cmd] [--retry-delay] [-h|--help]

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
