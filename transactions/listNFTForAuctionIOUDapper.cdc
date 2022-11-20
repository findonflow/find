import IOU from "../contracts/IOU.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction(marketplace:Address, nftAliasOrIdentifier:String, id: UInt64, ftAliasOrIdentifier:String, price:UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?) {
	
	let saleItems : &FindMarketAuctionIOUDapper.SaleItemCollection?
	let vaultType : Type
	let pointer : FindViews.AuthNFTPointer
	
	prepare(dapper: AuthAccount, account: AuthAccount) {
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

		let adiBidType= Type<@FindMarketAuctionIOUDapper.MarketBidCollection>()
		let adiBidPublicPath=FindMarket.getPublicPath(adiBidType, name: tenant.name)
		let adiBidStoragePath= FindMarket.getStoragePath(adiBidType, name:tenant.name)
		let adiBidCap= account.getCapability<&FindMarketAuctionIOUDapper.MarketBidCollection{FindMarketAuctionIOUDapper.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(adiBidPublicPath) 
		if !adiBidCap.check() {
			account.save<@FindMarketAuctionIOUDapper.MarketBidCollection>(<- FindMarketAuctionIOUDapper.createEmptyMarketBidCollection(tenantCapability), to: adiBidStoragePath)
			account.link<&FindMarketAuctionIOUDapper.MarketBidCollection{FindMarketAuctionIOUDapper.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(adiBidPublicPath, target: adiBidStoragePath)
		}


		let path=FindMarket.getStoragePath(Type<@FindMarketAuctionIOUDapper.SaleItemCollection>(), name: tenant.name)


		// Get supported NFT and FT Information from Registries from input alias
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier)) 
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
		self.vaultType = ft.type

		var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.privatePath)
		
		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
			let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.privatePath,
					target: nft.storagePath
			)
			if newCap == nil {
				// If linking is not successful, we link it using finds custom link 
				let pathIdentifier = nft.privatePath.toString()
				let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					findPath,
					target: nft.storagePath
				)
				providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
			}
		}

		self.saleItems= account.borrow<&FindMarketAuctionIOUDapper.SaleItemCollection>(from: path)
		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
	}

	pre{
		IOU.DapperCoinTypes.contains(self.vaultType) : "Please use Escrowed contracts for this token type. Type : ".concat(self.vaultType.identifier)
		// Ben : panic on some unreasonable inputs in trxn 
		minimumBidIncrement > 0.0 : "Minimum bid increment should be larger than 0."
		(auctionReservePrice - auctionReservePrice) % minimumBidIncrement == 0.0 : "Acution ReservePrice should be in step of minimum bid increment." 
		auctionDuration > 0.0 : "Auction Duration should be greater than 0."
		auctionExtensionOnLateBid > 0.0 : "Auction Duration should be greater than 0."
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute {
		self.saleItems!.listForAuction(pointer: self.pointer, vaultType: self.vaultType, auctionStartPrice: price, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, auctionValidUntil:auctionValidUntil, saleItemExtraField: {})
	}
}
