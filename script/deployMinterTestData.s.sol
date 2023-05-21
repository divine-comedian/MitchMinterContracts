// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../contracts/MitchMinter.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../contracts/MitchToken.sol';

contract deployMitchMinter is Script {
    using SafeERC20 for IERC20;
    address mumbaiWETH = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
    address testGcWeth = 0x736a98655049433f79dCcF5e54b887E8890b63D1;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        MitchToken rewardToken = new MitchToken();
        string memory baseURI = 'ipfs://QmWkJT5MrHC85mMjgca3B8A3WdcpQsmuXLBQduUuwzHMYz';
        address paymentToken = testGcWeth;
        uint256 price = 0.001 ether;
        MitchMinter mintingContract = new MitchMinter(baseURI, IERC20(paymentToken), address(rewardToken), price);
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/1.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/2.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/3.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/4.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/5.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/6.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/7.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/8.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/9.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/10.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/11.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/12.json");
        mintingContract.addToken("ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/13.json");
        console.log("there are this many tokens", mintingContract.getUniqueTokens());
        console.log("this is the mitchMintingContract", address(mintingContract));
        console.log("this is the rewardToken", address(rewardToken));
        rewardToken.grantRole(rewardToken.MINTER_ROLE(), address(mintingContract));
        mintingContract.setNativeTokenMinting(false);

    }
}