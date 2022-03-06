// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketPlaceAddress;
     
    constructor (address marketAddress) ERC721("CRAZY MONKEY", "CM"){ 
        marketPlaceAddress = marketAddress;
        setApprovalForAll(marketPlaceAddress, true);
    }

    function mintNFT(string memory tokenURI) public  returns (uint){
        _tokenIds.increment();
        uint tokenId =  _tokenIds.current();
        _safeMint(msg.sender,tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

}