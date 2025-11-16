# spamhaus-drop-nftables-bash
Deploy Spamhaus' DROP list to Linux using bash and nftables

# Usage
Usage: ./spamhaus-drop-nftables.sh [-h|--help] [-q|--quiet] [--jq-cmd PATH] [--nft-cmd PATH]

Options:
  -h, --help           Print this help message
  -q, --quiet          Suppress final success message
      --jq-cmd PATH    Path to jq executable
                       (default: /usr/bin/jq)
      --nft-cmd PATH   Path to nft executable
                       (default: /usr/sbin/nft)
