//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

error _CandidateAlreadyExist();
error _AlreadyVoted();
error _CandidateNotVoteItself();

contract BlockchainVoting {
    address Manager;
    uint256 TotalCandidates;
    uint256 TotalVoters;
    uint256 epsilon = 5;

    constructor() {
        Manager = msg.sender;
    }

    struct Voter {
        uint256 Id;
        string name;
        address voterAddress;
        address votedCandidateAddress;
        bool hasVoted;
    }

    struct Candidate {
        string name;
        address candidateAddress;
        uint256 voteCount;
    }

    struct Results {
        string name;
        uint256 voteCount;
    }

    mapping(address => bool) public hasVoted;
    mapping(address => bool) public candidateExists;

    Voter[] public voters;
    Candidate[] public candidates;

    function setCandidate(address _address, string memory _name)
        external
        onlyManager
    {
        require(!candidateExists[_address], "Candidate already exists");
        candidates.push(Candidate(_name, _address, 0));
        candidateExists[_address] = true;
        TotalCandidates++;
    }

    function setVote(
        uint256 _Id,
        string memory _name,
        address _voterAddress,
        address _candidateAddress
    ) external {
        require(candidates.length >= 2, "Candidates must be at least 2");

        require(!hasVoted[_voterAddress], "Voter has already voted");
        hasVoted[_voterAddress] = true;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateAddress == _voterAddress) {
                revert _CandidateNotVoteItself();
            }
        }

        bool candidateFound = true;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateAddress == _candidateAddress) {
                uint256 randomNumber = getRandomNormalized();
                //if the random number < epsilon we add the vote to the candidate 1
                if (randomNumber < epsilon) {
                    candidates[0].voteCount++;
                    voters.push(
                        Voter(
                            _Id,
                            _name,
                            _voterAddress,
                            candidates[0].candidateAddress,
                            true
                        )
                    );
                } else {
                    // if the random number isnot < epsilon we keep the original vote. 
                    candidates[i].voteCount++;
                    voters.push(
                        Voter(
                            _Id,
                            _name,
                            _voterAddress,
                            candidates[i].candidateAddress,
                            true
                        )
                    );
                }
            }
            require(candidateFound, "Candidate not found");
            TotalVoters++;
        }
    }


    function getRandomNormalized() public view returns (uint256) {
        // Generate a pseudo-random number using keccak256 hash
        uint256 randomNumber = uint256(keccak256(abi.encode(block.timestamp, block.difficulty, msg.sender)));
        // Use modulo to limit the range of the random number from 0 to 100
        return randomNumber % 101;
    }

function publishResults() public view returns (Results[] memory) {
    Results[] memory finalResults = new Results[](2);

    
    if(candidates.length>0){
        uint256 total_number_of_votes_for_x = (4 * candidates[0].voteCount - 1) / 2;
        uint256 total_number_of_votes_for_y = candidates[1].voteCount - (total_number_of_votes_for_x - candidates[0].voteCount);
    finalResults[0] = Results(
         candidates[0].name,
       total_number_of_votes_for_x
    );
    finalResults[1] = Results(
        candidates[1].name,
       total_number_of_votes_for_y
    );
    }
    return finalResults;
}

    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    function getVoters() external view returns (Voter[] memory) {
        return voters;
    }

    modifier onlyManager() {
        require(msg.sender == Manager, "Only manager can perform this action");
        _;
    }
}
