# Worrell — Networks

Public configuration for the Worrell blockchain networks, following the
[Cosmos Chain Registry](https://github.com/cosmos/chain-registry) format.

The node source code (`worrelld`) is in
[worrellchain/worrell](https://github.com/worrellchain/worrell).

## Networks

| Network | Folder | Chain ID | Status |
|---------|--------|----------|--------|
| Testnet | [`worrell-testnet-1/`](worrell-testnet-1/) | `worrell-testnet-1` | Active |

## Join the testnet

| Field | Value |
|-------|-------|
| Chain ID | `worrell-testnet-1` |
| Binary | `worrelld` (Cosmos SDK v0.53.6) |
| Source / version | [worrellchain/worrell](https://github.com/worrellchain/worrell) @ `52e7afe` |
| Genesis | [`worrell-testnet-1/genesis.json`](worrell-testnet-1/genesis.json) |
| Genesis sha256 | `a81c507b12ba0678c3172394ff4bb03e1c3db60050cc5568c127a24ec19378fd` |
| Persistent peer | `bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656` |
| Min gas price | `0.025uworrell` |
| Faucet | `POST http://164.68.98.186:4500` with `{"address":"worrell1..."}` (100 WORRELL) |

```bash
# After building worrelld and `worrelld init <moniker> --chain-id worrell-testnet-1`:
curl -s https://raw.githubusercontent.com/worrellchain/networks/main/worrell-testnet-1/genesis.json \
  -o ~/.worrell/config/genesis.json
worrelld config set config p2p.persistent_peers "bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656"
# set minimum-gas-prices = "0.025uworrell" in app.toml, then:
worrelld start
```

## Contents of each network

- **`chain.json`** — Chain Registry metadata (chain_id, peers, fees, version, genesis URL).
- **`assetlist.json`** — token definition (WORRELL / uworrell, 6 decimals).
- **`genesis.json`** — the official genesis file; every node must use this exact file.
- **`config.yml`** — Ignite configuration (accounts, validator, module parameters, faucet).
- **`setup-genesis.sh`** — rebuilds the genesis from scratch with `worrelld` + `jq` (used to *create* the network, not to join it).
- **`setup-multisig.sh`** — creates the signer keys, auxiliary keys, and multisig accounts (treasury 3/3; airdrop/incentives/reserve 2/4).

> Note: to *join* the network, download the published `genesis.json` above — do **not** run
> `setup-genesis.sh`, which would generate a different (incompatible) network.
