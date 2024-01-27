
import { expect } from "chai";
import crypto from 'crypto';
import { Contract, JsonRpcProvider, toUtf8Bytes } from "ethers";
import { ethers } from "hardhat";
import { Blake2s } from "../typechain-types";

describe("Blake2s", function () {
    let blake2s: Blake2s;

    beforeEach(async function () {

        const f = await ethers.getContractFactory("Blake2s")
        blake2s = await f.deploy();

    });


    it.only("small digest", async () => {
        const input = "hello world";

        const expected = crypto.createHash('blake2s256').update(input).digest();
        const actual = await blake2s.blake2sFormatted(toUtf8Bytes(input), toUtf8Bytes(''), 32)

        expect(actual).to.equal("0x" + expected.toString('hex'))

    })


    // Add more test cases as needed
});