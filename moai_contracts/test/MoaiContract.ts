// test/MoaiContract.test.js
const { expect } = require("chai");
const hre = require('hardhat');

const PUSHPROTOCOL_SDK_ADDRESS = "0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7";

describe("MoaiContract", function () {
    let MoaiContract;
    let contractInstance: any;
    let owner: any;
    let member1: any;
    let member2: any;
    let nonMember: any;

    beforeEach(async () => {
        await hre.network.provider.send("hardhat_reset");
        [owner, member1, member2, nonMember] = await hre.ethers.getSigners();

        // Deploy MoaiContract
        MoaiContract = await hre.ethers.getContractFactory("MoaiContract");
        contractInstance = await MoaiContract.deploy(100, PUSHPROTOCOL_SDK_ADDRESS); // Standard amount is set to 100

        // Add members
        await contractInstance.addMember(member1.address);
        await contractInstance.addMember(member2.address);
    });

    it("Should add members correctly", async function () {



        // Emit MemberAdded event
        expect(await contractInstance.addMember(member1.address))
            .to.emit(contractInstance, "MemberAdded")
            .withArgs(member1.address);

        expect(await contractInstance.addMember(member2.address))
            .to.emit(contractInstance, "MemberAdded")
            .withArgs(member2.address);


    });

    it("Should contribute correctly", async function () {
        // Emit Contribution event
        await expect(contractInstance.connect(member1).contribute({ value: 100 }))
            .to.emit(contractInstance, "Contribution")
            .withArgs(member1.address, 100);
        await expect(contractInstance.connect(member2).contribute({ value: 100 }))
            .to.emit(contractInstance, "Contribution")
            .withArgs(member2.address, 100);

        expect(await contractInstance.getContractBalance()).to.equal(200);
    });

    it("Should start voting and cast vote correctly", async function () {
        // Start voting
        await contractInstance.connect(member1).startVoting(member2.address, 50);

        // Check if voting started correctly
        expect(await contractInstance.members(member1.address)).to.include({
            hasVoted: false,
        });
        expect(await contractInstance.members(member2.address)).to.include({
            hasVoted: false,
        });

        // Cast vote
        await contractInstance.connect(member1).castVote(true);

        // Check if vote is casted correctly
        expect(await contractInstance.members(member1.address)).to.include({
            hasVoted: true,
        });

        // Emit VoteCasted event
        await expect(contractInstance.connect(member1).castVote(true))
            .to.emit(contractInstance, "VoteCasted")
            .withArgs(member1.address, true);
    });

    it("Should initiate transfer and send funds correctly", async function () {
        // Contribute to members
        await contractInstance.connect(member1).contribute({ value: 100 });
        await contractInstance.connect(member2).contribute({ value: 100 });

        // Start voting
        await contractInstance.connect(member1).startVoting(member2.address, 50);

        // Cast votes
        await contractInstance.connect(member1).castVote(true);
        await contractInstance.connect(member2).castVote(true);

        // Initiate transfer
        await contractInstance.connect(owner).initiateTransfer(member2.address, 50);

        // Check if funds are transferred correctly
        expect(await contractInstance.members(member2.address)).to.include({
            balance: 150, // 100 (initial) + 50 (transfer)
        });

        // Emit FundsSent event
        await expect(contractInstance.connect(owner).initiateTransfer(member2.address, 50))
            .to.emit(contractInstance, "FundsSent")
            .withArgs(member2.address, 50);
    });

    it("Should not initiate transfer if insufficient votes", async function () {
        // Contribute to members
        await contractInstance.connect(member1).contribute({ value: 100 });
        await contractInstance.connect(member2).contribute({ value: 100 });

        // Start voting
        await contractInstance.connect(member1).startVoting(member2.address, 50);

        // Cast votes (only member1 votes, less than 50%)
        await contractInstance.connect(member1).castVote(true);

        // Initiate transfer (should fail)
        await expect(
            contractInstance.connect(owner).initiateTransfer(member2.address, 50)
        ).to.be.revertedWith("Insufficient votes");

        // Check if funds are not transferred
        expect(await contractInstance.members(member2.address)).to.include({
            balance: 100, // Initial balance
        });

        // Emit FundsNotSent event
        await expect(
            contractInstance.connect(owner).initiateTransfer(member2.address, 50)
        )
            .to.emit(contractInstance, "FundsNotSent")
            .withArgs(member2.address, 50);
    });



});