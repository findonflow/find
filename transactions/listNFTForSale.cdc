import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(marketplace:Address, nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, directSellPrice:UFix64) {
	prepare(account: AuthAccount) {
		// Get the salesItemRef from tenant
		let tenant=FindMarketOptions.getTenant(marketplace)
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))!

		// Get supported NFT and FT Information from Registries from input alias
		let nft = NFTRegistry.getNFTInfo(nftAliasOrIdentifier) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet")

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.providerPath)

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

