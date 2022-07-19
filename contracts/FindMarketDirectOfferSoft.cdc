import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import Profile from "./Profile.cdc"

pub contract FindMarketDirectOfferSoft {

	pub event DirectOffer(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo?, buyer:Address?, buyerName:String?, buyerAvatar:String?, endsAt: UFix64?, previousBuyer:Address?, previousBuyerName:String?)

	pub resource SaleItem : FindMarket.SaleItem{

		access(contract) var pointer: AnyStruct{FindViews.Pointer}
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>

		access(contract) var directOfferAccepted:Bool
		access(contract) var validUntil: UFix64?
		access(contract) var saleItemExtraField: {String : AnyStruct}
		access(contract) let totalRoyalties: UFix64 

		init(pointer: AnyStruct{FindViews.Pointer}, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
			self.pointer=pointer
			self.offerCallback=callback
			self.directOfferAccepted=false
			self.validUntil=validUntil
			self.saleItemExtraField=saleItemExtraField
			self.totalRoyalties=self.pointer.getTotalRoyaltiesCut()
		}


		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun acceptDirectOffer() {
			self.directOfferAccepted=true
		}

		//Here we do not get a vault back, it is sent in to the method itself
		pub fun acceptNonEscrowedBid() { 
			if !self.offerCallback.check() {
				panic("Bidder unlinked the bid collection capability. Bidder Address : ".concat(self.offerCallback.address.toString()))
			}
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			self.offerCallback.borrow()!.acceptNonEscrowed(<- pointer.withdraw())
		}

		pub fun getRoyalty() : MetadataViews.Royalties {
			return self.pointer.getRoyalty()
		}

		pub fun getFtType() : Type {
			if !self.offerCallback.check() {
				panic("Bidder unlinked the bid collection capability. Bidder Address : ".concat(self.offerCallback.address.toString()))
			}
			return self.offerCallback.borrow()!.getVaultType(self.getId())
		}

		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		pub fun getAuction(): FindMarket.AuctionItem? {
			return nil
		}

		pub fun getSaleType() : String {
			if self.directOfferAccepted {
				return "active_finished"
			}
			return "active_ongoing"
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun getListingTypeIdentifier() : String {
			return Type<@SaleItem>().identifier
		}

		pub fun getBalance() : UFix64 {
			if !self.offerCallback.check() {
				panic("Bidder unlinked the bid collection capability. Bidder Address : ".concat(self.offerCallback.address.toString()))
			}
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

		pub fun setValidUntil(_ time: UFix64?) {
			self.validUntil=time
		}

		pub fun getValidUntil() : UFix64? {
			return self.validUntil 
		}

		pub fun setPointer(_ pointer: FindViews.AuthNFTPointer) {
			self.pointer=pointer
		}

		pub fun setCallback(_ callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {
			self.offerCallback=callback
		}

		pub fun checkPointer() : Bool {
			return self.pointer.valid()
		}

		pub fun getSaleItemExtraField() : {String : AnyStruct} {
			return self.saleItemExtraField
		}

		access(contract) fun setSaleItemExtraField(_ field: {String : AnyStruct}) {
			self.saleItemExtraField = field
		}
		
		pub fun getTotalRoyalties() : UFix64 {
			return self.totalRoyalties
		}

		pub fun getDisplay() : MetadataViews.Display {
			return self.pointer.getDisplay()
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			return self.pointer.getNFTCollectionData()
		}
	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		pub fun containsId(_ id: UInt64): Bool
		access(contract) fun cancelBid(_ id: UInt64) 
		access(contract) fun registerIncreasedBid(_ id: UInt64) 

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct})

		access(contract) fun isAcceptedDirectOffer(_ id:UInt64) : Bool

		access(contract) fun fulfillDirectOfferNonEscrowed(id:UInt64, vault: @FungibleToken.Vault)

		}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		init (_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.items <- {}
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			if !self.tenantCapability.check() {
				panic("Tenant client is not linked anymore")
			}
			return self.tenantCapability.borrow()!
		}

		pub fun isAcceptedDirectOffer(_ id:UInt64) : Bool{
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			let saleItem = self.borrow(id)

			return saleItem.directOfferAccepted
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

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "cancel bid in direct offer soft"), seller: nil, buyer: nil)

			if !actionResult.allowed {
				panic(actionResult.message)
			}
			
			let status="cancel"
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			var nftInfo:FindMarket.NFTInfo?=nil 
			if saleItem.checkPointer() {
				nftInfo=saleItem.toNFTInfo()
			} 

			emit DirectOffer(tenant:tenant.name, id: saleItem.getId(), saleID: saleItem.uuid, seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)


			destroy <- self.items.remove(key: id)
		}

		//The only thing we do here is basically register an event
		access(contract) fun registerIncreasedBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			let saleItem=self.borrow(id)

			let tenant=self.getTenant()
			let nftType=saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "increase bid in direct offer soft"), seller: self.owner!.address, buyer: saleItem.offerCallback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let status="active_offered"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			let nftInfo=saleItem.toNFTInfo()

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)
		
		}


		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {

			let id = item.getUUID()

			//If there are no bids from anybody else before we need to make the item
			if !self.items.containsKey(id) {
				let saleItem <- create SaleItem(pointer: item, callback: callback, validUntil: validUntil, saleItemExtraField: saleItemExtraField)

				let tenant=self.getTenant()
				let nftType= saleItem.getItemType()
				let ftType= saleItem.getFtType()

				let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:true, name: "bid in direct offer soft"), seller: self.owner!.address, buyer: callback.address)

				if !actionResult.allowed {
					panic(actionResult.message)
				}
				self.items[id] <-! saleItem
				let saleItemRef=self.borrow(id)
				let status="active_offered"
				let owner=self.owner!.address
				let balance=saleItemRef.getBalance()
				let buyer=callback.address
				let buyerName=FIND.reverseLookup(buyer)
				let profile = Profile.find(buyer)

				let nftInfo=saleItemRef.toNFTInfo()

				emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItemRef.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItemRef.validUntil, previousBuyer:nil, previousBuyerName:nil)
			

				return 
			}


			let saleItem=self.borrow(id)
			if self.borrow(id).getBuyer()! == callback.address {
				panic("You already have the latest bid on this item, use the incraseBid transaction")
			}

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "bid in direct offer soft"), seller: self.owner!.address, buyer: callback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()?.getBalance(id) ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(callback.address.toString()))

			let currentBalance=saleItem.getBalance()
			Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
			if currentBalance >= balance {
				panic("There is already a higher bid on this item. Current bid : ".concat(currentBalance.toString()).concat(" . New bid is at : ").concat(balance.toString()))
			}
			let previousBuyer=saleItem.offerCallback.address
			//somebody else has the highest item so we cancel it
			saleItem.offerCallback.borrow()!.cancelBidFromSaleItem(id)
			saleItem.setValidUntil(validUntil)
			saleItem.setSaleItemExtraField(saleItemExtraField)
			saleItem.setCallback(callback)

			let status="active_offered"
			let owner=self.owner!.address
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			let nftInfo=saleItem.toNFTInfo()

			let previousBuyerName = FIND.reverseLookup(previousBuyer)


			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)
		

		}


		//cancel will reject a direct offer
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "reject offer in direct offer soft"), seller: nil, buyer: nil)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let status = "cancel_rejected"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			var nftInfo:FindMarket.NFTInfo?=nil 
			if saleItem.checkPointer() {
				nftInfo=saleItem.toNFTInfo()
			} 

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)

			if !saleItem.offerCallback.check() {
				panic("Seller unlinked the SaleItem collection capability. seller address : ".concat(saleItem.offerCallback.address.toString()))
			}
			saleItem.offerCallback.borrow()!.cancelBidFromSaleItem(id)
			destroy <- self.items.remove(key: id)
		}

		pub fun acceptOffer(_ pointer: FindViews.AuthNFTPointer) {
			pre {
				self.items.containsKey(pointer.getUUID()) : "Invalid id=".concat(pointer.getUUID().toString())
			}

			let id = pointer.getUUID()
			let saleItem = self.borrow(id)

			if saleItem.validUntil != nil && saleItem.validUntil! < Clock.time() {
				panic("This direct offer is already expired")
			}

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "accept offer in direct offer soft"), seller: self.owner!.address, buyer: saleItem.offerCallback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			//Set the auth pointer in the saleItem so that it now can be fulfilled
			saleItem.setPointer(pointer)
			saleItem.acceptDirectOffer()

			let status="active_accepted"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			let nftInfo=saleItem.toNFTInfo()

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)
		
	
		}

		/// this is called from a bid when a seller accepts
		access(contract) fun fulfillDirectOfferNonEscrowed(id:UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem = self.borrow(id)
			if !saleItem.directOfferAccepted {
				panic("cannot fulfill a direct offer that is not accepted yet")
			}

			if vault.getType() != saleItem.getFtType() {
				panic("The FT vault sent in to fulfill does not match the required type. Required Type : ".concat(saleItem.getFtType().identifier).concat(" . Sent-in vault type : ".concat(vault.getType().identifier)))
			}

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "fulfill directOffer"), seller: self.owner!.address, buyer: saleItem.offerCallback.address)
			
			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= tenant.getTeantCut(name: actionResult.name, listingType: Type<@FindMarketDirectOfferSoft.SaleItem>(), nftType: nftType, ftType: ftType)


			let status="sold"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let sellerName=FIND.reverseLookup(owner)
			let profile = Profile.find(buyer)

			let nftInfo=saleItem.toNFTInfo()

			emit DirectOffer(tenant:tenant.name, id: saleItem.getId(), saleID: saleItem.uuid, seller:owner, sellerName: sellerName, amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)

			let royalty=saleItem.getRoyalty()
			saleItem.acceptNonEscrowedBid()

			let resolved : {Address : String} = {}
			resolved[buyer] = buyerName ?? ""
			resolved[owner] = sellerName ?? ""
			resolved[FindMarketDirectOfferSoft.account.address] =  "find" 
			// Have to make sure the tenant always have the valid find name 
			resolved[FindMarket.tenantNameAddress[tenant.name]!] =  tenant.name

			FindMarket.pay(tenant: tenant.name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo: nftInfo, cuts:cuts, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) }, resolvedAddress: resolved,rewardFN: FIND.rewardFN())

			destroy <- self.items.remove(key: id)
		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun containsId(_ id: UInt64): Bool {
			return self.items.containsKey(id)
		}

		pub fun borrow(_ id: UInt64): &SaleItem {
			if !self.items.containsKey(id) {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.items[id] as &SaleItem?)!
		}

		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
			if !self.items.containsKey(id) {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.items[id] as &SaleItem{FindMarket.SaleItem}?)!
		}

		destroy() {
			destroy self.items
		}
	}

	/*
	==========================================================================
	Bids are a collection/resource for storing the bids bidder made on leases
	==========================================================================
	*/

	pub resource Bid : FindMarket.Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let itemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64
		access(contract) var balance: UFix64 //This is what you bid for non escrowed bids
		access(contract) let bidExtraField: {String : AnyStruct}

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultType:Type,  nonEscrowedBalance:UFix64, bidExtraField: {String : AnyStruct}){
			self.vaultType= vaultType
			self.balance=nonEscrowedBalance
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
			self.bidExtraField=bidExtraField
		}

		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		access(contract) fun increaseBid(_ amount:UFix64) {
			self.balance=self.balance+amount
		}

		pub fun getBalance() : UFix64 {
			return self.balance
		}

		pub fun getSellerAddress() : Address {
			return self.from.address
		}

		pub fun getBidExtraField() : {String : AnyStruct} {
			return self.bidExtraField 
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBalance(_ id: UInt64) : UFix64
		pub fun getVaultType(_ id: UInt64) : Type
		pub fun containsId(_ id: UInt64): Bool
		access(contract) fun acceptNonEscrowed(_ nft: @NonFungibleToken.NFT)
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			if !self.tenantCapability.check() {
				panic("Tenant client is not linked anymore")
			}
			return self.tenantCapability.borrow()!
		}

		//called from lease when auction is ended
		access(contract) fun acceptNonEscrowed(_ nft: @NonFungibleToken.NFT) {
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			if !bid.nftCap.check() {
				panic("Bidder unlinked the nft receiver capability. bidder address : ".concat(bid.nftCap.address.toString()))
			}
			bid.nftCap.borrow()!.deposit(token: <- nft)
			destroy bid
		}

		pub fun getVaultType(_ id:UInt64) : Type {
			return self.borrowBid(id).vaultType
		}

		pub fun getIds() : [UInt64] {
			return self.bids.keys
		}

		pub fun containsId(_ id: UInt64) : Bool {
			return self.bids.containsKey(id)
		}

		pub fun getBidType() : Type {
			return Type<@Bid>()
		}


		pub fun bid(item: FindViews.ViewReadPointer, amount:UFix64, vaultType:Type, nftCap: Capability<&{NonFungibleToken.Receiver}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}, bidExtraField: {String : AnyStruct}) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()
			let tenant=self.getTenant()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), nftCap: nftCap, vaultType: vaultType, nonEscrowedBalance:amount, bidExtraField: bidExtraField)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))

			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, validUntil: validUntil, saleItemExtraField: saleItemExtraField)
			destroy oldToken
		}

		pub fun fulfillDirectOffer(id:UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already".concat(id.toString())
			}

			let bid =self.borrowBid(id)
			let saleItem=bid.from.borrow()!

			if !saleItem.isAcceptedDirectOffer(id) {
				panic("offer is not accepted yet")
			}

			saleItem.fulfillDirectOfferNonEscrowed(id:id, vault: <- vault)
		}

		pub fun increaseBid(id: UInt64, increaseBy: UFix64) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.increaseBid(increaseBy)
			if !bid.from.check() {
				panic("Seller unlinked the SaleItem collection capability. seller address : ".concat(bid.from.address.toString()))
			}
			bid.from.borrow()!.registerIncreasedBid(id)
		}

		/// The users cancel a bid himself
		pub fun cancelBid(_ id: UInt64) {
			let bid= self.borrowBid(id)
			if !bid.from.check() {
				panic("Seller unlinked the SaleItem collection capability. seller address : ".concat(bid.from.address.toString()))
			}
			bid.from.borrow()!.cancelBid(id)
			self.cancelBidFromSaleItem(id)
		}

		//called from saleItem when things are cancelled 
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
			let bid <- self.bids.remove(key: id) ?? panic("missing bid")
			destroy bid
		}

		pub fun borrowBid(_ id: UInt64): &Bid {
			if !self.bids.containsKey(id) {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.bids[id] as &Bid?)!
		}

		pub fun borrowBidItem(_ id: UInt64): &{FindMarket.Bid} {
			if !self.bids.containsKey(id) {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.bids[id] as &Bid{FindMarket.Bid}?)!
		}

		pub fun getBalance(_ id: UInt64) : UFix64 {
			let bid= self.borrowBid(id)
			return bid.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>): @SaleItemCollection {
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		if FindMarket.getTenantCapability(marketplace) == nil {
			panic("Invalid tenant")
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
		if FindMarket.getTenantCapability(marketplace) == nil {
			panic("Invalid tenant")
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
		}
		return nil
	}

	init() {
		FindMarket.addSaleItemType(Type<@SaleItem>())
		FindMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
		FindMarket.addMarketBidType(Type<@Bid>())
		FindMarket.addMarketBidCollectionType(Type<@MarketBidCollection>())
	}
}
