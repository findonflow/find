import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, ids: [UInt64]) {

	let market : &FindMarketDirectOfferSoft.SaleItemCollection
	let pointer : [FindViews.AuthNFTPointer]

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())

		var counter = 0
		self.pointer = []
		let nfts : {String : NFTRegistry.NFTInfo} = {}

		while counter < ids.length {
			let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])
			var nft : NFTRegistry.NFTInfo? = nil
			let nftIdentifier = item.getItemType().identifier

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				nft = NFTRegistry.getNFTInfo(nftIdentifier) ?? panic("This NFT is not supported by the Find Market yet. Type : ".concat(nftIdentifier))
				nfts[nftIdentifier] = nft
			}

			let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft!.providerPath)
			let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
			self.pointer.append(pointer)
			counter = counter + 1
		}
	}

	execute {
		var counter = 0
		while counter < ids.length {
			self.market.acceptOffer(self.pointer[counter])
			counter = counter + 1
		}
	}
}
