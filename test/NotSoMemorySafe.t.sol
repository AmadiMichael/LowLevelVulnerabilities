// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {NotSoMmemorySafe0, NotSoMmemorySafe1} from "src/NotSoMemorySafe.sol";
import {Test} from "forge-std/Test.sol";

contract NotSoMmemorySafeTest is Test {
    NotSoMmemorySafe0 notSoMmemorySafe0;
    NotSoMmemorySafe1 notSoMmemorySafe1;

    function setUp() public {
        notSoMmemorySafe0 = new NotSoMmemorySafe0();
        notSoMmemorySafe1 = new NotSoMmemorySafe1();
    }

    function test_poc() external {
        // It is meant to return (address(this), 1 ether) but due to the bug will return (address(contributionId), uint256(contributorIds.slot))
        (address addr, uint256 amount) = notSoMmemorySafe0.deposit{value: 1 ether}({contributionId: 42});
        assertEq(addr, address(42));
        assertEq(amount, 1);

        // It is meant to return (address(this), 1 ether) but due to the bug will return (address(contributorIds.slot), 1 ether)
        (addr, amount) = notSoMmemorySafe1.deposit{value: 1 ether}({contributionId: 24});
        assertEq(addr, address(1));
        assertEq(amount, 1 ether);
    }
}
