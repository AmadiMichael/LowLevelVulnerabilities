# Low level vulnerabilities & POCs

Examples and POCs of Vulnerabilities that are unique to EVM contracts written without the guardrails of higher level languages like solidity or vyper. Still adding more POCs

## Validate all input bit size

Validate that inputs do not exceed the size of it's expected type and either revert or clean the unused bits depending on your use case before using that value

- The file `src/NoInputTypeSizeValidation.huff` holds a contract vulnerable to this and `test/NoInputTypeSizeValidation.t.sol` holds the POC for it. The vulnerability can lead to permanent loss of funds when transfer is called with the an address greater than 160 bits. Normally this should be checked and revert if the bit size of the expected type (in this case an address) is less than the bit size of what was sent. e.g

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

## End execution after function dispatching

Ensure that your code reverts after comparing all supported function signatures, fallback etc and not matching any. Omitting this can mean that the execution continues into other parts of your bytecode which you most likely don't want. This is trivial but can be forgotten and if so can have critical consequences.

## Ensure that addresses being called, static-called or delegate-called have code deployed to them

Calling an address without code is always successful. If you're sure the address has and will always have code deployed to it, then this check can be omitted to save runtime gas costs.

## Ensure overflow and underflow are always checked when not desired

Also remember that while division never overflows/underflows, signed division (`sdiv`` opcode) will overflow when you divide the minimum of a signed type by -1. this should be checked if not desired. E.g

```
int8 x = int8(-128) / int8(-1);
```

This will revert as is from solidity >= 0.8.0 since this should be 128 but type(int8).max is 127 so it overflows.
But if put in an unchecked block this overflow is ignored and overflows to the type(int8).min (since the overflow is just by 1). Hence x will be -128 which is incorrect and can be critical if not desired.

## When calling precompiles, check the returndatasize not the success of the call to determine if it failed

When calling precompiles, be aware that on error/”failure”, the call is still successful. A failed precompile call simply has a returndatasize of 0.

## When dividing or modulo'in check that the denominator is not 0

At the evm level and even in yul/inline assembly, when dividing or modulo'ing by 0, It does not revert with Panic(18) as solidity would do, its result 0. If this behavior is not desired it should be checked. Basically, x / 0 = 0 and x % 0 = 0.
