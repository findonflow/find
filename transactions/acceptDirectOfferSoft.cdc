import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

transaction(marketplace:Address, id: UInt64) {


	prepare(account: AuthAccount) {
		let tenant=FindMarketOptions.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		let market = account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		let saleInformation = FindMarketOptions.getSaleInformation(tenant:marketplace, address: account.address, marketOption: marketOption, id:id, getNFTInfo:false) 
		if saleInformation==nil {
			panic("This offer is made on a ghost listing")

		}
		let nftIdentifier = saleInformation!.nftIdentifier

		//If this is nil, there must be something wrong with FIND setup
		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(nftIdentifier)!

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.providerPath)
		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)

		market.acceptOffer(pointer)

	}
}
