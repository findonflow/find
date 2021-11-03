import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
import Artifact from "./Artifact.cdc"
/*

///FIND

///Flow Integrated Name Directory - A naming service on flow,

/// Lease a name in the network for as little as 5 FUSD a year, (4 characters cost 100, 3 cost 500)

Taxonomy:

- name: a textual description minimum 3 chars long that can be leased in FIND 
- profile: A Versus profile that represents a person, a name registed in FIND points to a profile
- lease: a resource representing registering a name for a period of 1 year
- leaseCollection: Collection of the leases an account holds
- leaseStatus: FREE|TAKEN|LOCKED, a LOCKED lease can be reopend by the owner. A lease will be locked for 90 days before it is freed
*/
pub contract FIND {

	/// An event to singla that there is a name in the network
	pub event Name(name: String)

	///  Emitted when a name is registred in FIND
	pub event Register(name: String, owner: Address, validUntil: UFix64, lockedUntil: UFix64)

	/// Emitted when a name is moved to a new owner
	pub event Moved(name: String, previousOwner: Address, newOwner: Address, expireAt: UFix64)

	/// Emitted when a name is sold to a new owner
	pub event Sold(name: String, previousOwner: Address, newOwner: Address, expireAt: UFix64, amount: UFix64)

	/// Emitted when a name is explicistly put up for sale
	pub event ForSale(name: String, owner: Address, expireAt: UFix64, directSellPrice: UFix64, active: Bool)
	pub event ForAuction(name: String, owner: Address, expireAt: UFix64,  auctionStartPrice: UFix64, auctionReservePrice: UFix64, active: Bool)

	/// Emitted if a bid occurs at a name that is too low or not for sale
	pub event BlindBid(name: String, bidder: Address, amount: UFix64)

	/// Emitted if a blind bid is canceled
	pub event BlindBidCanceled(name: String, bidder: Address)

	/// Emitted if a blind bid is rejected
	pub event BlindBidRejected(name: String, bidder: Address, amount: UFix64)

	//TODO: spelling error
	/// Emitted if an auction is canceled
	pub event AuctionCancelled(name: String, bidder: Address, amount: UFix64)

	/// Emitted when an auction starts. 
	pub event AuctionStarted(name: String, bidder: Address, amount: UFix64, auctionEndAt: UFix64)

	/// Emitted when there is a new bid in an auction
	pub event AuctionBid(name: String, bidder: Address, amount: UFix64, auctionEndAt: UFix64)

	//store bids made by a bidder to somebody elses leases
	pub let BidPublicPath: PublicPath
	pub let BidStoragePath: StoragePath

	//store the network itself
	pub let NetworkStoragePath: StoragePath
	pub let NetworkPrivatePath: PrivatePath

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath

	//store the leases you own
	pub let LeaseStoragePath: StoragePath
	pub let LeasePublicPath: PublicPath


	//These methods are basically just here for convenience

	/// Calculate the cost of an name
	/// @param _ the name to calculate the cost for
	pub fun calculateCost(_ name:String) : UFix64 {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}


		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.calculateCost(name)
		}
		panic("Network is not set up")
	}

	/// Lookup the address registered for a name
	pub fun lookupAddress(_ name:String): Address? {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.lookup(name)?.owner?.address
		}
		panic("Network is not set up")
	}

	/// Lookup the profile registered for a name
	pub fun lookup(_ name:String): &{Profile.Public}? {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.lookup(name)
		}
		panic("Network is not set up")
	}

	/// Deposit FT to name
	/// @param to: The name to send money too
	/// @param from: The vault to send too
	pub fun deposit(to:String, from: @FungibleToken.Vault) {
		pre {
			FIND.validateFindName(to) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			let profile=network.lookup(to) ?? panic("could not find name")
			profile.deposit(from: <- from)
			return 
		}
		panic("Network is not set up")
	}

	/// Return the status for a given name
	/// @return The Name status of a name
	pub fun status(_ name: String): NameStatus {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.readStatus(name)
		}
		panic("Network is not set up")
	}


	/// Struct holding information about a lease. Contains both the internal status the owner of the lease and if the state is persisted or not. 
	pub struct NameStatus{
		pub let status: LeaseStatus
		pub let owner: Address?

		init(status:LeaseStatus, owner:Address?) {
			self.status=status
			self.owner=owner
		}
	}

	/*
	=============================================================
	Lease is a collection/resource for storing the token leases 
	Also have a seperate Auction for tracking auctioning of leases
	=============================================================
	*/

	/*

	Lease is a resource you get back when you register a lease.
	You can use methods on it to renew the lease or to move to another profile
	*/
	pub resource Lease {
		access(contract) let name: String
		access(contract) let networkCap: Capability<&Network> 
		access(contract) var salePrice: UFix64?
		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var offerCallback: Capability<&BidCollection{BidCollectionPublic}>?

		init(name:String, networkCap: Capability<&Network>) {
			self.name=name
			self.networkCap= networkCap
			self.salePrice=nil
			self.auctionStartPrice=nil
			self.auctionReservePrice=nil
			self.auctionDuration=86400.0
			self.auctionExtensionOnLateBid=300.0
			self.auctionMinBidIncrement=10.0
			self.offerCallback=nil
		}

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
		}

		pub fun setAuctionDuration(_ duration: UFix64) {
			self.auctionDuration=duration
		}

		pub fun setSalePrice(_ price: UFix64?) {
			self.salePrice=price
		}

		pub fun setReservePrice(_ price: UFix64?) {
			self.auctionReservePrice=price
		}

		pub fun setMinBidIncrement(_ price: UFix64) {
			self.auctionMinBidIncrement=price
		}

		pub fun setStartAuctionPrice(_ price: UFix64?) {
			self.auctionStartPrice=price
		}

		pub fun setCallback(_ callback: Capability<&BidCollection{BidCollectionPublic}>?) {
			self.offerCallback=callback
		}

		pub fun extendLease(_ vault: @FUSD.Vault) {
			let network= self.networkCap.borrow()!
			network.renew(name: self.name, vault:<-  vault)
		}

		access(contract) fun move(profile: Capability<&{Profile.Public}>) {
			let network= self.networkCap.borrow()!
			network.move(name: self.name, profile: profile)
		}

		pub fun getLeaseExpireTime() : UFix64 {
			return self.networkCap.borrow()!.getLeaseExpireTime(self.name)
		}

		pub fun getLeaseLocedUntil() : UFix64 {
			return self.networkCap.borrow()!.getLeaseLocedUntil(self.name)
		}

		pub fun getProfile():&{Profile.Public}? {
			return self.networkCap.borrow()!.profile(self.name)
		}

		pub fun getLeaseStatus() : LeaseStatus {
			return FIND.status(self.name).status
		}
	}

	/* An Auction for a lease */
	pub resource Auction {
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) var latestBidCallback: Capability<&BidCollection{BidCollectionPublic}>
		access(contract) let name: String

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&BidCollection{BidCollectionPublic}>, name: String) {
			pre {
				startedAt < endsAt : "Cannot start before it will end"
				extendOnLateBid != 0.0 : "Extends on late bid must be a non zero value"
			}
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.latestBidCallback=latestBidCallback
			self.name=name
		}

		pub fun getBalance() : UFix64 {
			return self.latestBidCallback.borrow()!.getBalance(self.name)
		}

		pub fun addBid(callback: Capability<&BidCollection{BidCollectionPublic}>, timestamp: UFix64) {
			let offer=callback.borrow()!
			offer.setBidType(name: self.name, type: "auction")

			if callback.address != self.latestBidCallback.address {
				if offer.getBalance(self.name) <= self.getBalance() {
					panic("bid must be larger then previous bid")
				}
				//we send the money back
				self.latestBidCallback.borrow()!.cancel(self.name)
			}
			self.latestBidCallback=callback
			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				self.endsAt=suggestedEndTime
			}
			emit AuctionBid(name: self.name, bidder: self.latestBidCallback.address, amount: self.getBalance(), auctionEndAt: self.endsAt)
		}
	}

	//struct to expose information about leases
	pub struct LeaseInformation {
		pub let name: String
		pub let address: Address
		pub let cost: UFix64
		pub let status: String
		pub let validUntil: UFix64
		pub let lockedUntil: UFix64
		pub let latestBid: UFix64?
		pub let auctionEnds: UFix64?
		pub let salePrice: UFix64?
		pub let latestBidBy: Address?
		pub let currentTime: UFix64
		pub let auctionStartPrice: UFix64?
		pub let auctionReservePrice: UFix64?
		pub let extensionOnLateBid: UFix64?

		init(name: String, status:LeaseStatus, validUntil: UFix64, lockedUntil:UFix64, latestBid: UFix64?, auctionEnds: UFix64?, salePrice: UFix64?, latestBidBy: Address?, auctionStartPrice: UFix64?, auctionReservePrice: UFix64?, extensionOnLateBid:UFix64?, address:Address){

			self.name=name
			var s="TAKEN"	
			if status == LeaseStatus.FREE {
				s="FREE"
			} else if status == LeaseStatus.LOCKED {
				s="LOCKED"
			}
			self.status=s
			self.validUntil=validUntil
			self.lockedUntil=lockedUntil
			self.latestBid=latestBid
			self.latestBidBy=latestBidBy
			self.auctionEnds=auctionEnds
			self.salePrice=salePrice
			self.currentTime=Clock.time()
			self.auctionStartPrice=auctionStartPrice
			self.auctionReservePrice=auctionReservePrice
			self.extensionOnLateBid=extensionOnLateBid
			self.address=address
			self.cost=FIND.calculateCost(name)
		}

	}
	/*
	Since a single account can own more then one name there is a collecition of them
	This collection has build in support for direct sale of a FIND leaseToken. The network owner till take 2.5% cut
	*/
	pub resource interface LeaseCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getLeases(): [String]
		//fetch all names that are for sale
		pub fun getLeaseInformation() : [LeaseInformation]
		pub fun getLease(_ name: String) :LeaseInformation?

		//add a new lease token to the collection, can only be called in this contract
		access(contract) fun deposit(token: @FIND.Lease)

		access(contract)fun cancelBid(_ name: String) 
		access(contract) fun increaseBid(_ name: String) 

		//place a bid on a token
		access(contract) fun bid(name: String, callback: Capability<&BidCollection{BidCollectionPublic}>)

		//anybody should be able to fullfill an auction as long as it is done
		pub fun fullfillAuction(_ name: String) 
	}


	pub resource LeaseCollection: LeaseCollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(contract) var leases: @{String: FIND.Lease}

		access(contract) var auctions: @{String: Auction}

		//the cut the network will take, default 2.5%
		access(contract) let networkCut: UFix64

		//the wallet of the network to transfer royalty to
		access(contract) let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.leases <- {}
			self.auctions <- {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		pub fun getLease(_ name: String) : LeaseInformation? {
			if !self.leases.containsKey(name) {
				return nil 
			}
			let token=self.borrow(name)

			var latestBid: UFix64? = nil
			var auctionEnds: UFix64?= nil
			var latestBidBy: Address?=nil

			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)
				auctionEnds= auction.endsAt
				latestBid= auction.getBalance()
				latestBidBy= auction.latestBidCallback.address
			} else {
				if let callback = token.offerCallback {
					latestBid= callback.borrow()!.getBalance(name)
					latestBidBy=callback.address
				}
			}

			return LeaseInformation(name:  name, status: token.getLeaseStatus(), validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLocedUntil(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy, auctionStartPrice: token.auctionStartPrice, auctionReservePrice: token.auctionReservePrice, extensionOnLateBid: token.auctionExtensionOnLateBid, address: token.owner!.address)
		}

		pub fun getLeaseInformation() : [LeaseInformation]  {
			var info: [LeaseInformation]=[]
			for name in self.leases.keys {
				//TODO: for testnet
				if !FIND.validateFindName(name) {
					continue
				}
				let lease=self.getLease(name)
				if lease != nil && lease!.status != "FREE" {
					info.append(lease!)
				}
			}
			return info
		}

		//call this to start an auction for this lease
		pub fun startAuction(_ name: String) {
			let timestamp=Clock.time()
			let lease = self.borrow(name)
			let duration=lease.auctionDuration
			let extensionOnLateBid=lease.auctionExtensionOnLateBid
			if lease.offerCallback == nil {
				panic("cannot start an auction on a name without a bid, set salePrice")
			}

			let callback=lease.offerCallback!
			let offer=callback.borrow()!
			offer.setBidType(name: name, type: "auction")

			let endsAt=timestamp + duration
			emit AuctionStarted(name: name, bidder: callback.address, amount: offer.getBalance(name), auctionEndAt: endsAt)

			let oldAuction <- self.auctions[name] <- create Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: extensionOnLateBid, latestBidCallback: callback, name: name)
			lease.setCallback(nil)

			if lease.offerCallback == nil {
				Debug.log("offer callback is empty")
			}else {
				Debug.log("offer callback is NOT empty")
			}

			destroy oldAuction
		}


		//TODO: Should be allowed to cancel a bid if auction is on an item that is free
		access(contract) fun cancelBid(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
				!self.auctions.containsKey(name) : "Cannot cancel a bid that is in an auction=".concat(name)
			}

			let bid= self.borrow(name)
			if let callback = bid.offerCallback {
				emit BlindBidCanceled(name: name, bidder: callback.address)
			}

			bid.setCallback(nil)
		}

		access(contract) fun increaseBid(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			let timestamp=Clock.time()

			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:auction.latestBidCallback, timestamp:timestamp)
				return
			}

			let balance=lease.offerCallback!.borrow()!.getBalance(name) 
			Debug.log("Offer is at ".concat(balance.toString()))
			if lease.salePrice == nil  && lease.auctionStartPrice == nil{
				emit BlindBid(name: name, bidder: lease.offerCallback!.address, amount: balance)
				return
			}


			if lease.salePrice != nil && lease.salePrice != nil && balance >= lease.salePrice! {
				self.fullfill(name)
			} else if lease.auctionStartPrice != nil && balance >= lease.auctionStartPrice! {
				self.startAuction(name)
			} else {
				emit BlindBid(name: name, bidder: lease.offerCallback!.address, amount: balance)
			}

		}

		access(contract) fun bid(name: String, callback: Capability<&BidCollection{BidCollectionPublic}>) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let timestamp=Clock.time()
			let lease = self.borrow(name)

			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)

				if auction.latestBidCallback.address == callback.address {
					panic("You already have the latest bid on this item, use the incraseBid transaction")
				}
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp)
				return
			} 

			if let cb= lease.offerCallback {
				if cb.address == callback.address {
					panic("You already have the latest bid on this item, use the incraseBid transaction")
				}
				cb.borrow()!.cancel(name)
			}

			lease.setCallback(callback)

			let balance=callback.borrow()!.getBalance(name)
			Debug.log("Balance of lease is at ".concat(balance.toString()))
			if lease.salePrice == nil && lease.auctionStartPrice == nil {
				Debug.log("Sale price not set")
				emit BlindBid(name: name, bidder: callback.address, amount: balance)
				return
			}

			if lease.salePrice != nil && balance >= lease.salePrice! {
				Debug.log("Direct sale!")
				self.fullfill(name)
			}	 else if lease.auctionStartPrice != nil && balance >= lease.auctionStartPrice! {
				self.startAuction(name)
			} else {
				emit BlindBid(name: name, bidder: callback.address, amount: balance)
			}

		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			//if we have a callback there is no auction and it is a blind bid
			if let cb= lease.offerCallback {
				Debug.log("we have a blind bid so we cancel that")
				emit BlindBidRejected(name: name, bidder: cb.address, amount: cb.borrow()!.getBalance(name))
				cb.borrow()!.cancel(name)
				lease.setCallback(nil)
			}

			if self.auctions.containsKey(name) {

				let auction=self.borrowAuction(name)
				let balance=auction.getBalance()

				let auctionEnded= auction.endsAt <= Clock.time()
				var hasMetReservePrice= false
				if lease.auctionReservePrice != nil && lease.auctionReservePrice! <= balance {
					hasMetReservePrice=true
				}
				let price= lease.auctionReservePrice?.toString() ?? ""
				//the auction has ended
				Debug.log("Latest bid is ".concat(balance.toString()).concat(" reserve price is ").concat(price))
				if auctionEnded && hasMetReservePrice {
					//&& lease.auctionReservePrice != nil && lease.auctionReservePrice! < balance {
					panic("Cannot cancel finished auction, fullfill it instead")
				}

				emit AuctionCancelled(name: name, bidder: auction.latestBidCallback.address, amount: balance)
				auction.latestBidCallback.borrow()!.cancel(name)
				destroy <- self.auctions.remove(key: name)!
			}
		}

		/// fullfillAuction wraps the fullfill method and ensure that only a finished auction can be fullfilled by anybody
		pub fun fullfillAuction(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
				self.auctions.containsKey(name) : "Cannot fullfill sale that is not an auction=".concat(name)
			}

			return self.fullfill(name)
		}

		pub fun fullfill(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			if lease.getLeaseStatus() == LeaseStatus.FREE {
				panic("cannot fullfill sale name is now free")
			}

			let oldProfile=lease.getProfile()!

			if let cb= lease.offerCallback {
				let offer= cb.borrow()!
				let newProfile= getAccount(cb.address).getCapability<&{Profile.Public}>(Profile.publicPath)
				let soldFor=offer.getBalance(name)
				//move the token to the new profile
				emit Sold(name: name, previousOwner:lease.owner!.address, newOwner: newProfile.address, expireAt: lease.getLeaseExpireTime(), amount: soldFor)
				lease.move(profile: newProfile)

				let token <- self.leases.remove(key: name)!
				let vault <- offer.fullfill(<- token)
				if self.networkCut != 0.0 {
					let cutAmount= soldFor * self.networkCut
					self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				//why not use Profile to send money :P
				oldProfile.deposit(from: <- vault)
				return
			}

			if !self.auctions.containsKey(name) {
				panic("Name is not for auction name=".concat(name))
			}

			if self.borrowAuction(name).endsAt > Clock.time() {
				panic("Auction has not ended yet")
			}


			let auctionRef=self.borrowAuction(name)
			let soldFor=auctionRef.getBalance()
			let reservePrice=lease.auctionReservePrice ?? 0.0

			if reservePrice > soldFor {
				self.cancel(name)
				return
			}

			let auction <- self.auctions.remove(key: name)!
			let newProfile= getAccount(auction.latestBidCallback.address).getCapability<&{Profile.Public}>(Profile.publicPath)

			//move the token to the new profile
			emit Sold(name: name, previousOwner:lease.owner!.address, newOwner: newProfile.address, expireAt: lease.getLeaseExpireTime(), amount: soldFor)
			lease.move(profile: newProfile)

			let token <- self.leases.remove(key: name)!

			let vault <- auction.latestBidCallback.borrow()!.fullfill(<- token)
			if self.networkCut != 0.0 {
				let cutAmount= soldFor * self.networkCut
				self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}

			//why not use FIND to send money :P
			oldProfile.deposit(from: <- vault)

			destroy auction

		}

		pub fun listForAuction(name :String, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64) {
			//TODO; Add pre fields
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			tokenRef.setStartAuctionPrice(auctionStartPrice)
			tokenRef.setReservePrice(auctionReservePrice)
			tokenRef.setAuctionDuration(auctionDuration)
			tokenRef.setExtentionOnLateBid(auctionExtensionOnLateBid)
			emit ForAuction(name: name, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), auctionStartPrice: tokenRef.auctionStartPrice!, auctionReservePrice: tokenRef.auctionReservePrice!,  active: true)
		}

		pub fun listForSale(name :String, directSellPrice:UFix64) {
			//TODO; Add pre fields
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			tokenRef.setSalePrice(directSellPrice)
			emit ForSale(name: name, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), directSellPrice: tokenRef.salePrice!, active: true)
		}


		pub fun delistAuction(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)

			emit ForAuction(name: name, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), auctionStartPrice: tokenRef.auctionStartPrice!,  auctionReservePrice: tokenRef.auctionReservePrice!, active: false)
			tokenRef.setStartAuctionPrice(nil)
			tokenRef.setReservePrice(nil)
		}


		pub fun delistSale(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			emit ForSale(name: name, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), directSellPrice: tokenRef.salePrice!, active: false)
			tokenRef.setSalePrice(nil)
		}

		//note that when moving a name
		pub fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			let token <- self.leases.remove(key:  name) ?? panic("missing NFT")
			emit Moved(name: name, previousOwner:self.owner!.address, newOwner: profile.address, expireAt: token.getLeaseExpireTime())
			emit Register(name: name, owner:profile.address, validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLocedUntil())
			token.move(profile: profile)
			to.borrow()!.deposit(token: <- token)
		}

		//depoit a lease token into the lease collection, not available from the outside
		access(contract) fun deposit(token: @FIND.Lease) {
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.leases[token.name] <- token

			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getLeases(): [String] {
			return self.leases.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrow(_ name: String): &FIND.Lease {
			return &self.leases[name] as &FIND.Lease
		}

		//borrow the auction
		pub fun borrowAuction(_ name: String): &FIND.Auction {
			return &self.auctions[name] as &FIND.Auction
		}


		//This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
		pub fun register(name: String, vault: @FUSD.Vault){
			let profileCap = self.owner!.getCapability<&{Profile.Public}>(Profile.publicPath)
			let leases= self.owner!.getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

			if !network.publicEnabled {
				panic("Public registration is not enabled yet")
			}

			network.register(name:name, vault: <- vault, profile: profileCap, leases: leases)
		}

		destroy() {
			destroy self.leases
			destroy self.auctions
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptyLeaseCollection(): @FIND.LeaseCollection {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return <- create LeaseCollection(networkCut:network.secondaryCut, networkWallet: network.wallet)
		}
		panic("Network is not set up")
	}



	/*
	Core network things
	//===================================================================================================================
	*/
	//a struct that represents a lease of a name in the network. 
	pub struct NetworkLease {
		pub let registeredTime: UFix64
		pub var validUntil: UFix64
		pub var lockedUntil: UFix64
		pub(set) var profile: Capability<&{Profile.Public}>
		pub var address: Address
		pub var name: String

		init( validUntil:UFix64, lockedUntil:UFix64, profile: Capability<&{Profile.Public}>, name: String) {
			self.validUntil=validUntil
			self.lockedUntil=lockedUntil
			self.registeredTime=Clock.time()
			self.profile=profile
			self.address= profile.address
			self.name=name
		}

		pub fun setValidUntil(_ unit: UFix64) {
			self.validUntil=unit
		}

		pub fun setLockedUntil(_ unit: UFix64) {
			self.lockedUntil=unit
		}

		pub fun status() : LeaseStatus {
			let time=Clock.time()

			if time >= self.lockedUntil {
				return LeaseStatus.FREE
			}

			if time >= self.validUntil {
				return LeaseStatus.LOCKED
			}
			return 	LeaseStatus.TAKEN
		}
	}


	/*
	FREE, does not exist in profiles dictionary
	TAKEN, registered with a time that is currentTime + leasePeriod
	LOCKED, after TAKEN.time you will get a new  status and the new time will be

	*/

	pub enum LeaseStatus: UInt8 {
		pub case FREE
		pub case TAKEN
		pub case LOCKED
	}

	/*
	The main network resource that holds the state of the names in the network
	*/
	pub resource Network  {
		access(contract) var wallet: Capability<&{FungibleToken.Receiver}>
		access(contract) let leasePeriod: UFix64
		access(contract) let lockPeriod: UFix64
		access(contract) var defaultPrice: UFix64
		access(contract) let secondaryCut: UFix64
		//		access(contract) var pricesChangedAt: UFix64 //TODO add before mainnet
		access(contract) var lengthPrices: {Int: UFix64}
		access(contract) var publicEnabled: Bool

		//map from name to lease for that name
		access(contract) let profiles: { String: NetworkLease}

		init(leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>, publicEnabled:Bool) {
			self.leasePeriod=leasePeriod
			self.lockPeriod=lockPeriod
			self.secondaryCut=secondaryCut
			self.defaultPrice=defaultPrice
			//			self.pricesChangedAt=Clock.time()
			self.lengthPrices=lengthPrices
			self.profiles={}
			self.wallet=wallet
			self.publicEnabled=publicEnabled
		}


		pub fun setPrice(default: UFix64, additionalPrices: {Int: UFix64}) {
			//TODO: pre this that the pricesChangedAt cannot be 
			self.defaultPrice=default
			self.lengthPrices=additionalPrices
		}


		//this method is only called from a lease, and only the owner has that capability
		access(contract) fun renew(name: String, vault: @FUSD.Vault) {
			if let lease= self.profiles[name] {

				var newTime=0.0
				if lease.status() == LeaseStatus.TAKEN {
					//the name is taken but not expired so we extend the total period of the lease
					lease.setValidUntil(lease.validUntil + self.leasePeriod)
				} else {
					lease.setValidUntil(Clock.time() + self.leasePeriod)
				}
				lease.setLockedUntil(lease.validUntil+ self.lockPeriod)

				let cost= self.calculateCost(name)
				if vault.balance != cost {
					panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
				}
				self.wallet.borrow()!.deposit(from: <- vault)

				emit Register(name: name, owner:lease.profile.address, validUntil: lease.validUntil, lockedUntil: lease.lockedUntil)
				self.profiles[name] =  lease
				return
			}
			panic("Could not find profile with name=".concat(name))
		}


		access(contract) fun getLeaseExpireTime(_ name: String) : UFix64{
			if let lease= self.profiles[name] {
				return lease.validUntil
			}
			panic("Could not find profile with name=".concat(name))
		}

		access(contract) fun getLeaseLocedUntil(_ name: String) : UFix64{
			if let lease= self.profiles[name] {
				return lease.lockedUntil
			}
			panic("Could not find profile with name=".concat(name))
		}

		//moving leases are done from the lease collection
		access(contract) fun move(name: String, profile: Capability<&{Profile.Public}>) {
			if let lease= self.profiles[name] {
				lease.profile=profile
				self.profiles[name] = lease
				return
			}
			panic("Could not find profile with name=".concat(name))
		}

		//everybody can call register, normally done through the convenience method in the contract
		pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			pre {
				name.length >= 3 : "A FIND name has to be minimum 3 letters long"
			}

			let nameStatus=self.readStatus(name)
			if nameStatus.status == LeaseStatus.TAKEN {
				panic("Name already registered")
			}

			//if we have a locked profile that is not owned by the same identity then panic
			if nameStatus.status == LeaseStatus.LOCKED {
				panic("Name is locked")
			}

			let cost= self.calculateCost(name)
			if vault.balance != cost {
				panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
			}
			self.wallet.borrow()!.deposit(from: <- vault)

			let lease= NetworkLease(
				validUntil:Clock.time() + self.leasePeriod,
				lockedUntil: Clock.time() + self.leasePeriod+ self.lockPeriod,
				profile: profile,
				name: name
			)

			emit Register(name: name, owner:profile.address, validUntil: lease.validUntil, lockedUntil: lease.lockedUntil)
			emit Name(name: name)
			self.profiles[name] =  lease

			leases.borrow()!.deposit(token: <- create Lease(name: name, networkCap: FIND.account.getCapability<&Network>(FIND.NetworkPrivatePath)))
		}

		pub fun readStatus(_ name: String): NameStatus {
			let currentTime=Clock.time()
			if let lease= self.profiles[name] {
				if !lease.profile.check() {
					return NameStatus(status: LeaseStatus.TAKEN, owner: nil)
				}
				let owner=lease.profile.borrow()!.owner!.address
				return NameStatus(status: lease.status(), owner: owner)
			}
			return NameStatus(status:LeaseStatus.FREE, owner: nil)
		}

		access(account) fun profile(_ name: String) : &{Profile.Public}? {
			let nameStatus=self.readStatus(name)
			if nameStatus.status == LeaseStatus.FREE {
				return nil
			}

			if let lease=self.profiles[name] {
				return lease.profile.borrow()
			}
			return nil
		}


		//lookup a name that is not locked
		pub fun lookup(_ name: String) : &{Profile.Public}? {
			let nameStatus=self.readStatus(name)
			if nameStatus.status != LeaseStatus.TAKEN {
				return nil
			}

			if let lease=self.profiles[name] {
				return lease.profile.borrow()
			}
			return nil
		}

		pub fun calculateCost(_ name: String) : UFix64 {
			if self.lengthPrices[name.length] != nil {
				return self.lengthPrices[name.length]!
			} else {
				return self.defaultPrice
			}
		}

		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			self.wallet=wallet
		}

		pub fun setPublicEnabled(_ enabled: Bool) {
			self.publicEnabled=enabled
		}
	}



	/*
	==========================================================================
	Bids are a collection/resource for storing the bids bidder made on leases
	==========================================================================
	*/

	//Struct that is used to return information about bids
	pub struct BidInfo{
		pub let name: String
		pub let type: String
		pub let amount: UFix64
		pub let timestamp: UFix64
		pub let lease: LeaseInformation?

		init(name: String, amount: UFix64, timestamp: UFix64, type: String, lease: LeaseInformation?) {
			self.name=name
			self.amount=amount
			self.timestamp=timestamp
			self.type=type
			self.lease=lease
		}
	}


	pub resource Bid {
		access(contract) let from: Capability<&LeaseCollection{LeaseCollectionPublic}>
		access(contract) let name: String
		access(contract) var type: String
		access(contract) let vault: @FUSD.Vault
		access(contract) var bidAt: UFix64

		init(from: Capability<&LeaseCollection{LeaseCollectionPublic}>, name: String, vault: @FUSD.Vault){
			self.vault <- vault
			self.name=name
			self.from=from
			self.type="blind"
			self.bidAt=Clock.time()
		}

		access(contract) fun setType(_ type: String) {
			self.type=type
		}
		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		destroy() {
			//This is kinda bad. find FUSD vault of owner and deploy to that?
			destroy self.vault
		}
	}

	pub resource interface BidCollectionPublic {
		pub fun getBids() : [BidInfo]
		pub fun getBalance(_ name: String) : UFix64
		access(contract) fun fullfill(_ token: @FIND.Lease) : @FungibleToken.Vault
		access(contract) fun cancel(_ name: String)
		access(contract) fun setBidType(name: String, type: String) 
	}

	//A collection stored for bidders/buyers
	pub resource BidCollection: BidCollectionPublic {

		access(contract) var bids : @{String: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let leases: Capability<&LeaseCollection{LeaseCollectionPublic}>

		init(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.leases=leases
		}

		//called from lease when auction is ended
		//if purchase if fullfilled then we deposit money back into vault we get passed along and token into your own leases collection
		access(contract) fun fullfill(_ token: @FIND.Lease) : @FungibleToken.Vault{

			let bid <- self.bids.remove(key: token.name) ?? panic("missing bid")

			let vaultRef = &bid.vault as &FungibleToken.Vault

			token.setSalePrice(nil)
			token.setCallback(nil)
			token.setReservePrice(nil)
			token.setStartAuctionPrice(nil)
			self.leases.borrow()!.deposit(token: <- token)
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		//called from lease when things are cancelled
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancel(_ name: String) {
			let bid <- self.bids.remove(key: name) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)
				let leaseCollection= bid.from.borrow() ?? panic("Could not borrow lease bid from owner of name=".concat(bid.name))
				bidInfo.append(BidInfo(name: bid.name, amount: bid.vault.balance, timestamp: bid.bidAt, type: bid.type, lease: leaseCollection.getLease(bid.name)))
			}
			return bidInfo
		}

		//make a bid on a name
		pub fun bid(name: String, vault: @FUSD.Vault) {
			let nameStatus=FIND.status(name)
			if nameStatus.status ==  LeaseStatus.FREE {
				panic("cannot bid on name that is free")
			}
			let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let bid <- create Bid(from: from, name:name, vault: <- vault)
			let leaseCollection= from.borrow() ?? panic("Could not borrow lease bid from owner of name=".concat(name))


			let callbackCapability =self.owner!.getCapability<&BidCollection{BidCollectionPublic}>(FIND.BidPublicPath)
			let oldToken <- self.bids[bid.name] <- bid
			//send info to leaseCollection
			destroy oldToken
			leaseCollection.bid(name: name, callback: callbackCapability) 
		}


		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(name: String, vault: @FungibleToken.Vault) {
			let nameStatus=FIND.status(name)
			if nameStatus.status ==  LeaseStatus.FREE {
				panic("cannot increaseBid on name that is free")
			}
			let seller=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let bid =self.borrowBid(name)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
			from.borrow()!.increaseBid(name)
		}

		//cancel a bid, will panic if called after auction has started
		pub fun cancelBid(_ name: String) {

			let nameStatus=FIND.status(name)
			if nameStatus.status == LeaseStatus.FREE {
				self.cancel(name)
				return
			}
			let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
			from.borrow()!.cancelBid(name)
			self.cancel(name)
		}

		pub fun borrowBid(_ name: String): &Bid {
			return &self.bids[name] as &Bid
		}

		access(contract) fun setBidType(name: String, type: String) {
			let bid= self.borrowBid(name)
			bid.setType(type)
		}

		pub fun getBalance(_ name: String) : UFix64 {
			let bid= self.borrowBid(name)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	pub fun createEmptyBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) : @BidCollection {
		return <- create BidCollection(receiver: receiver,  leases: leases)
	}



	/// ===================================================================================
	// Admin things
	/// ===================================================================================

	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&Network>)
	}


	//admin proxy with capability receiver 
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&Network>?

		pub fun addCapability(_ cap: Capability<&Network>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}


		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setWallet(wallet)
		}


		/// Enable or disable public registration 
		pub fun setPublicEnabled(_ enabled: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPublicEnabled(enabled)
		}

		pub fun setPrice(default: UFix64, additional : {Int: UFix64}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPrice(default: default, additionalPrices: additional)
		}

		pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&LeaseCollection{LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			  FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			self.capability!.borrow()!.register(name:name, vault: <- vault, profile: profile, leases: leases)
		}

		pub fun createMinter(platform: Artifact.MinterPlatform) : @Artifact.ArtifactMinter {
			return <- Artifact.createMinter(platform:platform)
		}


		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}


		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun debug(_ value: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(value)
		}

		init() {
			self.capability = nil
		}

	}

	pub fun validateFindName(_ value: String) : Bool {
		if value.length < 3 || value.length > 16 {
			return false
		}
		if !FIND.validateAlphanumericLowerDash(value) {
			return false
		}

		return true
	}

	pub fun validateAlphanumericLowerDash(_ value:String) : Bool {
		let lowerA: UInt8=97
		let lowerZ: UInt8=122

		let dash:UInt8=45
		let number0:UInt8=48
		let number9:UInt8=57

		let bytes=value.utf8
		for byte in bytes {
			if byte >= lowerA && byte <= lowerZ {
				continue
			}
			if byte >= number0 && byte <= number9  {
				continue
			}

			if byte == dash {
				continue
			}
			return false

		}
		return true

	}

	pub fun validateHex(_ value:String) : Bool {
		let lowerA: UInt8=97
		let lowerF: UInt8=102

		let number0:UInt8=48
		let number9:UInt8=57

		let bytes=value.utf8
		for byte in bytes {
			if byte >= lowerA && byte <= lowerF {
				continue
			}
			if byte >= number0 && byte <= number9  {
				continue
			}
			return false

		}
		return true

	}
	init() {
		self.NetworkPrivatePath= /private/FIND
		self.NetworkStoragePath= /storage/FIND

		self.AdminProxyPublicPath= /public/findAdminProxy
		self.AdminProxyStoragePath=/storage/findAdminProxy

		self.LeasePublicPath=/public/findLeases2
		self.LeaseStoragePath=/storage/findLeases2

		self.BidPublicPath=/public/findBids2
		self.BidStoragePath=/storage/findBids2

		let wallet=self.account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

		// these values are hardcoded here for a reason. Then plan is to throw away the key and not have setters for them so that people can trust the contract to be the same
		let network <-  create Network(
			//TODO: change!
			//leasePeriod: 86400.0, //365 days
			//lockPeriod: 86400.0, //90 days
			leasePeriod: 31536000.0, //365 days
			lockPeriod: 7776000.0, //90 days
			secondaryCut: 0.05,
			defaultPrice: 5.0,
			lengthPrices: {3: 500.0, 4:100.0},
			wallet: wallet,
			publicEnabled: false
		)
		self.account.save(<-network, to: FIND.NetworkStoragePath)
		self.account.link<&Network>( FIND.NetworkPrivatePath, target: FIND.NetworkStoragePath)

	}
}
