const Web3 = require('web3');
const fs = require("fs");
const { on } = require('events');
const { count } = require('console');
require('dotenv').config();


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

// Process votes from the JSON file (ONE BY ONE)
async function processVotes(signer) {
  const json = await readJSONFile();
  counter = 0;
  for (const vote of json) {
    try {
      const receipt = await contract.methods.setVote(vote.address, vote.addressCandidate)
        .send({ from: signer.address, gas: 50000000 });
      console.log(receipt);
    } catch (error) {
      console.error(error);
    }
  }
}


// Get the list of voters

async function getVoters() {
  await contract.methods.getVoters().call((error, result) => {
    if (!error) {
      console.log(result);
    } else {
      console.log(error);
    }
  });
}

// Get the list of candidates

async function getCandidates() {
  await contract.methods.getCandidates().call((error, result) => {
    if (!error) {
      console.log(result);
    } else {
      console.log(error);
    }
  });
}

// Get the list of candidates with results
async function getCandidatesR() {
  await contract.methods.getCandidatesR().call((error, result) => {
    if (!error) {
      console.log(result);
    } else {
      console.log(error);
    }
  });

}

// Publish the results
async function publishResults() {
  await contract.methods.publishResults().call((error, result) => {
    if (!error) {
      console.log(result);
    } else {
      console.log(error);
    }
  }
  );
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

async function simulateElections() {
  await setCandidates();
  await startElections();
  await processVotes(signer);
  await publishResults();
  await getCandidatesR();
}


