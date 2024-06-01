import path from 'path'
import { type Hex, encodeAbiParameters, parseAbiParameter, parseAbiParameters } from 'viem'
import type { SuccessOutput } from './types'

export const root = path.resolve(__dirname, '../')
export const broadcastLocation = `${root}/**/broadcast`

export const signaturesPath = `${process.cwd()}/temp/sign/`

export const getArg = <T>(arg?: T) => {
  if (!arg) arg = process.argv[3] as T
  if (!arg) throw new Error('No argument provided')
  return arg
}

function out(str: SuccessOutput, err?: boolean): never {
  const exitCode = err ? 1 : 0
  if (!str.length) {
    process.exit(exitCode)
  }

  if (Array.isArray(str)) {
    process.stdout.write(str.join('\n'))
  } else {
    process.stdout.write(str)
  }

  process.exit(exitCode)
}

export function success(str: SuccessOutput): never {
  out(str)
}

export function error(str: string): never {
  out(encodeAbiParameters([parseAbiParameter('string')], [`(forge-safe) ${str}`]), true)
}

export enum Signer {
  Trezor,
  Frame,
  Ledger,
}

export type Method = 'personal_sign' | 'eth_sign' | 'eth_signTypedData_v4'

export const SAFE_API_V1 = {
  1: 'https://safe-transaction-mainnet.safe.global/api/v1',
  10: 'https://safe-transaction-optimism.safe.global/api/v1',
  56: 'https://safe-transaction-bsc.safe.global/api/v1',
  100: 'https://safe-transaction-gnosis-chain.safe.global/api/v1',
  137: 'https://safe-transaction-polygon.safe.global/api/v1',
  324: 'https://safe-transaction-zksync.safe.global/api/v1',
  1101: 'https://safe-transaction-zkevm.safe.global/api/v1',
  42161: 'https://safe-transaction-arbitrum.safe.global/api/v1',
  42220: 'https://safe-transaction-celo.safe.global/api/v1',
  11155111: 'https://safe-transaction-sepolia.safe.global/api/v1',
  1313161554: 'https://safe-transaction-aurora.safe.global/api/v1',
} as const

export const txPayloadOutput = parseAbiParameters([
  'Payloads result',
  'struct Payload { address to; uint256 value; bytes data; }',
  'struct PayloadExtra { string name; address contractAddr; string transactionType; string func; string funcSig; string[] args; address[] creations; uint256 gas; }',
  'struct Payloads { Payload[] payloads; PayloadExtra[] extras; uint256 txCount; uint256 creationCount; uint256 totalGas; uint256 safeNonce; string safeVersion; uint256 timestamp; uint256 chainId; }',
])

export const signPayloadInput = parseAbiParameters([
  'Batch batch',
  'struct Batch { address to; uint256 value; bytes data; uint8 operation; uint256 safeTxGas; uint256 baseGas; uint256 gasPrice; address gasToken; address refundReceiver; uint256 nonce; bytes32 txHash; bytes signature; }',
])

export const signatureOutput = parseAbiParameters(['string,bytes,address'])
export const proposeOutput = parseAbiParameters(['string,string'])
