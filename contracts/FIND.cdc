import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"

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

	/// Emitted when a transaction involving a lease calculates that this lease is now locked
	pub event Locked(name: String, lockedUntil:UFix64)

	///  Emitted when a name is registred in FIND
	pub event Register(name: String, owner: Address, expireAt: UFix64)

	/// Emitted when a name is moved to a new owner
	pub event Moved(name: String, previousOwner: Address, newOwner: Address, expireAt: UFix64)

	/// Emitted when a name is freed
	pub event Freed(name: String, previousOwner: Address)

	/// Emitted when a name is sold to a new owner
	pub event Sold(name: String, previousOwner: Address, newOwner: Address, expireAt: UFix64, amount: UFix64)

	/// Emitted when a name is explicistly put up for sale
	pub event ForSale(name: String, owner: Address, expireAt: UFix64, amount: UFix64, active: Bool)

	/// Emitted if a bid occurs at a name that is too low or not for sale
	pub event BlindBid(name: String, bidder: Address, amount: UFix64)

	/// Emitted if a blind bid is canceled
	pub event BlindBidCanceled(name: String, bidder: Address)

	/// Emitted if a blind bid is rejected
	pub event BlindBidRejected(name: String, bidder: Address, amount: UFix64)

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
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.calculateCost(name)
		}
		panic("Network is not set up")
	}

	/// Lookup the address registered for a name
	pub fun lookupAddress(_ name:String): Address? {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.lookup(name)?.owner?.address
		}
		panic("Network is not set up")
	}

	/// Lookup the profile registered for a name
	pub fun lookup(_ name:String): &{Profile.Public}? {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.lookup(name)
		}
		panic("Network is not set up")
	}

	/// Deposit FT to name
	/// @param to: The name to send money too
	/// @param from: The vault to send too
	pub fun deposit(to:String, from: @FungibleToken.Vault) {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			let profile=network.lookup(to) ?? panic("could not find name")
			profile.deposit(from: <- from)
			return 
		}
		panic("Network is not set up")
	}

	/// Used in script to return a list of names that are outdated
	pub fun outdated(): [String] {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.outdated()
		}
		panic("Network is not set up")

	}

	/// Task to janitor a name and lock/free it if appropriate
	pub fun janitor(_ name: String): NameStatus {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.status(name)
		}
		panic("Network is not set up")
	}

	/// Return the status for a given name
	/// @return The Name status of a name
	pub fun status(_ name: String): NameStatus {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.readStatus(name)
		}
		panic("Network is not set up")
	}


	/// Struct holding information about a lease. Contains both the internal status the owner of the lease and if the state is persisted or not. 
	pub struct NameStatus{
		pub let status: LeaseStatus
		pub let owner: Address?
		pub let persisted: Bool

		init(status:LeaseStatus, owner:Address?,persisted:Bool) {
			self.status=status
			self.owner=owner
			self.persisted=persisted
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
		access(contract) var offerCallback: Capability<&{BidCollectionPublic}>?

		init(name:String, networkCap: Capability<&Network>) {
			self.name=name
			self.networkCap= networkCap
			self.salePrice=nil
			self.offerCallback=nil
		}

		pub fun setSalePrice(_ price: UFix64?) {
			self.salePrice=price
		}

		pub fun setCallback(_ callback: Capability<&{BidCollectionPublic}>?) {
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

		pub fun getLeaseStatus() : LeaseStatus {
			return FIND.status(self.name).status
		}
	}

	/* An Auction for a lease */
	pub resource Auction {
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) var latestBidCallback: Capability<&{BidCollectionPublic}>
		access(contract) let name: String

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&{BidCollectionPublic}>, name: String) {
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.latestBidCallback=latestBidCallback
			self.name=name
		}

		pub fun getBalance() : UFix64 {
			return self.latestBidCallback.borrow()!.getBalance(self.name)
		}

		pub fun addBid(callback: Capability<&{BidCollectionPublic}>, timestamp: UFix64) {
			if callback.borrow()!.getBalance(self.name) <= self.getBalance() {
				panic("bid must be larger then previous bid")
			}

			//we send the money back
			self.latestBidCallback.borrow()!.cancel(self.name)
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
		pub let status: LeaseStatus
		pub let expireTime: UFix64
		pub let latestBid: UFix64?
		pub let auctionEnds: UFix64?
		pub let salePrice: UFix64?
		pub let latestBidBy: Address?
		pub let currentTime: UFix64

		init(name: String, status:LeaseStatus, expireTime: UFix64, latestBid: UFix64?, auctionEnds: UFix64?, salePrice: UFix64?, latestBidBy: Address?) {

			self.name=name
			self.status=status
			self.expireTime=expireTime
			self.latestBid=latestBid
			self.latestBidBy=latestBidBy
			self.auctionEnds=auctionEnds
			self.salePrice=salePrice
			self.currentTime=Clock.time()
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
		access(contract) fun bid(name: String, callback: Capability<&{BidCollectionPublic}>)

		//the janitor process has to remove leases
		access(contract) fun remove(_ name: String) 

		//anybody should be able to fullfill an auction as long as it is done
		pub fun fullfill(_ name: String) 
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

			return LeaseInformation(name:  name, status: token.getLeaseStatus(), expireTime: token.getLeaseExpireTime(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy)
		}

		pub fun getLeaseInformation() : [LeaseInformation]  {
			var info: [LeaseInformation]=[]
			for name in self.leases.keys {
				let lease=self.getLease(name)
				if lease != nil {
					info.append(lease!)
				}
			}
			return info
		}

		//call this to start an auction for this lease
		pub fun startAuction(_ name: String) {
			let timestamp=Clock.time()
			let duration=86400.0
			let lease = self.borrow(name)
			if lease.offerCallback == nil {
				panic("cannot start an auction on a name without a bid, set salePrice")
			}

			let endsAt=timestamp + duration
			emit AuctionStarted(name: name, bidder: lease.offerCallback!.address, amount: lease.offerCallback!.borrow()!.getBalance(name), auctionEndAt: endsAt)

			let oldAuction <- self.auctions[name] <- create Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: 300.0,latestBidCallback: lease.offerCallback!, name: name)
			lease.setCallback(nil)

			destroy oldAuction
		}


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
				!self.auctions.containsKey(name) : "Can only increase bid before auction=".concat(name)
			}

			let lease = self.borrow(name)

			if lease.salePrice == nil {
				emit BlindBid(name: name, bidder: lease.offerCallback!.address, amount: lease.offerCallback!.borrow()!.getBalance(name))
				return
			}

			if lease.salePrice!  <= lease.offerCallback!.borrow()!.getBalance(name) {
				self.startAuction(name)
			} else {
				emit BlindBid(name: name, bidder: lease.offerCallback!.address, amount: lease.offerCallback!.borrow()!.getBalance(name))
			}

		}

		access(contract) fun bid(name: String, callback: Capability<&{BidCollectionPublic}>) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let timestamp=Clock.time()
			let lease = self.borrow(name)
			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp)
				return
			} 

			if let cb= lease.offerCallback {
				cb.borrow()!.cancel(name)
			}


			lease.setCallback(callback)

			if lease.salePrice == nil {
				emit BlindBid(name: name, bidder: callback.address, amount: callback.borrow()!.getBalance(name))
				return
			}

			if lease.salePrice!  <= callback.borrow()!.getBalance(name) {
				self.startAuction(name)
			} else {
				emit BlindBid(name: name, bidder: callback.address, amount: callback.borrow()!.getBalance(name))
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

				emit BlindBidRejected(name: name, bidder: cb.address, amount: cb.borrow()!.getBalance(name))
				cb.borrow()!.cancel(name)
				lease.setCallback(nil)
			}

			if self.auctions.containsKey(name) {

				let auction=self.borrowAuction(name)

				//the auction has ended
				if auction.endsAt <= Clock.time() {
					panic("Cannot cancel finished auction, fullfill it instead")
				}

				emit AuctionCancelled(name: name, bidder: auction.latestBidCallback.address, amount: auction.getBalance())
				auction.latestBidCallback.borrow()!.cancel(name)
				destroy <- self.auctions.remove(key: name)!
			}
		}

		pub fun fullfill(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			let oldProfile=FIND.lookup(name)!
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
				panic("Tag is not for auction name=".concat(name))
			}

			if self.borrowAuction(name).endsAt > Clock.time() {
				panic("Auction has not ended yet")
			}

			let auction <- self.auctions.remove(key: name)!

			let newProfile= getAccount(auction.latestBidCallback.address).getCapability<&{Profile.Public}>(Profile.publicPath)

			let soldFor=auction.getBalance()
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

		pub fun listForSale(name :String, amount: UFix64) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			emit ForSale(name: name, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), amount: amount, active: true)
			tokenRef.setSalePrice(amount)

		}

		pub fun delistSale(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			emit ForSale(name: name, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), amount: tokenRef.salePrice!, active: false)
			tokenRef.setSalePrice(nil)
		}

		//note that when moving a name
		pub fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&{LeaseCollectionPublic}>) {
			let token <- self.leases.remove(key:  name) ?? panic("missing NFT")
			emit Moved(name: name, previousOwner:self.owner!.address, newOwner: profile.address, expireAt: token.getLeaseExpireTime())
			token.move(profile: profile)
			to.borrow()!.deposit(token: <- token)
		}

		//note that when moving a name
		access(contract) fun remove(_ name: String) {
			self.cancel(name)
			let token <- self.leases.remove(key:  name) ?? panic("missing NFT")
			emit Freed(name:name, previousOwner:self.owner!.address)
			destroy token
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
			let leases= self.owner!.getCapability<&{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!.register(name:name, vault: <- vault, profile: profileCap, leases: leases)
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
		pub(set) var status: LeaseStatus
		pub(set) var time: UFix64
		pub(set) var profile: Capability<&{Profile.Public}>
		pub var address: Address
		pub var name: String

		init(status:LeaseStatus, time:UFix64, profile: Capability<&{Profile.Public}>, name: String) {
			self.status=status
			self.time=time
			self.profile=profile
			self.address= profile.address
			self.name=name
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
		access(contract) let defaultPrice: UFix64
		access(contract) let secondaryCut: UFix64
		access(contract) let lengthPrices: {Int: UFix64}

		//map from name to lease for that name
		access(contract) let profiles: { String: NetworkLease}

		init(leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>) {
			self.leasePeriod=leasePeriod
			self.lockPeriod=lockPeriod
			self.secondaryCut=secondaryCut
			self.defaultPrice=defaultPrice
			self.lengthPrices=lengthPrices
			self.profiles={}
			self.wallet=wallet
		}


		//this method is only called from a lease, and only the owner has that capability
		access(contract) fun renew(name: String, vault: @FUSD.Vault) {
			if let lease= self.profiles[name] {
				let nameStatus=self.status(name)

				var newTime=0.0
				if nameStatus.status == LeaseStatus.TAKEN {
					//the name is taken but not expired so we extend the total period of the lease
					newTime= lease.time + self.leasePeriod
				} else {
					//the name was locked so we extend from now and for a new period
					let time=Clock.time()
					newTime = time + self.leasePeriod
				}

				let cost= self.calculateCost(name)
				if vault.balance != cost {
					panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
				}
				self.wallet.borrow()!.deposit(from: <- vault)


				let lease= NetworkLease(
					status: LeaseStatus.TAKEN,
					time:newTime,
					profile: lease.profile,
					name: name
				)

				emit Register(name: name, owner:nameStatus.owner!, expireAt: lease.time)
				self.profiles[name] =  lease
				return
			}
			panic("Could not find profile with name=".concat(name))
		}

		access(contract) fun getLeaseExpireTime(_ name: String) : UFix64{
			if let lease= self.profiles[name] {
				return lease.time
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
		pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&{LeaseCollectionPublic}>) {
			pre {
				name.length >= 3 : "A FIND name has to be minimum 3 letters long"
			}

			let nameStatus=self.status(name)
			if nameStatus.status == LeaseStatus.TAKEN {
				panic("Tag already registered")
			}

			//if we have a locked profile that is not owned by the same identity then panic
			if nameStatus.status == LeaseStatus.LOCKED {
				panic("Tag is locked")
			}

			let cost= self.calculateCost(name)
			if vault.balance != cost {
				panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
			}
			self.wallet.borrow()!.deposit(from: <- vault)

			let lease= NetworkLease(
				status: LeaseStatus.TAKEN,
				time:Clock.time() + self.leasePeriod,
				profile: profile,
				name: name
			)

			emit Register(name: name, owner:profile.address, expireAt: lease.time)
			self.profiles[name] =  lease

			leases.borrow()!.deposit(token: <- create Lease(name: name, networkCap: FIND.account.getCapability<&Network>(FIND.NetworkPrivatePath)))
		}

		pub fun readStatus(_ name: String): NameStatus {
			let currentTime=Clock.time()
			if let lease= self.profiles[name] {
				let owner=lease.profile.borrow()!.owner!.address
				if currentTime <= lease.time {
					return NameStatus(status: lease.status, owner: owner, persisted: true)
				}

				if lease.status == LeaseStatus.LOCKED {
					return NameStatus(status: LeaseStatus.FREE, owner: nil, persisted: false)
				}

				if lease.status == LeaseStatus.TAKEN {
					return NameStatus(status:LeaseStatus.LOCKED, owner:  owner, persisted:false)
				}
			}
			return NameStatus(status:LeaseStatus.FREE, owner: nil, persisted:true)
		}

		pub fun outdated() : [String] {
			var outdated :[String] = []

			for name in self.profiles.keys {
				if !self.readStatus(name).persisted {
					outdated.append(name)
				}
			}

			return outdated
		}

		/// This method is almost like readStatus except that it will mutate state and fix the name it looks up if it is invalid.  Events are emitted when this is done.
		pub fun status(_ name: String): NameStatus {
			let currentTime=Clock.time()
			if let lease= self.profiles[name] {
				let owner=lease.profile.borrow()!.owner!.address
				if currentTime <= lease.time {
					return NameStatus(status: lease.status, owner: owner, persisted:true)
				}

				if lease.status == LeaseStatus.LOCKED {

					let leaseCollection=getAccount(owner).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow()!
					leaseCollection.remove(name)

					self.profiles.remove(key: name)
					return NameStatus(status: LeaseStatus.FREE, owner: nil, persisted:true)
				}

				if lease.status == LeaseStatus.TAKEN {
					lease.status= LeaseStatus.LOCKED
					lease.time = currentTime + self.lockPeriod
					emit Locked(name: name, lockedUntil:lease.time)
					self.profiles[name] = lease
				}
				return NameStatus(status:lease.status, owner:  owner, persisted: true)
			}
			return NameStatus(status:LeaseStatus.FREE, owner: nil, persisted: true)
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
			let length= name.length

			for i in self.lengthPrices.keys {
				if length==i {
					return self.lengthPrices[i]!
				}
			}
			return self.defaultPrice
		}

		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			self.wallet=wallet
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
		pub let amount: UFix64
		pub let timestamp: UFix64

		init(name: String, amount: UFix64, timestamp: UFix64) {
			self.name=name
			self.amount=amount
			self.timestamp=timestamp
		}
	}


	pub resource Bid {
		access(contract) let from: Capability<&{FIND.LeaseCollectionPublic}>
		access(contract) let name: String
		access(contract) let vault: @FUSD.Vault
		access(contract) var bidAt: UFix64

		init(from: Capability<&{FIND.LeaseCollectionPublic}>, name: String, vault: @FUSD.Vault){
			self.vault <- vault
			self.name=name
			self.from=from
			self.bidAt=Clock.time()
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
	}

	//A collection stored for bidders/buyers
	pub resource BidCollection: BidCollectionPublic {

		access(contract) var bids : @{String: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let leases: Capability<&{FIND.LeaseCollectionPublic}>

		init(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&{FIND.LeaseCollectionPublic}>) {
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
				bidInfo.append(BidInfo(name: bid.name, amount: bid.vault.balance, timestamp: bid.bidAt))
			}
			return bidInfo
		}

		//make a bid on a name
		pub fun bid(name: String, vault: @FUSD.Vault) {
			let nameStatus=FIND.status(name)
			if nameStatus.status ==  LeaseStatus.FREE {
				panic("cannot bid on name that is free")
			}
			let from=getAccount(nameStatus.owner!).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let bid <- create Bid(from: from, name:name, vault: <- vault)
			let leaseCollection= from.borrow() ?? panic("Could not borrow lease bid from owner of name=".concat(name))
			let callbackCapability =self.owner!.getCapability<&{BidCollectionPublic}>(FIND.BidPublicPath)
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
			let seller=getAccount(nameStatus.owner!).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let bid =self.borrowBid(name)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			let from=getAccount(nameStatus.owner!).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			from.borrow()!.increaseBid(name)
		}

		//cancel a bid, will panic if called after auction has started
		pub fun cancelBid(_ name: String) {

			let nameStatus=FIND.status(name)
			if nameStatus.status == LeaseStatus.FREE {
				self.cancel(name)
				return
			}
			let from=getAccount(nameStatus.owner!).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			from.borrow()!.cancelBid(name)
			self.cancel(name)
		}


		pub fun borrowBid(_ name: String): &Bid {
			return &self.bids[name] as &Bid
		}

		pub fun getBalance(_ name: String) : UFix64 {
			let bid= self.borrowBid(name)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	pub fun createEmptyBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&{FIND.LeaseCollectionPublic}>) : @BidCollection {
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

		//Admins can register names without name length restrictions
		pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&{LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.register(name:name, vault: <- vault, profile: profile, leases: leases)
		}

		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable()
			Clock.enable()
			Clock.tick(time)
		}


		init() {
			self.capability = nil
		}

	}
	init() {
		self.NetworkPrivatePath= /private/FIND
		self.NetworkStoragePath= /storage/FIND

		self.AdminProxyPublicPath= /public/finAdminProxy
		self.AdminProxyStoragePath=/storage/finAdminProxy

		self.LeasePublicPath=/public/finLeases
		self.LeaseStoragePath=/storage/finLeases

		self.BidPublicPath=/public/finBids
		self.BidStoragePath=/storage/finBids

		let wallet=self.account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

		// these values are hardcoded here for a reason. Then plan is to throw away the key and not have setters for them so that people can trust the contract to be the same
		let network <-  create Network(
			leasePeriod: 31536000.0, //365 days
			lockPeriod: 7776000.0, //90 days
			secondaryCut: 0.025,
			defaultPrice: 5.0,
			lengthPrices: {3: 500.0, 4:100.0},
			wallet: wallet
		)
		self.account.save(<-network, to: FIND.NetworkStoragePath)
		self.account.link<&Network>( FIND.NetworkPrivatePath, target: FIND.NetworkStoragePath)

	}
}
