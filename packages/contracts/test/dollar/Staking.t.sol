// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract ZeroState is LiveTestHelper {
    event PriceReset(
        address _tokenWithdrawn,
        uint256 _amountWithdrawn,
        uint256 _amountTransferred
    );

    event Deposit(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount,
        uint256 _weeks,
        uint256 _endBlock
    );
    event RemoveLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _lpAmountTransferred,
        uint256 _lpRewards,
        uint256 _stakingShareAmount
    );

    event AddLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount
    );

    event StakingDiscountMultiplierUpdated(uint256 _stakingDiscountMultiplier);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);

    event Migrated(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpsAmount,
        uint256 _sharesAmount,
        uint256 _weeks
    );
    event DustSent(address _to, address _token, uint256 _amount);
    event ProtocolTokenAdded(address _token);
    event ProtocolTokenRemoved(address _token);
    event Paused(address _caller);
    event Unpaused(address _caller);

    address[] ogs;
    address[] ogsEmpty;
    uint256[] balances;
    uint256[] lockup;

    function setUp() public virtual override {
        super.setUp();
        deal(address(metapool), fourthAccount, 1000e18);
        ogs.push(secondAccount);
        ogs.push(thirdAccount);
        balances.push(1);
        balances.push(1);
        lockup.push(1);
        lockup.push(1);
    }
}

contract RemoteZeroStateTest is ZeroState {
    using stdStorage for StdStorage;

    function testAddUserToMigrate_ShouldWork(uint256 x, uint256 y) public {
        x = bound(x, 1, 2 ** 128 - 1);
        y = bound(y, 1, 208);

        vm.prank(admin);
        vm.record();
        staking.addUserToMigrate(fourthAccount, x, y);

        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(
            address(staking)
        );

        address checkAddress = address(
            bytes20(vm.load(address(staking), writes[1]) << 96)
        );
        uint256 checkLP = uint256(vm.load(address(staking), writes[3]));
        uint256 checkWeeks = uint256(vm.load(address(staking), writes[6]));

        assertEq(fourthAccount, checkAddress);
        assertEq(x, checkLP);
        assertEq(y, checkWeeks);
    }

    function test_ShouldRevert_IfDeployingAnEmptyAddress() public {
        vm.expectRevert("address array empty");
        Staking broken = new Staking(
            manager,
            stakingFormulas,
            ogsEmpty,
            balances,
            lockup
        );
    }

    function test_ShouldRevert_IfBalancesArrayNotSameLength() public {
        balances.push(1);
        vm.expectRevert("balances array not same length");
        Staking broken = new Staking(
            manager,
            stakingFormulas,
            ogs,
            balances,
            lockup
        );
    }

    function test_ShouldRevert_IfWeeksArrayNotSameLength() public {
        lockup.push(1);
        vm.expectRevert("weeks array not same length");
        Staking broken = new Staking(
            manager,
            stakingFormulas,
            ogs,
            balances,
            lockup
        );
    }

    function testSetMigrator_ShouldSetMigrator() public {
        vm.prank(admin);
        staking.setMigrator(secondAccount);
        assertEq(secondAccount, staking.migrator());
    }

    function testSetMigrator_ShouldRevert_IfNotMigrator() public {
        vm.expectRevert("not migrator");
        vm.prank(secondAccount);
        staking.setMigrator(fourthAccount);
    }

    function testSetMigrating_ShouldSetMigratingValue() public {
        assertEq(true, staking.migrating());
        vm.prank(admin);
        staking.setMigrating(false);
        assertEq(false, staking.migrating());
    }

    function testSetMigrating_ShouldRevert_IfNotMigrator() public {
        vm.expectRevert("not migrator");
        vm.prank(secondAccount);
        staking.setMigrating(false);
    }

    function testSetStakingFormulaAddress_ShouldSetStakingFormulaAddressValue()
        public
    {
        assertEq(
            bytes20(address(stakingFormulas)),
            bytes20(address(staking.stakingFormulas()))
        );
        vm.startPrank(admin);
        StakingFormulas stake = new StakingFormulas();
        staking.setStakingFormulas(stake);
        vm.stopPrank();

        assertEq(
            bytes20(address(stake)),
            bytes20(address(staking.stakingFormulas()))
        );
    }

    function testCannotSetStakingFormula_ShouldRevertWhenNotManager() public {
        vm.startPrank(secondAccount);
        StakingFormulas stake = new StakingFormulas();
        vm.expectRevert("not manager");
        staking.setStakingFormulas(stake);
        vm.stopPrank();
    }

    function testAddProtocolToken_ShouldEmitProtocolTokenAddedAndAddProtocolToken()
        public
    {
        emit ProtocolTokenAdded(address(DAI));
        vm.prank(admin);
        staking.addProtocolToken(address(DAI));
    }

    function testAddProtocolToken_ShouldRevert_IfTokenIsPartOfTheProtocol()
        public
    {
        vm.prank(admin);
        staking.addProtocolToken(address(DAI));

        vm.expectRevert("collectable-dust::token-is-part-of-the-protocol");
        vm.prank(admin);
        staking.addProtocolToken(address(DAI));
    }

    function testAddProtocolTokenNotManager_ShouldRevert_IfNotManager() public {
        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.addProtocolToken(secondAccount);
    }

    function testRemoveProtocolToken_ShouldEmitProtocolTokenRemovedAndRemoveProtocolToken()
        public
    {
        vm.startPrank(admin);
        staking.addProtocolToken(address(DAI));
        vm.stopPrank();

        vm.expectEmit(true, false, false, true);
        emit ProtocolTokenRemoved(address(DAI));

        vm.startPrank(admin);
        staking.removeProtocolToken(address(DAI));
        vm.stopPrank();
    }

    function testRemoveProtocolToken_ShouldRevert_IfTokenIsNotPartOfTheProtocol()
        public
    {
        vm.expectRevert("collectable-dust::token-not-part-of-the-protocol");
        vm.prank(admin);
        staking.removeProtocolToken(address(DAI));
    }

    function testRemoveProtocolToken_ShouldRevert_IfNotManager() public {
        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.removeProtocolToken(secondAccount);
    }

    function testSendDust_ShouldEmitDustSentAndSendDust() public {
        vm.expectEmit(true, false, false, true);
        emit DustSent(fourthAccount, address(dollarToken), 1e18);

        vm.startPrank(admin);
        staking.sendDust(fourthAccount, address(dollarToken), 1e18);
        vm.stopPrank();
    }

    function testSendDust_ShouldRevert_IfZeroAddress() public {
        vm.expectRevert("collectable-dust::cant-send-dust-to-zero-address");
        vm.startPrank(admin);
        staking.sendDust(address(0), address(dollarToken), 1e18);
    }

    function testSendDust_ShouldRevert_IfTokenIsNotPartOfTheProtocol() public {
        vm.prank(admin);
        staking.addProtocolToken(address(dollarToken));

        vm.expectRevert("collectable-dust::token-is-part-of-the-protocol");
        vm.startPrank(admin);
        staking.sendDust(fourthAccount, address(dollarToken), 1e18);
    }

    function testSendDust_ShouldRevert_IfNotManager() public {
        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.sendDust(fourthAccount, address(dollarToken), 1e18);
    }

    function testPause_ShouldEmitPausedAndPause() public {
        vm.expectEmit(true, false, false, true);
        emit Paused(admin);

        vm.prank(admin);
        staking.pause();
    }

    function testUnpause_ShouldEmitsUnpausedAndUnpause() public {
        vm.prank(admin);
        staking.pause();

        vm.expectEmit(true, false, false, true);
        emit Unpaused(admin);

        vm.prank(admin);
        staking.unpause();
    }

    function testMigrate_ShouldRevert_IfZeroId() public {
        vm.expectRevert("not v1 address");
        vm.prank(fourthAccount);
        staking.migrate();
    }

    function testSetStakingDiscountMultiplier_ShouldEmitStakingDiscountMultiplierUpdatedAndSetStakingDiscountMultiplier(
        uint256 x
    ) public {
        vm.expectEmit(true, false, false, true);
        emit StakingDiscountMultiplierUpdated(x);
        vm.prank(admin);
        staking.setStakingDiscountMultiplier(x);
        assertEq(x, staking.stakingDiscountMultiplier());
    }

    function testSetStakingDiscountMultiplier_ShouldRevert_IfNotManager(
        uint256 x
    ) public {
        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.setStakingDiscountMultiplier(x);
    }

    function testSetBlockCountInAWeek_ShouldEmitBlockCountInAWeekUpdatedAndSetBlockCountInAWeek(
        uint256 x
    ) public {
        vm.expectEmit(true, false, false, true);
        emit BlockCountInAWeekUpdated(x);
        vm.prank(admin);
        staking.setBlockCountInAWeek(x);
        assertEq(x, staking.blockCountInAWeek());
    }

    function testSetBlockCountInAWeek_ShouldRevert_IfNotManager(
        uint256 x
    ) public {
        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.setBlockCountInAWeek(x);
    }

    function testDeposit_ShouldDeposit(
        uint256 lpAmount,
        uint256 lockup
    ) public {
        lpAmount = bound(lpAmount, 1, 100e18);
        lockup = bound(lockup, 1, 208);
        uint256 preBalance = metapool.balanceOf(stakingMinAccount);
        vm.expectEmit(true, false, false, true);
        emit Deposit(
            stakingMinAccount,
            stakingShare.totalSupply(),
            lpAmount,
            IUbiquityFormulas(manager.formulasAddress()).durationMultiply(
                lpAmount,
                lockup,
                staking.stakingDiscountMultiplier()
            ),
            lockup,
            (block.number + lockup * staking.blockCountInAWeek())
        );
        vm.startPrank(stakingMinAccount);
        metapool.approve(address(staking), 2 ** 256 - 1);
        staking.deposit(lpAmount, lockup);
        assertEq(metapool.balanceOf(stakingMinAccount), preBalance - lpAmount);
    }

    function testLockupMultiplier() public {
        uint256 minLP = metapool.balanceOf(stakingMinAccount);
        uint256 maxLP = metapool.balanceOf(stakingMaxAccount);
        /*minAmount = bound(minAmount, 1e9, minLP);
        maxAmount = bound(maxAmount, minAmount, maxLP);*/

        vm.startPrank(stakingMaxAccount);
        metapool.approve(address(staking), 2 ** 256 - 1);
        staking.deposit(maxLP, 208);
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        metapool.approve(address(staking), 2 ** 256 - 1);
        staking.deposit(minLP, 1);
        vm.stopPrank();

        uint256[2] memory bsMaxAmount = ubiquityChef.getStakingShareInfo(1);
        uint256[2] memory bsMinAmount = ubiquityChef.getStakingShareInfo(2);

        assertLt(bsMinAmount[0], bsMaxAmount[0]);
    }

    function testDeposit_ShouldRevert_IfMoreThan4Years(uint256 _weeks) public {
        _weeks = bound(_weeks, 209, 2 ** 256 - 1);
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        staking.deposit(1, _weeks);
    }

    function testDeposit_ShouldRevert_IfZeroWeeks() public {
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        staking.deposit(1, 0);
    }
}

contract DepositState is ZeroState {
    function setUp() public virtual override {
        super.setUp();
        address[3] memory depositingAccounts = [
            stakingMinAccount,
            fourthAccount,
            stakingMaxAccount
        ];
        uint256[3] memory depositAmounts = [
            metapool.balanceOf(stakingMinAccount),
            metapool.balanceOf(fourthAccount),
            metapool.balanceOf(stakingMaxAccount)
        ];
        uint256[3] memory lockupWeeks = [uint256(1), uint256(52), uint256(208)];

        for (uint256 i; i < depositingAccounts.length; ++i) {
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(staking), 2 ** 256 - 1);
            staking.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
        twapOracle.update();
    }
}

contract RemoteDepositStateTest is DepositState {
    address[] path1;
    address[] path2;

    function testDollarPriceReset_ShouldRevert_IfNotManager(
        uint256 amount
    ) public {
        amount = bound(
            amount,
            1000e18,
            dollarToken.balanceOf(address(metapool)) / 10
        );

        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.dollarPriceReset(amount);
    }

    function testDollarPriceReset_ShouldResetDollarPrice(
        uint256 amount
    ) public {
        amount = bound(
            amount,
            1000e18,
            dollarToken.balanceOf(address(metapool)) / 10
        );

        uint256 dollarPreBalance = dollarToken.balanceOf(address(metapool));

        vm.expectEmit(true, false, false, false, address(staking));
        emit PriceReset(address(dollarToken), 1000e18, 1000e18);
        vm.prank(admin);
        staking.dollarPriceReset(amount);

        uint256 dollarPostBalance = dollarToken.balanceOf(address(metapool));

        assertLt(dollarPostBalance, dollarPreBalance);
    }

    function testCRVPriceReset_ShouldResetCRVPrice(uint256 amount) public {
        amount = bound(
            amount,
            1000e18,
            crvToken.balanceOf(address(metapool)) / 10
        );
        uint256 crvPreBalance = crvToken.balanceOf(address(metapool));

        vm.expectEmit(true, false, false, false, address(staking));
        emit PriceReset(address(crvToken), amount, amount);
        vm.prank(admin);
        staking.crvPriceReset(amount);

        uint256 crvPostBalance = crvToken.balanceOf(address(metapool));
        assertLt(crvPostBalance, crvPreBalance);
    }

    function testCRVPriceReset_ShouldRevert_IfNotManager(
        uint256 amount
    ) public {
        amount = bound(
            amount,
            1000e18,
            crvToken.balanceOf(address(metapool)) / 10
        );

        vm.expectRevert("not manager");
        vm.prank(secondAccount);
        staking.crvPriceReset(amount);
    }

    function testAddLiquidity_ShouldAddLiquidity(
        uint256 amount,
        uint256 weeksLockup
    ) public {
        weeksLockup = bound(weeksLockup, 1, 208);
        amount = bound(amount, 1e18, 2 ** 128 - 1);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        uint256[2] memory preShares = ubiquityChef.getStakingShareInfo(1);
        deal(address(metapool), stakingMinAccount, uint256(amount));
        vm.roll(20000000);
        vm.expectEmit(true, true, false, false, address(staking));
        emit AddLiquidityFromStake(
            stakingMinAccount,
            1,
            amount,
            ubiquityFormulas.durationMultiply(
                stake.lpAmount + amount,
                weeksLockup,
                staking.stakingDiscountMultiplier()
            )
        );
        vm.prank(stakingMinAccount);
        staking.addLiquidity(uint256(amount), 1, weeksLockup);
        uint256[2] memory postShares = ubiquityChef.getStakingShareInfo(1);
        assertGt(postShares[0], preShares[0]);
    }

    function testRemoveLiquidity_ShouldRemoveLiquidity(uint256 amount) public {
        vm.roll(20000000);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        amount = bound(amount, 1, stake.lpAmount);

        uint256 preBal = metapool.balanceOf(stakingMinAccount);
        vm.expectEmit(true, false, false, false, address(staking));
        emit RemoveLiquidityFromStake(
            stakingMinAccount,
            1,
            amount,
            amount,
            amount,
            amount
        );
        vm.prank(stakingMinAccount);
        staking.removeLiquidity(amount, 1);
        uint256 postBal = metapool.balanceOf(stakingMinAccount);

        assertEq(preBal + amount, postBal);
    }

    function testPendingLPRewards_ShouldReturn_PendingLPRewards() public {
        uint256 prePending = staking.pendingLpRewards(3);

        deal(address(metapool), address(staking), 1000000e18);

        uint256 postPending = staking.pendingLpRewards(3);
        assertGt(postPending, prePending);
    }

    function testRemoveLiquidity_ShouldRevert_IfAmountIsMoreThanBalance(
        uint256 amount
    ) public {
        vm.roll(20000000);
        StakingShare.Stake memory stake = stakingShare.getStake(2);
        amount = bound(amount, stake.lpAmount + 1, 2 ** 256 - 1);
        vm.expectRevert("Staking: amount too big");
        vm.prank(fourthAccount);
        staking.removeLiquidity(amount, 2);
    }

    function testRemoveLiquidity_ShouldRevert_IfNotOwner() public {
        vm.roll(20000000);
        vm.expectRevert("Staking: caller is not owner");
        vm.prank(stakingMinAccount);
        staking.removeLiquidity(1, 2);
    }

    function testRemoveLiquidity_ShouldRevert_IfStakeNotExpired() public {
        vm.expectRevert("Staking: Redeem not allowed before staking time");
        vm.prank(stakingMaxAccount);
        staking.removeLiquidity(1, 3);
    }
}
