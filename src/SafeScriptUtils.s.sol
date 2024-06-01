// SPDX-License-Identifier: MIT
// solhint-disable

pragma solidity ^0.8.0;

library Purify {
    function bytesFunc(
        function(bytes memory) view fn
    ) internal pure returns (function(bytes memory) pure out) {
        assembly {
            out := fn
        }
    }

    function emptyFunc(
        function() view fn
    ) internal pure returns (function() pure out) {
        assembly {
            out := fn
        }
    }
}
address constant clgAddr = 0x000000000000000000636F6e736F6c652e6c6f67;

function logv(bytes memory _b) view {
    uint256 len = _b.length;
    address _a = clgAddr;
    /// @solidity memory-safe-assembly
    assembly {
        let start := add(_b, 32)
        let r := staticcall(gas(), _a, start, len, 0, 0)
    }
}

function logp(bytes memory _p) pure {
    Purify.bytesFunc(logv)(_p);
}

function __revert(bytes memory _d) pure {
    assembly {
        revert(add(32, _d), mload(_d))
    }
}

library SafeScriptUtils {
    function equals(
        string memory _a,
        string memory _b
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function clg(string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string)", p0));
    }

    function clg(string memory p0, string memory p1) internal pure {
        logp(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function clg(address p0) internal pure {
        logp(abi.encodeWithSignature("log(address)", p0));
    }

    function clg(uint256 p0) internal pure {
        logp(abi.encodeWithSignature("log(uint256)", p0));
    }

    function clg(int256 p0) internal pure {
        logp(abi.encodeWithSignature("log(int256)", p0));
    }

    function clg(int256 p0, string memory p1) internal pure {
        logp(abi.encodeWithSignature("log(string,int256)", p1, p0));
    }

    function clg(bool p0) internal pure {
        logp(abi.encodeWithSignature("log(bool)", p0));
    }

    function clg(uint256 p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function clg(address p0, uint256 p1) internal pure {
        logp(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function clg(string memory p0, address p1, uint256 p2) internal pure {
        logp(
            abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2)
        );
    }

    function clg(address p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function blg(bytes32 p0) internal pure {
        logp(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function blg(bytes32 p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,bytes32)", p0, p1));
    }

    function blg(bytes memory p0) internal pure {
        logp(abi.encodeWithSignature("log(bytes)", p0));
    }

    function blg(bytes memory p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,bytes)", p0, p1));
    }
}
