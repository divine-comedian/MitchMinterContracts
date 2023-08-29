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
    address public optimismWETH = 0x4200000000000000000000000000000000000006;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        string memory baseURI = 'ipfs://QmWkJT5MrHC85mMjgca3B8A3WdcpQsmuXLBQduUuwzHMYz';
        IERC20 paymentToken = IERC20(optimismWETH);
        address rewardTokenAddress = 0x7e553D2cA84Ef26D13416563DE6F7f38597aEDD7;
        uint256 price = 0.005 ether;
        vm.startBroadcast(deployerPrivateKey);
        proxyAdmin = new ProxyAdmin();
        mintingContract = new MitchMinter();
        proxy = new TransparentUpgradeableProxy(address(mintingContract), address(proxyAdmin), '');
        mintingContractProxy = MitchMinter(address(proxy));
        MitchToken rewardToken =  MitchToken(rewardTokenAddress);
        mintingContractProxy.initialize(baseURI, paymentToken, rewardTokenAddress, price);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/AmericanDream.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/BananaChampagne.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/BarbieVoyage.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/Cappadocia.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/DogDude.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/DustyTrailer.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/HappyEaster.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/LetErBuckingham.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/MudMitch.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/NoArt.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/NoParking.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/WindyDesert.json', 50);
        mintingContractProxy.addToken('ipfs://Qma5GVzXysTpL79Qg4yvbW7bvMMQuY1LcRpEWLUAUWPhJz/ZebraPeel.json', 50);
        console.log('there are this many tokens', mintingContractProxy.uniqueTokens());
        console.log('this is the mitchmintingContractProxy', address(mintingContractProxy));
        console.log('this is the rewardToken', address(rewardToken));
        rewardToken.grantRole(rewardToken.MINTER_ROLE(), address(mintingContractProxy));
        mintingContractProxy.setNativeTokenMinting(true);
    }
}
