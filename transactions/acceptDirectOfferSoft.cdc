import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

transaction(id: UInt64) {

	
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getFindTenant()
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())!
		let market = account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let saleInformation = market.getItemForSaleInformation(id)
		let nftIdentifier = saleInformation.type.identifier

		//If this is nil, there must be something wrong with FIND setup
		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(nftIdentifier)!
		
		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(nft.providerPath)
		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)

		market.acceptOffer(pointer)

	}
}
