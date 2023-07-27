// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE = 0.1 ether;
    DeployFundMe deployFundMe;
    FundMe fundMe;

    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // sends some eth to the user
        vm.deal(USER, START_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testRevertIfWeDontSendEnoughEth() public {
        vm.expectRevert("You need to spend more ETH!");
        fundMe.fund{value: 10}();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(); // next tx will be sent by USER
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 fundedValue = fundMe.getAddressToAmountFunded(USER);
        assertEq(fundedValue, SEND_VALUE);
    }

    function testAddFundersToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 ownerBalanceBefore = fundMe.getOwner().balance;
        uint256 fundmeBalanceBefore = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Test
        uint256 ownerBalanceAfter = fundMe.getOwner().balance;
        uint256 fundmeBalanceAfter = address(fundMe).balance;

        assertEq(ownerBalanceAfter, ownerBalanceBefore + fundmeBalanceBefore);
        assertEq(fundmeBalanceAfter, 0);
    }
}
