import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(nftAlias: String, id: UInt64, ftAlias: String, directSellPrice:UFix64) {
	prepare(account: AuthAccount) {

		// Get the salesItemRef from tenant
		let tenant=FindMarket.getFindTenant() 
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())!)!

		// Get supported NFT and FT Information from Registries from input alias
		let nft = NFTRegistry.getNFTInfoByAlias(nftAlias) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfoByAlias(ftAlias) ?? panic("This FT is not supported by the Find Market yet")

		// Addition from Ben : Add a checker for private capability as well.
		// If they didn't set up the private capability, set one up for them
		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(nft.providerPath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.providerPath,
					target: nft.storagePath
			)
		}

		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		saleItems.listForSale(pointer: pointer, vaultType: ft.type, directSellPrice: directSellPrice)
	}
}
