// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'forge-std/Test.sol';
import 'ds-test/test.sol';
import '../contracts/MitchMinterSupply.sol';
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
    uint256 firstTokenPrice = 300;
    uint256 secondTokenPrice = 500;
    uint256 thirdTokenPrice = 700;
    uint256 fourthTokenPrice = 900;

    function setUp() public {
        vm.startPrank(owner);
        paymentTokenContract = new ERC20Mintable("payment token", "PAY");
        mitchTokenContract = new MitchToken();
        mintingContract = new MitchMinter(baseURI, paymentTokenContract, address(mitchTokenContract), price);
        mintingContract.setNativeTokenMinting(false);
        paymentTokenContract.mint(minterOne, 100000);
        paymentTokenContract.mint(minterTwo, 100000);
        paymentTokenContract.mint(minterThree, 100000);

        mintingContract.addToken('firstTest', 100);
        mintingContract.setTokenPrice(1, firstTokenPrice);
        mintingContract.addToken('secondTest', 100);
        mintingContract.setTokenPrice(2, secondTokenPrice);
        mintingContract.addToken('thirdTest', 100);
        mintingContract.setTokenPrice(3, thirdTokenPrice);
        mintingContract.addToken('fourthTest', 100);
        mintingContract.setTokenPrice(4, fourthTokenPrice);
        mitchTokenContract.grantRole(mitchTokenContract.MINTER_ROLE(), address(mintingContract));
        vm.stopPrank();

        vm.prank(minterOne);
        paymentTokenContract.approve(address(mintingContract), 5000);
        vm.prank(minterTwo);
        paymentTokenContract.approve(address(mintingContract), 5000);
        vm.prank(minterThree);
        paymentTokenContract.approve(address(mintingContract), 5000);
    }

    function testTokenPriceMint() public {
        vm.prank(minterOne);
        uint256 mintAmount = 5;
        mintingContract.mint(msg.sender, 1, mintAmount);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContract));

        assertEq(contractBalance, (firstTokenPrice * mintAmount));
    }

    function testTokenPriceBatchMint() public {
        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 2;
        tokenAmounts[1] = 2;
        tokenAmounts[2] = 2;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256 expectedBalance = (firstTokenPrice * tokenAmounts[0]) + (secondTokenPrice * tokenAmounts[1])
            + (thirdTokenPrice * tokenAmounts[2]);

        vm.prank(minterOne);
        mintingContract.mintBatch(msg.sender, tokenIds, tokenAmounts);
        uint256 contractBalance = paymentTokenContract.balanceOf(address(mintingContract));


        console.log('expected contract balance is', expectedBalance);
        console.log('contract balance is', contractBalance);
        assertEq(expectedBalance, contractBalance);
    }
}
