// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const { FN, BN, DECIMALS } = require("./constants");
const { setupInitState } = require("./helpers");

async function initDeploymentSetup() {
  const [deployer] = await ethers.getSigners();
  const accountsList = [
    "0x0Ba4E7bfb5cDc3c1a06E0722bC8286B7B7D39d5d",
    "0x00000000219ab540356cBB839Cbe05303d7705Fa",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8",
    "0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf",
    "0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0",

    "0xF977814e90dA44bFA03b6295A0616a897441aceC",
    "0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a",
    "0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503",
    "0xE92d1A43df510F82C66382592a047d288f85226f",
  ];

  return await setupInitState(deployer.address, accountsList);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
initDeploymentSetup().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
