// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Send} from "script/Send.s.sol";

contract Transaction is Send, Test {
    uint256 safeBalBefore;
    uint256 accBalBefore;

    function setUp() public override {
        super.setUp();
        safeBalBefore = SAFE_ADDRESS.balance;
        accBalBefore = account.balance;
        safeTx();
    }

    function testIt() public view {
        assertLt(SAFE_ADDRESS.balance, safeBalBefore, "safe-bal-not-lt");
        assertGt(account.balance, accBalBefore, "acc-bal-not-gt");
    }
}
