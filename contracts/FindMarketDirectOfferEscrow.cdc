import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import Profile from "./Profile.cdc"

pub contract FindMarketDirectOfferEscrow {

	pub event DirectOffer(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo?, buyer:Address?, buyerName:String?, buyerAvatar: String?, endsAt: UFix64?, previousBuyer:Address?, previousBuyerName:String?)


	pub resource SaleItem : FindMarket.SaleItem {

		access(contract) var pointer: AnyStruct{FindViews.Pointer}

		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>
		access(contract) var validUntil: UFix64?
		access(contract) var saleItemExtraField: {String : AnyStruct}
		access(contract) let totalRoyalties: UFix64

		init(pointer: AnyStruct{FindViews.Pointer}, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
			self.pointer=pointer
			self.offerCallback=callback
			self.validUntil=validUntil
			self.saleItemExtraField=saleItemExtraField
			self.totalRoyalties=self.pointer.getTotalRoyaltiesCut()
		}

		access(all) getId() : UInt64{
			return self.pointer.getUUID()
		}

		access(all) acceptEscrowedBid() : @FungibleToken.Vault {
			if !self.offerCallback.check() {
				panic("Bidder unlinked bid collection capability. Bidder Address : ".concat(self.offerCallback.address.toString()))
			}
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			let publicPath = pointer.getNFTCollectionData().publicPath
			let vault <- self.offerCallback.borrow()!.accept(<- pointer.withdraw(), path:publicPath)
			return <- vault
		}

		access(all) getRoyalty() : MetadataViews.Royalties {
			return self.pointer.getRoyalty()
		}

		access(all) getBalance() : UFix64 {
			if !self.offerCallback.check() {
				panic("Bidder unlinked bid collection capability. Bidder Address : ".concat(self.offerCallback.address.toString()))
			}
			return self.offerCallback.borrow()!.getBalance(self.getId())
		}

		access(all) getSeller() : Address {
			return self.pointer.owner()
		}

		access(all) getSellerName() : String? {
			let address = self.pointer.owner()
			return FIND.reverseLookup(address)
		}


		access(all) getBuyer() : Address? {
			return self.offerCallback.address
		}

		access(all) getBuyerName() : String? {
			if let name = FIND.reverseLookup(self.offerCallback.address) {
				return name
			}
			return nil
		}

		access(all) toNFTInfo(_ detail: Bool) : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id, detail:detail)
		}

		access(all) getSaleType() : String {
			return "active_ongoing"
		}

		access(all) getListingType() : Type {
			return Type<@SaleItem>()
		}

		access(all) getListingTypeIdentifier() : String {
			return Type<@SaleItem>().identifier
		}

		access(all) setPointer(_ pointer: FindViews.AuthNFTPointer) {
			self.pointer=pointer
		}

		access(all) getItemID() : UInt64 {
			return self.pointer.id
		}

		access(all) getItemType() : Type {
			return self.pointer.getItemType()
		}

		access(all) getAuction(): FindMarket.AuctionItem? {
			return nil
		}

		access(all) getFtType() : Type  {
			if !self.offerCallback.check() {
				panic("Bidder unlinked bid collection capability. Bidder Address : ".concat(self.offerCallback.address.toString()))
			}
			return self.offerCallback.borrow()!.getVaultType(self.getId())
		}

		access(all) setValidUntil(_ time: UFix64?) {
			self.validUntil=time
		}

		access(all) getValidUntil() : UFix64? {
			return self.validUntil
		}

		access(all) setCallback(_ callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {
			self.offerCallback=callback
		}

		access(all) checkPointer() : Bool {
			return self.pointer.valid()
		}

		access(all) checkSoulBound() : Bool {
			return self.pointer.checkSoulBound()
		}

		access(all) getSaleItemExtraField() : {String : AnyStruct} {
			return self.saleItemExtraField
		}

		access(contract) fun setSaleItemExtraField(_ field: {String : AnyStruct}) {
			self.saleItemExtraField = field
		}

		access(all) getTotalRoyalties() : UFix64 {
			return self.totalRoyalties
		}

		access(all) validateRoyalties() : Bool {
			return self.totalRoyalties == self.pointer.getTotalRoyaltiesCut()
		}

		access(all) getDisplay() : MetadataViews.Display {
			return self.pointer.getDisplay()
		}

		access(all) getNFTCollectionData() : MetadataViews.NFTCollectionData {
			return self.pointer.getNFTCollectionData()
		}
	}


	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		access(all) getIds(): [UInt64]
		access(all) containsId(_ id: UInt64): Bool
		access(contract)fun cancelBid(_ id: UInt64)

		access(contract) fun registerIncreasedBid(_ id: UInt64)

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct})

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

		access(all) getListingType() : Type {
			return Type<@SaleItem>()
		}

		//this is called when a buyer cancel a direct offer
		access(contract) fun cancelBid(_ id: UInt64) {
			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(id.toString()))
			}
			let saleItem=self.borrow(id)

			let tenant=self.getTenant()
			let ftType= saleItem.getFtType()

			let status="cancel"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			var nftInfo:FindMarket.NFTInfo?=nil
			if saleItem.checkPointer() {
				nftInfo=saleItem.toNFTInfo(false)
			}

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)

			destroy <- self.items.remove(key: id)
		}

		//The only thing we do here is basically register an event
		access(contract) fun registerIncreasedBid(_ id: UInt64) {

			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(id.toString()))
			}
			let saleItem=self.borrow(id)

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "add bid in direct offer"), seller: self.owner!.address, buyer: saleItem.offerCallback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let status="active_offered"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			let nftInfo=saleItem.toNFTInfo(true)

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

				let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "bid in direct offer"), seller: self.owner!.address, buyer: callback.address)

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

				let nftInfo=saleItemRef.toNFTInfo(true)

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

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "bid in direct offer"), seller: self.owner!.address, buyer: callback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()?.getBalance(id) ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(callback.address.toString()))

			let currentBalance=saleItem.getBalance()
			Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
			if currentBalance >= balance {
				panic("There is already a higher bid on this item")
			}
			//somebody else has the highest item so we cancel it
			let previousBuyer=saleItem.offerCallback.address
			let previousCB = saleItem.offerCallback.borrow() ?? panic("Previous bidder unlinked the bid collection capability. bidder address : ".concat(previousBuyer.toString()))
			previousCB.cancelBidFromSaleItem(id)
			saleItem.setValidUntil(validUntil)
			saleItem.setCallback(callback)

			let status="active_offered"
			let owner=self.owner!.address
			let buyer=callback.address
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			let nftInfo=saleItem.toNFTInfo(true)

			let previousBuyerName = FIND.reverseLookup(previousBuyer)

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)


		}

		//cancel will reject a direct offer
		access(all) cancel(_ id: UInt64) {

			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(id.toString()))
			}

			let saleItem=self.borrow(id)

			let tenant=self.getTenant()
			let ftType= saleItem.getFtType()


			var status="rejected"
			let owner=self.owner!.address
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)

			var nftInfo:FindMarket.NFTInfo?=nil
			if saleItem.checkPointer() {
				nftInfo=saleItem.toNFTInfo(false)
			}

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)

			saleItem.offerCallback.borrow()!.cancelBidFromSaleItem(id)
			destroy <- self.items.remove(key: id)
		}

		access(all) acceptDirectOffer(_ pointer: FindViews.AuthNFTPointer) {

			let id = pointer.getUUID()
			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(pointer.getUUID().toString()))
			}
			let saleItem = self.borrow(id)

			if saleItem.validUntil != nil && saleItem.validUntil! < Clock.time() {
				panic("This direct offer is already expired")
			}

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "fulfill directOffer"), seller: self.owner!.address, buyer: saleItem.offerCallback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= tenant.getCuts(name: actionResult.name, listingType: Type<@FindMarketDirectOfferEscrow.SaleItem>(), nftType: nftType, ftType: ftType)

			//Set the auth pointer in the saleItem so that it now can be fulfilled
			saleItem.setPointer(pointer)

			let royalty=saleItem.getRoyalty()
			let nftInfo=saleItem.toNFTInfo(true)

			let status="sold"
			let owner=saleItem.getSeller()
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			let buyerName=FIND.reverseLookup(buyer)
			let sellerName=FIND.reverseLookup(owner)
			let profile = Profile.find(buyer)

			emit DirectOffer(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: sellerName , amount: balance, status:status, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.validUntil, previousBuyer:nil, previousBuyerName:nil)

			let vault <- saleItem.acceptEscrowedBid()

			let resolved : {Address : String} = {}
			resolved[buyer] = buyerName ?? ""
			resolved[owner] = sellerName ?? ""
			resolved[FindMarketDirectOfferEscrow.account.address] =  "find"
			// Have to make sure the tenant always have the valid find name
			resolved[FindMarket.tenantNameAddress[tenant.name]!] =  tenant.name

			FindMarket.pay(tenant: tenant.name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) }, resolvedAddress: resolved)
			destroy <- self.items.remove(key: id)
		}

		access(all) getIds(): [UInt64] {
			return self.items.keys
		}

		access(all) getRoyaltyChangedIds(): [UInt64] {
			let ids : [UInt64] = []
			for id in self.getIds() {
				let item = self.borrow(id)
				if !item.validateRoyalties() {
					ids.append(id)
				}
			}
			return ids
		}

		access(all) containsId(_ id: UInt64): Bool {
			return self.items.containsKey(id)
		}

		access(all) borrow(_ id: UInt64): &SaleItem {
			return (&self.items[id] as &SaleItem?)!
		}

		access(all) borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
			if !self.items.containsKey(id) {
				panic("This id does not exist : ".concat(id.toString()))
			}
			return (&self.items[id] as &SaleItem{FindMarket.SaleItem}?)!
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
		access(contract) let bidExtraField: {String : AnyStruct}

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, bidExtraField: {String : AnyStruct}) {
			self.vaultType=vault.getType()
			self.vault <- vault
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
			self.bidExtraField=bidExtraField
		}

		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		access(all) getBalance() : UFix64 {
			return self.vault.balance
		}

		access(all) getSellerAddress() : Address {
			return self.from.address
		}

		access(all) getBidExtraField() : {String : AnyStruct} {
			return self.bidExtraField
		}

		destroy() {
			destroy self.vault
		}
	}

	pub resource interface MarketBidCollectionPublic {
		access(all) getBalance(_ id: UInt64) : UFix64
		access(all) getVaultType(_ id: UInt64) : Type
		access(all) containsId(_ id: UInt64): Bool
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT, path:PublicPath) : @FungibleToken.Vault
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

		access(contract) fun accept(_ nft: @NonFungibleToken.NFT, path:PublicPath) : @FungibleToken.Vault {
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault

			let nftCap = bid.nftCap
			if !nftCap.check() {
				 let cpCap =getAccount(nftCap.address).getCapability<&{NonFungibleToken.Collection}>(path)
				 if !cpCap.check() {
					panic("Bidder unlinked the nft receiver capability. bidder address : ".concat(bid.nftCap.address.toString()))
				} else {
					bid.nftCap.borrow()!.deposit(token: <- nft)
				}
			} else {
				bid.nftCap.borrow()!.deposit(token: <- nft)
			}

			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		access(all) getVaultType(_ id:UInt64) : Type {
			return self.borrowBid(id).vaultType
		}

		access(all) getIds() : [UInt64] {
			return self.bids.keys
		}

		access(all) containsId(_ id: UInt64) : Bool {
			return self.bids.containsKey(id)
		}

		access(all) getBidType() : Type {
			return Type<@Bid>()
		}

		access(all) bid(item: FindViews.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}, bidExtraField: {String : AnyStruct}) {

			// ensure it is not a 0 dollar listing
			if vault.balance <= 0.0 {
				panic("Offer price should be greater than 0")
			}

			// ensure validUntil is valid
			if validUntil != nil && validUntil! < Clock.time() {
				panic("Valid until is before current time")
			}

			// check soul bound
			if item.checkSoulBound() {
				panic("This item is soul bounded and cannot be traded")
			}

			if self.owner!.address == item.owner() {
				panic("You cannot bid on your own resource")
			}

			let uuid=item.getUUID()

			if self.bids[uuid] != nil {
				panic("You already have an bid for this item, use increaseBid on that bid")
			}
			let tenant=self.getTenant()

			// Check if it is onefootball. If so, listing has to be at least $0.65 (DUC)
			if tenant.name == "onefootball" {
				// ensure it is not a 0 dollar listing
				if vault.balance <= 0.65 {
					panic("Offer price should be greater than 0.65")
				}
			}

			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap, bidExtraField: bidExtraField)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, validUntil:validUntil, saleItemExtraField: saleItemExtraField)
			destroy oldToken
		}

		access(all) increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)
			if !bid.from.check() {
				panic("Seller unlinked SaleItem collection capability. seller address : ".concat(bid.from.address.toString()))
			}
			bid.from.borrow()!.registerIncreasedBid(id)
		}

		/// The users cancel a bid himself
		access(all) cancelBid(_ id: UInt64) {
			let bid= self.borrowBid(id)
			bid.from.borrow()!.cancelBid(id)
			self.cancelBidFromSaleItem(id)
		}

		access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
			if !self.receiver.check() {
				panic("This user does not have receiver vault set up. User: ".concat(self.receiver.address.toString()))
			}
			Debug.log("cancel bid")
			let bid <- self.bids.remove(key: id) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		access(all) borrowBid(_ id: UInt64): &Bid {
			if !self.bids.containsKey(id){
				panic("This id does not exist : ".concat(id.toString()))
			}
			return (&self.bids[id] as &Bid?)!
		}

		access(all) borrowBidItem(_ id: UInt64): &{FindMarket.Bid} {
			if !self.bids.containsKey(id){
				panic("This id does not exist : ".concat(id.toString()))
			}
			return (&self.bids[id] as &Bid{FindMarket.Bid}?)!
		}

		access(all) getBalance(_ id: UInt64) : UFix64 {
			let bid= self.borrowBid(id)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}
	//Create an empty lease collection that store your leases to a name
	access(all) createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>): @SaleItemCollection {
		return <- create SaleItemCollection(tenantCapability)
	}

	access(all) createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
	}

	access(all) getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		if FindMarket.getTenantCapability(marketplace) == nil {
			panic("Invalid tenant")
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}

	access(all) getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
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
