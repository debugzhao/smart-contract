require("@nomicfoundation/hardhat-toolbox");
require("@chainlink/env-enc").config()
require("@nomicfoundation/hardhat-verify")

// 读取当前进程env环境变量
const SEPOLIA_URL = process.env.SEPOLIA_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: SEPOLIA_URL,
      accounts: [PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      sepolia: "CR9CZUCXBNJ6V5FQ2WHVVD1TDGBVA6SYZW"
    }
  },
};
