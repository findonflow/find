import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(id: UInt64, directSellPrice:UFix64, nftAlias: String, ftAlias: String) {
	prepare(account: AuthAccount) {

		// Get the sales Item from tenant
		let tenant=FindMarket.getFindTenant() 
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())!)!

		// Get supported NFT and FT Information from Registries from input alias
		let nft = NFTRegistry.getNFTInfoByAlias(nftAlias) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfoByAlias(ftAlias) ?? panic("This FT is not supported by the Find Market yet")

		// Addition from Ben : Add a checker for private capability as well.
		// If they didn't set up the private capability, set one up for them
		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(nft.providerPath)

		/* Ben : Question -> can we set up the provider cap with generic interfaces? */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.providerPath,
					target: nft.storagePath
			)
		}

		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		//BAM: fetch the FTRegistry using identifier and sending in the type
		saleItems.listForSale(pointer: pointer, vaultType: ft.type, directSellPrice: directSellPrice)
	}
}
