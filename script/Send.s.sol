// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Tx} from "src/Tx.s.sol";
import {Utils} from "src/Utils.s.sol";

contract Send is Tx {
    using Utils for *;
    address internal account;

    function setUp() public virtual override {
        super.setUp();
        account = getAddr(0);

        account.clg("Account");
        SAFE_ADDRESS.clg("Safe Address");
        block.chainid.clg("Chain ID");
    }

    function safeTx() public {
        _doSomething();
        _doSomethingElse();
    }

    function _doSomething() internal broadcasted(SAFE_ADDRESS) {
        payable(account).transfer(0.0001 ether);
    }

    function _doSomethingElse() internal broadcasted(SAFE_ADDRESS) {
        payable(account).transfer(0.0001 ether);
    }
}
