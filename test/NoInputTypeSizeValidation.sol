// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

interface NoInputTypeSizeValidation {
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address addr) external view returns (uint256);
}

contract NoInputTypeSizeValidationTest is Test {
    NoInputTypeSizeValidation noInputTypeSizeValidation;

    error InsufficientBalance();
    error SendEtherFailed();

    function setUp() public {
        // deploy
        noInputTypeSizeValidation = NoInputTypeSizeValidation(
            (HuffDeployer.config().with_evm_version("paris").deploy("NoInputTypeSizeValidation"))
        );
        assertTrue(
            address(noInputTypeSizeValidation) != address(0) && address(noInputTypeSizeValidation).code.length > 0,
            "noInputTypeSizeValidation not deployed"
        );
    }

    function test_poc() external {
        vm.deal(address(this), 100 ether);

        /// ensure deposit works properly
        (bool success,) = payable(address(noInputTypeSizeValidation)).call{value: 1 ether}("");
        assertTrue(success, "Should successfully deposit");
        assertEq(noInputTypeSizeValidation.balanceOf(address(this)), 1 ether, "address(this) balance not updated 1");

        /// ensure transfer works properly
        noInputTypeSizeValidation.transfer(address(1111111111), 0.5 ether);
        assertEq(noInputTypeSizeValidation.balanceOf(address(this)), 0.5 ether, "address(this) balance not updated 2");
        assertEq(noInputTypeSizeValidation.balanceOf(address(1111111111)), 0.5 ether, "address(1111111111) not updated");

        // But if we call transfer with an address that has dirty upper 96 bits, it does not revert or truncate it for us
        // also meaning even the `to` would never be able to withdraw it as msg.sender always pushes at most type(uint160).max to the stack
        // let's test this
        uint256 addressWithThe161stBitDirty = 1111111111 + 2 ** 160; // This is obv greater than 160 bits and should be truncated in our contract but we do not do this in NoInputTypeSizeValidation contract
        // if truncated, it's still the same as address(1111111111)
        assertEq(address(1111111111), address(uint160(addressWithThe161stBitDirty)), "should be the same address");

        // call transfer with invalid address
        (success,) = address(noInputTypeSizeValidation).call(
            abi.encodePacked(
                NoInputTypeSizeValidation.transfer.selector, addressWithThe161stBitDirty, uint256(0.1 ether)
            )
        );
        assertTrue(success, "Should successfully transfer");

        // sender's balance reduces
        assertEq(noInputTypeSizeValidation.balanceOf(address(this)), 0.4 ether, "address(this) balance not updated 3");
        // supposed reciever gets nothing
        assertEq(
            noInputTypeSizeValidation.balanceOf(address(1111111111)), 0.5 ether, "address(1111111111) balance updated"
        );

        // there's a balance increase for invalid address
        // get balanceof
        bytes memory data = new bytes(0);
        (success, data) = address(noInputTypeSizeValidation).call(
            abi.encodePacked(
                NoInputTypeSizeValidation.balanceOf.selector, addressWithThe161stBitDirty, uint256(0.1 ether)
            )
        );
        assertTrue(success, "Should successfully check balance");
        assertEq(abi.decode(data, (uint256)), 0.1 ether, "addressWithThe161stBitDirty balance not updated");
    }

    receive() external payable {}
}
