// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '../contracts/MitchMinter.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../contracts/MitchToken.sol';



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
    ERC20Mintable public paymentTokenContract;
    MitchToken public mitchTokenContract;

    uint256 price = 300;

    address internal owner = address(1);
    address internal minterOne = address(2);
    address internal minterTwo = address(3);
    address internal minterThree = address(4);
    address internal minterFour = address(5);

    function setUp() public {
        vm.deal(address(minterOne), 2000);
        vm.deal(address(minterTwo), 2000);
        vm.deal(address(minterThree), 2000);
        
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("payment token", "PAY");
        mitchTokenContract = new MitchToken();
        mintingContract = new MitchMinter(baseURI, paymentTokenContract, address(mitchTokenContract), price);
        mintingContract.setNativeTokenMinting(false);
        paymentTokenContract.mint(minterOne, 100000);
        paymentTokenContract.mint(minterTwo, 100000);
        paymentTokenContract.mint(minterThree, 100000);

        mintingContract.addToken('firstTest');
        mintingContract.addToken('secondTest');
        mintingContract.addToken('thirdTest');
        mintingContract.addToken('fourthTest');
        mitchTokenContract.grantRole(mitchTokenContract.MINTER_ROLE(), address(mintingContract));

        vm.stopPrank();

        vm.prank(minterOne);
        paymentTokenContract.approve(address(mintingContract), 5000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(mintingContract), 5000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(mintingContract), 5000);
    }

    function testTokenURI() public {
       string memory firstURI = mintingContract.uri(1);
       string memory secondURI = mintingContract.uri(2);
       assertEq(firstURI, 'firstTest');
       assertEq(secondURI, 'secondTest');
    } 


    function testSetTokenURI() public {
        assertEq(mintingContract.uri(1), 'firstTest');
        vm.prank(owner);
        mintingContract.setTokenURI(1, "another test");
        assertEq(mintingContract.uri(1), "another test");
    }

    function testSetTokenPrice() public {
        uint256 tokenPrice;
        string memory tokenURI;
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        assertEq(tokenPrice, price);
        vm.prank(owner);
        mintingContract.setTokenPrice(1, 500);
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        assertEq(tokenPrice, 500);
    }

    function testSetDefaultPrice() public {
        uint256 tokenPrice;
        string memory tokenURI;
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        assertEq(tokenPrice, price);
        vm.prank(owner);
        mintingContract.setDefaultPrice(500);
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        assertEq(tokenPrice, 500);
    }

    function testResetTokenPrice() public {
        uint256 tokenPrice;
        string memory tokenURI;
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        vm.startPrank(owner);
        mintingContract.setTokenPrice(1, 500);
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        assertEq(tokenPrice, 500);
        mintingContract.resetTokenPrice(1);
        (tokenPrice, tokenURI) = mintingContract.getTokenInfo(1);
        assertEq(tokenPrice, price);
    }

    function testChangePaymentToken() public {
        address oldToken = address(mintingContract.paymentToken());
        ERC20 anotherToken = new ERC20Mintable("mitch 2", "M2TCH");
        vm.prank(owner);
        mintingContract.withdrawAndChangePaymentToken(anotherToken);
        address newToken = address(mintingContract.paymentToken());
        assertFalse(oldToken == newToken);
    }

    function testChangePaymentTokenWithBalance() public {
        IERC20 oldToken = mintingContract.paymentToken();
        ERC20 anotherToken = new ERC20Mintable("mitch 2", "M2TCH");
        vm.prank(minterOne);
        mintingContract.mint(msg.sender, 1, 2);
        vm.prank(minterTwo);
        mintingContract.mint(minterThree,2, 3);
        uint256 contractBalance = mintingContract.getBalance();
        vm.prank(owner);
        mintingContract.withdrawAndChangePaymentToken(anotherToken);
        assertEq(oldToken.balanceOf(address(mintingContract)), 0);
        assertEq(oldToken.balanceOf(address(mintingContract.owner())), contractBalance);
    }

    function testWithdraw() public {
        vm.prank(minterOne);
        mintingContract.mint(msg.sender, 1, 2);
        vm.prank(minterTwo);
        mintingContract.mint(minterThree,2, 3);
        uint256 contractBalance = mintingContract.getBalance();
        vm.prank(owner);
        mintingContract.withdrawTokens();
        assertEq(paymentTokenContract.balanceOf(address(mintingContract)), 0);
        assertEq(paymentTokenContract.balanceOf(address(mintingContract.owner())), contractBalance);
    }


    function testWithdrawEther() public {
        console.log("this is the contract's balance before minting", address(mintingContract).balance);
        vm.prank(minterOne);
        (bool success1,) = payable(address(mintingContract)).call{value: 2 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, 2)
        );
        console.log("mint one success" , success1);
        vm.prank(minterTwo);
        (bool success2,) = payable(address(mintingContract)).call{value: 3 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 2, 3)
        );
        console.log("mint two success" , success2);
        uint256 contractEtherBalance = address(mintingContract).balance;
        console.log("this is the contract's ether balance before withdraw", contractEtherBalance);
        vm.prank(owner);
        console.log(address(owner));
        console.log(address(mintingContract.owner()));
        vm.prank(owner);
    try mintingContract.withdrawNativeToken() {
        console.log("Withdraw success");
    } catch Error(string memory reason) {
        console.log("Withdraw failed with reason:", reason);
    } catch {
        console.log("Withdraw failed");
    }
        console.log("this is the owner's balance", address(mintingContract.owner()).balance);
        // assertEq(address(mintingContract).balance, 0);
        // assertEq(address(mintingContract.owner()).balance, contractEtherBalance); 

        }

    function testFailWithdraw() public {
        vm.prank(minterOne);
        mintingContract.mint(msg.sender, 1, 2);
        vm.prank(minterTwo);
        mintingContract.mint(minterThree,2, 3);
        vm.prank(minterFour);
        mintingContract.withdrawTokens();
    }

    function testGetNativeBalance() public {
        vm.deal(address(minterOne), 2000);
        vm.deal(address(minterTwo), 2000);
        vm.prank(owner);
        mintingContract.setNativeTokenMinting(true);
        vm.prank(minterOne);
         (bool success,) = payable(address(mintingContract)).call{value: 2 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, minterOne, 1, 2)
        );
        vm.prank(minterTwo);
         (bool success2,) = payable(address(mintingContract)).call{value: 3 * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, minterOne, 1, 3)
        );
        uint256 contractBalance = mintingContract.getNativeBalance();
        assertEq(contractBalance, 5 * price);
    }

    function testSetNativeTokenMinting() public {
        vm.prank(owner);
        mintingContract.setNativeTokenMinting(true);
        assertEq(mintingContract.nativeMintEnabled(), true);
    }
}
