import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(dapperAddress: Address, marketplace:Address, nftAliasOrIdentifier: String, id: UInt64, directSellPrice:UFix64, validUntil: UFix64?) {
	
	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer
	let vaultType : Type
	
	prepare(account: AuthAccount) {

		// This is initialization code that we could remove if that is OK and we know the state is like this before this action takes place
		let name = account.address.toString()
		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)

		var created=false
		var updated=false
		let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:name, createdAt: "find")
			account.save(<-profile, to: Profile.storagePath)
			account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
			created=true
		}

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!
		if !profile.hasWallet("DUC") {
			profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance:getAccount(dapperAddress).getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
			updated=true
		}

		if created {
			profile.emitCreatedEvent()
		} else {
			profile.emitUpdatedEvent()
		}

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!

		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath) 
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}
		//end initializtion

		// Get supported NFT and FT Information from Registries from input alias
		let nft = getCollectionData(nftAliasOrIdentifier) 
		let ft = FTRegistry.getFTInfo(Type<@DapperUtilityCoin.Vault>().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(Type<@DapperUtilityCoin.Vault>().identifier))

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.privatePath)
		// Get the salesItemRef from tenant
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
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

pub fun getCollectionData(_ nftIdentifier: String) : NFTCatalog.NFTCollectionData {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData
}
