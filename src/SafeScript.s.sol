// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {SafeScriptUtils, __revert} from "./SafeScriptUtils.s.sol";
import {MultisendAddr} from "./MultisendAddr.s.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";

// solhint-disable

contract SafeScript is MultisendAddr, Script {
    using SafeScriptUtils for *;

    enum Operation {
        CALL,
        DELEGATECALL
    }

    struct Payload {
        address to;
        uint256 value;
        bytes data;
    }

    struct Batch {
        address to;
        uint256 value;
        bytes data;
        Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address refundReceiver;
        uint256 nonce;
        bytes32 txHash;
        bytes signature;
    }

    address immutable MULTI_SEND_ADDRESS;
    address immutable SAFE_ADDRESS;
    uint256 immutable CHAIN_ID;
    string NETWORK;

    constructor() {
        NETWORK = vm.envString("SAFE_NETWORK");
        CHAIN_ID = vm.envUint("SAFE_CHAIN_ID");
        SAFE_ADDRESS = vm.envAddress("SAFE_ADDRESS");
        MULTI_SEND_ADDRESS = _multisend[CHAIN_ID];
        require(
            SAFE_ADDRESS != address(0),
            string.concat("SAFE_ADDRESS not set, chain:", vm.toString(CHAIN_ID))
        );
        require(
            MULTI_SEND_ADDRESS != address(0),
            string.concat(
                "MULTI_SEND_ADDRESS not set, chain:",
                vm.toString(CHAIN_ID)
            )
        );
    }

    bytes32 constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    bytes32 constant SAFE_TX_TYPEHASH =
        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    bytes[] transactions;
    string[] argsFFI;

    function sendBatch(string memory broadcastId) public {
        sendBatch(broadcastId, 0);
    }

    function sendBatch(string memory broadcastId, uint256 nonce) public {
        (, string memory fileName) = simulateAndSign(broadcastId, nonce);
        proposeBatch(fileName);
    }

    function simulateAndSign(
        string memory broadcastId,
        uint256 nonce
    ) public returns (bytes32 safeTxHash, string memory fileName) {
        (
            bytes32 txHash,
            string memory file,
            bytes memory sig,
            address signer
        ) = signBatch(simulate(broadcastId, nonce));
        string.concat("Hash: ", vm.toString(txHash)).clg();
        string.concat("Signer: ", vm.toString(signer)).clg();
        string.concat("Signature: ", vm.toString(sig)).clg();
        string.concat("Output File: ", file).clg();
        return (txHash, file);
    }

    function simulate(
        string memory broadcastId,
        uint256 nonce
    ) public returns (Batch memory batch) {
        vm.createSelectFork(NETWORK);
        Payloads memory data = getPayloads(broadcastId, nonce);
        printPayloads(data);
        for (uint256 i; i < data.payloads.length; ++i) {
            require(
                !data.extras[i].transactionType.equals("CREATE"),
                "Only CALL transactions are supported"
            );
        }

        batch = _simulate(data);
        writeOutput(broadcastId, batch, data.payloads);
    }

    // Encodes the stored encoded transactions into a single Multisend transaction
    function createBatch(
        Payloads memory data
    ) private view returns (Batch memory batch) {
        batch.to = MULTI_SEND_ADDRESS;
        batch.value = 0;
        batch.operation = Operation.DELEGATECALL;

        bytes memory calls;
        for (uint256 i; i < data.payloads.length; ++i) {
            calls = bytes.concat(
                calls,
                abi.encodePacked(
                    Operation.CALL,
                    data.payloads[i].to,
                    data.payloads[i].value,
                    data.payloads[i].data.length,
                    data.payloads[i].data
                )
            );
        }

        batch.data = abi.encodeWithSignature("multiSend(bytes)", calls);
        batch.nonce = data.safeNonce;
        batch.txHash = getSafeTxHash(batch);
    }

    function _simulate(
        Payloads memory payloads
    ) private returns (Batch memory batch) {
        batch = createBatch(payloads);
        bytes32 fromSafe = getSafeTxHash(batch);
        string
            .concat(
                "Simulating transaction in: ",
                NETWORK,
                " (",
                vm.toString(block.chainid),
                ")",
                "\n  safeTxHash: ",
                vm.toString(fromSafe),
                "\n  batch.txHash: ",
                vm.toString(batch.txHash)
            )
            .clg();
        vm.prank(SAFE_ADDRESS);
        (bool success, bytes memory returnData) = SAFE_ADDRESS.call(
            abi.encodeWithSignature(
                "simulateAndRevert(address,bytes)",
                batch.to,
                batch.data
            )
        );
        if (!success) {
            (bool successRevert, bytes memory successReturnData) = abi.decode(
                returnData,
                (bool, bytes)
            );
            if (!successRevert) {
                ("Batch simulation failed: ").clg(
                    vm.toString(successReturnData)
                );
                __revert(successReturnData);
            }
            if (successReturnData.length == 0) {
                ("Batch simulation successful.").clg();
            } else {
                ("Batch simulation successful:").clg(
                    vm.toString(successReturnData)
                );
            }
        }
    }

    // Computes the EIP712 hash of a Safe transaction.
    // Look at https://github.com/safe-global/safe-eth-py/blob/174053920e0717cc9924405e524012c5f953cd8f/gnosis/safe/safe_tx.py#L186
    // and https://github.com/safe-global/safe-eth-py/blob/master/gnosis/eth/eip712/__init__.py
    function getSafeTxHash(Batch memory batch) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    hex"1901",
                    keccak256(
                        abi.encode(
                            DOMAIN_SEPARATOR_TYPEHASH,
                            CHAIN_ID,
                            SAFE_ADDRESS
                        )
                    ),
                    keccak256(
                        abi.encode(
                            SAFE_TX_TYPEHASH,
                            batch.to,
                            batch.value,
                            keccak256(batch.data),
                            batch.operation,
                            batch.safeTxGas,
                            batch.baseGas,
                            batch.gasPrice,
                            batch.gasToken,
                            batch.refundReceiver,
                            batch.nonce
                        )
                    )
                )
            );
    }

    function getSafeTxFromSafe(
        Batch memory batch
    ) internal view returns (bytes32) {
        (bool success, bytes memory returnData) = SAFE_ADDRESS.staticcall(
            abi.encodeWithSignature(
                "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)",
                batch.to,
                batch.value,
                batch.data,
                uint8(batch.operation),
                batch.safeTxGas,
                batch.baseGas,
                batch.gasPrice,
                batch.gasToken,
                batch.refundReceiver,
                batch.nonce
            )
        );
        if (!success) {
            __revert(returnData);
        }
        return abi.decode(returnData, (bytes32));
    }

    function getPayloads(
        string memory broadcastId,
        uint256 nonce
    ) public returns (Payloads memory) {
        argsFFI = [
            "bun",
            "utils/ffi.ts",
            "getSafePayloads",
            broadcastId,
            vm.toString(block.chainid),
            vm.toString(SAFE_ADDRESS),
            vm.toString(nonce)
        ];
        return abi.decode(_execFfi(argsFFI), (Payloads));
    }

    function signBatch(
        Batch memory batch
    )
        internal
        returns (
            bytes32 txHash,
            string memory fileName,
            bytes memory signature,
            address signer
        )
    {
        argsFFI = [
            "bun",
            "utils/ffi.ts",
            "signBatch",
            vm.toString(SAFE_ADDRESS),
            vm.toString(CHAIN_ID),
            vm.toString(abi.encode(batch))
        ];

        (fileName, signature, signer) = abi.decode(
            _execFfi(argsFFI),
            (string, bytes, address)
        );
        txHash = batch.txHash;
    }

    function proposeBatch(
        string memory fileName
    ) public returns (string memory response, string memory json) {
        argsFFI = ["bun", "utils/ffi.ts", "proposeBatch", fileName];
        (response, json) = abi.decode(_execFfi(argsFFI), (string, string));

        response.clg();
        json.clg();
    }

    function deleteProposal(bytes32 safeTxHash, string memory filename) public {
        deleteTx(safeTxHash);
        (bool success, bytes memory ret) = address(vm).call(
            abi.encodeWithSignature("removeFile(string)", filename)
        );
        if (!success) {
            __revert(ret);
        }
        string.concat("Removed Safe Tx: ", vm.toString(safeTxHash)).clg();
        string.concat("Deleted file: ", filename).clg();
    }

    function deleteProposal(bytes32 safeTxHash) public {
        deleteTx(safeTxHash);
        string.concat("Removed Safe Tx: ", vm.toString(safeTxHash)).clg();
    }

    function deleteTx(bytes32 txHash) private {
        argsFFI = ["bun", "utils/ffi.ts", "deleteBatch", vm.toString(txHash)];
        _execFfi(argsFFI);
    }

    function writeOutput(
        string memory broadcastId,
        Batch memory data,
        Payload[] memory payloads
    ) private {
        string memory path = "temp/batch/";
        string memory fileName = string.concat(
            path,
            broadcastId,
            "-",
            vm.toString(SAFE_ADDRESS),
            "-",
            vm.toString(CHAIN_ID),
            ".json"
        );
        if (!vm.exists(path)) {
            vm.createDir(path, true);
        }
        string memory out = "values";
        vm.serializeBytes(out, "id", abi.encode(broadcastId));
        vm.serializeBytes(out, "batch", abi.encode(data));
        vm.serializeAddress(out, "multisendAddr", MULTI_SEND_ADDRESS);
        vm.writeFile(
            fileName,
            vm.serializeBytes(out, "payloads", abi.encode(payloads))
        );
        string.concat("Output File: ", fileName).clg();
    }

    function printPayloads(Payloads memory payloads) public pure {
        for (uint256 i; i < payloads.payloads.length; ++i) {
            Payload memory payload = payloads.payloads[i];
            // string memory data = string(payload.data);
            string memory txStr = string.concat(
                "to: ",
                vm.toString(payload.to),
                " value: ",
                vm.toString(payload.value)
            );
            txStr.clg();
            string memory funcStr = string.concat(
                "new contracts -> ",
                vm.toString(payloads.extras[i].creations.length),
                "\n  function -> ",
                payloads.extras[i].func,
                "\n  args -> ",
                join(payloads.extras[i].args)
            );
            funcStr.clg();
            ("\n").clg();
        }
    }

    function join(
        string[] memory arr
    ) private pure returns (string memory result) {
        for (uint256 i; i < arr.length; ++i) {
            uint256 len = bytes(arr[i]).length;
            string memory suffix = i == arr.length - 1 ? "" : ",";

            if (len > 500) {
                string memory lengthStr = string.concat(
                    "bytes(",
                    vm.toString(len),
                    ")"
                );
                result = string.concat(result, lengthStr, suffix);
            } else {
                result = string.concat(result, arr[i], suffix);
            }
        }
    }

    function _execFfi(
        string[] memory args
    ) private returns (bytes memory result) {
        Vm.FfiResult memory res = vm.tryFfi(args);
        if (res.exitCode == 1) {
            revert(abi.decode(res.stdout, (string)));
        }
        return res.stdout;
    }

    struct PayloadExtra {
        string name;
        address contractAddr;
        string transactionType;
        string func;
        string funcSig;
        string[] args;
        address[] creations;
        uint256 gas;
    }

    struct Payloads {
        Payload[] payloads;
        PayloadExtra[] extras;
        uint256 txCount;
        uint256 creationCount;
        uint256 totalGas;
        uint256 safeNonce;
        string safeVersion;
        uint256 timestamp;
        uint256 chainId;
    }

    struct Load {
        SavedBatch batch;
    }

    struct SavedBatch {
        Payload[] payloads;
        Batch batch;
    }
}
