const { ethers } = require("hardhat");

async function main() {
    const TokenFactory = await ethers.getContractFactory("SwapperToken");
    const PoolFactory = await ethers.getContractFactory("Pool");
    const Token = await TokenFactory.deploy("Token1", "TK");
    const Pool = await PoolFactory.deploy('SwapperToken', "ST", Token.address);
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});