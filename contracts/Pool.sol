 // SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./SwapperToken.sol";
import "./PriceConsumerV3.sol";

contract Pool is SwapperToken {
    // Globals
    address PairTokenAddr; // Token for exchanges and LP 
    
    uint256 EthPrice = 3000;
    uint256 tokenPrice = 2;  // TODO: Connect the price oracle
    
    uint256 public TokenAmount;
    uint256 public EtherAmount;
    
    PriceConsumerV3 private Consumer;

    struct ProviderData {
        uint256 tokenAmount; 
        uint256 etherAmount;
        uint256 locktime;
    }

    mapping (address => ProviderData) LProviders;

    constructor 
    (
        string memory name_,
        string memory symbol_,
        address _PairTokenAddr
    ) SwapperToken(name_, symbol_) {
        Consumer = new PriceConsumerV3();
        PairTokenAddr = _PairTokenAddr;
    }
    
    // modifier UpdateEtherPrice () {
    //     EthPrice = Consumer.getLatestPrice();
    //     _;
    // }

    /**
     * @param tokenAmount - Should be sent equal value of tokens and ethers 
     * @param locktime - Should be locktime deadline in UNIX timestamp
    */
    
    function addLiquidity(uint256 tokenAmount, uint256 locktime) public payable /*UpdateEtherPrice*/ {
        // require((msg.value / 10^18) * EthPrice == tokenAmount * tokenPrice, "Equal values of ether and tokens should be sent");
        require(IERC20(PairTokenAddr).transferFrom(msg.sender, address(this), tokenAmount), "Sender should approve tokens first.");
        LProviders[msg.sender] = ProviderData(tokenAmount, msg.value, locktime);
        TokenAmount += tokenAmount;
        EtherAmount += msg.value;
        SwapperToken._mint(address(msg.sender), tokenAmount);
    }

    function removeLiquidity() public /*UpdateEtherPrice*/ {
        require(block.timestamp >= LProviders[msg.sender].locktime, "Wait some time before taking profit.");
        uint256 localAmount = LProviders[msg.sender].tokenAmount;
        uint256 localEthers = LProviders[msg.sender].etherAmount;
        require(localAmount <= TokenAmount && localEthers <= EtherAmount, "No liquidity");
        delete LProviders[msg.sender];
        SwapperToken._burn(msg.sender, localAmount);
        payable(address(msg.sender)).transfer(((tokenPrice * localAmount) / EthPrice) * 100000000000000000);
        TokenAmount -= localAmount;
        EtherAmount -= ((tokenPrice * localAmount) / EthPrice) * 100000000000000000;
        IERC20(PairTokenAddr).transfer(msg.sender, localAmount);
    }

    function swapTokenToEth(address receiver, uint256 amount) public /*UpdateEtherPrice*/ {
        require(EtherAmount >= (tokenPrice * amount) / EthPrice, "No liquidity");
        require(IERC20(PairTokenAddr).transferFrom(msg.sender, address(this), amount), "Approve some amount of tokens");
        payable(receiver).transfer(((tokenPrice * amount) / EthPrice) * 100000000000000000);
        TokenAmount += amount;
        EtherAmount -= ((tokenPrice * amount) / EthPrice) * 100000000000000000;
    }

    function swapEthToToken(address receiver) public /*UpdateEtherPrice*/ payable {
        uint256 requiredAmount = ((EthPrice * msg.value) / tokenPrice) / 100000000000000000;
        require(TokenAmount >= requiredAmount, "No liquidity");
        IERC20(PairTokenAddr).transfer(receiver, requiredAmount);
        TokenAmount -= requiredAmount;
        EtherAmount += msg.value;
    }
}