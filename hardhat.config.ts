import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-gas-reporter"


const config: HardhatUserConfig = {
  solidity: "0.8.20",
  gasReporter: {
    currency: 'USD',
    gasPrice: 21
  },
  mocha: {
    timeout: 100000000
  },
 
 
};

export default config;
