const BoostoPool = artifacts.require('./BoostoPool.sol');

const toWei = (number) => number * Math.pow(10, 18);

const transaction = (address, wei) => ({
    from: address,
    value: wei
});

const fail = (msg) => (error) => assert(false, error ?
    `${msg}, but got error: ${error.message}` : msg);

const revertExpectedError = async(promise) => {
    try {
        await promise;
        fail('expected to fail')();
    } catch (error) {
        assert(error.message.indexOf('revert') >= 0 || error.message.indexOf('invalid opcode') >= 0,
            `Expected revert, but got: ${error.message}`);
    }
}

const timeController = (() => {

    const addSeconds = (seconds) => new Promise((resolve, reject) =>
        web3.currentProvider.sendAsync({
            jsonrpc: "2.0",
            method: "evm_increaseTime",
            params: [seconds],
            id: new Date().getTime()
        }, (error, result) => error ? reject(error) : resolve(result.result)));

    const addDays = (days) => addSeconds(days * 24 * 60 * 60);
    const addHours = (hours) => addSeconds(hours * 60 * 60);

    const currentTimestamp = () => web3.eth.getBlock(web3.eth.blockNumber).timestamp;

    return {
        addSeconds,
        addDays,
        addHours,
        currentTimestamp
    };
})();

const ethBalance = (address) => web3.eth.getBalance(address).toNumber();

contract('BoostoPool', accounts => {

    const admin = accounts[1];
    const account1 = accounts[2];
    const account2 = accounts[3];

    const account3 = accounts[4];

    const oneEth = toWei(1);
    const oneMonth = 30 * 24 * 60 * 60;

    const testAsync = async() => {
        const response = await new Promise(resolve => {
            setTimeout(() => {
                //resolve("async await test...");
            }, 1000);
        });
        //console.log(response);
    }

    const createPool = () => BoostoPool.new(
        timeController.currentTimestamp(), //uint256 _startDate,
        oneMonth, //uint256 _duration,
        3,//uint256 _winnerCount,
        toWei(2), //uint256 _bonus,
        true,//bool _bonusInETH,
        toWei(0.1), //uint256 _unit,
        toWei(100),  //uint256 _BSTAmount,
        10
    );

    
    it('test random', async() => {
        const pool = await createPool();

        var rand1 = await pool.random();
        var rand2 = await pool.random();
        console.log(rand1, rand2);
    });

});
