// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 20 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public {
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

    function testOnlyOnwnerCanWithdraw() public funded {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnderBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnderBalance
        );
    }

    function testWithdrawfromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFounders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFounders; i++) {
            //vm prank new address
            //vm deal new address
            //address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            //act
            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();
            vm.stopPrank();

            //assert
            assert(address(fundMe).balance == 0);
            assert(
                startingFundMeBalance + startingOwnerBalance ==
                    fundMe.getOwner().balance
            );
        }
    }

    function testWithdrawfromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFounders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFounders; i++) {
            //vm prank new address
            //vm deal new address
            //address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            //act
            vm.startPrank(fundMe.getOwner());
            fundMe.cheaperWithdraw();
            vm.stopPrank();

            //assert
            assert(address(fundMe).balance == 0);
            assert(
                startingFundMeBalance + startingOwnerBalance ==
                    fundMe.getOwner().balance
            );
        }
    }
}

//tests
//unit- specific part of the code. ie one function
//Integration test - how it works with other oarts of the code
//forked test - simulated real environment
//staging test - in real env that is not prod.
