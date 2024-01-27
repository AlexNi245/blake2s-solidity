pragma solidity 0.8.20;

import {Blake2s} from "./Blake2s.sol";
import "hardhat/console.sol";

contract TestContract {
    function hash(bytes memory input) public pure returns (bytes32) {
        Blake2s.BLAKE2s_ctx memory ctx;
        ctx.c = 23989;

   

  

   
        // return Blake2s.toBytes32(input);
    }
}
