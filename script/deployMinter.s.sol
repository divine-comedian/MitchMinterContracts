// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../contracts/MitchMinter.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../contracts/MitchToken.sol';

contract deployMitchMinter is Script {
    using SafeERC20 for IERC20;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        MitchToken rewardToken = new MitchToken();
        string memory baseURI = 'ipfs://QmWkJT5MrHC85mMjgca3B8A3WdcpQsmuXLBQduUuwzHMYz';
        address paymentToken = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        uint256 price = 0.001 ether;
        MitchMinter mintingContract = new MitchMinter(baseURI, IERC20(paymentToken), address(rewardToken), price);
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/AmericanDream.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/BananaChampagne.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/BarbieVoyage.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/Cappadocia.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/DogDude.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/DustyTrailer.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/HappyEaster.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/LetErBuckingham.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/MudMitch.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/NoArt.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/NoParking.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/WindyDesert.json");
        mintingContract.addToken("ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/ZebraPeel.json");
        console.log("there are this many tokens", mintingContract.getUniqueTokens());
        console.log("this is the mitchMintingContract", address(mintingContract));
        console.log("this is the rewardToken", address(rewardToken));
        rewardToken.grantRole(rewardToken.MINTER_ROLE(), address(mintingContract));
        mintingContract.setNativeTokenMinting(false);
    }
}