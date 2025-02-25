// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNftTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNftAddress;

    event MintedCreditNft(
        address recipient,
        uint256 expiryBlock,
        uint256 amount
    );

    event BurnedCreditNft(
        address creditNftHolder,
        uint256 expiryBlock,
        uint256 amount
    );

    function setUp() public override {
        super.setUp();
        creditNftAddress = address(new CreditNft(manager));
    }

    function testMintCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        CreditNft(creditNftAddress).mintCreditNft(address(0x123), 1, 100);
    }

    function testMintCreditNft_ShouldMintCreditNft() public {
        address receiver = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 mintAmount = 1;

        uint256 init_balance = CreditNft(creditNftAddress).balanceOf(
            receiver,
            expiryBlockNumber
        );
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit MintedCreditNft(receiver, expiryBlockNumber, 1);
        CreditNft(creditNftAddress).mintCreditNft(
            receiver,
            mintAmount,
            expiryBlockNumber
        );
        uint256 last_balance = CreditNft(creditNftAddress).balanceOf(
            receiver,
            expiryBlockNumber
        );
        assertEq(last_balance - init_balance, mintAmount);

        uint256[] memory holderTokens = CreditNft(creditNftAddress)
            .holderTokens(receiver);
        assertEq(holderTokens[0], expiryBlockNumber);
    }

    function testBurnCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        CreditNft(creditNftAddress).burnCreditNft(address(0x123), 1, 100);
    }

    function testBurnCreditNft_ShouldBurnCreditNft() public {
        address creditNftOwner = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 burnAmount = 1;

        vm.prank(admin);
        CreditNft(creditNftAddress).mintCreditNft(
            creditNftOwner,
            10,
            expiryBlockNumber
        );
        uint256 init_balance = CreditNft(creditNftAddress).balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        vm.prank(creditNftOwner);
        CreditNft(creditNftAddress).setApprovalForAll(admin, true);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BurnedCreditNft(creditNftOwner, expiryBlockNumber, 1);
        CreditNft(creditNftAddress).burnCreditNft(
            creditNftOwner,
            burnAmount,
            expiryBlockNumber
        );
        uint256 last_balance = CreditNft(creditNftAddress).balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        assertEq(init_balance - last_balance, burnAmount);
    }

    function testUpdateTotalDebt_ShouldUpdateTotalDebt() public {
        vm.startPrank(admin);
        CreditNft(creditNftAddress).mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        CreditNft(creditNftAddress).mintCreditNft(address(0x222), 10, 20000);
        CreditNft(creditNftAddress).mintCreditNft(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(block.number + 15000);
        CreditNft(creditNftAddress).updateTotalDebt();
        uint256 outStandingTotalDebt = CreditNft(creditNftAddress)
            .getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 20);
    }

    function testGetTotalOutstandingDebt_ReturnTotalDebt() public {
        vm.startPrank(admin);
        CreditNft(creditNftAddress).mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        CreditNft(creditNftAddress).mintCreditNft(address(0x222), 10, 20000);
        CreditNft(creditNftAddress).mintCreditNft(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(block.number + 25000);
        CreditNft(creditNftAddress).updateTotalDebt();
        uint256 outStandingTotalDebt = CreditNft(creditNftAddress)
            .getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 10);
    }
}
