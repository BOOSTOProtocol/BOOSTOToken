pragma solidity ^0.4.25;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

/**
 * @title Boosto Reseller
 */
contract BoostoReseller{
    using SafeMath for uint256;

    //address private BSTContract = 0xDf0041891BdA1f911C4243f328F7Cf61b37F965b;
    address private BSTContract = 0x7e3D9BF69D24862A699343429843Ed93a22beab2;

    address private fundsWallet;
    address private operatorWallet;

    uint256 minPerUser;
    uint256 maxPerUser;

    uint256 BSTPerETH;

    /**
     * @dev Creates a new pool
     */
    constructor(
        uint256 _minPerUser,
        uint256 _maxPerUser,
        uint256 _BSTPerETH,
        address _fundsWallet,
        address _operatorWallet
        ) public{
        
        minPerUser = _minPerUser;
        maxPerUser = _maxPerUser;
        BSTPerETH = _BSTPerETH;

        fundsWallet = _fundsWallet;
        operatorWallet = _operatorWallet;
    }

    /**
     * @dev Checks if the pool is still open or not
     */
    modifier isPoolOpen() {
        StandardToken bst = StandardToken(BSTContract);
        uint256 bstBalance = bst.balanceOf(this);
        require(bstBalance > msg.value.mul(BSTPerETH));
        _;
    }

    /**
     * @dev modifier for check msg.value
     */
    modifier checkInvestAmount(){
        require(msg.value >= minPerUser);
        require(msg.value <= maxPerUser);
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
    function() checkInvestAmount isPoolOpen payable public{
        fundsWallet.transfer(msg.value);

        StandardToken bst = StandardToken(BSTContract);
        bst.transfer(msg.sender, msg.value.mul(BSTPerETH));
    }

    /**
     * @dev Allows admin to withdraw remaining BSTs
     */
    function adminWithdraw() isAdmin public{
        StandardToken bst = StandardToken(BSTContract);
        uint256 bstBalance = bst.balanceOf(this);

        if(bstBalance > 0){
            bst.transfer(msg.sender, bstBalance);
        }
    }
}
