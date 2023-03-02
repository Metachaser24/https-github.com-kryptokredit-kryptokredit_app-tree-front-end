// Import the necessary modules from Hardhat
const { expect } = require("chai");
const { ethers } = require("hardhat");

// Define the tests for the signInvoiceInvoicer() function
describe("MyContract", function () {
  // Define a variable to hold the deployed contract instance
  let myContract;

  // Deploy the contract before running the tests
  before(async function () {
    // Get the contract factory from the artifact
    const MyContract = await ethers.getContractFactory("NFTInvoicer");

    // Deploy the contract
    myContract = await MyContract.deploy();
  });

  // Define a test for the signInvoiceInvoicer() function
  describe("signInvoiceInvoicer()", function () {
    it("should sign the invoice with the given ID and signature", async function () {
      // Define the input parameters for the function
      const id = 1;
      const signature = "0x1234567890abcdef";
      await myContract.createInvoice(
        1,
        "1677628800",
        "0xa26358a33569ee5ddd91776ff3d5d5f1fbad2d00",
        1
      );
      // Call the signInvoiceInvoicer() function with the input parameters
      await myContract.signInvoiceInvoicer(id, signature);

      // Check that the invoice has been signed
      const invoice = await myContract.getInvoicerSignature(id);
      expect(invoice).to.equal(signature);
    });
  });
});
