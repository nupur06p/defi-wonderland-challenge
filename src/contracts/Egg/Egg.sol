
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/interfaces/IERC20.sol";

// import {Ownable} from './Ownable.sol';
//Deployer: 0x4d696155d02d83d8c66C729c0088984682b00e74
//Deployed to: 0x32369528a9af9f4fb0A69c809B9a5e640B4dFd72
//Transaction hash: 0x98470caecf2c853b089fe634c64bf3a5806a3d5c6b8c058cb3f38c86ae0b0e5b

interface IEgg is IERC20 {
  function mint(address, uint256) external;
}

//SPDX-License-Identifier: Unlicense
// pragma solidity 0.8.4 < 0.9.0;
pragma solidity ^0.8.20;

contract Egg is ERC20, IEgg {
  //@audit - this address is not required
  // address private _ants;


  // @info - _ants is a private address that stores the address of the CryptoAnts contract
  // @audit - why are CryptoAnts contract minting new EGG tokens ? It is the other way round. CryptoAnts address should be removed
  constructor() ERC20('EGG', 'EGG') {
    // _ants = __ants;
  }

  function mint(address _to, uint256 _amount) external override{
    //solhint-disable-next-line

    // @ Q - why only the ants contract can call this function? EGG can be used to create an ANT, so why is it the other way round?
    // @info - It mints '_amount' of EGG tokens to the '_to' address using the _mint function inherited from the ERC20 contract.
    // if (msg.sender != _ants){
    //   revert OnlyAntsCanMintTheEggs();
    // }
    _mint(_to, _amount);
  }

  //@info - Override the decimals function to return 0, making the token indivisible
  // @info - The visisbility of this function should be public to match the visibility of the parent contract
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}
