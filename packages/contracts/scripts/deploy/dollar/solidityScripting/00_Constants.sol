// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "src/dollar/core/CreditNft.sol";
import "src/dollar/core/CreditNftManager.sol";
import "src/dollar/core/CreditNftRedemptionCalculator.sol";
import "src/dollar/core/CreditRedemptionCalculator.sol";
import "src/dollar/core/DollarMintCalculator.sol";
import "src/dollar/core/DollarMintExcess.sol";
import "src/dollar/core/TWAPOracleDollar3pool.sol";
import "src/dollar/core/UbiquityCreditToken.sol";
import "src/dollar/core/UbiquityDollarManager.sol";
import "src/dollar/core/UbiquityDollarToken.sol";
import "src/dollar/core/UbiquityGovernanceToken.sol";
import "src/dollar/interfaces/IMetaPool.sol";

import "src/dollar/DirectGovernanceFarmer.sol";
import "src/dollar/Staking.sol";
import "src/dollar/StakingFormulas.sol";
import "src/dollar/StakingShare.sol";
import "src/dollar/UbiquityChef.sol";
import "src/dollar/UbiquityFormulas.sol";

import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Script.sol";

contract Constants is Script {
    uint256[] shareAmounts;
    uint256[] ids;

    string uri;
    address curve3PoolToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address basePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address curveFactory = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4;
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address admin = vm.envAddress("PUBLIC_KEY");

    address[] public users = [
        0x89eae71B865A2A39cBa62060aB1b40bbFFaE5b0D,
        0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd,
        0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6,
        0x7c76f4DB70b7E2177de10DE3e2f668daDcd11108,
        0x4007CE2083c7F3E18097aeB3A39bb8eC149a341d,
        0xf6501068a54f3EAb46C1F145CB9d3fb91658B220,
        0x10693e86f2e7151B3010469E33b6C1C2dA8887d6,
        0xCEFD0E73cC48B0b9d4C8683E52B7d7396600AbB2,
        0xD028BaBBdC15949aAA35587f95F9E96c7d49417D,
        0x9968eFe1424D802e1f79FD8aF8dA67b0f08C814d,
        0xd3BC13258e685df436715104882888d087f87ED8,
        0x0709B103d46d71458a71e5d81230DD688809A53D,
        0xE3E39161d35E9A81edEc667a5387bfAE85752854,
        0x7c361828849293684DdF7212Fd1d2Cb5f0aADe70,
        0x9d3F4EEB533B8e3C8f50dbbD2E351D1BF2987908,
        0x865Dc9A621B50534BA3d17e0Ea8447C315E31886,
        0x324E0b53CefA84CF970833939249880f814557c6,
        0xcE156D5d62a8F82326dA8d808D0f3F76360036D0,
        0x26bdDe6506bd32bD7B5Cc5C73cd252807fF18568,
        0xD6EfC21d8c941AA06F90075dE1588ac7E912Fec6,
        0xe0D62CC9233C7E2F1f23fE8C77D6b4D1a265D7Cd,
        0x0B54B916E90b8f28ad21dA40638E0724132C9c93,
        0x629cd43eAF443e66A9a69ED246728E1001289EAC,
        0x0709e442A5469B88bB090dD285b1B3a63fb0c226,
        0x94A2fFDbDbD84984AC7967878C5C397126E7BBBe,
        0x51EC66e63199176f59C80268e0Be6fFa91Fab220,
        0x0a71e650F70B35fca8b70e71E4441df8D44E01e9,
        0xC1b6052E707dfF9017DEAb13ae9B89008FC1Fc5d,
        0x9be95ef84676393588e49Ad8B99c9d4CdFdAA631,
        0xFFFFF6E70842330948Ca47254F2bE673B1cb0dB7,
        0x0000CE08fa224696A819877070BF378e8B131ACF,
        0xC2cb4B1bCAEbAa78c8004e394CF90BA07A61C8f7,
        0xB2812370f17465AE096Ced55679428786734a678,
        0x3eb851c3959F0d37E15C2d9476C4ADb46d5231D1,
        0xad286cF287b91719eE85d3ba5cF3DA483D631Dba,
        0xbD37A957773D883186B989f6b21c209459022252
    ];

    uint256[] public lpAmounts = [
        1301000000000000000,
        3500000000000000000000,
        9351040526163838324896,
        44739174270101943975392,
        74603879373206500005186,
        2483850000000000000000,
        1878674425540571814543,
        8991650309086743220575,
        1111050988607803612915,
        4459109737462155546375,
        21723000000000000000000,
        38555895255762442000000,
        5919236274824521937931,
        1569191092350025897388,
        10201450658519659933880,
        890339946944155414434,
        5021119790948940093253,
        761000000000000000000,
        49172294677407855270013,
        25055256356185888278372,
        1576757078627228869179,
        3664000000000000000000,
        1902189597146391302863,
        34959771702943278635904,
        9380006436252701023610,
        6266995559166564365470,
        100000000000000000000,
        3696476262155265118082,
        740480000000000000000,
        2266000000000000000000,
        1480607760433248019987,
        24702171480214199310951,
        605000000000000000000,
        1694766661387270251234,
        14857000000000000000000,
        26000000000000000000
    ];

    uint256[] public terms = [
        176,
        30,
        208,
        208,
        208,
        32,
        208,
        208,
        4,
        1,
        67,
        208,
        208,
        109,
        12,
        29,
        1,
        1,
        3,
        4,
        7,
        1,
        128,
        2,
        4,
        3,
        208,
        6,
        1,
        208,
        2,
        1,
        12,
        208,
        4,
        208
    ];
}
