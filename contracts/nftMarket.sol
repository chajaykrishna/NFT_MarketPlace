// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NftMarketPlace is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter _itemIds;
    Counters.Counter unavailableItems;
    uint listingPrice = 1000;
    address nftContract ;

    /// @dev marketOwner is marketplace owner, one who gets benifitted with listing fee.
    address payable marketOwner;
    struct MarketItem {
        uint tokenId;
        uint price;
        address seller;
        itemStatus_ itemStatus;
    }
    enum itemStatus_ {sold, available, cancelled}
    mapping(uint => MarketItem) idToMarketItem;
    MarketItem[] MarketItems;

    // events
    event setNFTContractAddress_(address newNftContract);
    event updateListingPrice_(uint oldPrpice, uint newPrice);
    event listMarketItem_(uint indexed itemId, uint indexed price, address indexed seller_ );
    event buyItem_(uint indexed itemId, address indexed buyer, uint price, address seller);
    event cancel_(uint indexed itemId, address indexed seller);


    constructor (){
        marketOwner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == marketOwner, "only owner can update the listing price");
        _;
    }


    /***  @dev this function let owner set the erc721 contract address.*/
    function setNFTContractAddress(address nftContract_) public onlyOwner {
        nftContract = nftContract_;
        emit setNFTContractAddress_(nftContract_);
    }

    function updateListingPrice(uint price) public onlyOwner {
        emit updateListingPrice_(listingPrice, price);
        listingPrice =  price;
    }
    function getListingPrice() public view returns(uint) {
        return listingPrice;
    }

    function listMarketItem(
        uint price,
        uint tokenId
    ) public payable nonReentrant returns (bool){ 
        // require(msg.value == listingPrice, "send the listing fee: ${getListingPrice}") ;
        require (price >0, "price cannot be 0");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender,"only owner can list the nft");
        // require(IERC721(nftContract).)  have to check if the tokenId id available or not

        // IERC721(nftContract).approve(address(this), tokenId);
        IERC721(nftContract).transferFrom((msg.sender), payable(address(this)), tokenId);
        _itemIds.increment();
        uint itemId = _itemIds.current();
        MarketItem memory marketItem = MarketItem(tokenId, price, msg.sender, itemStatus_.available);
        idToMarketItem[itemId] = marketItem;
        MarketItems.push(marketItem);

        emit listMarketItem_(itemId, price, msg.sender);
        return true;
    }

    function getListingItems() public view returns (MarketItem[] memory){
        uint totalavailableItems = _itemIds.current() - unavailableItems.current();
        MarketItem[] memory availableItems = new MarketItem[](totalavailableItems);
        uint tempCount =0;
        for (uint i=1; i<=totalavailableItems; i++){
            if(idToMarketItem[i].itemStatus == itemStatus_.available){
                availableItems[tempCount] = idToMarketItem[i];
            }
        }
        
        return availableItems;
    }

    function _exist(uint itemId_) private view returns(bool) {
        require(idToMarketItem[itemId_].seller != address(0), "item doesn't exist" );
        return true;
    }

    function buyItem(uint itemId) public payable nonReentrant {
        require(_exist(itemId),"itemId not avilable");
        require(idToMarketItem[itemId].itemStatus == itemStatus_.available, "item not avilable for sale");
        require(msg.sender != idToMarketItem[itemId].seller, "seller cannot buy the item");
        require(msg.value == idToMarketItem[itemId].price, "Insufficient funds");
        idToMarketItem[itemId].itemStatus = itemStatus_.sold;
        (bool success, ) = payable(idToMarketItem[itemId].seller).call{value: msg.value}("");
        require(success, "transfer failed");
        IERC721(nftContract).safeTransferFrom(address(this), payable(msg.sender), idToMarketItem[itemId].tokenId);

        idToMarketItem[itemId].seller = msg.sender;
        
        emit buyItem_(itemId, msg.sender, idToMarketItem[itemId].price, idToMarketItem[itemId].seller);
        // increment the unavailable counter
        unavailableItems.increment();
    }

    // function deleteUnlistedItem() internal {
    //     uint totalItems = _itemIds.current();
    //     for(uint i= 1; i<= totalItems; i++){
    //         if 
    //     }
    // }

    function cancelListing(uint itemId) public nonReentrant {
        require(_exist(itemId),"itemId not avilable");
        require(idToMarketItem[itemId].itemStatus == itemStatus_.available, "item not avilable for sale");
        require(msg.sender == idToMarketItem[itemId].seller, "only seller can cancel the item");
        idToMarketItem[itemId].itemStatus = itemStatus_.cancelled;
        IERC721(nftContract).safeTransferFrom(address(this), idToMarketItem[itemId].seller , idToMarketItem[itemId].tokenId);
        // increment the unavailable counter
        unavailableItems.increment();
        emit cancel_(itemId,idToMarketItem[itemId].seller);

    }

}