// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';

interface IMitchToken {
    function mint(address to, uint256 amount) external;
}   

contract MitchMinter is ERC1155Burnable, Ownable, ERC1155URIStorage, ERC1155Supply {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    error NoTokenExists(uint256 tokenId);

    event Mint(address recipient, uint256 tokenId, uint256 amount, uint256 totalPrice);
    event MintBatch(address recipient, uint256 totalAmounts, uint256 finalPrice);
    event Withdrawal(address recipient, uint256 amount);

    bool public nativeMintEnabled;
    IERC20 public paymentToken;
    uint96 public uniqueTokens = 0;
    IMitchToken public mitchToken;
    string baseURI;
    uint256 defaultPrice;

    mapping(uint256 => uint256) public tokenPrice;
    mapping(uint256 => uint256) public maxTokenSupply;

    /// This is the basic initliazation function for the contract
    /// @param _baseURI the base URI to initliaze the contract with - will not be shown to users
    /// @param _paymentToken this is the token that will be used to buy NFTs when nativeMintEnabled is false
    /// @param _mitchToken this is the address of the Mitch Token which is minted to the NFT minter for every NFT they mint
    /// @param _defaultPrice the default price if none has been defined for a specific tokenID
    constructor(string memory _baseURI, IERC20 _paymentToken, address _mitchToken, uint256 _defaultPrice)
        ERC1155(_baseURI)
    {
        baseURI = _baseURI;
        paymentToken = _paymentToken;
        defaultPrice = _defaultPrice;
        mitchToken = IMitchToken(_mitchToken);
        nativeMintEnabled = true;
    }

    function _handleMint(address to, uint256 id, uint256 amount, uint256 value, bool isNative) internal {
        uint256 totalPrice;
        uint256 unitPrice;
        uint256 currentSupply = totalSupply(id);
        require(amount > 0, 'Amount cannot be 0');
        require(currentSupply + amount <= maxTokenSupply[id], 'Cannot exceed Max Supply');

        if (msg.sender != owner()) {
            tokenPrice[id] == 0 ? unitPrice = defaultPrice : unitPrice = tokenPrice[id];
            totalPrice = unitPrice.mul(amount);
            if (isNative) {
                require(value >= totalPrice, 'Insufficient funds!');
            } else {
                paymentToken.safeTransferFrom(msg.sender, address(this), totalPrice);
            }
            emit Mint(to, id, amount, totalPrice);
        }
        mitchToken.mint(to, amount.mul(1 ether));
        _mint(to, id, amount, '');
    }

    /// mint NFTs with payment token
    /// @param to the address to mint the NFTs to
    /// @param id The token ID of the mint to be minted
    /// @param amount the amount of NFTs to mint
    function mint(address to, uint256 id, uint256 amount) external {
        if (id > uniqueTokens) {
            revert NoTokenExists(id);
        }
        require(!nativeMintEnabled, 'Can only mint with ERC20 token');
        _handleMint(to, id, amount, 0, nativeMintEnabled);
    }

    /// mint NFTs with the network native token
    /// @param to the address to mint the NFTs to
    /// @param id The token ID of the mint to be minted
    /// @param amount the amount of NFTs to mint
    function mintWithNativeToken(address to, uint256 id, uint256 amount) external payable {
        if (id > uniqueTokens) {
            revert NoTokenExists(id);
        }
        require(nativeMintEnabled, 'Can only mint with native token');
        _handleMint(to, id, amount, msg.value, nativeMintEnabled);
    }

    function _handleMintBatch(address to, uint256[] memory ids, uint256[] memory amounts, uint256 value, bool isNative) internal {
    uint256 finalPrice;
    uint256 totalAmount;
    if (msg.sender != owner()) {
        for (uint256 i = 0; i < ids.length;) {
            require(amounts[i] > 0, 'Amount cannot be 0');
            if (ids[i] > uniqueTokens) {
                revert NoTokenExists(ids[i]);
            }
            uint256 currentSupply = totalSupply(ids[i]);
            require(currentSupply + amounts[i] <= maxTokenSupply[ids[i]], 'Cannot exceed Max Supply');
            uint256 unitPrice;
            tokenPrice[ids[i]] == 0 ? unitPrice = defaultPrice : unitPrice = tokenPrice[ids[i]];
            finalPrice += unitPrice.mul(amounts[i]);
            totalAmount += amounts[i];
            unchecked {
                i++;
            }
        }
        if (isNative) {
            require(value >= finalPrice, 'Insufficient funds!');
        } else {
            paymentToken.safeTransferFrom(msg.sender, address(this), finalPrice);
        }
        emit MintBatch(to, totalAmount, finalPrice);
    }
    mitchToken.mint(to, totalAmount.mul(1 ether));
    _mintBatch(to, ids, amounts, '');
}

     
    /// @notice This will mint multiple NFTS with different ids and amounts to an address using the payment token
    /// @param to the address to mint the NFTs to
    /// @param ids an array of the token IDs of the NFTs to be minted
    /// @param amounts an array of the amount of each corresponding NFT by tokenID to be minted
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        require(!nativeMintEnabled, 'Can only mint with ERC20 token');
        _handleMintBatch(to, ids, amounts, 0, nativeMintEnabled);
    }
    /// @notice This will mint multiple NFTS with different ids and amounts to an address using the network native token as payment
    /// @param to the address to mint the NFTs to
    /// @param ids an array of the token IDs of the NFTs to be minted
    /// @param amounts an array of the amount of each corresponding NFT by tokenID to be minted

    function mintBatchWithNativeToken(address to, uint256[] memory ids, uint256[] memory amounts) external payable {
        require(nativeMintEnabled, 'Can only mint with native token');
               _handleMintBatch(to, ids, amounts, msg.value, nativeMintEnabled);
    }
    ///
    /// @param tokenId the token id of the NFT
    /// @return uri URI for a given token ID

    function uri(uint256 tokenId) public view virtual override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return super.uri(tokenId);
    }

    /// @notice This will set the price of a specific NFT by its token ID, only callable by owner
    /// @param tokenId the token id of the NFT
    /// @param price the price of the NFT per unit
    function setTokenPrice(uint256 tokenId, uint256 price) external onlyOwner {
        require(price != 0, 'cannot set price to 0');
        tokenPrice[tokenId] = price;
    }

    /// @notice this will set the price of all NFTs that do not have a price set, only callable by owner
    /// @param price the price of the NFT per unit
    function setDefaultPrice(uint256 price) external onlyOwner {
        defaultPrice = price;
    }

    /// @notice this will reset the price of an NFT that has been given a specific price back to the default price, only callable by owner
    /// @param tokenId the token id of the NFT
    function resetTokenPrice(uint256 tokenId) external onlyOwner {
        tokenPrice[tokenId] = 0;
    }

    /// @notice this will change the address of the ERC20 compatible token used for payment of NFTs, only callable by owner
    /// @param newPaymentToken the address of the new ERC20 compatible token
    function setPaymentToken(IERC20 newPaymentToken) external onlyOwner {
        paymentToken = newPaymentToken;
    }

    /// @notice this will change the URI of a specific NFT by tokenID, only callable by owner
    /// @param tokenId the token id of the NFT
    /// @param tokenURI the new URI of the NFT
    function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    /// @notice this will change the base URI set by the constructor contract, only callable by owner
    /// @param _baseURI the new base URI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    /// @notice this will add a new token to the collection, starts with default price, only callable by owner
    /// @param tokenURI the URI of the new token to be added
    function addToken(string memory tokenURI, uint256 maxSupply) external onlyOwner {
        uniqueTokens++;
        _setURI(uniqueTokens, tokenURI);
        uint256 tokenId = uniqueTokens;
        maxTokenSupply[tokenId] = maxSupply;
    }

    /// @notice withdraws the whole balance of payment tokens in the contract to the owner address, only callable by owner
    function withdrawTokens() external onlyOwner {
        uint256 tokenBalance = paymentToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            paymentToken.safeTransfer(owner(), tokenBalance);
        }
    }

    /// @notice sets if the minter pays for NFTs with native tokens or the payment token, only callable by owner
    /// @param enabled true if the minter pays with native tokens, false if the minter pays with the payment token
    function setNativeTokenMinting(bool enabled) external onlyOwner {
        nativeMintEnabled = enabled;
    }

    /// @notice withdraws the whole balance of network native tokens in the contract to the owner address, only callable by owner
    function withdrawNativeToken() external payable onlyOwner {
        (bool sent,) = payable(owner()).call{value: address(this).balance}('');
        require(sent, 'Failed to send Ether');
    }

    /// @notice this will return the price and URI of a specific NFT by its token ID
    function getTokenInfo(uint256 tokenId) external view returns (uint256 price, string memory tokenURI) {
        tokenPrice[tokenId] == 0 ? price = defaultPrice : price = tokenPrice[tokenId];
        tokenURI = uri(tokenId);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
