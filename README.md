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

## Setup

```shell
forge install && cp .env.example .env
```

- SIGNER_TYPE: 0 = Trezor, 1 = Frame, 2 = Ledger
- SAFE_ADDRESS: Address of your safe.
- SAFE_NETWORK: Matches what is configured in foundry.toml eg. "arbitrum".
- SAFE_CHAIN_ID: Matches the above network.
- MNEMONIC_PATH: Derivation path for directly using trezor/ledger.
- MNEMONIC: Optional, some other wallet (use with eg. getAddr(0), see: SafeTxBase.sol)

## Usage

This thing relies on unique function naming as it uses `--sig "myFunc()"` - do not use the default function `run()`.

Only transactions broadcasted by `SAFE_ADDRESS` are included in the batch. If the batch depends on other transactions they need to be broadcasted separately.

## Dry run

Simulates and signs a batch without proposing:

```shell
just safe-dry Send safeTx
```

You can later propose it using the output file written in `temp/sign`, eg:

```shell
just safe-file 1717240045-42161-signed-batch
```

### Propose a script as batch

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
