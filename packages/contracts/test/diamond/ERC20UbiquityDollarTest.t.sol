// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./DiamondTestSetup.sol";
import "../../src/diamond/libraries/Constants.sol";

contract ERC20UbiquityDollarTest is DiamondSetup {
    address token_addr;
    address dollar_manager_addr;
    event Minting(
        address indexed mock_addr1,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    function setUp() public override {
        super.setUp();
        token_addr = address(diamond);
        dollar_manager_addr = address(diamond);
    }

    function testSetSymbol_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("ERC20Ubiquity: not admin");
        IDollar.setSymbol("ANY_SYMBOL");
    }

    function testSetSymbol_ShouldSetSymbol() public {
        vm.prank(admin);
        IDollar.setSymbol("ANY_SYMBOL");
        assertEq(IDollar.symbol(), "ANY_SYMBOL");
    }

    function testSetName_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("ERC20Ubiquity: not admin");
        IDollar.setName("ANY_NAME");
    }

    function testSetName_ShouldSetName() public {
        vm.prank(admin);
        IDollar.setName("ANY_NAME");
        assertEq(IDollar.name(), "ANY_NAME");
    }

    function testPermit_ShouldRevert_IfDeadlineExpired() public {
        // create owner and spender addresses
        uint256 ownerPrivateKey = 0x1;
        uint256 spenderPrivateKey = 0x2;
        address curOwner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                IDollar.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        curOwner,
                        spender,
                        1e18,
                        IDollar.nonces(curOwner),
                        0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: EXPIRED");
        IDollar.permit(curOwner, spender, 1e18, 0, v, r, s);
    }

    function testPermit_ShouldRevert_IfSignatureIsInvalid() public {
        // create owner and spender addresses
        uint256 ownerPrivateKey = 0x1;
        uint256 spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                IDollar.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        1e18,
                        IDollar.nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: INVALID_SIGNATURE");
        IDollar.permit(owner, spender, 1e18, block.timestamp + 1 days, v, r, s);
    }

    function testPermit_ShouldIncreaseSpenderAllowance() public {
        // create owner and spender addresses
        uint256 ownerPrivateKey = 0x1;
        uint256 spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                IDollar.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        1e18,
                        IDollar.nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        uint256 noncesBefore = IDollar.nonces(owner);
        vm.prank(spender);
        IDollar.permit(owner, spender, 1e18, block.timestamp + 1 days, v, r, s);
        assertEq(IDollar.allowance(owner, spender), 1e18);
        assertEq(IDollar.nonces(owner), noncesBefore + 1);
    }

    function testBurn_ShouldRevert_IfContractIsPaused() public {
        vm.prank(admin);
        IDollar.pause();
        vm.expectRevert("Pausable: paused");
        IDollar.burn(50);
    }

    function testBurn_ShouldBurnTokens() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IDollar.mint(mockAddress, 100);
        assertEq(IDollar.balanceOf(mockAddress), 100);
        // burn 50 tokens from user
        vm.prank(mockAddress);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        IDollar.burn(50);
        assertEq(IDollar.balanceOf(mockAddress), 50);
    }

    function testBurnFrom_ShouldRevert_IfCalledNotByTheBurnerRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Dollar token: not burner");
        IDollar.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldRevert_IfContractIsPaused() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IDollar.mint(mockAddress, 100);
        assertEq(IDollar.balanceOf(mockAddress), 100);
        // create burner role
        address burner = address(0x2);
        vm.prank(admin);
        IAccessCtrl.grantRole(keccak256("DOLLAR_TOKEN_BURNER_ROLE"), burner);
        // admin pauses contract
        vm.prank(admin);
        IDollar.pause();
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectRevert("Pausable: paused");
        IDollar.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldBurnTokensFromAddress() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IDollar.mint(mockAddress, 100);
        assertEq(IDollar.balanceOf(mockAddress), 100);
        // create burner role
        address burner = address(0x2);
        vm.prank(admin);
        IAccessCtrl.grantRole(keccak256("DOLLAR_TOKEN_BURNER_ROLE"), burner);
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        IDollar.burnFrom(mockAddress, 50);
        assertEq(IDollar.balanceOf(mockAddress), 50);
    }

    function testMint_ShouldRevert_IfCalledNotByTheMinterRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Dollar token: not minter");
        IDollar.mint(mockAddress, 100);
    }

    function testMint_ShouldRevert_IfContractIsPaused() public {
        vm.startPrank(admin);
        IDollar.pause();
        address mockAddress = address(0x1);
        vm.expectRevert("Pausable: paused");
        IDollar.mint(mockAddress, 100);
        vm.stopPrank();
    }

    function testMint_ShouldMintTokens() public {
        address mockAddress = address(0x1);
        uint256 balanceBefore = IDollar.balanceOf(mockAddress);
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Minting(mockAddress, admin, 100);
        IDollar.mint(mockAddress, 100);
        uint256 balanceAfter = IDollar.balanceOf(mockAddress);
        assertEq(balanceAfter - balanceBefore, 100);
    }

    function testPause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("ERC20Ubiquity: not pauser");
        IDollar.pause();
    }

    function testPause_ShouldPauseContract() public {
        assertFalse(IDollar.paused());
        vm.prank(admin);
        IDollar.pause();
        assertTrue(IDollar.paused());
    }

    function testUnpause_ShouldRevert_IfCalledNotByThePauserRole() public {
        // admin pauses contract
        vm.prank(admin);
        IDollar.pause();
        vm.expectRevert("ERC20Ubiquity: not pauser");
        IDollar.unpause();
    }

    function testUnpause_ShouldUnpauseContract() public {
        vm.startPrank(admin);
        IAccessCtrl.pause();
        assertTrue(IAccessCtrl.paused());
        IAccessCtrl.unpause();
        assertFalse(IAccessCtrl.paused());
        vm.stopPrank();
    }

    function testName_ShouldReturnTokenName() public {
        // cspell: disable-next-line
        assertEq(IDollar.name(), "Ubiquity Algorithmic Dollar");
    }

    function testSymbol_ShouldReturnSymbolName() public {
        // cspell: disable-next-line
        assertEq(IDollar.symbol(), "uAD");
    }

    function testTransfer_ShouldRevert_IfContractIsPaused() public {
        // admin pauses contract
        vm.prank(admin);
        IDollar.pause();
        // transfer tokens to user
        address userAddress = address(0x1);
        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        IDollar.transfer(userAddress, 10);
    }

    function testTransferFrom_ShouldRevert_IfContractIsPaused() public {
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        vm.prank(admin);
        IDollar.mint(userAddress, 100);
        // admin pauses contract
        vm.prank(admin);
        IDollar.pause();
        vm.prank(userAddress);
        IDollar.approve(user2Address, 100);
        vm.expectRevert("Pausable: paused");
        vm.prank(user2Address);
        IDollar.transferFrom(userAddress, user2Address, 100);
    }

    function testTransfer_ShouldTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollar.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        assertEq(IDollar.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollar.transfer(userAddress, 10);
        assertEq(IDollar.balanceOf(userAddress), 10);
    }

    // test transferFrom function should transfer tokens from address
    function testTransferFrom_ShouldTransferTokensFromAddress() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollar.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        assertEq(IDollar.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollar.transfer(userAddress, 100);
        assertEq(IDollar.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        IDollar.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        IDollar.transferFrom(userAddress, user2Address, 100);
        assertEq(IDollar.balanceOf(userAddress), 0);
        assertEq(IDollar.balanceOf(user2Address), 100);
    }

    // test approve function should approve address to transfer tokens
    function testApprove_ShouldApproveAddressToTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollar.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        assertEq(IDollar.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollar.transfer(userAddress, 100);
        assertEq(IDollar.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        IDollar.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        IDollar.transferFrom(userAddress, user2Address, 100);
        assertEq(IDollar.balanceOf(userAddress), 0);
        assertEq(IDollar.balanceOf(user2Address), 100);
    }

    // test allowance function should return allowance
    function testAllowance_ShouldReturnAllowance() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollar.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        assertEq(IDollar.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollar.transfer(userAddress, 100);
        assertEq(IDollar.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        IDollar.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        IDollar.transferFrom(userAddress, user2Address, 100);
        assertEq(IDollar.balanceOf(userAddress), 0);
        assertEq(IDollar.balanceOf(user2Address), 100);
        assertEq(IDollar.allowance(userAddress, user2Address), 0);
    }
}
