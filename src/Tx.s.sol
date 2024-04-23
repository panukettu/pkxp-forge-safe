// SPDX-License-Identifier: MIT
// solhint-disable

pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";

abstract contract Tx is Script {
    string private __mnemonicEnv = "MNEMONIC";
    address internal SAFE_ADDRESS;

    modifier broadcasted(address _sender) {
        vm.startBroadcast(_sender);
        _;
        vm.stopBroadcast();
    }

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("SAFE_NETWORK"));
        SAFE_ADDRESS = vm.envAddress("SAFE_ADDRESS");
        require(SAFE_ADDRESS != address(0), "SAFE_ADDRESS not set");
    }

    function useMnemonic(string memory _mnemonicEnv) internal {
        __mnemonicEnv = _mnemonicEnv;
    }

    function getAddr(uint32 _idx) internal returns (address) {
        return vm.rememberKey(vm.deriveKey(vm.envString(__mnemonicEnv), _idx));
    }

    function getAddr(string memory _pk) internal returns (address) {
        return vm.rememberKey(vm.envUint(_pk));
    }
}
