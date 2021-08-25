import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"

/*

FNS

A naming service flow flow,

3 token tag cost 500 FUSD a year
4 token tag cost 100 FUSD a year
5 or more token tag cost 5 FUSD a year


This contract is pretty long, I have tried splitting it up into several files, but then there are issues

*/
pub contract FiNS {

	pub event JanitorLock(tag: String, lockedUntil:UFix64)

	pub event JanitorFree(tag: String)

	//	pub event Janitor(tag: String, 
	//event that is emited when a tag is registered or renewed
	pub event Register(tag: String, owner: Address, expireAt: UFix64)

	//event that is emitted when a tag is moved
	pub event Moved(tag: String, previousOwner: Address, newOwner: Address, expireAt: UFix64)

	pub event Freed(tag: String, previousOwner: Address)

	//event that is emitted when a tag is sold
	pub event Sold(tag: String, previousOwner: Address, newOwner: Address, expireAt: UFix64, amount: UFix64)

	//event that is emitted when an tag is listed for sale, if the active flag is false it is no longer for sale
	pub event ForSale(tag: String, owner: Address, expireAt: UFix64, amount: UFix64, active: Bool)

	//event that is emitted if a bid occurs at a tag that is too low or not for sale
	pub event BlindBid(tag: String, bidder: Address, amount: UFix64)

	//event that is emitted if a blind bid is canceled	
	pub event BlindBidCanceled(tag: String, bidder: Address)

	//event reject the blind bid
	pub event BlindBidRejected(tag: String, bidder: Address, amount: UFix64)


	//event that is emitted if a auction is canceled
	pub event AuctionCancelled(tag: String, bidder: Address, amount: UFix64)

	//event that is emitted when an auction is startet, that is a bid that is greater then the minimum price has been added, 
	//or the start auction is called manually by the seller on a lower bid
	pub event AuctionStarted(tag: String, bidder: Address, amount: UFix64, auctionEndAt: UFix64)

	//event that is emitted when there is a bid on a given auction
	pub event AuctionBid(tag: String, bidder: Address, amount: UFix64, auctionEndAt: UFix64)

	//store bids made by a bidder to somebody elses leases
	pub let BidPublicPath: PublicPath
	pub let BidStoragePath: StoragePath

	//store the network itself
	pub let NetworkStoragePath: StoragePath
	pub let NetworkPrivatePath: PrivatePath

	//store the administrator
	pub let AdministratorPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath

	//store the leases you own
	pub let LeaseStoragePath: StoragePath
	pub let LeasePublicPath: PublicPath

	//want to mock time on emulator. 
	access(contract) var fakeClock:UFix64?

	//For convenience the contract has a link to the given network so that you can call methods without having to borrow things.
	access(contract) var networkCap: Capability<&Network>?


	//These methods are basically just here for convenience
	pub fun calculateCost(_ tag:String) : UFix64 {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.calculateCost(tag)
	}


	pub fun lookup(_ tag:String): &{Profile.Public}? {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.lookup(tag)
	}

	pub fun deposit(to:String, from: @FungibleToken.Vault) {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		let profile=self.lookup(to) ?? panic("could not find tag")
		profile.deposit(from: <- from)
	}

	pub fun outdated(): [String] {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.outdated()
	}

	pub fun janitor(_ tag: String): TagStatus {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.status(tag)
	}

	pub fun status(_ tag: String): TagStatus {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.readStatus(tag)
	}


	pub struct  TagStatus{
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

	LeaseToken is a resource you get back when you register a lease.
	You can use methods on it to renew the lease or to move to another profile
	*/
	pub resource LeaseToken {
		access(contract) let tag: String
		access(contract) let networkCap: Capability<&Network> //Does this have to be an interface?
		access(contract) var salePrice: UFix64?
		access(contract) var  callback: Capability<&{BidCollectionPublic}>?

		init(tag:String, networkCap: Capability<&Network>) {
			self.tag=tag
			self.networkCap= networkCap
			self.salePrice=0.0
			self.callback=nil
		}

		pub fun setSalePrice(_ price: UFix64?) {
			self.salePrice=price
		}

		pub fun setCallback(_ callback: Capability<&{BidCollectionPublic}>?) {
			self.callback=callback
		}

		pub fun extendLease(_ vault: @FUSD.Vault) {
			let network= self.networkCap.borrow()!
			network.renew(tag: self.tag, vault:<-  vault)
		}

		access(contract) fun move(profile: Capability<&{Profile.Public}>) {
			let network= self.networkCap.borrow()!
			network.move(tag: self.tag, profile: profile)
		}

		pub fun getLeaseExpireTime() : UFix64 {
			return self.networkCap.borrow()!.getLeaseExpireTime(self.tag)
		}

		pub fun getLeaseStatus() : LeaseStatus {
			return FiNS.status(self.tag).status
		}
	}

	/* An Auction for a lease */
	pub resource Auction {
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) var callback: Capability<&{BidCollectionPublic}>
		access(contract) let tag: String

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, callback: Capability<&{BidCollectionPublic}>, tag: String) {
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.callback=callback
			self.tag=tag
		}

		pub fun getBalance() : UFix64 {
			return self.callback.borrow()!.getBalance(self.tag)
		}

		pub fun addBid(callback: Capability<&{BidCollectionPublic}>, timestamp: UFix64) {
			if callback.borrow()!.getBalance(self.tag) <= self.getBalance() {
				panic("bid must be larger then previous bid")
			}

			//we send the money back
			self.callback.borrow()!.cancel(self.tag)
			self.callback=callback
			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				self.endsAt=suggestedEndTime
			}
			emit AuctionBid(tag: self.tag, bidder: self.callback.address, amount: self.getBalance(), auctionEndAt: self.endsAt)
		}
	}

	//struct to expose information about leases
	pub struct LeaseInformation {
		pub let tag: String
		pub let status: LeaseStatus
		pub let expireTime: UFix64
		pub let latestBid: UFix64?
		pub let auctionEnds: UFix64?
		pub let salePrice: UFix64?
		pub let latestBidBy: Address?
		pub let currentTime: UFix64

		init(tag: String, status:LeaseStatus, expireTime: UFix64, latestBid: UFix64?, auctionEnds: UFix64?, salePrice: UFix64?, latestBidBy: Address?) {

			self.tag=tag
			self.status=status
			self.expireTime=expireTime
			self.latestBid=latestBid
			self.latestBidBy=latestBidBy
			self.auctionEnds=auctionEnds
			self.salePrice=salePrice
			self.currentTime=FiNS.time()
		}

	}
	/*
	Since a single account can own more then one tag there is a collecition of them
	This collection has build in support for direct sale of a FiNS leaseToken. The network owner till take 2.5% cut
	*/
	pub resource interface LeaseCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getTokens(): [String]
		//fetch all tags that are for sale
		pub fun getLeaseInformation() : [LeaseInformation]
		pub fun getLease(_ tag: String) :LeaseInformation?

		//add a new lease token to the collection, can only be called in this contract
		access(contract) fun deposit(token: @FiNS.LeaseToken)

		access(contract)fun cancelBid(_ tag: String) 
		access(contract) fun increaseBid(_ tag: String) 

		//place a bid on a token
		access(contract) fun bid(tag: String, callback: Capability<&{BidCollectionPublic}>)

		//the janitor process has to remove leases
		access(contract) fun remove(_ tag: String) 

		//anybody should be able to fullfill an auction as long as it is done
		pub fun fullfill(_ tag: String) 
	}


	pub resource LeaseCollection: LeaseCollectionPublic {
		// TODO: janitor process, check if there are tokens that are expired or tokens that will soon be locked. Emit events should be public, script to check it and transaction to send events

		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(contract) var tokens: @{String: FiNS.LeaseToken}

		access(contract) var auctions: @{String: Auction}

		//the cut the network will take, default 2.5%
		access(contract) let networkCut: UFix64

		//the wallet of the network to transfer royalty to
		access(contract) let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.tokens <- {}
			self.auctions <- {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		pub fun getLease(_ tag: String) : LeaseInformation? {
			if !self.tokens.containsKey(tag) {
				return nil 
			}
			let token=self.borrow(tag)

			var latestBid: UFix64? = nil
			var auctionEnds: UFix64?= nil
			var latestBidBy: Address?=nil

			if self.auctions.containsKey(tag) {
				let auction = self.borrowAuction(tag)
				auctionEnds= auction.endsAt
				latestBid= auction.getBalance()
				latestBidBy= auction.callback.address
			} else {
				if let callback = token.callback {
					latestBid= callback.borrow()!.getBalance(tag)
					latestBidBy=callback.address
				}
			}

			return LeaseInformation(tag:  tag, status: token.getLeaseStatus(), expireTime: token.getLeaseExpireTime(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy)
		}

		pub fun getLeaseInformation() : [LeaseInformation]  {
			var info: [LeaseInformation]=[]
			for tag in self.tokens.keys {
				let lease=self.getLease(tag)
				if lease != nil {
					info.append(lease!)
				}
			}
			return info
		}

		//call this to start an auction for this lease
		pub fun startAuction(_ tag: String) {
			let timestamp=FiNS.time()
			let duration=86400.0
			let lease = self.borrow(tag)
			if lease.callback == nil {
				panic("cannot start an auction on a tag without a bid, set salePrice")
			}

			let endsAt=timestamp + duration
			emit AuctionStarted(tag: tag, bidder: lease.callback!.address, amount: lease.callback!.borrow()!.getBalance(tag), auctionEndAt: endsAt)

			let oldAuction <- self.auctions[tag] <- create Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: 300.0, callback: lease.callback!, tag: tag)
			lease.setCallback(nil)

			destroy oldAuction
		}


		access(contract) fun cancelBid(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				!self.auctions.containsKey(tag) : "Cannot cancel a bid that is in an auction=".concat(tag)
			}

			let bid= self.borrow(tag)
			if let callback = bid.callback {
				emit BlindBidCanceled(tag: tag, bidder: callback.address)
			}

			bid.setCallback(nil)
		}

		access(contract) fun increaseBid(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				!self.auctions.containsKey(tag) : "Can only increase bid before auction=".concat(tag)
			}

			let lease = self.borrow(tag)

			if lease.salePrice == nil {
				return
			}

			if lease.salePrice!  <= lease.callback!.borrow()!.getBalance(tag) {
				self.startAuction(tag)
			} else {
				emit BlindBid(tag: tag, bidder: lease.callback!.address, amount: lease.callback!.borrow()!.getBalance(tag))
			}

		}

		access(contract) fun bid(tag: String, callback: Capability<&{BidCollectionPublic}>) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
			}

			let timestamp=FiNS.time()
			let lease = self.borrow(tag)
			if self.auctions.containsKey(tag) {
				let auction = self.borrowAuction(tag)
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp)
				return
			} 

			if let cb= lease.callback {
				cb.borrow()!.cancel(tag)
			}


			lease.setCallback(callback)

			if lease.salePrice == nil {
				return
			}

			if lease.salePrice!  <= callback.borrow()!.getBalance(tag) {
				self.startAuction(tag)
			} else {
				emit BlindBid(tag: tag, bidder: callback.address, amount: callback.borrow()!.getBalance(tag))
			}

		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
			}


			let lease = self.borrow(tag)
			//if we have a callback there is no auction and it is a blind bid
			if let cb= lease.callback {

				emit BlindBidRejected(tag: tag, bidder: cb.address, amount: cb.borrow()!.getBalance(tag))
				cb.borrow()!.cancel(tag)
				lease.setCallback(nil)
			}

			if self.auctions.containsKey(tag) {

				let auction=self.borrowAuction(tag)

				//the auction has ended
				if auction.endsAt <= FiNS.time() {
					panic("Cannot cancel finished auction, fullfill it instead")
				}

				emit AuctionCancelled(tag: tag, bidder: auction.callback.address, amount: auction.getBalance())
				auction.callback.borrow()!.cancel(tag)
				destroy <- self.auctions.remove(key: tag)!
			}
		}

		pub fun fullfill(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				self.auctions.containsKey(tag) : "Tag is not for auction tag=".concat(tag)
				self.borrowAuction(tag).endsAt < FiNS.time() : "Auction has not ended yet"
			}

			let oldProfile=FiNS.lookup(tag)!

			let auction <- self.auctions.remove(key: tag)!

			let newProfile= getAccount(auction.callback.address).getCapability<&{Profile.Public}>(Profile.publicPath)

			let soldFor=auction.getBalance()
			//move the token to the new profile
			let tokenRef = self.borrow(tag)
			emit Sold(tag: tag, previousOwner:tokenRef.owner!.address, newOwner: newProfile.address, expireAt: tokenRef.getLeaseExpireTime(), amount: soldFor)
			tokenRef.move(profile: newProfile)

			let token <- self.tokens.remove(key: tag)!

			let vault <- auction.callback.borrow()!.fullfill(<- token)
			if self.networkCut != 0.0 {
				let cutAmount= soldFor * self.networkCut
				self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}

			//why not use FiNS to send money :P
			oldProfile.deposit(from: <- vault)

			destroy auction

		}

		pub fun listForSale(tag :String, amount: UFix64) {
			pre {
				self.tokens.containsKey(tag) : "Cannot list tag for sale that is not registered to you tag=".concat(tag)
			}

			let tokenRef = self.borrow(tag)
			emit ForSale(tag: tag, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), amount: amount, active: true)
			tokenRef.setSalePrice(amount)

		}

		pub fun delistSale(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Cannot list tag for sale that is not registered to you tag=".concat(tag)
			}

			let tokenRef = self.borrow(tag)
			emit ForSale(tag: tag, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), amount: tokenRef.salePrice!, active: false)
			tokenRef.setSalePrice(nil)
		}

		//note that when moving a tag
		pub fun move(tag: String, profile: Capability<&{Profile.Public}>, to: Capability<&{LeaseCollectionPublic}>) {
			let token <- self.tokens.remove(key:  tag) ?? panic("missing NFT")
			emit Moved(tag: tag, previousOwner:self.owner!.address, newOwner: profile.address, expireAt: token.getLeaseExpireTime())
			token.move(profile: profile)
			to.borrow()!.deposit(token: <- token)
		}

		//note that when moving a tag
		access(contract) fun remove(_ tag: String) {
			self.cancel(tag)
			let token <- self.tokens.remove(key:  tag) ?? panic("missing NFT")
			emit Freed(tag:tag, previousOwner:self.owner!.address)
			destroy token
		}

		//depoit a lease token into the lease collection, not available from the outside
		access(contract) fun deposit(token: @FiNS.LeaseToken) {
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.tokens[token.tag] <- token

			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getTokens(): [String] {
			return self.tokens.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrow(_ tag: String): &FiNS.LeaseToken {
			return &self.tokens[tag] as &FiNS.LeaseToken
		}

		//borrow the auction
		pub fun borrowAuction(_ tag: String): &FiNS.Auction {
			return &self.auctions[tag] as &FiNS.Auction
		}


		//This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
		pub fun register(tag: String, vault: @FUSD.Vault){
			pre {
				tag.length >= 3 : "A public minted FiNS tag has to be minimum 3 letters long"
			}
			let profileCap = self.owner!.getCapability<&{Profile.Public}>(Profile.publicPath)
			let leases= self.owner!.getCapability<&{LeaseCollectionPublic}>(FiNS.LeasePublicPath)
			FiNS.networkCap!.borrow()!.register(tag:tag, vault: <- vault, profile: profileCap, leases: leases)
		}



		destroy() {
			destroy self.tokens
			destroy self.auctions
		}
	}

	//Create an empty lease collection that store your leases to a tag
	pub fun createEmptyLeaseCollection(): @FiNS.LeaseCollection {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		let network=self.networkCap!.borrow()!

		return <- create LeaseCollection(networkCut:network.secondaryCut, networkWallet: network.wallet)
	}

	//a struct that represents a lease of a tag in the network. 
	pub struct NetworkLease {
		pub(set) var status: LeaseStatus
		pub(set) var time: UFix64
		pub(set) var profile: Capability<&{Profile.Public}>
		pub var address: Address
		pub var tag: String

		init(status:LeaseStatus, time:UFix64, profile: Capability<&{Profile.Public}>, tag: String) {
			self.status=status
			self.time=time
			self.profile=profile
			self.address= profile.address
			self.tag=tag
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
	The main network resource that holds the state of the tags in the network
	*/
	pub resource Network  {
		access(contract) let wallet: Capability<&{FungibleToken.Receiver}>
		access(contract) var leasePeriod: UFix64
		access(contract) var lockPeriod: UFix64
		access(contract) var defaultPrice: UFix64
		access(contract) var secondaryCut: UFix64
		access(contract) var lengthPrices: {Int: UFix64}

		//map from tag to lease for that tag
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
		access(contract) fun renew(tag: String, vault: @FUSD.Vault) {
			if let lease= self.profiles[tag] {
				let tagStatus=self.status(tag)

				var newTime=0.0
				if tagStatus.status == LeaseStatus.TAKEN {
					//the tag is taken but not expired so we extend the total period of the lease
					newTime= lease.time + self.leasePeriod
				} else {
					//the tag was locked so we extend from now and for a new period
					let time=FiNS.time()
					newTime = time + self.leasePeriod
				}

				let cost= self.calculateCost(tag)
				if vault.balance != cost {
					panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
				}
				self.wallet.borrow()!.deposit(from: <- vault)


				let lease= NetworkLease(
					status: LeaseStatus.TAKEN,
					time:newTime,
					profile: lease.profile,
					tag: tag
				)

				emit Register(tag: tag, owner:tagStatus.owner!, expireAt: lease.time)
				self.profiles[tag] =  lease
				return
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		access(contract) fun getLeaseExpireTime(_ tag: String) : UFix64{
			if let lease= self.profiles[tag] {
				return lease.time
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		//moving leases are done from the lease collection
		access(contract) fun move(tag: String, profile: Capability<&{Profile.Public}>) {
			if let lease= self.profiles[tag] {
				lease.profile=profile
				self.profiles[tag] = lease
				return
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		//everybody can call register, normally done through the convenience method in the contract
		pub fun register(tag: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&{LeaseCollectionPublic}>) {

			let tagStatus=self.status(tag)
			if tagStatus.status == LeaseStatus.TAKEN {
				panic("Tag already registered")
			}

			//if we have a locked profile that is not owned by the same identity then panic
			if tagStatus.status == LeaseStatus.LOCKED {
				panic("Tag is locked")
			}

			let cost= self.calculateCost(tag)
			if vault.balance != cost {
				panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
			}
			self.wallet.borrow()!.deposit(from: <- vault)

			let lease= NetworkLease(
				status: LeaseStatus.TAKEN,
				time:FiNS.time() + self.leasePeriod,
				profile: profile,
				tag: tag
			)

			emit Register(tag: tag, owner:profile.address, expireAt: lease.time)
			self.profiles[tag] =  lease

			leases.borrow()!.deposit(token: <- create LeaseToken(tag: tag, networkCap: FiNS.networkCap!))
		}

		pub fun readStatus(_ tag: String): TagStatus {
			let currentTime=FiNS.time()
			if let lease= self.profiles[tag] {
				let owner=lease.profile.borrow()!.owner!.address
				if currentTime <= lease.time {
					return TagStatus(status: lease.status, owner: owner, persisted: true)
				}

				if lease.status == LeaseStatus.LOCKED {
					return TagStatus(status: LeaseStatus.FREE, owner: nil, persisted: false)
				}

				if lease.status == LeaseStatus.TAKEN {
					return TagStatus(status:LeaseStatus.LOCKED, owner:  owner, persisted:false)
				}
			}
			return TagStatus(status:LeaseStatus.FREE, owner: nil, persisted:true)
		}

		pub fun outdated() : [String] {
			var outdated :[String] = []

			for tag in self.profiles.keys {
				if !self.readStatus(tag).persisted {
					outdated.append(tag)
				}
			}

			return outdated
		}

		pub fun status(_ tag: String): TagStatus {
			let currentTime=FiNS.time()
			if let lease= self.profiles[tag] {
				let owner=lease.profile.borrow()!.owner!.address
				if currentTime <= lease.time {
					return TagStatus(status: lease.status, owner: owner, persisted:true)
				}

				if lease.status == LeaseStatus.LOCKED {

					let leaseCollection=getAccount(owner).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath).borrow()!
					leaseCollection.remove(tag)

					self.profiles.remove(key: tag)
					emit JanitorFree(tag: tag)
					return TagStatus(status: LeaseStatus.FREE, owner: nil, persisted:true)
				}

				if lease.status == LeaseStatus.TAKEN {
					lease.status= LeaseStatus.LOCKED
					lease.time = currentTime + self.lockPeriod
					emit JanitorLock(tag: tag, lockedUntil:lease.time)
					self.profiles[tag] = lease
				}
				return TagStatus(status:lease.status, owner:  owner, persisted: true)
			}
			return TagStatus(status:LeaseStatus.FREE, owner: nil, persisted: true)
		}

		//lookup a tag that is not locked
		pub fun lookup(_ tag: String) : &{Profile.Public}? {
			let tagStatus=self.readStatus(tag)
			if tagStatus.status != LeaseStatus.TAKEN {
				return nil
			}

			if let lease=self.profiles[tag] {
				return lease.profile.borrow()
			}
			return nil
		}

		pub fun calculateCost(_ tag: String) : UFix64 {
			let length= tag.length

			for i in self.lengthPrices.keys {
				if length==i {
					return self.lengthPrices[i]!
				}
			}
			return self.defaultPrice
		}

		pub fun setLengthPrices(_ lengthPrices: {Int: UFix64}) {
			self.lengthPrices=lengthPrices
		}

		pub fun setDefaultPrice(_ price: UFix64) {
			self.defaultPrice=price
		}

		pub fun setLeasePeriod(_ period: UFix64)  {
			self.leasePeriod=period
		}

		pub fun setLockPeriod(_ period: UFix64) {
			self.lockPeriod=period
		}

	}

	//An Minter resource that can create a Network
	pub resource Administrator {

		pub fun createNetwork(
			leasePeriod: UFix64,
			lockPeriod: UFix64,
			secondaryCut: UFix64,
			defaultPrice: UFix64,
			lengthPrices: {Int:UFix64},
			wallet:Capability<&{FungibleToken.Receiver}>
		): @Network {
			return  <-  create Network(
				leasePeriod: leasePeriod,
				lockPeriod: lockPeriod,
				secondaryCut: secondaryCut,
				defaultPrice: defaultPrice,
				lengthPrices: lengthPrices,
				wallet: wallet
			)
		}

	}


	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&Administrator>)
	}


	//admin proxy with capability receiver 
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&Administrator>?

		pub fun addCapability(_ cap: Capability<&Administrator>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}


		//Admins can register tags without tag length restrictions
		pub fun register(tag: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&{LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FiNS, capability is not set"
			}

			FiNS.networkCap!.borrow()!.register(tag:tag, vault: <- vault, profile: profile, leases: leases)
		}

		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FiNS, capability is not set"
			}

			FiNS.fakeClock=(FiNS.fakeClock ?? 0.0) + time
			log("clock is now at=".concat(FiNS.fakeClock?.toString() ?? "" ))
		}

		//sending in the admin account here is maybe not recommended but since it is called once i do not think it really matters.
		pub fun createNetwork( admin: AuthAccount, leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>) {

			pre {
				self.capability != nil: "Cannot create FiNS, capability is not set"
			}

			let network <- self.capability!.borrow()!.createNetwork(
				leasePeriod: leasePeriod,
				lockPeriod: lockPeriod,
				secondaryCut:secondaryCut,
				defaultPrice:defaultPrice,
				lengthPrices:lengthPrices,
				wallet: wallet
			)
			admin.save(<-network, to: FiNS.NetworkStoragePath)
			admin.link<&Network>( FiNS.NetworkPrivatePath, target: FiNS.NetworkStoragePath)
			//For convenience in FiNS we set the network in the contract itself. So there should really only be a single FiNS. Not sure if this is really needed or apropriate.
			FiNS.networkCap= admin.getCapability<&Network>(FiNS.NetworkPrivatePath)
		}

		init() {
			self.capability = nil
		}

	}


	/*
	==========================================================================
	Bids are a collection/resource for storing the bids bidder made on leases
	==========================================================================
	*/

	//Struct that is used to return information about bids
	pub struct BidInfo{
		pub let tag: String
		pub let amount: UFix64
		pub let timestamp: UFix64

		init(tag: String, amount: UFix64, timestamp: UFix64) {
			self.tag=tag
			self.amount=amount
			self.timestamp=timestamp
		}
	}


	pub resource Bid {
		access(contract) let from: Capability<&{FiNS.LeaseCollectionPublic}>
		access(contract) let tag: String
		access(contract) let vault: @FUSD.Vault
		access(contract) var bidAt: UFix64

		init(from: Capability<&{FiNS.LeaseCollectionPublic}>, tag: String, vault: @FUSD.Vault){
			self.vault <- vault
			self.tag=tag
			self.from=from
			self.bidAt=FiNS.time()
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
		pub fun getBalance(_ tag: String) : UFix64
		access(contract) fun fullfill(_ token: @FiNS.LeaseToken) : @FungibleToken.Vault
		access(contract) fun cancel(_ tag: String)
	}

	//A collection stored for bidders/buyers
	pub resource BidCollection: BidCollectionPublic {

		access(contract) var bids : @{String: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let leases: Capability<&{FiNS.LeaseCollectionPublic}>

		init(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&{FiNS.LeaseCollectionPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.leases=leases
		}

		//called from lease when auction is ended
		//if purchase if fullfilled then we deposit money back into vault we get passed along and token into your own leases collection
		access(contract) fun fullfill(_ token: @FiNS.LeaseToken) : @FungibleToken.Vault{

			let bid <- self.bids.remove(key: token.tag) ?? panic("missing bid")

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
		access(contract) fun cancel(_ tag: String) {
			let bid <- self.bids.remove(key: tag) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)
				bidInfo.append(BidInfo(tag: bid.tag, amount: bid.vault.balance, timestamp: bid.bidAt))
			}
			return bidInfo
		}

		//make a bid on a tag
		pub fun bid(tag: String, vault: @FUSD.Vault) {
			let tagStatus=FiNS.status(tag)
			if tagStatus.status ==  LeaseStatus.FREE {
				panic("cannot bid on tag that is free")
			}
			let from=getAccount(tagStatus.owner!).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)

			let bid <- create Bid(from: from, tag:tag, vault: <- vault)
			let leaseCollection= from.borrow() ?? panic("Could not borrow lease bid from owner of tag=".concat(tag))
			let callbackCapability =self.owner!.getCapability<&{BidCollectionPublic}>(FiNS.BidPublicPath)
			let oldToken <- self.bids[bid.tag] <- bid
			//send info to leaseCollection
			destroy oldToken
			leaseCollection.bid(tag: tag, callback: callbackCapability) 
		}


		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(tag: String, vault: @FungibleToken.Vault) {
			let tagStatus=FiNS.status(tag)
			if tagStatus.status ==  LeaseStatus.FREE {
				panic("cannot increaseBid on tag that is free")
			}
			let seller=getAccount(tagStatus.owner!).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)

			let bid =self.borrowBid(tag)
			bid.setBidAt(FiNS.time())
			bid.vault.deposit(from: <- vault)

			let from=getAccount(tagStatus.owner!).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)
			from.borrow()!.increaseBid(tag)
		}

		//cancel a bid, will panic if called after auction has started
		pub fun cancelBid(_ tag: String) {

			let tagStatus=FiNS.status(tag)
			if tagStatus.status == LeaseStatus.FREE {
				self.cancel(tag)
				return
			}
			let from=getAccount(tagStatus.owner!).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)
			from.borrow()!.cancelBid(tag)
			self.cancel(tag)
		}


		pub fun borrowBid(_ tag: String): &Bid {
			return &self.bids[tag] as &Bid
		}

		pub fun getBalance(_ tag: String) : UFix64 {
			let bid= self.borrowBid(tag)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	pub fun createEmptyBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&{FiNS.LeaseCollectionPublic}>) : @BidCollection {
		return <- create BidCollection(receiver: receiver,  leases: leases)
	}


	//mocking the time! Should probably remove self.fakeClock in mainnet?
	access(contract) fun time() : UFix64 {
		return self.fakeClock ?? getCurrentBlock().timestamp
	}

	init() {
		self.NetworkPrivatePath= /private/FiNS
		self.NetworkStoragePath= /storage/FiNS

		self.AdministratorStoragePath=/storage/finAdmin
		self.AdministratorPrivatePath=/private/finAdmin

		self.AdminProxyPublicPath= /public/finAdminProxy
		self.AdminProxyStoragePath=/storage/finAdminProxy

		self.LeasePublicPath=/public/finLeases
		self.LeaseStoragePath=/storage/finLeases

		self.BidPublicPath=/public/finBids
		self.BidStoragePath=/storage/finBids


		self.account.save(<- create Administrator(), to: self.AdministratorStoragePath)
		self.account.link<&Administrator>(self.AdministratorPrivatePath, target: self.AdministratorStoragePath)
		self.networkCap = nil

		self.fakeClock=nil
	}
}
