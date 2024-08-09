### Project Preview
The project is updated on the below details:

• EGGs are ERC20 tokens

• EGGs are indivisible

• ANTs are ERC721 tokens (NFTs)

• Users buy EGGs using ETH

• EGGs costs 0.01 ETH

• An EGG can be used to create an ANT

• Users create an ANT if they own at least one EGG

• An ANT can be sold for 0.004 ETH by the ANT owner

• EGGS can be created randomly between 0 to antMaxEggs. Ants have a x% of dying while creating EGGS

• Owner can change the price of an EGG and ANT

• TimeLock and Expired function handles the time duration

• Random function generates a random number between 0 to antMaxEggs

• Ownable librray applies the onlyOwner modifier to the required functions

• Modifier lock is set to handle Reentrancy attack

• Ownership can be transferred by the owner

• Owner can change the price of an EGG and ANT

• Max eggs (_antMaxEggs) created randomly and ANT death chance (_antDeathChance) can be changed by the owner

### Testing
• Slither and Aderyn tools were used to check for errors.

• Some important errors handled- -- Reentrancy Errors

 -- Removing block.timestamp and creating Timelock Expired functions

 -- Creating a better random function than that using `keccak256(abi.encodePacked)`

 -- Adding several custom errors and events to the code

 -- Marking public functions as external as per the requirement
• E2E tests are complete

• Project is deployed to local network and sepolia test network

• Screenshots of testing the project using foundry and deploying them to local network and sepolia test network is in folder crypto_testdeploy

• E2E tests are complete

Efforts Than Could Make The Code Better
• RandomNumber function was being tested to generate random numbers using Chainlik VRF but faced issues in its deployment and it was required to raise it on GitHub to check the error. It woudl have taken more 2-3 days. Hence, didn't proceed due to time constrain.
