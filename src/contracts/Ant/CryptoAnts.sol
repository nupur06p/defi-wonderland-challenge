import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Counters.sol";
// import {RandomNumberConsumerV2} from './RandomNumber.sol';

// @Info - IEgg extends the IERC20 interface by adding a mint function, which allows for minting new tokens.
interface IEgg is IERC20 {
    function mint(address, uint256) external;
}

interface IAnts is IERC721 {
    function _safeMint(address, uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

contract CryptoAnts is ERC721, ERC721Holder, Ownable {
    error NoEggs();
    error Unauthorized();
    error CallFailed();
    error NotAllowedToReEnter();
    error InsufficientBalance();
    error CannotCreateEggs();
    error NOtEnoughBalance(uint256 value);
    error EGGSNotCreated();

    using Counters for Counters.Counter;

    ////////////STATE VARIABLES//////////////

    bool public locked = false;
    bool private constant _notLocked = false;

    mapping(address => uint256) public eggsToOwner;
    mapping(address => uint256) public antToAddress;
    mapping(uint256 => address) public antToOwner;
    mapping(uint256 => uint256) public lastEggCreationTime;
    mapping(address => uint256) public balances;

    IEgg public immutable EGGS;
    IAnts ANTS;

    uint256 private constant MINT_PRICE = 10 ether;
    uint256 private constant EGG_TO_ANT_CONVERSION_RATE = 1;
    Counters.Counter public antidCounter;

    address public _owneR;
    uint256 public expirationBlock;
    uint256 private _eggPrice = 0.01 ether;
    uint256 private _antSalePrice = 0.004 ether;
    // uint256 private _antCreationInterval = 10 minutes;
    uint256 private _antMaxEggs = 20;
    uint256 private _antDeathChance = 10; // 10%

    ///////////////EVENTS///////////////////

    event EggsBought(address indexed, uint256 indexed);
    event AntCreated(uint256 indexed _antId, address indexed addr_owner);
    event AntSold(uint256 indexed _antId, address indexed addr_owner);
    event EggsCreated(uint256 indexed _antId, uint256 indexed amount);

    ///////////////MODIFIERS/////////////////

    /*@info - Modifier ensures that the function is not re-entrant. Sets locked to true before 
     executing the function and sets it to NOT_LOCKED after the function execution
    */
    modifier lock() {
        if (locked) {
            revert NotAllowedToReEnter();
        }
        locked = true;
        _;
        locked = _notLocked;
    }

    ////////////FUNCTIONS /////////////////

    constructor(address _eggs) Ownable(msg.sender) ERC721("Crypto Ants", "ANTS") {
        EGGS = IEgg(_eggs);
        _owneR = Ownable.owner();
    }

    //////////// External Functions ////////////////////

    //@info - Function allows users to mint egg
    function buyEggs(uint256 _amount) external lock {
        uint256 eggPrice = _eggPrice;
        uint256 eggsCreated = 0;

        //@info - Calculates the number of eggs the caller can buy based on the sent Ether and the egg price
        uint256 eggsCallerCanBuy = (getContractBalance(_owneR) / eggPrice);

        if (eggsCallerCanBuy < _amount) {
            revert InsufficientBalance();
        }
      
        eggsCreated += _amount;
        eggsToOwner[_owneR] += eggsCreated;
        emit EggsBought(_owneR, _amount);

        EGGS.mint(_owneR, _amount);
    }

    //@info - Function allows users to create an ant if they own at least one egg
    function createAnt() external lock {
        if (EGGS.balanceOf(_owneR) < EGG_TO_ANT_CONVERSION_RATE) {
            revert NoEggs();
        }

        antidCounter.increment();
        uint256 _antId = antidCounter.current();

        uint256 antsIdAddress = 0;
        ++antsIdAddress;

        antToOwner[_antId] = _owneR;
        antToAddress[_owneR] += antsIdAddress;
        delete eggsToOwner[_owneR];
        lastEggCreationTime[_antId] = block.timestamp;

        emit AntCreated(_antId, antToOwner[_antId]);
        _safeMint(address(this), _antId, "");
        
    }

    //@info - Function allows the owner of an ant to sell it for 0.004 Ether
    function sellAnt(uint256 antId,address _recipient) external payable lock onlyOwner {

        uint256 _antId = antId;
        address recipient = payable(_recipient);

        if (antToOwner[_antId] != msg.sender) {
            revert Unauthorized();
        }

        if (recipient.balance < _antSalePrice) {
            revert NOtEnoughBalance({value: recipient.balance});
        }

        antToOwner[_antId] = recipient;
        uint256 antsIdAddress = 0;
        ++antsIdAddress;
        
        delete antToAddress[_owneR];
        antToAddress[recipient] += antsIdAddress;
        emit AntSold(_antId, recipient);

        //@info - Transfers Ether to owner
        _safeTransfer(address(this), recipient, _antId, "");
        (bool success, ) = payable(_owneR).call{value: _antSalePrice}("");
        if (!success) {
            revert CallFailed();
        }
        balances[_owneR] = 0;
    }

    /*@info - Function allows creating of eggs using ants. Ants randomly create multiple eggs at a time. 
    Ants have x% (_antDeathChance) chance of dying while creating eggs */
    function createEggs(uint256 antId) external lock onlyOwner {
        uint256 _antId = antId;

        if (antToOwner[_antId] != msg.sender) {
            revert Unauthorized();
        }

        if (!isExpired()) {
            revert CannotCreateEggs();
        }
        lastEggCreationTime[_antId] = expirationBlock;

        if (_random(100) < _antDeathChance) {
            _burn(_antId);
        }

        delete antToOwner[_antId];
        uint256 eggAmount = _random(_antMaxEggs + 1); // random number between 0 and antMaxEggs

        if (eggAmount > 0) {
            eggsToOwner[_owneR] += eggAmount;
            emit EggsBought(_owneR, eggAmount);
        } else {
            revert EGGSNotCreated();
        }
        EGGS.mint(_owneR, eggAmount);
    }

    function setTimeLock(uint256 _duration) public {
        expirationBlock = block.number + _duration;
    }

    function isExpired() private view returns (bool) {
        return block.number >= expirationBlock;
    }

    function _random(uint256 max) private view returns (uint256) {
        uint256 blockNumber = block.number - 1; // Use the previous block's hash
        bytes32 blockHash = blockhash(blockNumber);
        return uint256(blockHash) % max;
    }

    function transferOwnership(address newAddress) public override onlyOwner {
        require(newAddress != address(0), "Address zero detected");
        require(newAddress != _owneR, "You are already the owner");
        _owneR = newAddress;
    }

    function setAntSalePrice(uint256 newPrice) external onlyOwner {
        _antSalePrice = newPrice;
    }

    function setEggPrice(uint256 egg_price) external onlyOwner {
        _eggPrice = egg_price;
    }

    // function setAntCreationInterval(uint256 newInterval) external onlyOwner {
    //     _antCreationInterval = newInterval;
    // }

    function setAntMaxEggs(uint256 newMax) external onlyOwner {
        _antMaxEggs = newMax;
    }

    function setAntDeathChance(uint256 newChance) external onlyOwner {
        _antDeathChance = newChance;
    }

    //@info - Returns the balance of the contract
    function getContractBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }

    //@info - Returns the number of ants created
    function getAntsCreated() external view returns (uint256) {
        return antidCounter.current();
    }
}