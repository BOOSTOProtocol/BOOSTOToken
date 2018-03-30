pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract BoostoToken is StandardToken {
    using SafeMath for uint256;

    string public name = "Boosto";
    string public symbol = "BST";
    uint8 public decimals = 18;

    // 1B total supply
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    
    uint256 public totalRaised; // total ether raised (in wei)

    uint256 public startTimestamp; // timestamp after which ICO will start
    
    // 1 month = 1 * 30 * 24 * 60 * 60
    uint256 public durationSeconds;

    // the ICO ether max cap (in wei)
    uint256 public maxCap;

    uint256 public testNumber = 987654;
     // Minimum Transaction Amount(0.1 ETH)
    uint256 public minAmount = 0.1 ether;

    // 1 ETH = X BST
    uint256 public coinsPerETH = 1000;

    /**
     * weeklyRewards[week number] = percent
     * for example weeklyRewards[1] = 20 -- 20% more coins for first week after ICO start
     */
    mapping(uint => uint) public weeklyRewards;

    /**
     * if true, everyone can participate in ICOs.
     * otherwise just whitelisted wallets can participate
     */
    bool isPublic = false;

    /**
     * mapping to save whitelisted users
     */
    mapping(address => bool) public whiteList;
    
    /**
     * Address which will receive raised funds 
     * and owns the total supply of tokens
     */
    address public fundsWallet;

    /**
     * @dev Constructor
     */
    function BoostoToken() public{
        fundsWallet = msg.sender;

        startTimestamp = now;

        // ICO is not active by default. Admin can set it later
        durationSeconds = 0;

        //initially assign all tokens to the fundsWallet
        balances[fundsWallet] = totalSupply;
        Transfer(0x0, fundsWallet, totalSupply);
    }

    /**
     * @dev Checks if an ICO is open
     */
    modifier isIcoOpen() {
        require(isIcoInProgress());
        _;
    }

    /**
     * @dev Checks if the investment amount is greater than min amount
     */
    modifier checkMin(){
        require(msg.value >= minAmount);
        _;
    }

    /**
     * @dev Checks if msg.sender can participate in the ICO
     */
    modifier isWhiteListed(){
        require(isPublic || whiteList[msg.sender]);
        _;
    }

    /**
     * @dev Checks if msg.sender is admin
     */

    modifier isOwner(){
        require(msg.sender == fundsWallet);
        _;
    }

    /**
     * @dev Payable fallback. This function will be called
     * when investors send ETH to buy BST
     */
    function() public isIcoOpen checkMin isWhiteListed payable{
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        Transfer(fundsWallet, msg.sender, tokenAmount);

        // immediately transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    /**
     * @dev Calculates token amount for investors based on weekly rewards
     * and msg.value
     * @param weiAmount ETH amount in wei amount
     * @return Total BST amount
     */
    function calculateTokenAmount(uint256 weiAmount) public constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinsPerETH);
        // setting rewards is possible only for 4 weeks
        for (uint i = 1; i <= 4; i++) {
            if (now <= startTimestamp + (i * 7 days)) {
                return tokenAmount.mul(100+weeklyRewards[i]).div(100);    
            }
        }
        return tokenAmount;
    }

    /**
     * @dev Update WhiteList for an address
     * @param _address The address
     * @param _value Boolean to represent the status
     */
    function adminUpdateWhiteList(address _address, bool _value) public isOwner{
        whiteList[_address] = _value;
    }

    /**
     * @dev Allows admin to launch a new ICO
     * @param _startTimestamp Start timestamp in epochs
     * @param _durationSeconds ICO time in seconds(1 day=24*60*60)
     * @param _coinsPerETH BST price in ETH(1 ETH = ? BST)
     * @param _maxCap Max ETH capture in wei amount
     * @param _minAmount Min ETH amount per user in wei amount
     * @param _week1Rewards % of rewards for week 1
     * @param _week2Rewards % of rewards for week 2
     * @param _week3Rewards % of rewards for week 3
     * @param _week4Rewards % of rewards for week 4
     * @param _isPublic Boolean to represent that the ICO is public or not
     */
    function adminAddICO(uint256 _startTimestamp, uint256 _durationSeconds, 
        uint256 _coinsPerETH, uint256 _maxCap, uint256 _minAmount, uint _week1Rewards,
        uint _week2Rewards, uint _week3Rewards, uint _week4Rewards, bool _isPublic) public isOwner{

        // we can't add a new ICO when an ICO is already in progress
        assert(!isIcoInProgress());

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap;
        minAmount = _minAmount;

        weeklyRewards[1] = _week1Rewards;
        weeklyRewards[2] = _week2Rewards;
        weeklyRewards[3] = _week3Rewards;
        weeklyRewards[4] = _week4Rewards;

        isPublic = _isPublic;
        // reset totalRaised
        totalRaised = 0;

    }

    /**
     * @dev Return true if an ICO is already in progress;
     * otherwise returns false
     */
    function isIcoInProgress() public constant returns(bool){
        if(now < startTimestamp){
            return false;
        }
        if(now > (startTimestamp + durationSeconds)){
            return false;
        }
        if(totalRaised >= maxCap){
            return false;
        }
        return true;
    }
}
