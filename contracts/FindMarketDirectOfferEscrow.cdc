import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

pub contract FindMarketDirectOfferEscrow {


	access(self) let salePathPrefix : String
	access(self) let bidPathPrefix : String

	pub event DirectOffer(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo, buyer:Address?, buyerName:String?)


	pub resource SaleItem : FindMarket.SaleItem {

		access(contract) var pointer: AnyStruct{FindViews.Pointer}

		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>

		init(pointer: AnyStruct{FindViews.Pointer}, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {
			self.pointer=pointer
			self.offerCallback=callback
		}

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun acceptEscrowedBid() : @FungibleToken.Vault {
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			let vault <- self.offerCallback.borrow()!.accept(<- pointer.withdraw())
			return <- vault
		}

		pub fun getRoyalty() : MetadataViews.Royalties? {
			if self.pointer.getViews().contains(Type<MetadataViews.Royalties>()) {
				return self.pointer.resolveView(Type<MetadataViews.Royalties>())! as! MetadataViews.Royalties
			}
			if self.pointer.getViews().contains(Type<MetadataViews.Royalty>()) {
				let royalty= self.pointer.resolveView(Type<MetadataViews.Royalty>())! as! MetadataViews.Royalty
				return MetadataViews.Royalties([royalty])
			}
			if self.pointer.getViews().contains(Type<[MetadataViews.Royalty]>()) {
				let royalty= self.pointer.resolveView(Type<[MetadataViews.Royalty]>())! as! [MetadataViews.Royalty]
				return MetadataViews.Royalties(royalty)
			}

			return  nil
		}

		pub fun getBalance() : UFix64 {
			return self.offerCallback.borrow()!.getBalance(self.getId())
		}

		pub fun getSeller() : Address {
			return self.pointer.owner()
		}

		pub fun getSellerName() : String? {
			let address = self.pointer.owner()
			return FIND.reverseLookup(address)
		}


		pub fun getBuyer() : Address? {
			return self.offerCallback.address
		}

		pub fun getBuyerName() : String? {
			if let name = FIND.reverseLookup(self.offerCallback.address) {
				return name 
			}
			return nil
		}

		pub fun toNFTInfo() : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id)
		}

		pub fun getSaleType() : String {
			return "active_ongoing"
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun getListingTypeIdentifier() : String {
			return Type<@SaleItem>().identifier
		}

		pub fun setPointer(_ pointer: FindViews.AuthNFTPointer) {
			self.pointer=pointer
		}

		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		pub fun getItemCollectionAlias() : String {
			return NFTRegistry.getNFTInfoByTypeIdentifier(self.getItemType().identifier)!.alias
		}

		pub fun getAuction(): FindMarket.AuctionItem? {
			return nil
		}

		pub fun getFtType() : Type  {
			return self.offerCallback.borrow()!.getVaultType(self.getId())
		}

		pub fun getFtAlias() : String {
			return FTRegistry.getFTInfoByTypeIdentifier(self.getFtType().identifier)!.alias
		}

		pub fun getValidUntil() : UFix64? {
			return nil 
		}

		pub fun setCallback(_ callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {
			self.offerCallback=callback
		}

		pub fun checkPointer() : Bool {
			return self.pointer.valid()
		}
	}


	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]

		access(contract)fun cancelBid(_ id: UInt64) 

		access(contract) fun registerIncreasedBid(_ id: UInt64) 

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>)

	}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>

		init (_ tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>) {
			self.items <- {}
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic} {
			pre{
				self.tenantCapability.check() : "Tenant client is not linked anymore"
			}
			return self.tenantCapability.borrow()!
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		//this is called when a buyer cancel a direct offer
		access(contract) fun cancelBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			let saleItem=self.borrow(id)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "cancel in direct offer"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			self.emitEvent(saleItem: saleItem, status: "cancel")
			destroy <- self.items.remove(key: id)
		}

		access(self) fun emitEvent(saleItem: &SaleItem, status: String) {
			let owner=saleItem.getSeller()
			let ftType=saleItem.getFtType()
			let nftInfo=saleItem.toNFTInfo()
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			emit DirectOffer(tenant:self.getTenant().name, id: saleItem.getId(), seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
		}

		//The only thing we do here is basically register an event
		access(contract) fun registerIncreasedBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			let saleItem=self.borrow(id)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:true, "add bid in direct offer"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			self.emitEvent(saleItem: saleItem, status: "active_offered")
		}

		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {

			let id = item.getUUID()

			//If there are no bids from anybody else before we need to make the item
			if !self.items.containsKey(id) {
				let saleItem <- create SaleItem(pointer: item, callback: callback)
				let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:true, "bid in direct offer"))

				if !actionResult.allowed {
					panic(actionResult.message)
				}
				
				self.items[id] <-! saleItem
				let item=self.borrow(id)
				self.emitEvent(saleItem: item, status: "active_offered")
				return 
			}


			let saleItem=self.borrow(id)

			if self.borrow(id).getBuyer()! == callback.address {
				panic("You already have the latest bid on this item, use the incraseBid transaction")
			}

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:true, "bid in direct offer"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()!.getBalance(id)

			let currentBalance=saleItem.getBalance()
			Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
			if currentBalance >= balance {
				panic("There is already a higher bid on this item")
			}
			//somebody else has the highest item so we cancel it
			saleItem.offerCallback.borrow()!.cancelBidFromSaleItem(id)
			saleItem.setCallback(callback)

			self.emitEvent(saleItem: saleItem, status: "offered")

		}

		//cancel will reject a direct offer
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "reject in direct offer"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			self.emitEvent(saleItem: saleItem, status: "rejected")

			saleItem.offerCallback.borrow()!.cancelBidFromSaleItem(id)
			destroy <- self.items.remove(key: id)
		}

		pub fun acceptDirectOffer(_ pointer: FindViews.AuthNFTPointer) {
			pre {
				self.items.containsKey(pointer.getUUID()) : "Invalid id=".concat(pointer.getUUID().toString())
			}

			let id = pointer.getUUID()
			let saleItem = self.borrow(id)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "fulfill directOffer"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= self.getTenant().getTeantCut(name: actionResult.name, listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())

			//Set the auth pointer in the saleItem so that it now can be fulfilled
			saleItem.setPointer(pointer)

			let royalty=saleItem.getRoyalty()
			let nftInfo=saleItem.toNFTInfo()

			self.emitEvent(saleItem: saleItem, status: "sold")
			let vault <- saleItem.acceptEscrowedBid()
			FindMarket.pay(tenant: self.getTenant().name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts
, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) })
			destroy <- self.items.remove(key: id)
		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun borrow(_ id: UInt64): &SaleItem {
			return &self.items[id] as &SaleItem
		}

		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
			pre{
				self.items.containsKey(id) : "This id does not exist : ".concat(id.toString())
			}
			return &self.items[id] as &SaleItem{FindMarket.SaleItem}
		}

		destroy() {
			destroy self.items
		}
	}

	pub resource Bid : FindMarket.Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let itemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) let vault: @FungibleToken.Vault
		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			self.vaultType=vault.getType()
			self.vault <- vault
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
		}

		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		pub fun getBalance() : UFix64 {
			return self.vault.balance
		}

		pub fun getSellerAddress() : Address {
			return self.from.address
		}

		destroy() {
			destroy self.vault
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBalance(_ id: UInt64) : UFix64
		pub fun getVaultType(_ id: UInt64) : Type
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic} {
			pre{
				self.tenantCapability.check() : "Tenant client is not linked anymore"
			}
			return self.tenantCapability.borrow()!
		}

		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault {
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			bid.nftCap.borrow()!.deposit(token: <- nft)
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		pub fun getVaultType(_ id:UInt64) : Type {
			return self.borrowBid(id).vaultType
		}

		pub fun getIds() : [UInt64] {
			return self.bids.keys
		}

		pub fun getBidType() : Type {
			return Type<@Bid>()
		}

		pub fun bid(item: FindViews.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.getTenant().getPublicPath(FindMarketDirectOfferEscrow.salePathPrefix))

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.getTenant().getPublicPath(FindMarketDirectOfferEscrow.bidPathPrefix))
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability)
			destroy oldToken
		}

		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			bid.from.borrow()!.registerIncreasedBid(id)
		}

		/// The users cancel a bid himself
		pub fun cancelBid(_ id: UInt64) {
			let bid= self.borrowBid(id)
			bid.from.borrow()!.cancelBid(id)
			self.cancelBidFromSaleItem(id)
		}

		access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
			let bid <- self.bids.remove(key: id) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun borrowBid(_ id: UInt64): &Bid {
			pre{
				self.bids.containsKey(id) : "This id does not exist : ".concat(id.toString())
			}
			return &self.bids[id] as &Bid
		}

		pub fun borrowBidItem(_ id: UInt64): &{FindMarket.Bid} {
			pre{
				self.bids.containsKey(id) : "This id does not exist : ".concat(id.toString())
			}
			return &self.bids[id] as &Bid{FindMarket.Bid}
		}

		pub fun getBalance(_ id: UInt64) : UFix64 {
			let bid= self.borrowBid(id)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	init() {
		self.salePathPrefix=FindViews.typeToPathIdentifier(Type<@SaleItemCollection>())
		self.bidPathPrefix=FindViews.typeToPathIdentifier(Type<@MarketBidCollection>())
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>): @SaleItemCollection {
		let wallet=FindMarketDirectOfferEscrow.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		pre{
			FindMarketTenant.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarketTenant.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(self.salePathPrefix))
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
		pre{
			FindMarketTenant.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarketTenant.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(tenant.getPublicPath(self.bidPathPrefix))
		}
		return nil
	}
}
