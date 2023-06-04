// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../../contracts/MitchMinterSupply.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../contracts/MitchToken.sol';

contract deployMitchMinter is Script {
    using SafeERC20 for IERC20;

    address goerliDAI = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60;
    address mumbaiWETH = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
    address testGcWeth = 0x736a98655049433f79dCcF5e54b887E8890b63D1;
    address goerliMitchToken = 0x32c3345101e6e51314f2cfcCc50B116001a89b89;
    address gnosisTestMitchToken = 0xf7dcE74803F441466528721E20CB4b0F0AdB5314;
    address mumbaMitchToken = 0x9F397aD4F786Ee7aA7E3613b4c721Be32aB95369;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        MitchToken rewardToken =  MitchToken(gnosisTestMitchToken);
        string memory baseURI = 'ipfs://QmWkJT5MrHC85mMjgca3B8A3WdcpQsmuXLBQduUuwzHMYz';
        address paymentToken = testGcWeth;
        uint256 price = 0.001 ether;
        MitchMinter mintingContract = new MitchMinter(baseURI, IERC20(paymentToken), address(rewardToken), price);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/1.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/2.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/3.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/4.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/5.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/6.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/7.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/8.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/9.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/10.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/11.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/12.json',100);
        mintingContract.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/13.json',100);
        console.log('there are this many tokens', mintingContract.uniqueTokens());
        console.log('this is the mitchMintingContract', address(mintingContract));
        console.log('this is the rewardToken', address(rewardToken));
        rewardToken.grantRole(rewardToken.MINTER_ROLE(), address(mintingContract));
        mintingContract.setNativeTokenMinting(false);
    }
}
