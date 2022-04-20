import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"

//TODO: use execute and post
transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())!

		let bidsReference= account.borrow<&FindMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath)
		let nftIdentifier = bidsReference.getBid(id).item.type.identifier

		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(saleInformation.type.identifier) ?? panic("This NFT is not supported by the Find Market yet")

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(nft.providerPath)
		
		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.providerPath,
					target: nft.storagePath
			)
		}
		
		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		let market = account.borrow<&FindMarket.SaleItemCollection>(from: tenant.getTenantInformation().saleItemStoragePath)!
		market.acceptDirectOffer(pointer)

	}
}
