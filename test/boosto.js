const BoostoToken = artifacts.require('./BoostoToken.sol');

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

contract('BoostoToken', accounts => {

    const admin = accounts[1];
    const account1 = accounts[2];
    const account2 = accounts[3];

    const account3 = accounts[4];

    const oneEth = toWei(1);

    const supply = toWei(1000000000);
    const maxCap = toWei(4);
    const minAmount = toWei(0.1);

    const oneMonth = 30 * 24 * 60 * 60;
    const coinsPerETH = 100;

    const rewardHours = [10, 24, 48, 100];
    const rewardPerents = [20, 10, 5, 0];

    const testAsync = async() => {
        const response = await new Promise(resolve => {
            setTimeout(() => {
                //resolve("async await test...");
            }, 1000);
        });
        //console.log(response);
    }

    const adminUpdateWhiteList = (boosto) => (address, value) => boosto.adminUpdateWhiteList(address, value, { from: admin });

    const test = (a) => (b) => {
        //console.log('jiashunran test', a, b);
    }
    const createToken = () => BoostoToken.new({ from: admin });

    const addPublicICO = (boosto) => boosto.adminAddICO(
        timeController.currentTimestamp(),
        oneMonth,
        coinsPerETH,
        maxCap,
        minAmount,
        rewardHours,
        rewardPerents,
        true, //isPublic
        { from: admin }
    );

    const addPrivateICO = (boosto) => boosto.adminAddICO(
        timeController.currentTimestamp(),
        oneMonth,
        coinsPerETH,
        maxCap,
        minAmount,
        rewardHours,
        rewardPerents,
        false, //isPublic
        { from: admin }
    )

    it('jiashunran test', async() => {
        test(1)(2)
        testAsync()
        const boosto = await createToken();
    })

    it('test total supply, minAmount, admin balance', async() => {
        const boosto = await createToken();

        const totalSupply = await boosto.totalSupply();
        assert.equal(supply, totalSupply.toNumber(), 'Total supply mismatch');

        const adminBalance = await boosto.balanceOf(admin);
        assert.equal(adminBalance.toNumber(), adminBalance, 'Admin wallet balance mismatch');

        const min = await boosto.minAmount();
        assert.equal(min.toNumber(), minAmount, 'minAmount mismatch');


    });

    it('no ICO by default', async() => {
        const boosto = await createToken();
        // need to revert the transaction. Because there is not any ICO in progress
        await revertExpectedError(boosto.sendTransaction(transaction(account1, oneEth)));
    });

    it('test add ICO', async() => {
        const boosto = await createToken();

        // No ICO by default
        var ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, false, "An ICO is in progress by default");

        await addPublicICO(boosto);

        ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, true, "No ICO in progress after adding a public ICO");

        assert.equal((await boosto.maxCap()).toNumber(), maxCap, "ICO maxCap mismatch");
        assert.equal((await boosto.minAmount()).toNumber(), minAmount, "ICO minAmount mismatch");
        assert.equal((await boosto.totalRaised()).toNumber(), 0, "Initial totalRaised mismatch");
        assert.equal((await boosto.durationSeconds()).toNumber(), oneMonth, "durationSeconds mismatch");
        assert.equal((await boosto.coinsPerETH()).toNumber(), coinsPerETH, "coinsPerETH mismatch");

        // An ICO is in progress. So we can't add an another ICO
        await revertExpectedError(addPublicICO(boosto));

    });

    it('test multiple ICO', async() => {
        const boosto = await createToken();
        // No ICO by default
        var ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, false, "An ICO is in progress by default");

        await addPublicICO(boosto);

        ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, true, "No ICO in progress after adding a public ICO");

        await boosto.sendTransaction(transaction(account1, oneEth * 4));
        ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, false, "ICO is still in progress after reaching maxCap");

        await addPublicICO(boosto);
        ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, true, "second ICO is not in progress");

        timeController.addHours(50);
        //send 1 ether to ICO
        await boosto.sendTransaction(transaction(account2, oneEth));
        var expectedBSTBalance = oneEth * coinsPerETH * (100 + rewardPerents[3]) / 100;
        assert.equal((await boosto.balanceOf(account2)).toNumber(), expectedBSTBalance,
            "second ICO BST balance mismatch");
    });

    it('test transfer', async() => {
        const boosto = await createToken();
        await addPublicICO(boosto);

        const adminBalanceBefore = ethBalance(admin);

        //send 1 ether to ICO
        await boosto.sendTransaction(transaction(account1, oneEth));

        const adminBalanceAfter = ethBalance(admin);
        // funds will go to admin wallet
        assert.equal(adminBalanceAfter, adminBalanceBefore + oneEth, "admin ethBalance mismatch");

        var expectedBSTBalance = oneEth * coinsPerETH * (100 + rewardPerents[0]) / 100;
        assert.equal((await boosto.balanceOf(account1)).toNumber(), expectedBSTBalance,
            "BST balance mismatch(period1)");

        //test week 2
        await timeController.addHours(rewardHours[0] + 1);
        await boosto.sendTransaction(transaction(account2, oneEth));
        expectedBSTBalance = oneEth * coinsPerETH * (100 + rewardPerents[1]) / 100;
        assert.equal((await boosto.balanceOf(account2)).toNumber(), expectedBSTBalance,
            "BST balance mismatch(period2)");

        // check minAmount
        await revertExpectedError(boosto.sendTransaction(transaction(account2, toWei(0.05))));
        assert.equal((await boosto.balanceOf(account2)).toNumber(), expectedBSTBalance,
            "BST balance mismatch after minAmount test");
    });

    it('test whitelist', async() => {
        const boosto = await createToken();

        const adminBalanceBefore = ethBalance(admin);

        await adminUpdateWhiteList(boosto)(account1, true)

        const isInWhiteList1 = await boosto.whiteList(account1);
        //console.log('account1 is in whitelist', isInWhiteList1);

        const isInWhiteList2 = await boosto.whiteList(account2);
        //console.log('account2 is in whitelist', isInWhiteList2);

        //send 1 ether to ICO
        // await boosto.sendTransaction(transaction(account1, oneEth));
    })

    it('test private ico ', async() => {
        const boosto = await createToken();

        // No ICO by default
        var ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, false, "An ICO is in progress by default");

        await addPrivateICO(boosto);

        ICOInProgress = await boosto.isIcoInProgress()
        assert.equal(ICOInProgress, true, "No ICO in progress after adding a public ICO");

        assert.equal((await boosto.maxCap()).toNumber(), maxCap, "ICO maxCap mismatch");
        assert.equal((await boosto.minAmount()).toNumber(), minAmount, "ICO minAmount mismatch");
        assert.equal((await boosto.totalRaised()).toNumber(), 0, "Initial totalRaised mismatch");
        assert.equal((await boosto.durationSeconds()).toNumber(), oneMonth, "durationSeconds mismatch");
        assert.equal((await boosto.coinsPerETH()).toNumber(), coinsPerETH, "coinsPerETH mismatch");

        // An ICO is in progress. So we can't add an another ICO
        await revertExpectedError(addPublicICO(boosto));

    })
    it('test private ico transfer', async() => {
        const boosto = await createToken();

        await adminUpdateWhiteList(boosto)(account1, true)
        await adminUpdateWhiteList(boosto)(account2, true)

        await addPrivateICO(boosto);

        const adminBalanceBefore = ethBalance(admin);

        //send 1 ether to ICO
        await boosto.sendTransaction(transaction(account1, oneEth));

        const adminBalanceAfter = ethBalance(admin);
        // funds will go to admin wallet
        assert.equal(adminBalanceAfter, adminBalanceBefore + oneEth, "admin ethBalance mismatch");

        var expectedBSTBalance = oneEth * coinsPerETH * (100 + rewardPerents[0]) / 100;
        var balance = (await boosto.balanceOf(account1)).toNumber()
        //console.log(balance)

        assert.equal(balance, expectedBSTBalance,
            "BST balance mismatch(week1)");

        //test week 2
        await timeController.addHours(rewardHours[0]+1);
        await boosto.sendTransaction(transaction(account2, oneEth));
        expectedBSTBalance = oneEth * coinsPerETH * (100 + rewardPerents[1]) / 100;

        var balance = (await boosto.balanceOf(account2)).toNumber()
        //console.log(balance)
        assert.equal(balance, expectedBSTBalance,
            "BST balance mismatch(week2)");

        // check minAmount
        await revertExpectedError(boosto.sendTransaction(transaction(account2, toWei(0.05))));
        assert.equal((await boosto.balanceOf(account2)).toNumber(), expectedBSTBalance,
            "BST balance mismatch after minAmount test");
    });

});