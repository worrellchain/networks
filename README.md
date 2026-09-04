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
| Source / version | [worrellchain/worrell](https://github.com/worrellchain/worrell) @ `v0.1.2` ([prebuilt binaries](https://github.com/worrellchain/worrell/releases/tag/v0.1.2)) |
| Genesis | [`worrell-testnet-1/genesis.json`](worrell-testnet-1/genesis.json) |
| Genesis sha256 | `a81c507b12ba0678c3172394ff4bb03e1c3db60050cc5568c127a24ec19378fd` |
| Persistent peer | `bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656` |
| Min gas price | `0.025uworrell` |
| Faucet | `POST http://164.68.98.186:4500` with `{"address":"worrell1..."}` (500 WORRELL) |
| Validator announcements | Telegram [t.me/worrellvalidators](https://t.me/worrellvalidators) — upgrades, governance, coordination |
| Explorers | [test.anode.team/worrell](https://test.anode.team/worrell) (community-run by [ANODE.TEAM](https://anode.team)) · [explorer.oshvank.xyz/worrel-testnet](https://explorer.oshvank.xyz/worrel-testnet) (community-run by [OshVanK](https://oshvank.xyz)) |
| Public REST API | `https://worrell.api.t.anode.team` (community-run by ANODE.TEAM) |
| Public RPC | `https://worrel-testnet-rpc.oshvank.xyz` (community-run by OshVanK) |
| Community guides | [docs.oshvank.xyz/docs/testnet/Worrel](https://docs.oshvank.xyz/docs/testnet/Worrel) (by OshVanK) |
| Questions / support | [GitHub Discussions](https://github.com/worrellchain/worrell/discussions) · hello@worrellchain.com |

```bash
# After installing worrelld and running `worrelld init <moniker> --chain-id worrell-testnet-1`:
curl -s https://raw.githubusercontent.com/worrellchain/networks/main/worrell-testnet-1/genesis.json \
  -o ~/.worrell/config/genesis.json
sha256sum ~/.worrell/config/genesis.json   # must match the hash above
sed -i 's|^persistent_peers = .*|persistent_peers = "bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656"|' ~/.worrell/config/config.toml
sed -i 's|^minimum-gas-prices = .*|minimum-gas-prices = "0.025uworrell"|' ~/.worrell/config/app.toml
worrelld start
```

For the full step-by-step validator guide (hardware, build, sync, create-validator,
monitoring), see [docs/RUNNING-A-NODE.md](https://github.com/worrellchain/worrell/blob/main/docs/RUNNING-A-NODE.md)
in the code repository.

## Contents of each network

- **`chain.json`** — Chain Registry metadata (chain_id, peers, fees, version, genesis URL).
- **`assetlist.json`** — token definition (WORRELL / uworrell, 6 decimals).
- **`genesis.json`** — the official genesis file; every node must use this exact file.
- **`config.yml`** — Ignite configuration (accounts, validator, module parameters, faucet).
- **`setup-genesis.sh`** — rebuilds the genesis from scratch with `worrelld` + `jq` (used to *create* the network, not to join it).
- **`setup-multisig.sh`** — creates the signer keys, auxiliary keys, and multisig accounts (treasury 3/3; airdrop/incentives/reserve 2/4).

> Note: to *join* the network, download the published `genesis.json` above — do **not** run
> `setup-genesis.sh`, which would generate a different (incompatible) network.
