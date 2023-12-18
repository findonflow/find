import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperStorageRent from "../contracts/standard/DapperStorageRent.cdc"
import TopShot from "../contracts/community/TopShot.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

//first argument is the address to the merchant that gets the funds
transaction(address: Address, id: UInt64, amount: UFix64) {

	let targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault
	let receiver : Address

	let saleItemsCap: Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>
	let balanceBeforeTransfer: UFix64
	prepare(dapper: auth(BorrowValue)  AuthAccountAccount, account: auth(BorrowValue)  AuthAccountAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		self.receiver=account.address
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

		self.saleItemsCap= FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

		//we do some security check to verify that this tenant can do this operation. This will ensure that the onefootball tenant can only sell using DUC and not some other token. But we can change this with transactions later and not have to modify code/transactions
		let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)
   		let collectionIdentifier = NFTCatalog.getCollectionsForType(nftTypeIdentifier: item.getItemType().identifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(item.getItemType().identifier))
		let collection = NFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		var ftVaultPath : StoragePath? = nil
		switch item.getFtType() {
			case Type<@DapperUtilityCoin.Vault>() :
				ftVaultPath = /storage/dapperUtilityCoinVault

			case Type<@FlowUtilityToken.Vault>() :
				ftVaultPath = /storage/flowUtilityTokenVault

			default :
			panic("This FT is not supported by the Find Market in Dapper Wallet. Type : ".concat(item.getFtType().identifier))
		}

		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)

		if !self.targetCapability.check() {
			let cd = item.getNFTCollectionData()
			if let storage = account.borrow<&AnyResource>(from: cd.storagePath) {
				if let st = account.borrow<&TopShot.Collection>(from: cd.storagePath) {
					// here means the topShot is not linked in the way it should be. We can relink that for our use
					account.unlink(cd.publicPath)
					account.link<&TopShot.Collection{TopShot.MomentCollectionPublic,NonFungibleToken.Receiver,NonFungibleToken.Collection,ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
				} else {
					panic("This collection public link is not set up properly.")
				}
			} else {
				account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
				account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
			}
		}

		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ftVaultPath!) ?? panic("No suitable wallet linked for this account")
		self.balanceBeforeTransfer = self.walletReference.balance
	}

	pre {
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
		DapperStorageRent.tryRefill(self.receiver)
	}

	// Check that all dapper Coin was routed back to Dapper
	post {
		self.walletReference.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
	}
}
