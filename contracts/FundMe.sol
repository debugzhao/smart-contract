// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 1.创建一个收款函数
// 2.记录投资人并且可以查看
// 3.在锁定期内，达到目标值，生产商可以提款
// 4.在锁定期内，没有达到目标值，投资人可以在锁定期解除后退款
contract FundMe {
    mapping(address => uint256) public funders2Amount;
    // 计量单位：wei
    uint256 constant MIN_VALUE = 100 * 10 ** 18; // 100 USD
    AggregatorV3Interface internal dataFeed;
    
    // 筹款目标值1000美元
    uint256 constant TARGET = 1000 * 10 ** 18;

    // 当前合约拥有者
    address public owner;

    // 当前合约部署时间
    uint256 deployTimestamp;
    // 合约锁定时间
    uint256 lockTime;

    /**
     * 收款：只有在锁定期内才可以收款
     */
    function fund() external payable {
        require(convertEth2USD(msg.value) >= MIN_VALUE, "send more ETH");
        require(block.timestamp < deployTimestamp + lockTime, "window is closed");
        funders2Amount[msg.sender] = msg.value;
    }
    
    /**
     * 构造函数在合约部署的时候只会调用一次
     * Network: Sepolia
     */
    constructor(uint256 _lockTime) {
        owner = msg.sender;
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // 当前区块时间
        deployTimestamp = block.timestamp;
        lockTime = _lockTime;
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    /**
     * Eth换算为USD
     */
    function convertEth2USD(uint256 ethAmount) internal view returns(uint256) {
        // 转换公式：eth数量 * eth价格
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return ethAmount * ethPrice / (10 ** 8);
    }

    /**
     * 提款：锁定期结束后才可以提款
     */
    function getFund() external windowClosed onlyOwner {
        require(convertEth2USD(address(this).balance) >= TARGET, "Target is not reached");

        // transfer: transfer ETH and revert if tx failed
        // this：当前合约 
        // address(this)：当前合约地址
        // address(this).balance：当前合约余额
        // payable(msg.sender).transfer(address(this).balance);

        // send: transfer ETH and return false if failed
        // bool result = payable(msg.sender).send(address(this).balance);
        // require(result, "tx failed");

        // call: transfer ETH with data, return value of function and bool
        bool success;
        (success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer tx failed");
        funders2Amount[msg.sender] = 0;
    }

    /**
     * 退款：在锁定期内，没有达到目标值，投资人可以在锁定期解除后退款
     */
    function refund() external windowClosed {
        require(convertEth2USD(address(this).balance) < TARGET, "target is reached");
        require(funders2Amount[msg.sender] != 0, "there is no fund for you");
        
        bool success;
        (success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer tx failed");
        funders2Amount[msg.sender] = 0;
    }


    /**
     * 转移合约拥有者
     */
    function transferOwnershio(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    modifier windowClosed() {
        require(block.timestamp >= deployTimestamp + lockTime, "window is not closed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "this function can only be called by owner");
        _;
    }
}