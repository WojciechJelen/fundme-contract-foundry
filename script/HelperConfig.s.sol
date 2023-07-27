// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// 1. Deploy mocks when we are on the local anvil chain
// 2. Keep track of the contract address accross chain

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeConfig = getSepholiaEthConfig();
        } else {
            activeConfig = getOrCreateAnvilEthConfig();
        }
    }

    // if we are on Anvil local chain, deploy mocks,
    // otherwise, use the real address
    function getSepholiaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepholiaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });

        return sepholiaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeConfig.priceFeed != address(0)) {
            return activeConfig;
        }

        vm.startBroadcast();
        // after broadcast: we are spending gas!
        // Mock
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
