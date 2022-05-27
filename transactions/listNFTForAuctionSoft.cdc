import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

transaction(marketplace:Address, nftAliasOrIdentifier:String, id: UInt64, ftAliasOrIdentifier:String, price:UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketOptions.getTenant(marketplace)
		let saleItems= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>())!)!

		// Get supported NFT and FT Information from Registries from input alias
		let nft = NFTRegistry.getNFTInfo(nftAliasOrIdentifier) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet")

		let providerCap = account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.providerPath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.providerPath,
					target: nft.storagePath
			)
		}
		
		let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		// Ben : panic on some unreasonable inputs in trxn 
		assert(minimumBidIncrement > 0.0, message:"Minimum bid increment should be larger than 0.")
		assert((auctionReservePrice - auctionReservePrice) % minimumBidIncrement == 0.0, message:"Acution ReservePrice should be in step of minimum bid increment." )
		assert(auctionDuration > 0.0, message: "Auction Duration should be greater than 0.")
		assert(auctionExtensionOnLateBid > 0.0, message: "Auction Duration should be greater than 0.")
		
		saleItems.listForAuction(pointer: pointer, vaultType: ft.type, auctionStartPrice: price, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, saleItemExtraField: {})

	}
}
