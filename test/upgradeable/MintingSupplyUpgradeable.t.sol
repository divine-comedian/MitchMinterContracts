// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../contracts/MitchMinterSupplyUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../../contracts/MitchToken.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract ERC20Mintable is ERC20, Ownable {
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

contract TestMitchMinter is Test {
    using SafeMath for uint256;

    string baseURI = 'test';
    MitchMinter public mintingContract;
    MitchMinter public mintingContractProxy;
    ERC20Mintable public paymentTokenContract;
    MitchToken public mitchTokenContract;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public proxy;
    uint256 price = 300;
    address internal proxyAdminAddress = address(0);
    address internal owner = address(1);
    address internal minterOne = address(2);
    address internal minterTwo = address(3);
    address internal minterThree = address(4);
    address internal minterFour = address(5);

    function setUp() public {
        vm.prank(proxyAdminAddress);
        proxyAdmin = new ProxyAdmin();
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("payment token", "PAY");
        mitchTokenContract = new MitchToken();
        mintingContract = new MitchMinter();
        proxy = new TransparentUpgradeableProxy(address(mintingContract), address(proxyAdmin), '');
        mintingContractProxy = MitchMinter(address(proxy));
        mintingContractProxy.initialize(baseURI, IERC20(paymentTokenContract), address(mitchTokenContract), price);
        mintingContractProxy.setNativeTokenMinting(false);
        paymentTokenContract.mint(minterOne, 100000);
        paymentTokenContract.mint(minterTwo, 100000);
        paymentTokenContract.mint(minterThree, 100000);

        mintingContractProxy.addToken('firstTest', 100);
        mintingContractProxy.addToken('secondTest', 100);
        mintingContractProxy.addToken('thirdTest', 100);
        mintingContractProxy.addToken('fourthTest', 100);
        mitchTokenContract.grantRole(mitchTokenContract.MINTER_ROLE(), address(mintingContractProxy));
        vm.stopPrank();

        vm.prank(minterOne);
        paymentTokenContract.approve(address(mintingContractProxy), 5000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(mintingContractProxy), 5000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(mintingContractProxy), 5000);
    }

    function testMint() public {
        vm.prank(minterOne);
        uint256 mintAmount = 5;
        mintingContractProxy.mint(msg.sender, 1, mintAmount);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContractProxy));
        assertEq(contractBalance, (price * mintAmount));
    }

    function testMintWithNative() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);
        vm.deal(address(minterOne), 2000);
        vm.prank(minterOne);
        console.log(address(minterOne).balance);
        uint256 mintAmount = 5;
        payable(address(mintingContractProxy)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, mintAmount)
        );
        uint256 contractBalance = address(mintingContractProxy).balance;
        assertEq(contractBalance, (price * mintAmount));
    }

    function testMintBatchWithNative() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);
        uint256 finalPrice;
        uint256 totalAmount;
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenPrice;
            string memory tokenURI;
            (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(tokenIds[i]);
            finalPrice += tokenPrice * tokenAmounts[i];
            totalAmount += tokenAmounts[i];
            unchecked {
                i++;
            }
        }

        console.log('this is the price', finalPrice);
        vm.deal(address(minterOne), 3000);
        vm.prank(minterOne);
        console.log("this is the minter's balance", address(minterOne).balance);
        payable(address(mintingContractProxy)).call{value: finalPrice}(
            abi.encodeWithSelector(MitchMinter.mintBatchWithNativeToken.selector, msg.sender, tokenIds, tokenAmounts)
        );
        uint256 contractBalance = address(mintingContractProxy).balance;
        assertEq(contractBalance, (finalPrice));
        console.log("this is the minter's balance after mint", address(minterOne).balance);
    }

    function testMintNoExist() public {
        vm.prank(minterOne);
        uint256 tokenId = 6;
        uint256 mintAmount = 5;
        vm.expectRevert(abi.encodeWithSelector(MitchMinter.NoTokenExists.selector, tokenId));
        mintingContractProxy.mint(msg.sender, tokenId, mintAmount);
    }

    function testBatchMint() public {
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.prank(minterOne);
        mintingContractProxy.mintBatch(msg.sender, tokenIds, tokenAmounts);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContractProxy));
        assertEq(contractBalance, 1800);
    }

    function testOwnerBatchMint() public {
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.prank(owner);
        mintingContractProxy.mintBatch(msg.sender, tokenIds, tokenAmounts);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContractProxy));
        assertEq(contractBalance, 0);
    }

    function testOwnerMint() public {
        vm.prank(owner);
        uint256 mintAmount = 5;
        mintingContractProxy.mint(msg.sender, 1, mintAmount);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContractProxy));
        assertEq(contractBalance, 0);
    }

    function testMitchBalance() public {
        vm.prank(minterOne);
        uint256 mintAmount = 5;
        mintingContractProxy.mint(minterOne, 1, mintAmount);
        uint256 mitchTokenBalance = mitchTokenContract.balanceOf(minterOne);
        console.log('the balance of the mitch token is', mitchTokenBalance);
        assertEq(mitchTokenBalance, mintAmount.mul(1 ether));
    }

    function testMitchBalanceBatch() public {
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256 finalPrice;
        uint256 totalAmount;

        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenPrice;
            string memory tokenURI;
            (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(tokenIds[i]);
            finalPrice += tokenPrice * tokenAmounts[i];
            totalAmount += tokenAmounts[i];
            unchecked {
                i++;
            }
        }

        console.log('this is the price', finalPrice);

        vm.prank(minterOne);
        mintingContractProxy.mintBatch(minterOne, tokenIds, tokenAmounts);
        uint256 mitchTokenBalance = mitchTokenContract.balanceOf(minterOne);
        console.log('this is the total amount', totalAmount);
        console.log('the balance of the mitch token is', mitchTokenBalance);
        assertEq(mitchTokenBalance, totalAmount.mul(1 ether));
    }

    function testMitchBalanceBatchWithNative() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);

        uint256 finalPrice;
        uint256 totalAmount;
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenPrice;
            string memory tokenURI;
            (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(tokenIds[i]);
            finalPrice += tokenPrice * tokenAmounts[i];
            totalAmount += tokenAmounts[i];
            unchecked {
                i++;
            }
        }

        console.log('this is the price', finalPrice);
        vm.deal(address(minterOne), 3000);
        vm.prank(minterOne);
        console.log("this is the minter's balance", address(minterOne).balance);
        payable(address(mintingContractProxy)).call{value: finalPrice}(
            abi.encodeWithSelector(MitchMinter.mintBatchWithNativeToken.selector, minterOne, tokenIds, tokenAmounts)
        );
        uint256 mitchTokenBalance = mitchTokenContract.balanceOf(minterOne);
        console.log('the balance of the mitch token is', mitchTokenBalance);
        assertEq(mitchTokenBalance, totalAmount.mul(1 ether));
    }

    function testMitchBalanceWithNative() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);
        vm.deal(address(minterOne), 2000);
        uint256 mintAmount = 5;
        vm.prank(minterOne);
        (bool success,) = payable(address(mintingContractProxy)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, minterOne, 1, mintAmount)
        );
        console.log('minted successfully', success);
        uint256 mitchTokenBalance = mitchTokenContract.balanceOf(minterOne);
        console.log('the balance of the mitch token is', mitchTokenBalance);
        assertEq(mitchTokenBalance, mintAmount.mul(1 ether));
    }

    function testFailNativeTokenMint() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(false);
        vm.deal(address(minterOne), 2000);
        uint256 mintAmount = 5;
        vm.prank(minterOne);
        (bool success,) = payable(address(mintingContractProxy)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, minterOne, 1, mintAmount)
        );
        vm.expectRevert(bytes('Can only mint with ERC20 token'));
    }

    function testFailerc20TokenMint() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);
        uint256 mintAmount = 5;
        vm.prank(minterOne);
        mintingContractProxy.mint(minterOne, 1, mintAmount);
        vm.expectRevert(bytes('Can only mint with native token'));
    }
}
