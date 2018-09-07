pragma solidity ^0.4.15;

import 'contracts/BoostoPool.sol';


contract BoostoPoolFactory {

    function createNew(
        uint256 _startDate,
        uint256 _duration,
        uint256 _winnerCount,
        uint256 _bonus,
        bool _bonusInETH,
        uint256 _unit,
        uint256 _BSTAmount,
        uint256 _size
    ) public returns(address created){
        return new BoostoPool(
            _startDate,
            _duration,
            _winnerCount,
            _bonus,
            _bonusInETH,
            _unit,
            _BSTAmount,
            _size
        );
    }
}
