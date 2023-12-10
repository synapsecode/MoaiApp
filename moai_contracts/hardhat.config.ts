import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
require("@nomicfoundation/hardhat-toolbox");

const config: HardhatUserConfig = {
  solidity: "0.8.19",
};

export default config;
