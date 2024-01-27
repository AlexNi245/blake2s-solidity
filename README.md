# Blake2s Solidity Implementation

This repository contains a Solidity implementation of the BLAKE2s cryptographic hash function, as specified in [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693.txt). The `Blake2s.sol` contract provides functions to compute BLAKE2s hashes within Ethereum smart contracts.

## Features

- Solidity implementation of BLAKE2s hash function.
- Functions for hashing data and converting the result to `bytes32`.
- Implemented in Solidity 0.8.20
- Fuzz tested

## Getting Started

To use this repository, clone it to your local machine and follow the instructions below to integrate the BLAKE2s contract into your project.

### Installation

1. Install dependencies `yarn install`
2. Run tests `yarn test`

## Usage

```solidity
pragma solidity 0.8.20;

import {Blake2s} from "blake2s-solidity/contracts/Blake2s.sol";

contract MyContract {
    function hash() public pure returns (bytes32) {
        bytes memory input = "foo";
        bytes32 hash = Blake2s.toBytes32(input);
        //0x08d6cad88075de8f192db097573d0e829411cd91eb6ec65e8fc16c017edfdb74
        return hash;
    }
}

```
