import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

//TODO: use execute and post
transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())

		let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		let saleItem = FindMarketOptions.getFindSaleInformation(address: account.address, marketOption: marketOption, id:id)
		if saleItem==nil {
			panic("Cannot fulfill market offer on ghost listing")

		}
		let nftTypeIdentifier = saleItem!.nftIdentifier
		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(nftTypeIdentifier) ?? panic("This NFT is not supported by the Find Market yet")
		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.providerPath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.providerPath,
					target: nft.storagePath
			)
		}

		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		let market = account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)!
		market.acceptDirectOffer(pointer)

	}
}
