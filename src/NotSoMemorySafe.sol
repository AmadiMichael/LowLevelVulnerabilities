// SPDX-License-Identifier: MIT
pragma solidity 0.8.x;

contract NotSoMmemorySafe0 {
    address owner;
    mapping(uint256 => uint256) public contributorIds;

    /// @dev This should return (msg.sender, msg.value) but it will instead return (contributoraId, 1)
    /// This is because the mapping read of `contributorIds[contributionId] += msg.value;`,
    /// since this is a 2D mapping, solidity uses the scratch space offsets of 0x00 and 0x20 to store the key and slot respectively before hashing to get the required storage slot
    /// This overrides what we stored mem offsets 0x00 and 0x20 while in the first assembly block.
    function deposit(uint256 contributionId) external payable returns (address, uint256) {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, callvalue())
        }

        contributorIds[contributionId] += msg.value;

        assembly {
            return(0x00, 0x40)
        }
    }
}

contract NotSoMmemorySafe1 {
    address owner;
    uint256[] public contributorIds;

    constructor() {
        // allow for 30 depositor ids
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
        contributorIds.push();
    }

    /// @dev This should return (msg.sender, msg.value) but it will instead return (1, msg.value)
    /// This is because the array read happening at `contributorIds[contributionId] += msg.value;`,
    /// solidity uses the scratch space offset of 0x00 to store the slot of the array before hashing and adding the contributionId to get the required storage slot
    /// This overrides what we stored in mem offset 0x00 while in the first assembly block.
    function deposit(uint256 contributionId) external payable returns (address, uint256) {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, callvalue())
        }

        contributorIds[contributionId] += msg.value;

        assembly {
            return(0x00, 0x40)
        }
    }
}
