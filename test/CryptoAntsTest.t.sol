// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {CryptoAnts} from "../src/contracts/Ant/CryptoAnts.sol";
import {Egg} from "../src/contracts/Egg/Egg.sol";
import {IEgg} from "../src/contracts/Ant/CryptoAnts.sol";
import {IAnts} from "../src/contracts/Ant/CryptoAnts.sol";
import {Counters} from "../src/contracts/Ant/Counters.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoAntsTest is Test{
    
    fallback() external payable {}
    receive() external payable {}

    using Counters for Counters.Counter;
    Counters.Counter public _antIdCounter;
    CryptoAnts cryptoAnts;
    ERC721 erc721;
    
    Egg egg = new Egg();
    IEgg EGGS;
    Ownable ownable;

    error NotAllowedToReEnter();
    mapping(address=> uint256) public balances;
    mapping(address=>uint256) public eggsToOwner;
    mapping(address => uint256) public antToAddress;
    mapping(uint256 => address) public antToOwner;

    bool public locked = false;
    bool constant private _notLocked = false;
    address addrEgg = address(egg);

    uint256 _EGG_PRICE = 0.01 ether;
    uint256 constant private MINT_PRICE = 10 ether;
    uint256 _antId;
    uint256 _antSalePrice = 0.004 ether;
    uint256 constant private EGG_TO_ANT_CONVERSION_RATE = 1;
    uint256 _mint_amount = 2;
    // uint256 _antCreationInterval = 0 minutes;
    uint256 _antMaxEggs = 20;
    uint256 _antDeathChance = 10; // 10%

    event EggsBought(address indexed, uint256 indexed);
    event AntCreated(uint256 indexed _antId, address indexed addr_owner);
    event AntSold(uint256 indexed _antId, address indexed addr_owner);
    event EggsCreated(uint256 indexed _antId, uint256 indexed amount);
    
    function setUp() external { 
        cryptoAnts = new CryptoAnts(addrEgg);
        // ownable = Ownable(cryptoAnts.owner());
    }

    modifier lock() {
    if (locked){
      revert NotAllowedToReEnter();
    }
    locked = true;
    _;
    locked = _notLocked;
    }

    function testInitializationOwner() public view{
        assertEq(cryptoAnts.owner(), address(this));
    }

    function testUsersCanMintEggsWithETH() public lock{
        vm.deal(cryptoAnts.owner(), 1 ether);
        vm.prank(cryptoAnts.owner());
        cryptoAnts.buyEggs(_mint_amount);
        assertEq(cryptoAnts.eggsToOwner(cryptoAnts.owner()), _mint_amount);
    }

    function testRevert_EggUser_InsufficientBalance() public {
        address(4).balance == 0;
        vm.prank(cryptoAnts.owner());
        cryptoAnts.transferOwnership(address(4));
        console.log("Balance:", address(4).balance);
        vm.expectRevert(CryptoAnts.InsufficientBalance.selector);
        cryptoAnts.buyEggs(2);
    }

    function testRevert_NotEnoughEggTokens() public{
        vm.deal(cryptoAnts.owner(), 1 ether);
        vm.prank(cryptoAnts.owner());
        vm.expectRevert(CryptoAnts.NoEggs.selector);
        cryptoAnts.createAnt();
    }

    modifier buyEGGS() {
        vm.deal(cryptoAnts.owner(), 1 ether);
        vm.prank(cryptoAnts.owner());
        cryptoAnts.buyEggs(_mint_amount);
        _;  
    }

    function test_UsersCreate_AntUsingEgg() public buyEGGS {
        vm.deal(cryptoAnts.owner(), 1 ether);
        vm.startPrank(cryptoAnts.owner());

        _antIdCounter.increment();
        _antId = _antIdCounter.current();
        uint256 antsIdAddress = 0;
        ++antsIdAddress;
        cryptoAnts.createAnt();
       
        assertEq(cryptoAnts.antToOwner(_antId), cryptoAnts.owner());
        assertEq(cryptoAnts.eggsToOwner(cryptoAnts.owner()), 0);
        vm.stopPrank();
    }

    modifier createANT() {
        vm.deal(cryptoAnts.owner(), 1 ether);
        vm.startPrank(cryptoAnts.owner());
        _antIdCounter.increment();
        _antId = _antIdCounter.current();
        uint256 antsIdAddress = 0;
        ++antsIdAddress;
        cryptoAnts.createAnt();
        vm.stopPrank();
        _;
    }

    function test_SellAnt() public buyEGGS createANT lock{
        
        address _recipient = payable(0x7D4BF49D39374BdDeB2aa70511c2b772a0Bcf91e);
        vm.deal(cryptoAnts.owner(), 1 ether);
        vm.deal(address(cryptoAnts), 1 ether);
        vm.deal(_recipient, 1 ether);
        vm.startPrank(cryptoAnts.owner());

        _antId = _antIdCounter.current();
        cryptoAnts.sellAnt(_antId, _recipient);

        assertNotEq(cryptoAnts.antToOwner(_antId), cryptoAnts.owner());
        assertEq(cryptoAnts.antToAddress(cryptoAnts.owner()), 0);
        assertEq(cryptoAnts.antToOwner(_antId), _recipient);
        assertEq(cryptoAnts.antToAddress(_recipient), 1);

        console.log("Balance of recipient:", (_recipient).balance);
        console.log("Balance of owner:", (cryptoAnts.owner()).balance);
        vm.stopPrank();  
    }

    
     function _random(uint256 max) private view returns (uint256) {
        uint256 blockNumber = block.number - 1; 
        bytes32 blockHash = blockhash(blockNumber);
        return uint256(blockHash) % max;
    }
    
    function isExpired() private pure returns (bool) {
        uint256 blockNumber = 1000;
        uint256 expirationBlock = 90;
        return blockNumber >= expirationBlock;
    }

    function test_createEggs() public  buyEGGS createANT lock{
        vm.deal(cryptoAnts.owner(), 10 ether);
        vm.startPrank(cryptoAnts.owner());

        _antId = _antIdCounter.current();
        isExpired();

        assertLt(_random(10), _antDeathChance);
        delete antToOwner[_antId];
        uint256 eggAmount = _random(_antMaxEggs + 1);
        cryptoAnts.createEggs(_antId);
        console.log("Egg Amount:", eggAmount);
        eggsToOwner[cryptoAnts.owner()] += eggAmount;
        
        assertNotEq(cryptoAnts.antToOwner(_antId), cryptoAnts.owner());
        assertEq(cryptoAnts.eggsToOwner(cryptoAnts.owner()),eggAmount);
        vm.stopPrank();
    }
}

