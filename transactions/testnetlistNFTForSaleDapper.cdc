import "FindMarket"
import "FindMarketSale"
import "FINDNFTCatalog"
import "FTRegistry"
import "FindViews"
import "NonFungibleToken"
import "MetadataViews"
import "FlowUtilityToken"
import "TokenForwarding"
import "FungibleToken"

transaction(nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

	let saleItems : auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer
	let vaultType : Type

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!

		let tenant = tenantCapability.borrow()!

		let dapper= getAccount(0x82ec283f88a62e65)

		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		// Get supported NFT and FT Information from Registries from input alias
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		let futReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		if ft.type == Type<@FlowUtilityToken.Vault>() && !futReceiver!.check() {
			// Create a new Forwarder resource for FUT and store it in the new account's storage
			let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
			account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
			// Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver,target: /storage/flowUtilityTokenReceiver)
		}


		let  var providerCap=account.capabilities.storage.get<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft.storagePath)

		if !providerCap.check() {
			account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				nft.privatePath,
				target: nft.storagePath
			)
		}
		// Get the salesItemRef from tenant
		self.saleItems= account.storage.borrow<auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		self.vaultType= ft.type
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})

	}
}
