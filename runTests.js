const Web3 = require('web3');
const fs = require("fs");
const { on } = require('events');
const { count } = require('console');
require('dotenv').config();
const { performance } = require('perf_hooks');


// Set up a web3 provider
const web3 = new Web3(process.env.URL_NODE_1);

// Read the votes from a Json File

async function readJSONFile() {
  try {
    const data = await fs.readFileSync(process.env.VOTESJSON, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error("An error occurred:", error);
  }
}

// Define the contract ABI
const { abi, evm } = JSON.parse(fs.readFileSync(process.env.SCJSON));
const signer = web3.eth.accounts.privateKeyToAccount(
  process.env.PRIVATE_KEY,
);
web3.eth.accounts.wallet.add(signer);
// Specify the contract address
const contractAddress = process.env.CONTRACT_ADDRESS;
// Create contract instance
const contract = new web3.eth.Contract(abi, contractAddress);


//Set candidates
async function setCandidates() {
  await contract.methods.setCandidate(process.env.CANDIDATE1ADDRESS, process.env.CANDIDATE1NAME).send({ from: signer.address, gas: 50000000 })
    .on('receipt', console.log)
    .on('error', console.error);
  await contract.methods.setCandidate(process.env.CANDIDATE2ADDRESS, process.env.CANDIDATE2NAME).send({ from: signer.address, gas: 50000000 })
    .on('receipt', console.log)
    .on('error', console.error);
}


// Start the elections
async function startElections() {
  await contract.methods.startVoting().send({ from: signer.address, gas: 50000000 })
    .on('receipt', console.log)
    .on('error', console.error);
}

// Get the epsilon 

async function getEpsilon() {
  await contract.methods.showEpsilon().call((error, result) => {
    if (!error) {
      console.log(result);
    } else {
      console.log(error);
    }
  }
  );
}



async function test() {
  listOftimes = [];
  const json = await readJSONFile();
  counter = 0;
  testsNumbersitems = [1, 10, 100, 200, 300];
  j = 0;
  for (testI in testsNumbersitems) {
    var startTime = performance.now()
    i = 0;
    console.log(`Test with ${testsNumbersitems[testI]} items`);

    while (i < testsNumbersitems[testI] && j < json.length) {
      console.log('vote: ', i + 1);
      try {
        const receipt = await contract.methods.setVote(json[j].address, json[j].addressCandidate)
          .send({ from: signer.address, gas: 50000000 });
        console.log(receipt);
      } catch (error) {
        console.error(error);
      }
      i++;
      j++;

    }
    var endTime = performance.now()
    listOftimes.push(endTime - startTime);
    console.log(`Call to setVote took ${endTime - startTime} milliseconds`)
  }

  return listOftimes;
}
// Test to measure the time it takes to process a batch of votes

async function stressTest() {
  const json = await readJSONFile();
  let votes = [];
  counter = 0;
  for (vote of json) {
    let currentNonce = await web3.eth.getTransactionCount(signer.address, 'pending');
    const transaction = contract.methods.setVote(vote.address, vote.addressCandidate);
    const encodedTransaction = transaction.encodeABI();
    try {
      const signedTx = await signer.signTransaction({
        nonce: currentNonce + counter,
        gas: 50000000,
        to: contract.options.address,
        data: encodedTransaction
      });
      votes.push(signedTx);
    } catch (error) {
      console.error(error);
      continue;
    }
    counter++;
    if (counter == process.env.BATCH_SIZE) {
      const startTime = Date.now(); // Record start time
      const promises = [];
      for (let i = 0; i < votes.length; i++) {
        try {
          const promise = web3.eth.sendSignedTransaction(votes[i].rawTransaction);
          promises.push(promise);
        } catch (error) {
          console.error(error);
        }
      }
      try {
        await Promise.all(promises);
        const endTime = Date.now(); // Record end time
        const executionTime = endTime - startTime;
        console.log(`All transactions sent in ${executionTime} milliseconds.`);
      } catch (error) {
        console.error("Error sending transactions:", error);
      }
      await sleep(10000);
      votes = [];
      counter = 0;
      currentNonce = await web3.eth.getTransactionCount(signer.address, 'pending');
    }
  }
}

function sleep(milliseconds) {
  console.log('sleeping for 20 seconds');
  return new Promise(resolve => setTimeout(resolve, milliseconds));
}

async function simulateTest() {
  await setCandidates();
  await startElections();
  await test();
  await stressTest();
}


simulateTest();