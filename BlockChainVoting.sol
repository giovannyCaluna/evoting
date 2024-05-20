//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

error _CandidateAlreadyExist();
error _AlreadyVoted();
error _CandidateNotVoteItself();

contract BlockchainVoting {
    address Manager;
    uint256 TotalCandidates;
    uint256 TotalVoters;
    uint256 epsilon;
    uint256 pivot;
    uint nounce = 0;

    constructor() {
        Manager = msg.sender;
    }

    struct Voter {
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
    Candidate[] public candidatesR;

    function setCandidate(
        address _address,
        string memory _name
    ) external onlyManager {
        require(!candidateExists[_address], "Candidate already exists");
        candidates.push(Candidate(_name, _address, 0));
        candidateExists[_address] = true;
        TotalCandidates++;
    }

    function setVote(
        address _voterAddress,
        address _candidateAddress
    ) external {
        require(candidates.length >= 2, "Candidates must be at least 2");
        require(!hasVoted[_voterAddress], "Voter has already voted");
        require(candidateExists[_candidateAddress], "Candidate does not exist");
        hasVoted[_voterAddress] = true;
        if (_candidateAddress == candidatesR[0].candidateAddress) {
            uint256 randomNumber = getRandomNormalized(nounce++);
            if (randomNumber <= epsilon) {
                candidatesR[0].voteCount++;
                voters.push(
                    Voter(_voterAddress, candidates[0].candidateAddress, true)
                );
            } else {
                candidatesR[returnInterval(randomNumber)].voteCount++;
                voters.push(
                    Voter(
                        _voterAddress,
                        candidates[returnInterval(randomNumber)]
                            .candidateAddress,
                        true
                    )
                );
            }
        } else {
            for (uint256 i = 1; i < candidatesR.length; i++) {
                if (candidatesR[i].candidateAddress == _candidateAddress) {
                    candidatesR[i].voteCount++;
                    voters.push(
                        Voter(
                            _voterAddress,
                            candidatesR[i].candidateAddress,
                            true
                        )
                    );
                    break;
                }
            }
        }
        TotalVoters++;
    }

    // Function to rearrange an array by moving the element at 'index' to the front
    function rearrange(uint index) public {
        delete candidatesR;
        uint n = candidates.length;
        require(index < n, "Index out of bounds");
        candidatesR.push(candidates[index]); // Place the chosen index element at the start
        for (uint i = 0; i < index; i++) {
            candidatesR.push(candidates[i]);
        }
        for (uint j = index + 1; j < n; j++) {
            candidatesR.push(candidates[j]);
        }
        candidates = candidatesR;
    }

    function returnInterval(
        uint256 randomNumber
    ) public view returns (uint256) {
        if (randomNumber % epsilon == 0) {
            if ((randomNumber / epsilon) - 1 >= TotalCandidates) {
                return TotalCandidates - 1;
            } else {
                return (randomNumber / epsilon) - 1;
            }
        } else {
            if (randomNumber / epsilon >= TotalCandidates) {
                return TotalCandidates - 1;
            } else {
                return randomNumber / epsilon;
            }
        }
    }

    function getRandomNormalized(uint randNonce) public view returns (uint256) {
        uint randomNumber = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        );
        return randomNumber % 10001;
    }

    function publishResults() public view returns (Results[] memory) {
        Results[] memory finalResults = new Results[](candidatesR.length);
        uint256 total_number_of_votes_for_pivot = 0;
        if (candidatesR.length > 0) {
            total_number_of_votes_for_pivot =
                candidatesR[0].voteCount *
                TotalCandidates;
            finalResults[0] = Results(
                candidatesR[0].name,
                total_number_of_votes_for_pivot
            );
            for (uint256 i = 1; i < candidatesR.length; i++) {
                if (candidatesR[i].voteCount > 0) {
                    uint256 pivotBack = total_number_of_votes_for_pivot /
                        TotalCandidates;
                    if (pivotBack < candidatesR[i].voteCount) {
                        finalResults[i] = Results(
                            candidatesR[i].name,
                            candidatesR[i].voteCount - pivotBack
                        );
                    } else {
                        finalResults[i] = Results(
                            candidatesR[i].name,
                            candidatesR[i].voteCount
                        );
                    }
                } else {
                    finalResults[i] = Results(
                        candidatesR[i].name,
                        candidatesR[i].voteCount
                    );
                }
            }
        }
        return finalResults;
    }

    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }
    function getCandidatesR() external view returns (Candidate[] memory) {
        return candidatesR;
    }
    function getVoters() external view returns (Voter[] memory) {
        return voters;
    }
    function getEpsilon() external view returns (uint256) {
        return ((100 / TotalCandidates) * 100);
    }
    function getPivotCandidate() external view returns (uint256) {
        uint randomNumber = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nounce))
        );
        return randomNumber % TotalCandidates;
    }
    function startVoting() external onlyManager {
        epsilon = this.getEpsilon();
        pivot = this.getPivotCandidate();
        this.rearrange(pivot);
    }
    function showEpsilon() external view returns (uint256) {
        return epsilon;
    }
    function showPivot() external view returns (uint256) {
        return pivot;
    }
    modifier onlyManager() {
        require(msg.sender == Manager, "Only manager can perform this action");
        _;
    }
}
