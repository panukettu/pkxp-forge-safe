// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract MUltiSendAddr {
    mapping(uint256 => address) internal _multisend;

    constructor() {
        _multisend[1] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        _multisend[10] = 0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B;
        _multisend[56] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        _multisend[100] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        _multisend[137] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        _multisend[324] = 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F;
        _multisend[1101] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        _multisend[42161] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        _multisend[42220] = 0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B;
        _multisend[11155111] = 0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B;
        _multisend[1313161554] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    }
}
