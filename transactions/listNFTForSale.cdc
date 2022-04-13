import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(id: UInt64, directSellPrice:UFix64, nftAlias: String, ftAlias: String) {
	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenant() 
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())!)!


		let nft = NFTRegistry.getNFTInfoByAlias(nftAlias) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfoByAlias(ftAlias) ?? panic("This FT is not supported by the Find Market yet")

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(nft.providerPath)

		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		//BAM: fetch the FTRegistry using identifier and sending in the type
		saleItems.listForSale(pointer: pointer, vaultType: ft.type, directSellPrice: directSellPrice)
	}
}
