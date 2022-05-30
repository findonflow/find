import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64) {


	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		let market = account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
		let nftIdentifier = item.getItemType().identifier

		//If this is nil, there must be something wrong with FIND setup
		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(nftIdentifier)!

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.providerPath)
		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)

		market.acceptOffer(pointer)

	}
}
