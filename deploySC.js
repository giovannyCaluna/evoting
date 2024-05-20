const  Web3  = require("web3");
require('dotenv').config();


// Loading the contract ABI and Bytecode
// (the results of a previous compilation step)
const fs = require("fs");
const { abi, evm } = JSON.parse(fs.readFileSync(process.env.SCJSON));

async function main() {
  // Configuring the connection to an Ethereum node
  const web3 = new Web3(
    new Web3.providers.HttpProvider(
      process.env.URL_NODE_1,
    ),
  );


   // Creating a signing account from a private key
  const signer = web3.eth.accounts.privateKeyToAccount(
    process.env.PRIVATE_KEY,
  );
  web3.eth.accounts.wallet.add(signer);

  // Using the signing account to deploy the contract (Governor)

  const contract = new web3.eth.Contract(abi);
  contract.options.data = evm.bytecode.object;
  const deployTx = contract.deploy();
  const deployedContract = await deployTx
    .send({
      from: signer.address,
      gas: 50000000,
    })
    .once("transactionHash", (txhash) => {
      console.log(`Mining deployment transaction ...`);
    });
  // The contract is now deployed on chain!
  console.log(`Contract deployed at ${deployedContract.options.address}`);
}


require("dotenv").config();
main();