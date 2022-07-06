import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64) {

	let market : &FindMarketDirectOfferEscrow.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer

	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())

		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(item.getItemType().identifier) ?? panic("This NFT is not supported by the Find Market yet. Type : ".concat(item.getItemType().identifier))
	
		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.providerPath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.providerPath,
					target: nft.storagePath
			)
		}

		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
		self.market = account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)

	}

	pre{
		self.market != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.market!.acceptDirectOffer(self.pointer)
	}
}
