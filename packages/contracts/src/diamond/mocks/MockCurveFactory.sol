// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ICurveFactory} from "../../dollar/interfaces/ICurveFactory.sol";
import {MockMetaPool} from "../../dollar/mocks/MockMetaPool.sol";

contract MockCurveFactory is ICurveFactory {
    // solhint-disable-next-line no-empty-blocks
    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee
    ) external returns (address) {
        MockMetaPool metaPoolAddress = new MockMetaPool(
            _coin,
            MockMetaPool(_base_pool).coins(1)
        );
        return address(metaPoolAddress);
    }

    function find_pool_for_coins(
        address _from,
        address _to
    ) external view returns (address) {}

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external view returns (address) {}

    function get_n_coins(
        address _pool
    ) external view returns (uint256, uint256) {}

    function get_coins(
        address _pool
    ) external view returns (address[2] memory) {}

    function get_underlying_coins(
        address _pool
    ) external view returns (address[8] memory) {}

    function get_decimals(
        address _pool
    ) external view returns (uint256[2] memory) {}

    function get_underlying_decimals(
        address _pool
    ) external view returns (uint256[8] memory) {}

    function get_rates(
        address _pool
    ) external view returns (uint256[2] memory) {}

    function get_balances(
        address _pool
    ) external view returns (uint256[2] memory) {}

    function get_underlying_balances(
        address _pool
    ) external view returns (uint256[8] memory) {}

    function get_A(address _pool) external view returns (uint256) {}

    function get_fees(address _pool) external view returns (uint256, uint256) {}

    function get_admin_balances(
        address _pool
    ) external view returns (uint256[2] memory) {}

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (int128, int128, bool) {}

    function add_base_pool(
        address _base_pool,
        address _metapool_implementation,
        address _fee_receiver
    ) external {}

    function commit_transfer_ownership(address addr) external {}

    function accept_transfer_ownership() external {}

    function set_fee_receiver(
        address _base_pool,
        address _fee_receiver
    ) external {}

    function convert_fees() external returns (bool) {}

    function admin() external view returns (address) {}

    function future_admin() external view returns (address) {}

    function pool_list(uint256 arg0) external view returns (address) {}

    function pool_count() external view returns (uint256) {}

    function base_pool_list(uint256 arg0) external view returns (address) {}

    function base_pool_count() external view returns (uint256) {}

    function fee_receiver(address arg0) external view returns (address) {}
}
