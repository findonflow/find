import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"

transaction(id: UInt64) {

    let market : &FindMarketDirectOfferSoft.SaleItemCollection
    let pointer : FindViews.AuthNFTPointer

    prepare(account: auth(BorrowValue, IssueStorageCapabilityController) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
        self.market = account.storage.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
        let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
        let nftIdentifier = item.getItemType().identifier

        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData


        var providerCap=account.capabilities.storage.issue<auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft.storagePath)
        self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())

    }

    execute {
        self.market.acceptOffer(self.pointer)
    }

}
