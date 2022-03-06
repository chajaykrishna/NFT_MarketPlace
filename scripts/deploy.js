
const hre = require("hardhat");

async function main() {
  
  const tokenURI = "https://jsonkeeper.com/b/GNAX";
  const MarketPlace = await hre.ethers.getContractFactory("NftMarketPlace");
  const marketplace = await MarketPlace.deploy();
  await marketplace.deployed();

  const NFT = await hre.ethers.getContractFactory("NFT");
  const nft = await NFT.deploy(marketplace.address);
  await nft.deployed();
  console.log(`nft contract deployed to ${nft.address}\n marketplace contract deployed to: ${marketplace.address}`);

  
  const tokenId = await nft.mintNFT(tokenURI);
  await marketplace.setNFTContractAddress(nft.address)
  const listItem = await marketplace.listMarketItem(100, 1);
  listItem ? console.log('item listed') : console.log('item not listed');
  console.log(await marketplace.getListingItems());
  console.log(await marketplace.cancelListing(1))
  console.log(await marketplace.getListingItems());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
