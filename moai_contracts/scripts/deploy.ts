import { formatEther, parseEther } from "viem";
const hre = require('hardhat');
require('dotenv').config();

async function main() {
  const standardAmount = parseEther("0.0005");
  const moai = await hre.viem.deployContract("MoaiContract", [standardAmount, process.env.PUSHPROTOCOL_SDK_ADDRESS]);
  console.log(`MoaiContract deployed on scroll to address: ${moai.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
