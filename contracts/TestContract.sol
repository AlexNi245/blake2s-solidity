pragma solidity 0.8.20;

import {Blake2s} from "./Blake2s.sol";


contract TestContract {
    function hash(bytes memory input) external pure returns (bytes32) {
        return Blake2s.toBytes32(input);
    }
}
