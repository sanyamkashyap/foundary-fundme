// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/fundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollerIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        uint256 amountfunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountfunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithSinglefunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();


        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new addredd
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            //Act
            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();
            vm.stopPrank();

            //Assert
            assert(address(fundMe).balance == 0);
            assert(
                startingFundMeBalance + startingOwnerBalance ==
                    fundMe.getOwner().balance
            );
        }
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new addredd
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            //Act
            vm.startPrank(fundMe.getOwner());
            fundMe.cheaperWithdraw();
            vm.stopPrank();

            //Assert
            assert(address(fundMe).balance == 0);
            assert(
                startingFundMeBalance + startingOwnerBalance ==
                    fundMe.getOwner().balance
            );
        }
    }
}
