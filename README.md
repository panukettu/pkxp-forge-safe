# forge + safe

Send batch of transactions from forge script to Safe Transaction Service.
Supports Trezor, Ledger or Frame (for pk/mnemonic and it also supports Trezor/Ledger).

Chains: Mainnet, Sepolia, Optimism, Arbitrum, BSC, Gnosis, Polygon, Polygon zkEVM, zkSync, Celo, Aurora

## Requirements

- **foundry**: required, obvious

```shell
curl -L https://foundry.paradigm.xyz | bash
```

- **bun**: required, for ffi-scripts

```shell
curl -fsSL https://bun.sh/install | bash
```

- **frame**: optional, required for pk/mnemonic

https://frame.sh/

- **just**: optional, buut better just use it

https://github.com/casey/just

## Usage

### Setup

```shell
forge install && cp .env.example .env
```

- SIGNER_TYPE: 0 = Trezor, 1 = Frame, 2 = Ledger
- SAFE_ADDRESS: Address of your safe.
- SAFE_NETWORK: Matches what is configured in foundry.toml eg. "arbitrum".
- SAFE_CHAIN_ID: Matches the above network.
- MNEMONIC_PATH: Derivation path for directly using trezor/ledger.

### Propose a script as batch

This thing relies on using scripts with unique `--sig "myFunc()"` so do not use `run()`.

Use current nonce

```shell
just safe-run Send safeTx
```

or

```shell
forge script Send --sig "safeTx()" && forge script SafeScript --sig "sendBatch(string)" safeTx --ffi -vvv
```

Use custom nonce

```shell
just safe-run-nonce Send safeTx 111
```

or

```shell
forge script Send --sig "safeTx()" && forge script SafeScript --sig "sendBatch(string,uint256)" safeTx 111 --ffi -vvv
```

### Delete a proposed transaction batch

```shell
just safe-del 0xSAFE_TX_HASH
```

or

```shell
bun utils/ffi.ts deleteBatch 0xSAFE_TX_HASH
```

## Misc

- Look into `utils/ffi.ts` for other available commands using `bun utils/ffi.ts command ...args`
