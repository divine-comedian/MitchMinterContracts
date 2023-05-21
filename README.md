# Givers PFP Contract Spec 

ERC721 Enumerable base contract - contract has imported open-zeppelin Ownable and Pausable controls

## Allow List 

we have an allow list and an allow list period. users must be manually added to the allow list by the owner. 

the allow list period is controlled arbitrarily by the owner by an allowList boolean.

when allowlist is on (true) only users added to the allow list can mint PFPs. when the allowlist is off (false) anyone can mint PFPs.

the owner can remove users from the allow list.

## Buy PFPs

users can only mint a specified max amount of PFPs with a single transaction

we specify an ERC20 token as the payment token and a price denominated in said ERC20 payment token. the payment token and price can be changed by the owner only.

for each pfp to be minted, users must pay the price in the specified payment token

the owner does not have to pay to mint PFPs and does not have to be on the allow list during the allow list period to do so. 

each pfp minted must have a unique token ID

## Manage metadata

controls for setting and updating the URI of where the ipfs data is stored of the pfp metadata

allows for a starting "hidden" image and nft metadata - defined by a specific ipfs URI and an event function where the unique art is revealed, changing the URI of the PFP - reveal can only be called once

in case we need to update the metadata, the URI can be changed by the owner

## Withdraw funds

withdraw function will transfer all payment token funds from the pfp contract to the owner's address
this function cannot be called if there are no funds to withdraw
