// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccess {
    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function transferOwnership(address) external;

    function acceptOwnership() external;

    function acceptOwnership(address) external;

    function renounceOwnership() external;

    function contractOwner() external view returns (address);

    function hasRole(bytes32, address) external view returns (bool);

    function grantRole(bytes32, address) external;

    function revokeRole(bytes32, address) external;

    function renounceRole(bytes32, address) external;

    function setRoleAdmin(bytes32, bytes32) external;

    function getRoleAdmin(bytes32) external view returns (bytes32);

    function getRoleMember(bytes32, uint256) external view returns (address);

    function getRoleMemberCount(bytes32) external view returns (uint256);

    function getRoleMemberIndex(
        bytes32,
        address
    ) external view returns (uint256);
}
