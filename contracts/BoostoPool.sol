pragma solidity ^0.4.25;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

/**
 * @title Boosto Pool
 */
contract BoostoPool{
    using SafeMath for uint256;

    // total number of investors
    uint256 public totalInvestors;

    address[] investorsList;

    mapping(address => bool) public investors;
    mapping(address => bool) public winners;

    address private BSTContract = 0xDf0041891BdA1f911C4243f328F7Cf61b37F965b;
    address private fundsWallet;
    address private operatorWallet;

    uint256 public unit;
    uint256 public size;

    uint256 public BSTAmount;

    uint256 public winnerCount;
    uint256 public paidWinners = 0;

    uint256 public bonus;
    bool public bonusInETH;

    uint256 public startDate;
    uint256 public duration; // in seconds

    /**
     * @dev Creates a new pool
     */
    constructor(
        uint256 _startDate,
        uint256 _duration,
        uint256 _winnerCount,
        uint256 _bonus,
        bool _bonusInETH,
        uint256 _unit,
        uint256 _BSTAmount,
        uint256 _size,
        address _fundsWallet,
        address _operatorWallet
        ) public{
        
        startDate = _startDate;
        duration = _duration;
        
        winnerCount = _winnerCount;
        bonus = _bonus;
        bonusInETH = _bonusInETH;
        unit = _unit;
        BSTAmount = _BSTAmount;
        size = _size;

        fundsWallet = _fundsWallet;
        operatorWallet = _operatorWallet;
    }

    /**
     * @dev Checks if the pool is still open or not
     */
    modifier isPoolOpen() {
        require(totalInvestors < size && now < (startDate + duration) && now >= startDate);
        _;
    }

    /**
     * @dev Checks if the pool is closed
     */
    modifier isPoolClosed() {
        require(totalInvestors >= size || now >= (startDate + duration));
        _;
    }

    /**
     * @dev Checks if the pool is finished successfully
     */
    modifier isPoolFinished() {
        require(totalInvestors >= size);
        _;
    }

    /**
     * @dev modifier for check msg.value
     */
    modifier checkInvestAmount(){
        require(msg.value == unit);
        _;
    }

    /**
     * @dev check if the sender is already invested
     */
    modifier notInvestedYet(){
        require(!investors[msg.sender]);
        _;
    }

    /**
     * @dev check if the sender is admin
     */
    modifier isAdmin(){
        require(msg.sender == operatorWallet);
        _;
    }

    /**
     * @dev fallback function
     */
    function() checkInvestAmount notInvestedYet isPoolOpen payable public{
        fundsWallet.transfer(msg.value);

        StandardToken bst = StandardToken(BSTContract);
        bst.transfer(msg.sender, BSTAmount);

        investorsList[investorsList.length++] = msg.sender;
        investors[msg.sender] = true;

        totalInvestors += 1;
    }

    /**
     * @dev Allows the admin to tranfer ETH to SC 
     * when bounus is in ETH
     */
    function adminDropETH() isAdmin payable public{
        assert(bonusInETH);
        assert(msg.value == winnerCount.mul(bonus));
    }

    /**
     * @dev Allows the admin to withdraw remaining token and ETH when
     * the pool is closed and not reached the goal(no rewards)
     */
    function adminWithdraw() isAdmin isPoolClosed public{
        assert(totalInvestors <= size);

        StandardToken bst = StandardToken(BSTContract);
        uint256 bstBalance = bst.balanceOf(this);

        if(bstBalance > 0){
            bst.transfer(msg.sender, bstBalance);
        }

        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
            msg.sender.transfer(ethBalance);
        }
    }

    /**
     * @dev Selects a random winner and transfer the funds.
     * This function could fail when the selected wallet is a duplicate winner
     * and need to try again to select an another random investor.
     * When we have N winners, the admin need to call this function N times. This is 
     * not an efficient method but since we have just a few winners it will work fine.
     */
    function adminAddWinner() isPoolFinished isAdmin public{
        assert(paidWinners < winnerCount);
        uint256 winnerIndex = random();
        assert(!winners[investorsList[winnerIndex]]);

        winners[investorsList[winnerIndex]] = true;
        paidWinners += 1;

        if(bonusInETH){
            investorsList[winnerIndex].transfer(bonus);
        }else{
            StandardToken(BSTContract).transfer(investorsList[winnerIndex], bonus);
        }
    }

    /**
     * @dev Selects a random winner among all investors
     */
    function random() public view returns (uint256) {
        return uint256(keccak256(block.timestamp, block.difficulty))%size;
    }

    /**
     * @dev Returns the details of an investor by its index.
     * UI can use this function to show the info.
     * @param index Index of the investor in investorsList
     */
    function getWalletInfoByIndex(uint256 index) 
            public constant returns (address _addr, bool _isWinner){
        _addr = investorsList[index];
        _isWinner = winners[_addr];
    }

    /**
     * @dev Returns the details of an investor
     * UI can use this function to show the info.
     * @param addr Address of the investor
     */
    function getWalletInfo(address addr) 
            public constant returns (bool _isWinner){
        _isWinner = winners[addr];
    }

    /**
     * @dev checks if there is enough funds in the contract or not
     * @param status Boolean to show if there is enough funds or not
     */
    function isHealthy() 
            public constant returns (bool status){

        // ETH balance is not enough
        if(bonusInETH && address(this).balance < winnerCount.mul(bonus)){
            return false;
        }
        
        uint256 bstBalance = StandardToken(BSTContract).balanceOf(this);

        uint256 enoughBalance = BSTAmount.mul(size - totalInvestors); 
        if(!bonusInETH){
            enoughBalance = bstBalance.add(winnerCount.mul(bonus));
        }
        if(bstBalance < enoughBalance){
            return false;
        }
        return true;
    }
}
