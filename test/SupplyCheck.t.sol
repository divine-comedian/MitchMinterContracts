// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '../contracts/MitchMinterSupply.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../contracts/MitchToken.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

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
    ERC20Mintable public paymentTokenContract;
    MitchToken public mitchTokenContract;
    uint256 price = 300;

    address internal owner = address(1);
    address internal minterOne = address(2);
    address internal minterTwo = address(3);
    address internal minterThree = address(4);
    address internal minterFour = address(5);

    function setUp() public {
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("payment token", "PAY");
        mitchTokenContract = new MitchToken();
        mintingContract = new MitchMinter(baseURI, paymentTokenContract, address(mitchTokenContract), price);
        mintingContract.setNativeTokenMinting(false);
        paymentTokenContract.mint(minterOne, 10000000);
        paymentTokenContract.mint(minterTwo, 100000000);
        paymentTokenContract.mint(minterThree, 100000000);
        vm.deal(address(minterOne), 200000);
        vm.deal(address(minterTwo), 200000);
        vm.deal(address(minterThree), 200000);

        mintingContract.addToken('firstTest', 10);
        mintingContract.addToken('secondTest', 10);
        mintingContract.addToken('thirdTest', 10);
        mintingContract.addToken('fourthTest', 10);
        mitchTokenContract.grantRole(mitchTokenContract.MINTER_ROLE(), address(mintingContract));
        vm.stopPrank();

        vm.prank(minterOne);
        paymentTokenContract.approve(address(mintingContract), 500000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(mintingContract), 500000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(mintingContract), 500000);
    }

    function testFailMintTokenSupply() public {
        uint256 mintAmount = 4;
        vm.prank(minterOne);
        mintingContract.mint(msg.sender, 1, mintAmount);
                vm.prank(minterTwo);
        mintingContract.mint(msg.sender, 1, mintAmount);
        vm.prank(minterThree);
        mintingContract.mint(msg.sender, 1, mintAmount);

        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContract));

        vm.expectRevert(bytes('Cannot exceed Max Supply'));
    }

    function testMintTokenSupply() public {

        uint256 mintAmount = 4;
        vm.prank(minterOne);
        mintingContract.mint(msg.sender, 1, mintAmount);
                vm.prank(minterTwo);
        mintingContract.mint(msg.sender, 1, mintAmount);
        vm.prank(minterThree);
        mintingContract.mint(msg.sender, 1, 2);
        console.log('this is the max supply', mintingContract.maxTokenSupply(1));
        console.log('this is the total supply', mintingContract.totalSupply(1));
        assertEq(mintingContract.totalSupply(1), mintingContract.maxTokenSupply(1));
    }

    function testMintWithNativeTokenSupply() public {
        vm.prank(owner);
        mintingContract.setNativeTokenMinting(true);
        vm.deal(address(minterOne), 2000);
        vm.prank(minterOne);
        console.log(address(minterOne).balance);
        uint256 mintAmount = 5;
        payable(address(mintingContract)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, mintAmount)
        );
        vm.prank(minterTwo);
        console.log(address(minterOne).balance);
        payable(address(mintingContract)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, mintAmount)
        );
        uint256 contractBalance = address(mintingContract).balance;
        assertEq(mintingContract.totalSupply(1), mintingContract.maxTokenSupply(1));
    }

    function testFailMintWithNativeTokenSupply() public {
        vm.prank(owner);
        mintingContract.setNativeTokenMinting(true);
        vm.deal(address(minterOne), 2000);
        vm.prank(minterOne);
        console.log(address(minterOne).balance);
        uint256 mintAmount = 6;
        payable(address(mintingContract)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, mintAmount)
        );
        vm.prank(minterTwo);
        console.log(address(minterOne).balance);
        payable(address(mintingContract)).call{value: mintAmount * price}(
            abi.encodeWithSelector(MitchMinter.mintWithNativeToken.selector, msg.sender, 1, mintAmount)
        );
        uint256 contractBalance = address(mintingContract).balance;
        vm.expectRevert(bytes('Cannot exceed Max Supply'));
    }


    function testFailMintBatchWithNativeTokenSupply() public {
        vm.prank(owner);
        mintingContract.setNativeTokenMinting(true);
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
            (tokenPrice, tokenURI) = mintingContract.getTokenInfo(tokenIds[i]);
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
        payable(address(mintingContract)).call{value: finalPrice}(
            abi.encodeWithSelector(MitchMinter.mintBatchWithNativeToken.selector, msg.sender, tokenIds, tokenAmounts)
        );
         vm.prank(minterTwo);
        console.log("this is the minter's balance", address(minterOne).balance);
        payable(address(mintingContract)).call{value: finalPrice}(
            abi.encodeWithSelector(MitchMinter.mintBatchWithNativeToken.selector, msg.sender, tokenIds, tokenAmounts)
        );
        uint256 contractBalance = address(mintingContract).balance;
        vm.expectRevert(bytes('Cannot exceed Max Supply'));
        console.log("this is the minter's balance after mint", address(minterOne).balance);
    }


    function testFailBatchMintTokenSupply() public {
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.prank(minterOne);
        mintingContract.mintBatch(msg.sender, tokenIds, tokenAmounts);
        vm.prank(minterTwo);
        mintingContract.mintBatch(msg.sender, tokenIds, tokenAmounts);
        vm.expectRevert(bytes('Cannot exceed Max Supply'));
    }

    function testFailOwnerBatchMintTokenSupply() public {
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 3;
        tokenAmounts[1] = 4;
        tokenAmounts[2] = 4;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.prank(owner);
        mintingContract.mintBatch(msg.sender, tokenIds, tokenAmounts);
        vm.expectRevert(bytes('Cannot exceed Max Supply'));
    }

    
}
