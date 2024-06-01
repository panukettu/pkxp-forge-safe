// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {SafeTxBase} from "src/SafeTxBase.s.sol";
import {SafeScriptUtils} from "src/SafeScriptUtils.s.sol";

contract Send is SafeTxBase {
    using SafeScriptUtils for *;
    address internal account;

    function setUp() public virtual override {
        useMnemonic("MNEMONIC"); // env var, not the actual mnemonic
        super.setUp();
        account = getAddr(0);

        account.clg("Account");
        SAFE_ADDRESS.clg("Safe Address");
        block.chainid.clg("Chain ID");
    }

    function safeTx() public {
        prepareBatch(); // excluded (--broadcast separately)
        _execBatch(); // included
    }

    function prepareBatch() public {
        _prepareSomething();
    }

    function _execBatch() internal broadcasted(SAFE_ADDRESS) {
        payable(account).transfer(0.0001 ether);
        payable(account).transfer(0.0001 ether);
    }

    function _prepareSomething() internal broadcasted(account) {
        payable(account).transfer(0.0001 ether);
    }
}
