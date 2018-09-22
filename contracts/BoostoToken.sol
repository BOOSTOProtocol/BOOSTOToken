pragma solidity ^0.4.25;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract BoostoToken is StandardToken {
    using SafeMath for uint256;

    struct HourlyReward{
        uint passedHours;
        uint percent;
    }

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

    
     // Minimum Transaction Amount(0.1 ETH)
    uint256 public minAmount = 0.1 ether;

    // 1 ETH = X BST
    uint256 public coinsPerETH = 1000;

    /**
     * hourlyRewards[hours from start timestamp] = percent
     * for example hourlyRewards[10] = 20 -- 20% more coins for first 10 hoours after ICO start
     */
    HourlyReward[] public hourlyRewards;

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
    address public fundsWallet = 0x776EFa46B4b39Aa6bd2D65ce01480B31042aeAA5;

    /**
     * Address which will manage whitelist
     * and ICOs
     */
    address private adminWallet = 0xc6BD816331B1BddC7C03aB51215bbb9e2BE62dD2;    

    /**
     * @dev Constructor
     */
    constructor() public{
        //fundsWallet = msg.sender;

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
     * both fundsWallet and adminWallet are considered as admin
     */

    modifier isAdmin(){
        require(msg.sender == fundsWallet || msg.sender == adminWallet);
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
        for (uint i = 0; i < hourlyRewards.length; i++) {
            if (now <= startTimestamp + (hourlyRewards[i].passedHours * 1 hours)) {
                return tokenAmount.mul(100+hourlyRewards[i].percent).div(100);    
            }
        }
        return tokenAmount;
    }

    /**
     * @dev Update WhiteList for an address
     * @param _address The address
     * @param _value Boolean to represent the status
     */
    function adminUpdateWhiteList(address _address, bool _value) public isAdmin{
        whiteList[_address] = _value;
    }


    /**
     * @dev Allows admin to launch a new ICO
     * @param _startTimestamp Start timestamp in epochs
     * @param _durationSeconds ICO time in seconds(1 day=24*60*60)
     * @param _coinsPerETH BST price in ETH(1 ETH = ? BST)
     * @param _maxCap Max ETH capture in wei amount
     * @param _minAmount Min ETH amount per user in wei amount
     * @param _isPublic Boolean to represent that the ICO is public or not
     */
    function adminAddICO(
        uint256 _startTimestamp,
        uint256 _durationSeconds, 
        uint256 _coinsPerETH,
        uint256 _maxCap,
        uint256 _minAmount, 
        uint[] _rewardHours,
        uint256[] _rewardPercents,
        bool _isPublic
        ) public isAdmin{

        // we can't add a new ICO when an ICO is already in progress
        assert(!isIcoInProgress());
        assert(_rewardPercents.length == _rewardHours.length);

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap;
        minAmount = _minAmount;

        hourlyRewards.length = 0;
        for(uint i=0; i < _rewardHours.length; i++){
            hourlyRewards[hourlyRewards.length++] = HourlyReward({
                    passedHours: _rewardHours[i],
                    percent: _rewardPercents[i]
                });
        }

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
