require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");

require("solidity-coverage");

// @todo add test coverage pluging
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.19",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.GOERLI_PRIVATE_KEY],
    },
    hardhat: {
      chainId: 1337, // @dev need for third web lib compatibility
      networkId: 1337,
    },
    gnosis: {
      url: "https://rpc.eu-central-2.gateway.fm/v4/gnosis/non-archival/mainnet",
      accounts: [process.env.GOERLI_PRIVATE_KEY],
    },
    optimism: {
      url: "https://rpc.eu-north-1.gateway.fm/v4/optimism/non-archival/mainnet",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
};
