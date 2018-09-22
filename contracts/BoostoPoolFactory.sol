pragma solidity ^0.4.25;

import 'contracts/BoostoPool.sol';


contract BoostoPoolFactory {

    event NewPool(address creator, address pool);

    function createNew(
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
    ) public returns(address created){
        address ret = new BoostoPool(
            _startDate,
            _duration,
            _winnerCount,
            _bonus,
            _bonusInETH,
            _unit,
            _BSTAmount,
            _size,
            _fundsWallet,
            _operatorWallet
        );
        emit NewPool(msg.sender, ret);
    }
}
