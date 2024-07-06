// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/v0.8/VRFConsumerBaseV2.sol";

// SubscriptionId: 66105187901719882461218407454890193752065976317021913928458873002065167499587
// VRF Coordinator: 0x9ddfaca8183c41ad55329bdeed9f6a8d53168b1b
// Key Hash: 0x938a1f8c00d8643ff8b545baa347a9da64e941fa5c71c3bd8f52bfe334b6297f
contract RandomNumberConsumerV2 is VRFConsumerBaseV2 {

      event ReturnedRandomness(uint256[] indexed randomWords);
      event RequestSent(uint256 indexed requestId, uint32 indexed numWords);
    event RequestFulfilled(uint256 indexed requestId, uint256 indexed randomWord);

struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256 randomWord;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    VRFCoordinatorV2Interface immutable COORDINATOR;

    uint256 immutable s_subscriptionId;

    bytes32 immutable s_keyHash;

    uint32 constant CALLBACK_GAS_LIMIT = 1e5;

    uint16 constant REQUEST_CONFIRMATIONS = 3;

    uint32 constant NUM_WORDS = 1;

    uint256[] public s_randomWords;
    
    uint256 public requestId;
    address s_owner;
     uint256[] public requestIds;
    uint256 public lastRequestId;

  

    constructor(
        uint256 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords() external returns(uint256) {
       requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            uint64(s_subscriptionId),
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

         s_requests[requestId] = RequestStatus({
            randomWord:0,
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, NUM_WORDS);

        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[requestId].fulfilled = true;
        uint256 randomNumber=randomWords[0];
        s_requests[_requestId].randomWord = randomNumber;
        emit RequestFulfilled(_requestId,randomNumber);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256  randomWord) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWord);
    }   
    
}