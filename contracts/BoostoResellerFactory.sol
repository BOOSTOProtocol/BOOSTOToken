pragma solidity ^0.4.25;

import 'contracts/BoostoReseller.sol';


contract BoostoResellerFactory {

    event NewPool(address creator, address pool);

    function createNew(
        uint256 _minPerUser,
        uint256 _maxPerUser,
        uint256 _BSTPerETH,
        address _fundsWallet,
        address _operatorWallet
    ) public returns(address created){
        address ret = new BoostoReseller(
            _minPerUser,
            _maxPerUser,
            _BSTPerETH,
            _fundsWallet,
            _operatorWallet
        );
        emit NewPool(msg.sender, ret);
        return ret;
    }
}
