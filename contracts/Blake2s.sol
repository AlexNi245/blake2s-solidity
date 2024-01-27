pragma solidity 0.8.20;

import "hardhat/console.sol";

/*
    see https://www.rfc-editor.org/rfc/rfc7693.txt
    */
library Blake2s {
    uint32 constant DEFAULT_OUTLEN = 32;
    bytes constant DEFAULT_EMPTY_KEY = "";

    struct BLAKE2s_ctx {
        uint256[2] b; // Input buffer: 2 elements of 32 bytes each to make up 64 bytes
        uint32[8] h; // Chained state: 8 words of 32 bits each
        uint64 t; // Total number of bytes
        uint32 c; // Counter for buffer, indicates how much is filled
        uint32 outlen; // Digest output size
    }

    function toBytes32(
        bytes memory input
    ) public pure returns (bytes32 result) {
        uint32[8] memory digest = toDigest(input);
        for (uint i = 0; i < digest.length; i++) {
            result = bytes32(
                uint256(result) | (uint256(digest[i]) << (256 - ((i + 1) * 32)))
            );
        }
    }

    function toDigest(
        bytes memory input
    ) public pure returns (uint32[8] memory) {
        BLAKE2s_ctx memory ctx;
        uint32[8] memory out;
        uint32[2] memory DEFAULT_EMPTY_INPUT;
        init(
            ctx,
            DEFAULT_OUTLEN,
            DEFAULT_EMPTY_KEY,
            DEFAULT_EMPTY_INPUT,
            DEFAULT_EMPTY_INPUT
        );
        update(ctx, input);
        finalize(ctx, out);
        return out;
    }

    function init(
        BLAKE2s_ctx memory ctx,
        uint32 outlen,
        bytes memory key,
        uint32[2] memory salt,
        uint32[2] memory person
    ) private pure {
        if (outlen == 0 || outlen > 32 || key.length > 32) revert("outlen");

        // Initialize chained-state to IV
        for (uint i = 0; i < 8; i++) {
            ctx.h[i] = IV()[i];
        }

        // Set up parameter block
        ctx.h[0] = ctx.h[0] ^ 0x01010000 ^ (uint32(key.length) << 8) ^ outlen;

        if (salt.length == 2) {
            ctx.h[4] = ctx.h[4] ^ salt[0];
            ctx.h[5] = ctx.h[5] ^ salt[1];
        }

        if (person.length == 2) {
            ctx.h[6] = ctx.h[6] ^ person[0];
            ctx.h[7] = ctx.h[7] ^ person[1];
        }

        ctx.outlen = outlen;
    }

    function update(BLAKE2s_ctx memory ctx, bytes memory input) private pure {
        for (uint i = 0; i < input.length; i++) {
            // If buffer is full, update byte counters and compress
            if (ctx.c == 64) {
                // BLAKE2s block size is 64 bytes
                ctx.t += ctx.c; // Increment counter t by the number of bytes in the buffer
                compress(ctx, false);

                //clear input buffer counter after compressing
                ctx.b[0] = 0;
                ctx.b[1] = 0;
                //clear buffer counter after compressing
                ctx.c = 0;
            }

            //Assign the char from input to the buffer
            //Assembly function corrospends to the following code
            //  uint c = ctx.c;
            //  uint[2] memory b = ctx.b;
            //  uint8 a = uint8(input[i]);
            //  b[c] =a;F
            assembly {
                mstore8(
                    add(mload(add(ctx, 0)), mload(add(ctx, 0x60))),
                    shr(248, mload(add(input, add(0x20, i))))
                )
            }
            //After we assign the char to the buffer, we need to increment the buffer count
            ctx.c++;
        }
    }

    function compress(BLAKE2s_ctx memory ctx, bool last) private pure {
        uint32[16] memory v;
        uint32[16] memory m;

        // Initialize v[0..15]
        for (uint i = 0; i < 8; i++) {
            v[i] = ctx.h[i]; // First half from the state
            v[i + 8] = IV()[i]; // Second half from the IV
        }

        // Low 64 bits of t
        v[12] = v[12] ^ uint32(ctx.t & 0xFFFFFFFF);
        // High 64 bits of t (BLAKE2s uses only 32 bits for t[1], so this is often zeroed)
        v[13] = v[13] ^ uint32(ctx.t >> 32);

        // Set the last block flag if this is the last block
        if (last) {
            v[14] = ~v[14];
        }

        // Initialize m[0..15] with the bytes from the input buffer
        for (uint i = 0; i < 16; i++) {
            //input buffer ctx b is 2x32 bytes long; To fill the 16 words of m from the 64 bytes of ctx.b, We copt the first 8 byte from the first 32 bytes of ctx.b and the second 8 bytes from the second 32 bytes of ctx.b
            uint256 bufferSlice = ctx.b[i / 8];
            //Execution would be reverting due to overflow caused by modulo 256, hence its unchecked
            unchecked {
                uint offset = (256 - (((i + 1) * 32))) % 256;
                uint32 currentWord = uint32(bufferSlice >> offset);
                m[i] = getWords32(currentWord);
            }
        }

        // Mix the message block according to the BLAKE2s schedule
        uint8[16][10] memory SIGMA = [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
            [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
            [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
            [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
            [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
            [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
            [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
            [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
            [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]
        ];

        for (uint round = 0; round < 10; round++) {
            G(v, 0, 4, 8, 12, m[SIGMA[round][0]], m[SIGMA[round][1]]);
            G(v, 1, 5, 9, 13, m[SIGMA[round][2]], m[SIGMA[round][3]]);
            G(v, 2, 6, 10, 14, m[SIGMA[round][4]], m[SIGMA[round][5]]);
            G(v, 3, 7, 11, 15, m[SIGMA[round][6]], m[SIGMA[round][7]]);
            G(v, 0, 5, 10, 15, m[SIGMA[round][8]], m[SIGMA[round][9]]);
            G(v, 1, 6, 11, 12, m[SIGMA[round][10]], m[SIGMA[round][11]]);
            G(v, 2, 7, 8, 13, m[SIGMA[round][12]], m[SIGMA[round][13]]);
            G(v, 3, 4, 9, 14, m[SIGMA[round][14]], m[SIGMA[round][15]]);
        }

        // Update the state with the result of the G mixing operations
        for (uint i = 0; i < 8; i++) {
            ctx.h[i] = ctx.h[i] ^ v[i] ^ v[i + 8];
        }
    }

    function finalize(
        BLAKE2s_ctx memory ctx,
        uint32[8] memory out
    ) internal pure {
        // Add any uncounted bytes
        ctx.t += ctx.c;

        // Compress with finalization flag
        compress(ctx, true);

        // Flip little to big endian and store in output buffer
        for (uint i = 0; i < ctx.outlen / 4; i++) {
            out[i] = getWords32(ctx.h[i]);
        }
        // Properly pad output if it doesn't fill a full word
        if (ctx.outlen % 4 != 0) {
            out[ctx.outlen / 4] =
                getWords32(ctx.h[ctx.outlen / 4]) >>
                (32 - 8 * (ctx.outlen % 4));
        }
    }

    function getWords32(uint32 a) private pure returns (uint32 b) {
        return
            (a >> 24) |
            ((a >> 8) & 0x0000FF00) |
            ((a << 8) & 0x00FF0000) |
            (a << 24);
    }

    function ROTR32(uint32 x, uint8 n) private pure returns (uint32) {
        return (x >> n) | (x << (32 - n));
    }

    function G(
        uint32[16] memory v,
        uint a,
        uint b,
        uint c,
        uint d,
        uint32 x,
        uint32 y
    ) private pure {
        unchecked {
            v[a] = v[a] + v[b] + x;
            v[d] = ROTR32(v[d] ^ v[a], 16);
            v[c] = v[c] + v[d];
            v[b] = ROTR32(v[b] ^ v[c], 12);
            v[a] = v[a] + v[b] + y;
            v[d] = ROTR32(v[d] ^ v[a], 8);
            v[c] = v[c] + v[d];
            v[b] = ROTR32(v[b] ^ v[c], 7);
        }
    }

    function IV() private pure returns (uint32[8] memory) {
        return [
            0x6A09E667,
            0xBB67AE85,
            0x3C6EF372,
            0xA54FF53A,
            0x510E527F,
            0x9B05688C,
            0x1F83D9AB,
            0x5BE0CD19
        ];
    }
}
