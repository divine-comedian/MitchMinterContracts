// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../contracts/MitchMinterSupplyUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../../contracts/MitchToken.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract deployMitchMinter is Script {
    using SafeERC20 for IERC20;

    MitchMinter public mintingContract;
    MitchMinter public mintingContractProxy;
    MitchToken public mitchTokenContract;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public proxy;
    IERC20 public paymentTokenContract;

    address goerliDAI = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60;
    address mumbaiWETH = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
    address testGcWeth = 0x736a98655049433f79dCcF5e54b887E8890b63D1;
    address goerliMitchToken = 0x32c3345101e6e51314f2cfcCc50B116001a89b89;
    address gnosisTestMitchToken = 0xf7dcE74803F441466528721E20CB4b0F0AdB5314;
    address mumbaMitchToken = 0x9F397aD4F786Ee7aA7E3613b4c721Be32aB95369;
    address newProxyAdmin = 0x48A3cF9b05993e39b16866ff13b6134d3fED0cab;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        string memory baseURI = 'ipfs://QmWkJT5MrHC85mMjgca3B8A3WdcpQsmuXLBQduUuwzHMYz';
        IERC20 paymentToken = IERC20(testGcWeth);
        address rewardTokenAddress = gnosisTestMitchToken;
        uint256 price = 0.001 ether;
        vm.startBroadcast(deployerPrivateKey);
        proxyAdmin = new ProxyAdmin();
        mintingContract = new MitchMinter();
        proxy = new TransparentUpgradeableProxy(address(mintingContract), address(proxyAdmin), '');
        mintingContractProxy = MitchMinter(address(proxy));
        MitchToken rewardToken =  MitchToken(rewardTokenAddress);
        mintingContractProxy.initialize(baseURI, paymentToken, rewardTokenAddress, price);

        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/1.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/2.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/3.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/4.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/5.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/6.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/7.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/8.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/9.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/10.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/11.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/12.json',50);
        mintingContractProxy.addToken('ipfs://QmUsoyGXmfQDTdwqn3ZcDvtBTqTQzenUGgXuyFzwZcoiyk/13.json',50);
        console.log('there are this many tokens', mintingContractProxy.uniqueTokens());
        console.log('this is the mitchmintingContractProxy', address(mintingContractProxy));
        console.log('this is the rewardToken', address(rewardToken));
        rewardToken.grantRole(rewardToken.MINTER_ROLE(), address(mintingContractProxy));
        mintingContractProxy.setNativeTokenMinting(false);
    }
}
