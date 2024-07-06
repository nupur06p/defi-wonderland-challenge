// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {CryptoAnts} from "../src/contracts/Ant/CryptoAnts.sol";
import {Egg} from "../src/contracts/Egg/Egg.sol";
// import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../src/contracts/Ant/Counters.sol";

// interface IEgg is IERC20 {
//     function mint(address, uint256) external;
// }

// contract CryptoToken is CryptoAnts{

//     Egg egg = new Egg();
//     address _addr_egg = address(egg);

//     // IEgg EGGS;
//     using Counters for Counters.Counter;

//     constructor(address _initialOwner) CryptoAnts(_addr_egg){}

//     function _buyEggs(uint256 _amount) external {
//         EGGS.mint(_owneR, _amount);
//     }

//     function _createAnt() external {
//         antidCounter.increment();
//         uint256 _antId = antidCounter.current();
//         _safeMint(address(this), _antId, "");
//     }
// }

contract DeployCryptoAntsScript is Script {
    // function setUp() public {}

    Egg egg = new Egg();

    function run() external returns(CryptoAnts){

        // uint privateKey = vm.envUint("PRIVATE_KEY");
        // address account = vm.addr(privateKey);
        // console.log("Account:", account);

        vm.startBroadcast();
        CryptoAnts cryptoAnts = new CryptoAnts(address(egg));
        vm.stopBroadcast();
        return cryptoAnts;
    }
}
