const { expect } = require("chai");
const { ethers } = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether");
};

describe("Escrow", () => {
  let buyer, seller, inspector, lender;
  let realEstate, escrow;

  beforeEach(async () => {
    //Set up accounts
    [buyer, seller, inspector, lender] = await ethers.getSigners();

    //Deploy realestate
    const RealEstate = await ethers.getContractFactory("RealEstate");
    realEstate = await RealEstate.deploy();

    //Mint
    let transaction = await realEstate
      .connect(seller)
      .mint(
        "https://ipfs.io/ipfs/QmTudSYeM7mz3PkYEWXWqPjomRPHogcMFSq7XAvsvsgAPS"
      );

    await transaction.wait();

    const Escrow = await ethers.getContractFactory("Escrow");
    escrow = await Escrow.deploy(
      realEstate.target,
      seller.address,
      lender.address,
      inspector.address
    );

    //Approve transaction

    transaction = await realEstate.connect(seller).approve(escrow.target, 0);
    await transaction.wait();

    //List property
    transaction = await escrow
      .connect(seller)
      .list(0, buyer.address, ethers.parseEther("10"), ethers.parseEther("5"));
    await transaction.wait();
  });

  describe("Deployment", () => {
    it("Returns NFT address", async () => {
      const result = await escrow.nftAddress();
      expect(result).to.be.equal(realEstate.target);
    });

    it("Returns seller address", async () => {
      const result = await escrow.seller();
      expect(result).to.be.equal(seller.address);
    });

    it("Returns inspector address", async () => {
      const result = await escrow.inspector();
      expect(result).to.be.equal(inspector.address);
    });

    it("Returns lender address", async () => {
      const result = await escrow.lender();
      expect(result).to.be.equal(lender.address);
    });
  });

  describe("Listing", () => {
    it("Updates as listed", async () => {
      const result = await escrow.isListed(0);
      expect(result).to.be.equal(true);
    });

    it("Update ownershipt", async () => {
      expect(await realEstate.ownerOf(0)).to.be.equal(escrow.target);
    });

    it("Returns buyer", async () => {
      const result = await escrow.buyer(0);
      expect(result).to.be.equal(buyer.address);
    });

    it("Returns purchase price", async () => {
      const result = await escrow.purchasePrice(0);

      expect(result).to.be.equal(ethers.parseEther("10"));
    });

    it("Returns escrow amount", async () => {
      const result = await escrow.escrowAmount(0);

      expect(result).to.be.equal(ethers.parseEther("5"));
    });
  });

  describe("Deposits", () => {
    it("Updates contract balance", async () => {
      const transaction = await escrow
        .connect(buyer)
        .depositEarnest(0, { value: ethers.parseEther("5") });

      await transaction.wait();

      const result = await escrow.getBalance();

      expect(result).to.be.equal(ethers.parseEther("5"));
    });
  });

  describe("Inspection", () => {
    it("Updates inspection status", async () => {
      const transaction = await escrow
        .connect(inspector)
        .updateInspectionStatus(0, true);

      await transaction.wait();

      const result = await escrow.inspectionPassed(0);
      expect(result).to.be.equal(true);
    });
  });
});
