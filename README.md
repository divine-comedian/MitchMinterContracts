# Mint Mitch Contracts

There are two contracts in this repository:

## MitchMinter.sol
 This contract is used to mint Mitch tokens. It is an ERC115 contract that allows new tokens be added by the owner and users to mint multiple copies of NFTs. It also handles receiving payment from users in exchange for NFTs as well as mints a separate ERC20 to users for every NFT they mint.

## MitchToken.sol
 A simple ERC20 token contract that is minted to users when they mint NFTs. Designed for future Mitchenomics purposes.

 ----

 In this repo you'll also find a suite of tests I wrote in foundry to test the contracts. To run the tests, you'll need to setup a foundry project then run with `forge test`.