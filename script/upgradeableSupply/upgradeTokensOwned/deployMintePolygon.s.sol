// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../../contracts/MitchMinterSupplyUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../../../contracts/MitchToken.sol';
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
    address public proxyAddress = 0xf7dcE74803F441466528721E20CB4b0F0AdB5314;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        proxyAdmin = ProxyAdmin(0xA5d83aD8Cd670D2Cd450BDFc0257419AE5c1d077);
        mintingContract = new MitchMinter();
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(proxyAddress)), address(mintingContract));
        
    }
}
