import IOweYou from "../contracts/IOweYou.cdc"
import DapperIOweYou from "../contracts/DapperIOweYou.cdc"
import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction(marketplace:Address, user: String, id: UInt64, amount: UFix64) {

	let saleItemsCap: Capability<&FindMarketAuctionIOUDapper.SaleItemCollection{FindMarketAuctionIOUDapper.SaleItemCollectionPublic}> 
	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64
	let bidsReference: &FindMarketAuctionIOUDapper.MarketBidCollection?
	let balanceBeforeBid: UFix64
	let pointer: FindViews.ViewReadPointer
	let iouCollection: &DapperIOweYou.Collection

	prepare(dapper: AuthAccount, account: AuthAccount) {


		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise
		//SYNC with register
		//Add exising FUSD or create a new one and add it
		let name = account.address.toString()
		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinVault)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
		}

		let futReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		if !futReceiver.check() {
			// Create a new Forwarder resource for FUT and store it in the new account's storage
			let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-futForwarder, to: /storage/flowUtilityTokenVault)
			// Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver,target: /storage/flowUtilityTokenVault)
		}

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let dandyCapPrivate= account.getCapability<&{Dandy.CollectionPublic}>(Dandy.CollectionPrivatePath)
		if !dandyCapPrivate.check() {
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

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
			let ducWallet=Profile.Wallet( name:"DUC", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver), balance:dapper.getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapper", "dapperUtilityCoin"])
			profile.addWallet(ducWallet)
			updated=true
		}
		if !profile.hasWallet("FUT") {
			let futWallet=Profile.Wallet( name:"FUT", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver), balance:dapper.getCapability<&{FungibleToken.Balance}>(/public/flowUtilityTokenBalance), accept: Type<@FlowUtilityToken.Vault>(), tags: ["fut", "dapper", "flowUtilityToken"])
			profile.addWallet(futWallet)
			updated=true
		}

		if created {
			profile.emitCreatedEvent()
		} else if updated {
			profile.emitUpdatedEvent()
		}

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!

		let tenant = tenantCapability.borrow()!

	 /// auctions that refers FT 'IOUDapper' auction
		let adiSaleType= Type<@FindMarketAuctionIOUDapper.SaleItemCollection>()
		let adiSalePublicPath=FindMarket.getPublicPath(adiSaleType, name: tenant.name)
		let adiSaleStoragePath= FindMarket.getStoragePath(adiSaleType, name:tenant.name)
		let adiSaleCap= account.getCapability<&FindMarketAuctionIOUDapper.SaleItemCollection{FindMarketAuctionIOUDapper.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(adiSalePublicPath) 
		if !adiSaleCap.check() {
			account.save<@FindMarketAuctionIOUDapper.SaleItemCollection>(<- FindMarketAuctionIOUDapper.createEmptySaleItemCollection(tenantCapability), to: adiSaleStoragePath)
			account.link<&FindMarketAuctionIOUDapper.SaleItemCollection{FindMarketAuctionIOUDapper.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(adiSalePublicPath, target: adiSaleStoragePath)
		}

		let iouCap = account.getCapability<&DapperIOweYou.Collection{IOweYou.CollectionPublic}>(DapperIOweYou.CollectionPublicPath)
		if !iouCap.check() {
			account.save<@DapperIOweYou.Collection>( <- DapperIOweYou.createEmptyCollection(receiverCap) , to: DapperIOweYou.CollectionStoragePath)
			account.link<&DapperIOweYou.Collection{IOweYou.CollectionPublic}>(DapperIOweYou.CollectionPublicPath, target: DapperIOweYou.CollectionStoragePath)
		}

		let adiBidType= Type<@FindMarketAuctionIOUDapper.MarketBidCollection>()
		let adiBidPublicPath=FindMarket.getPublicPath(adiBidType, name: tenant.name)
		let adiBidStoragePath= FindMarket.getStoragePath(adiBidType, name:tenant.name)
		let adiBidCap= account.getCapability<&FindMarketAuctionIOUDapper.MarketBidCollection{FindMarketAuctionIOUDapper.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(adiBidPublicPath) 
		if !adiBidCap.check() {
			account.save<@FindMarketAuctionIOUDapper.MarketBidCollection>(<- FindMarketAuctionIOUDapper.createEmptyMarketBidCollection(receiver: iouCap, tenantCapability:tenantCapability), to: adiBidStoragePath)
			account.link<&FindMarketAuctionIOUDapper.MarketBidCollection{FindMarketAuctionIOUDapper.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(adiBidPublicPath, target: adiBidStoragePath)
		}

		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		self.saleItemsCap= FindMarketAuctionIOUDapper.getSaleItemCapability(marketplace:marketplace, user:address) ?? panic("cannot find sale item cap. User address : ".concat(address.toString()))

		self.iouCollection = account.borrow<&DapperIOweYou.Collection>(from: DapperIOweYou.CollectionStoragePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionIOUDapper.SaleItemCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

		let nftIdentifier = item.getItemType().identifier
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
	
		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		/* Check for nftCapability */
		if !self.targetCapability.check() {
			let cd = item.getNFTCollectionData()
			// should use account.type here instead
			if account.type(at: cd.storagePath) != nil {
				let pathIdentifier = nft.publicPath.toString()
				let findPath = PublicPath(identifier: pathIdentifier.slice(from: "/public/".length , upTo: pathIdentifier.length).concat("_FIND"))!
				account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					findPath,
					target: nft.storagePath
				)
				self.targetCapability = account.getCapability<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
			} else {
				account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
				account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
			}

		}
		
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.walletBalance = self.walletReference.balance

		let bidSstoragePath=tenant.getStoragePath(Type<@FindMarketAuctionIOUDapper.MarketBidCollection>())!

		self.bidsReference= account.borrow<&FindMarketAuctionIOUDapper.MarketBidCollection>(from: bidSstoragePath)
		self.balanceBeforeBid=self.walletReference.balance
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: item.getItemID())
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		let iou <- self.iouCollection.create(<- vault)
		self.bidsReference!.bid(item:self.pointer, iou: <- iou, nftCap: self.targetCapability, bidExtraField: {})
	}

	post{
		self.walletBalance == self.walletReference.balance : "Token leakage"
	}
}
