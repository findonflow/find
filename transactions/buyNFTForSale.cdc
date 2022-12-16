import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(marketplace:Address, user: String, id: UInt64, amount: UFix64) {

	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault

	let saleItemsCap: Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}> 

	prepare(account: AuthAccount) {

		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise
		//SYNC with register
		//Add exising FUSD or create a new one and add it
		let name = account.address.toString()
		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let usdcCap = account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
		if !usdcCap.check() {
				account.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
				account.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
		}

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let bidCollection = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			account.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			account.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
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

		if !profile.hasWallet("Flow") {
			let flowWallet=Profile.Wallet( name:"Flow", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance), accept: Type<@FlowToken.Vault>(), tags: ["flow"])
	
			profile.addWallet(flowWallet)
			updated=true
		}
		if !profile.hasWallet("FUSD") {
			profile.addWallet(Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), tags: ["fusd", "stablecoin"]))
			updated=true
		}

		if !profile.hasWallet("USDC") {
			profile.addWallet(Profile.Wallet( name:"USDC", receiver:usdcCap, balance:account.getCapability<&{FungibleToken.Balance}>(FiatToken.VaultBalancePubPath), accept: Type<@FiatToken.Vault>(), tags: ["usdc", "stablecoin"]))
			updated=true
		}

		if created {
			profile.emitCreatedEvent()
		} else if updated {
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

		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {
			panic("The address input is not a valid name nor address. Input : ".concat(user))
		}
		let address = resolveAddress!
		self.saleItemsCap= FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

		let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: item.getItemType().identifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(item.getItemType().identifier)) 
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

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
	}

	pre {
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
	}
}
