// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '../../contracts/MitchMinterSupplyUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../../contracts/MitchToken.sol';
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
        vm.deal(address(minterOne), 2000);
        vm.deal(address(minterTwo), 2000);
        vm.deal(address(minterThree), 2000);

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

    function testTokenURI() public {
        string memory firstURI = mintingContractProxy.uri(1);
        string memory secondURI = mintingContractProxy.uri(2);
        assertEq(firstURI, 'firstTest');
        assertEq(secondURI, 'secondTest');
    }

    function testSetTokenURI() public {
        assertEq(mintingContractProxy.uri(1), 'firstTest');
        vm.prank(owner);
        mintingContractProxy.setTokenURI(1, 'another test');
        assertEq(mintingContractProxy.uri(1), 'another test');
    }

    function testSetTokenPrice() public {
        uint256 tokenPrice;
        string memory tokenURI;
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        assertEq(tokenPrice, price);
        vm.prank(owner);
        mintingContractProxy.setTokenPrice(1, 500);
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        assertEq(tokenPrice, 500);
    }

    function testSetDefaultPrice() public {
        uint256 tokenPrice;
        string memory tokenURI;
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        assertEq(tokenPrice, price);
        vm.prank(owner);
        mintingContractProxy.setDefaultPrice(500);
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        assertEq(tokenPrice, 500);
    }

    function testResetTokenPrice() public {
        uint256 tokenPrice;
        string memory tokenURI;
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        vm.startPrank(owner);
        mintingContractProxy.setTokenPrice(1, 500);
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        assertEq(tokenPrice, 500);
        mintingContractProxy.resetTokenPrice(1);
        (tokenPrice, tokenURI) = mintingContractProxy.getTokenInfo(1);
        assertEq(tokenPrice, price);
    }

    function testChangePaymentToken() public {
        address oldToken = address(mintingContractProxy.paymentToken());
        ERC20 anotherToken = new ERC20Mintable("mitch 2", "M2TCH");
        vm.prank(owner);
        mintingContractProxy.setPaymentToken(anotherToken);
        address newToken = address(mintingContractProxy.paymentToken());
        assertFalse(oldToken == newToken);
    }

    function testChangePaymentTokenWithBalance() public {
        IERC20 oldToken = mintingContractProxy.paymentToken();
        ERC20 anotherToken = new ERC20Mintable("mitch 2", "M2TCH");
        vm.prank(minterOne);
        mintingContractProxy.mint(msg.sender, 1, 2);
        vm.prank(minterTwo);
        mintingContractProxy.mint(minterThree, 2, 3);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContractProxy));

        vm.startPrank(owner);
        mintingContractProxy.withdrawTokens();
        mintingContractProxy.setPaymentToken(anotherToken);
        assertEq(oldToken.balanceOf(address(mintingContractProxy)), 0);
        assertEq(oldToken.balanceOf(address(mintingContractProxy.owner())), contractBalance);
    }

    function testWithdraw() public {
        vm.prank(minterOne);
        mintingContractProxy.mint(msg.sender, 1, 2);
        vm.prank(minterTwo);
        mintingContractProxy.mint(minterThree, 2, 3);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContractProxy));

        vm.prank(owner);
        mintingContractProxy.withdrawTokens();
        assertEq(paymentTokenContract.balanceOf(address(mintingContractProxy)), 0);
        assertEq(paymentTokenContract.balanceOf(address(mintingContractProxy.owner())), contractBalance);
    }

    function testWithdrawEther() public {
        console.log("this is the contract's balance before minting", address(mintingContractProxy).balance);
        vm.prank(minterOne);
        (bool success1,) = payable(address(mintingContractProxy)).call{value: 2 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, 2)
        );
        console.log('mint one success', success1);
        vm.prank(minterTwo);
        (bool success2,) = payable(address(mintingContractProxy)).call{value: 3 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 2, 3)
        );
        console.log('mint two success', success2);
        uint256 contractEtherBalance = address(mintingContractProxy).balance;
        console.log("this is the contract's ether balance before withdraw", contractEtherBalance);
        vm.prank(owner);
        console.log(address(owner));
        console.log(address(mintingContractProxy.owner()));
        vm.prank(owner);
        try mintingContractProxy.withdrawNativeToken() {
            console.log('Withdraw success');
        } catch Error(string memory reason) {
            console.log('Withdraw failed with reason:', reason);
        } catch {
            console.log('Withdraw failed');
        }
        console.log("this is the owner's balance", address(mintingContractProxy.owner()).balance);
        // assertEq(address(mintingContractProxy).balance, 0);
        // assertEq(address(mintingContractProxy.owner()).balance, contractEtherBalance);
    }

    function testFailWithdraw() public {
        vm.prank(minterOne);
        mintingContractProxy.mint(msg.sender, 1, 2);
        vm.prank(minterTwo);
        mintingContractProxy.mint(minterThree, 2, 3);
        vm.prank(minterFour);
        mintingContractProxy.withdrawTokens();
    }

    function testGetNativeBalance() public {
        vm.deal(address(minterOne), 2000);
        vm.deal(address(minterTwo), 2000);
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);
        vm.prank(minterOne);
        (bool success,) = payable(address(mintingContractProxy)).call{value: 2 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, minterOne, 1, 2)
        );
        vm.prank(minterTwo);
        (bool success2,) = payable(address(mintingContractProxy)).call{value: 3 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, minterOne, 1, 3)
        );
        uint256 contractBalance = address(mintingContractProxy).balance;

        assertEq(contractBalance, 5 * price);
    }

    function testSetNativeTokenMinting() public {
        vm.prank(owner);
        mintingContractProxy.setNativeTokenMinting(true);
        assertEq(mintingContractProxy.nativeMintEnabled(), true);
    }
}
