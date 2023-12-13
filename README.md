# LOW LEVEL VULNERABILITIES AND POCs

Examples and POCs of Vulnerabilities that are unique to EVM contracts written without the guardrails of higher level languages like solidity or vyper

## Validate that inputs are of the right bit size and format and either revert or clean the unused bits depending on your use case before using that value

- The file `src/NoInputValidation.huff` holds a contract vulnerable to this and `test/NoInputValidation.t.sol` holds the POC for it. The vulnerability can lead to permanent loss of funds when transfer is called with the an address greater than 160 bits. Normally this should be checked and revert if the bit size of the expected type (in this case an address) is less than the bit size of what was sent. e.g

```rs
#define macro TRANSFER_IMPL() = {
    // get to from calldata
    0x04                                          // [0x04]
    calldataload                                  // [to]
    dup1                                          // [to]

    // if 2**160 > to continue, else revert
    0x10000000000000000000000000000000000000000   // [(2**160), to, to]
    gt                                            // [((2**160) > to)  to]
    revert_bad_address                            // [revert_bad_address, ((2**160) > to)  to]
    jumpi                                         // [to]

    // ... continue code and jump to exit_execution when done

    revert_bad_address:
        0x00 0x00 revert

    exit_execution:
        exit
}
```
