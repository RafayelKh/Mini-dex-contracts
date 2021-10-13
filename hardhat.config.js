require("@nomiclabs/hardhat-waffle");

const { INFURA_API, mnemonic } = require('./secrets.json')

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.0",
  networks: {
    kovan: {
      url: `https://kovan.infura.io/v3/${INFURA_API}`,
      accounts: {mnemonic: mnemonic}
    }
  },
};
