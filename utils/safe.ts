import { existsSync, mkdirSync, writeFileSync } from 'node:fs'
import { glob } from 'glob'
import {
  type Address,
  type Hex,
  checksumAddress,
  decodeAbiParameters,
  encodeAbiParameters,
  toFunctionSelector,
  zeroAddress,
} from 'viem'
import {
  SAFE_API_V1,
  broadcastLocation,
  getArg,
  proposeOutput,
  signPayloadInput,
  signatureOutput,
  signaturesPath,
  txPayloadOutput,
} from './shared'
import { signData, signHash } from './signers'
import type { BroadcastJSON, SafeInfoResponse } from './types'

if (!process.env.SAFE_ADDRESS) throw new Error('SAFE_ADDRESS not set')
if (!process.env.SAFE_CHAIN_ID) throw new Error('CHAIN_ID not set')

const SAFE_ADDRESS = process.env.SAFE_ADDRESS
const CHAIN_ID = process.env.SAFE_CHAIN_ID as unknown as keyof typeof SAFE_API_V1
const SAFE_API = SAFE_API_V1[CHAIN_ID]

export const types = {
  EIP712Domain: [
    { name: 'verifyingContract', type: 'address' },
    { name: 'chainId', type: 'uint256' },
  ],
  SafeTx: [
    { name: 'to', type: 'address' },
    { name: 'value', type: 'uint256' },
    { name: 'data', type: 'bytes' },
    { name: 'operation', type: 'uint8' },
    { name: 'safeTxGas', type: 'uint256' },
    { name: 'baseGas', type: 'uint256' },
    { name: 'gasPrice', type: 'uint256' },
    { name: 'gasToken', type: 'address' },
    { name: 'refundReceiver', type: 'address' },
    { name: 'nonce', type: 'uint256' },
  ],
}

const typedData = (safe: Address, message: any) => ({
  types,
  domain: {
    verifyingContract: safe,
    chainId: CHAIN_ID,
  },
  primaryType: 'SafeTx' as const,
  message: message,
})

export async function getSafePayloads() {
  const name = process.argv[3]
  const chainId = process.argv[4]
  const safeAddr = process.argv[5] as Address
  const nonce = process.argv[6] as string | undefined
  const payloads = await parseBroadcast(name, Number(chainId), safeAddr, nonce ? Number(nonce) : undefined)

  if (!payloads.length) {
    throw new Error(`No payloads found for ${name} on chain ${chainId}`)
  }
  return payloads
}

export async function signBatch() {
  const timestamp = Math.floor(Date.now() / 1000)

  const safe = process.argv[3] as Address
  const chainId = process.argv[4]
  const data = process.argv[5] as Hex
  if (!existsSync(signaturesPath)) mkdirSync(signaturesPath, { recursive: true })

  const file = (suffix: string) => `${signaturesPath}${timestamp}-${chainId}-${suffix}.json`

  const [decoded] = decodeAbiParameters(signPayloadInput, data)
  const typed = typedData(safe, {
    to: decoded.to,
    value: Number(decoded.value),
    data: decoded.data,
    operation: Number(decoded.operation),
    safeTxGas: Number(decoded.safeTxGas),
    baseGas: Number(decoded.baseGas),
    gasPrice: Number(decoded.gasPrice),
    gasToken: decoded.gasToken,
    refundReceiver: decoded.refundReceiver,
    nonce: Number(decoded.nonce),
  })

  const [signature, signer] = await safeSign(decoded.txHash)
  const fileName = file('signed-batch')
  writeFileSync(
    fileName,
    JSON.stringify({
      ...typed.message,
      safe,
      sender: signer,
      signature,
      contractTransactionHash: decoded.txHash,
    }),
  )

  return encodeAbiParameters(signatureOutput, [fileName, signature, signer])
}

export async function proposeBatch(filename?: string) {
  const file = getArg(filename)
  const results = !file.startsWith(process.cwd()) ? glob.sync(`${signaturesPath}${file}.json`) : [file]
  if (results.length !== 1) throw new Error(`Expected 1 file, got ${results.length} for ${file}`)
  const tx = require(results[0])
  const isCLI = process.argv[4] != null

  const response = await fetch(`${SAFE_API}/safes/${checksumAddress(tx.safe)}/multisig-transactions/`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(tx),
  })
  const json = await response.json()
  if (isCLI) {
    console.log(json)
    return
  }
  return encodeAbiParameters(proposeOutput, [`${response.status}: ${response.statusText}`, json])
}

export async function deleteBatch(txHash?: Hex) {
  const safeTxHash = getArg(txHash)
  const [signature] = await signData(deleteData(safeTxHash))
  const response = await fetch(`${SAFE_API}/transactions/${safeTxHash}/`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ signature, safeTxHash }),
  })
  if (!response.ok) throw new Error(await response.text())
  return response.statusText
}

export async function safeSign(txHash?: Hex): Promise<[Hex, Address]> {
  const [signature, signer] = await signHash(txHash)
  const v1 = parseInt(signature.slice(-2), 16) + 4
  return [`${signature.slice(0, -2)}${v1.toString(16)}` as Hex, signer]
}

async function parseBroadcast(name: string, chainId: number, safeAddr: Address, nonce?: number) {
  const files = glob.sync(`${broadcastLocation}/**/${chainId}/dry-run/${name}-latest.json`)
  if (files.length !== 1) throw new Error(`Expected 1 file, got ${files.length}`)
  const data: BroadcastJSON = require(files[0])

  if (!data.transactions?.length) {
    throw new Error(`No transactions found for ${name} on chain ${chainId}`)
  }

  const safeInfo: SafeInfoResponse = await fetch(`${SAFE_API}/safes/${checksumAddress(safeAddr)}`).then(res =>
    res.json(),
  )

  const result = data.transactions.map(tx => {
    const to = tx.transaction.to
    const value = tx.transaction.value
    const gas = tx.transaction.gas
    const data = tx.transaction.input
    return {
      payload: {
        to: checksumAddress(to ?? zeroAddress),
        value: BigInt(value),
        data,
      },
      payloadInfo: {
        name,
        transactionType: tx.transactionType,
        contractAddr: checksumAddress(tx.contractAddress ?? zeroAddress),
        func: tx.function ?? '',
        funcSig: tx.function ? toFunctionSelector(tx.function) : '0x',
        args: tx.arguments ?? [],
        creations: tx.additionalContracts.map(c => checksumAddress(c.address)),
        gas: BigInt(gas),
      },
    }
  })

  const metadata = {
    payloads: result.map(r => r.payload),
    extras: result.map(r => r.payloadInfo),
    txCount: BigInt(data.transactions.length),
    creationCount: BigInt(data.transactions.reduce((res, tx) => res + tx.additionalContracts.length, 0)),
    totalGas: BigInt(data.transactions.reduce((acc, tx) => acc + Number(tx.transaction.gas), 0)),
    safeNonce: BigInt(nonce ? nonce : safeInfo.nonce),
    safeVersion: safeInfo.version,
    timestamp: BigInt(data.timestamp),
    chainId: BigInt(data.chain),
  }
  return encodeAbiParameters(txPayloadOutput, [metadata])
}

const deleteData = (txHash: Hex) => ({
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    DeleteRequest: [
      { name: 'safeTxHash', type: 'bytes32' },
      { name: 'totp', type: 'uint256' },
    ],
  },
  primaryType: 'DeleteRequest',
  domain: {
    name: 'Safe Transaction Service',
    version: '1.0',
    chainId: CHAIN_ID,
    verifyingContract: SAFE_ADDRESS,
  },
  message: {
    safeTxHash: txHash,
    totp: Math.floor(Date.now() / 1000 / 3600),
  },
})
