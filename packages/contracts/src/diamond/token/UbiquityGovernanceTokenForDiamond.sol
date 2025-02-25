// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ERC20UbiquityForDiamond} from "./ERC20UbiquityForDiamond.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import "../libraries/Constants.sol";

contract UbiquityGovernanceTokenForDiamond is ERC20UbiquityForDiamond {
    constructor(
        address _diamond
    )
        // cspell: disable-next-line
        ERC20UbiquityForDiamond(_diamond, "Ubiquity", "UBQ")
    {} // solhint-disable-line no-empty-blocks, max-line-length

    // ----------- Modifiers -----------
    modifier onlyGovernanceMinter() {
        require(
            accessCtrl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, msg.sender),
            "Governance token: not minter"
        );
        _;
    }

    modifier onlyGovernanceBurner() {
        require(
            accessCtrl.hasRole(GOVERNANCE_TOKEN_BURNER_ROLE, msg.sender),
            "Governance token: not burner"
        );
        _;
    }

    /// @notice burn Ubiquity Dollar tokens from specified account
    /// @param account the account to burn from
    /// @param amount the amount to burn
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyGovernanceBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    // @dev Creates `amount` new tokens for `to`.
    function mint(
        address to,
        uint256 amount
    ) public override onlyGovernanceMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, msg.sender, amount);
    }
}
