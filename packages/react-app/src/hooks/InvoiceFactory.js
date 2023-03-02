const Web3 = require("web3");
const abi = require("./abi.json");
const web3 = new Web3("https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID");
const contractAddress = "0x1234567890123456789012345678901234567890"; // replace with your contract address

const contract = new web3.eth.Contract(abi, contractAddress);

async function issueDerogatoryMark(id) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.issueDerogatoryMark(id).send({
    from: accounts[0],
  });
  console.log(result);
}

async function revokeDerogatoryMark(id) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.revokeDerogatoryMark(id).send({
    from: accounts[0],
  });
  console.log(result);
}

async function updateValidatorContract(validatorContract) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.updateValidatorContract(validatorContract).send({
    from: accounts[0],
  });
  console.log(result);
}

async function addAddressToWhitelist(account) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.addAddressToWhitelist(account).send({
    from: accounts[0],
  });
  console.log(result);
}

async function addAddressesToWhitelist(accounts) {
  const batch = new web3.BatchRequest();
  accounts.forEach(async account => {
    const call = contract.methods.addAddressToWhitelist(account).send({
      from: accounts[0],
    });
    batch.add(call);
  });
  const result = await batch.execute();
  console.log(result);
}

async function removeAddressFromWhitelist(account) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.removeAddressFromWhitelist(account).send({
    from: accounts[0],
  });
  console.log(result);
}

async function createInvoice(amount, dueDate, payer, validator, fee) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.createInvoice(amount, dueDate, payer, validator, fee).send({
    from: accounts[0],
  });
  console.log(result);
}

async function signInvoiceInvoicer(id, invoicerSignature) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.signInvoiceInvoicer(id, invoicerSignature).send({
    from: accounts[0],
  });
  console.log(result);
}

async function signInvoicePayer(id, payerSignature) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.signInvoicePayer(id, payerSignature).send({
    from: accounts[0],
  });
  console.log(result);
}

async function signInvoiceValidator(id, validatorSignature) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.signInvoiceValidator(id, validatorSignature).send({
    from: accounts[0],
  });
  console.log(result);
}

async function verifySignatures(id) {
  const result = await contract.methods.verifySignatures(id).call();
  console.log(result);
}

async function mintTheInvoice(id, uri) {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.methods.mintTheInvoice(id, uri).send({
    from: accounts[0],
  });
  console.log(result);
}

async function payInvoice(id) {
  const accounts = await web3.eth.getAccounts();
  const amount = await contract.methods.getInvoice().amount;
  const result = await contract.methods.payInvoice(id).send({
    from: accounts[0],
    value: web3.utils.toWei(amount.toString(), "ether"),
  });
  console.log(result);
}

async function getInvoice(id) {
  const result = await contract.methods.getInvoice(id).call();
  console.log(result);
}

module.exports = {
  issueDerogatoryMark,
  revokeDerogatoryMark,
  updateValidatorContract,
  addAddressToWhitelist,
  addAddressesToWhitelist,
  removeAddressFromWhitelist,
  createInvoice,
  signInvoiceInvoicer,
  signInvoicePayer,
  signInvoiceValidator,
  verifySignatures,
  mintTheInvoice,
  payInvoice,
  getInvoice,
};
