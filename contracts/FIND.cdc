import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import FiatToken from "./standard/FiatToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import DapperUtilityCoin from "./standard/DapperUtilityCoin.cdc"
import Profile from "./Profile.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
import Sender from "./Sender.cdc"
import ProfileCache from "./ProfileCache.cdc"
import FindUtils from "./FindUtils.cdc"
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


    //Old events not in use anymore we cannot remove
    pub event Sold()
    pub event SoldAuction()
    pub event DirectOfferRejected()
    pub event DirectOfferCanceled()
    pub event AuctionStarted()
    pub event AuctionCanceled()
    pub event AuctionBid()
    pub event AuctionCanceledReservePrice()
    pub event ForSale()
    pub event ForAuction()

    // Deprecated in testnet
    pub event TokensRewarded()
    pub event TokensCanNotBeRewarded()

    //event when FT is sent
    pub event FungibleTokenSent(from:Address, fromName:String?, name:String, toAddress:Address, message:String, tag:String, amount: UFix64, ftType:String)

    /// An event to singla that there is a name in the network
    pub event Name(name: String)

    pub event AddonActivated(name: String, addon:String)

    ///  Emitted when a name is registred in FIND
    pub event Register(name: String, owner: Address, validUntil: UFix64, lockedUntil: UFix64)

    /// Emitted when a name is moved to a new owner
    pub event Moved(name: String, previousOwner: Address, newOwner: Address, validUntil: UFix64, lockedUntil: UFix64)

    /// Emitted when a name is explicistly put up for sale
    pub event Sale(name: String, uuid:UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, buyerAvatar: String?, validUntil: UFix64, lockedUntil: UFix64)

    /// Emitted when an name is put up for on-demand auction
    pub event EnglishAuction(name: String, uuid:UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, buyerAvatar: String?, endsAt: UFix64?, validUntil: UFix64, lockedUntil: UFix64, previousBuyer:Address?, previousBuyerName:String?)

    /// Emitted if a bid occurs at a name that is too low or not for sale
    pub event DirectOffer(name: String, uuid:UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, buyerAvatar: String?, validUntil: UFix64, lockedUntil: UFix64, previousBuyer:Address?, previousBuyerName:String?)

    pub event RoyaltyPaid(name: String, uuid: UInt64, address: Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, saleType: String)

    //store bids made by a bidder to somebody elses leases
    pub let BidPublicPath: PublicPath
    pub let BidStoragePath: StoragePath

    //store the network itself
    pub let NetworkStoragePath: StoragePath
    pub let NetworkPrivatePath: PrivatePath

    //store the leases you own
    pub let LeaseStoragePath: StoragePath
    pub let LeasePublicPath: PublicPath

    pub fun getLeases() : [NetworkLease] {
        if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.profiles.values
        }
        panic("Network is not set up")
    }


    //These methods are basically just here for convenience

    /// Calculate the cost of an name
    /// @param _ the name to calculate the cost for
    pub fun calculateCost(_ name:String) : UFix64 {
        if !FIND.validateFindName(name) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.calculateCost(name)
        }
        panic("Network is not set up")
    }

    pub fun resolve(_ input:String) : Address? {

        let trimmedInput = FIND.trimFindSuffix(input)

        if FIND.validateFindName(trimmedInput) {
            if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
                return network.lookup(trimmedInput)?.owner?.address
            }

            return nil
        }

        var address=trimmedInput
        if trimmedInput.utf8[1] == 120 {
            address = trimmedInput.slice(from: 2, upTo: trimmedInput.length)
        }
        var r:UInt64 = 0
        var bytes = address.decodeHex()

        while bytes.length>0{
            r = r  + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8 ))
        }

        return Address(r)
    }

    /// Lookup the address registered for a name
    pub fun lookupAddress(_ name:String): Address? {

        let trimmedName = FIND.trimFindSuffix(name)

        if !FIND.validateFindName(trimmedName) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.lookup(trimmedName)?.owner?.address
        }
        return nil
    }

    /// Lookup the profile registered for a name
    pub fun lookup(_ input:String): &{Profile.Public}? {
        if let address = FIND.resolve(input) {
            let account = getAccount(address)
            let cap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
            if cap.check() {
                return cap.borrow()
            }
        }
        return nil
    }


    pub fun reverseLookupFN() : ((Address) : String?) {
        return fun(address:Address): String? {
            return FIND.reverseLookup(address)
        }
    }

    /// lookup if an address has a .find name, if it does pick either the default one or the first registered
    pub fun reverseLookup(_ address:Address): String? {

        let leaseNameCache = ProfileCache.getAddressLeaseName(address)

        if leaseNameCache == nil {
            let account=getAccount(address)
            let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

            if !leaseCap.check() {
                return nil
            }

            let profileFindName= Profile.find(address).getFindName()

            let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) ?? panic("Network is not set up")

            if profileFindName != "" {
                let status = network.readStatus(profileFindName)
                if status.owner != nil && status.owner! == address {
                    if status.status == FIND.LeaseStatus.TAKEN {
                        ProfileCache.setAddressLeaseNameCache(address: address, leaseName: profileFindName, validUntil: network.getLeaseExpireTime(profileFindName))
                        return profileFindName
                    }
                }
            }

            let leaseCol = leaseCap.borrow()!
            let nameLeases = leaseCol.getNames()
            for nameLease in nameLeases {

                //filter out all leases that are FREE or LOCKED since they are not actice
                let status = network.readStatus(nameLease)
                if status.owner != nil && status.owner! == address {
                    if status.status == FIND.LeaseStatus.TAKEN {
                        ProfileCache.setAddressLeaseNameCache(address: address, leaseName: nameLease, validUntil: network.getLeaseExpireTime(nameLease))
                        return nameLease
                    }
                }
            }
            ProfileCache.setAddressLeaseNameCache(address: address, leaseName: nil, validUntil: UFix64.max)
            return nil
        } else if leaseNameCache! == "" {
            // If empty string, return no find Name
            return nil
        }
        return leaseNameCache!
    }

    /// Deposit FT to name
    /// @param to: The name to send money too
    /// @param message: The message to send
    /// @param tag: The tag to add to the event
    /// @param vault: The vault to send too
    /// @param from: The sender that sent the funds
    pub fun depositWithTagAndMessage(to:String, message:String, tag: String, vault: @FungibleToken.Vault, from: &Sender.Token){

        let fromAddress= from.owner!.address
        let maybeAddress = FIND.resolve(to)
        if maybeAddress  == nil{
            panic("Not a valid .find name or address")
        }
        let address=maybeAddress!

        let account = getAccount(address)
        let cap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
        if cap.check() {
            let profile= cap.borrow()!
            emit FungibleTokenSent(from: fromAddress, fromName: FIND.reverseLookup(fromAddress), name: to, toAddress: profile.getAddress(), message:message, tag:tag, amount:vault.balance, ftType:vault.getType().identifier)
            profile.deposit(from: <- vault)
            return
        }

        var path = ""
        if vault.getType() == Type<@FlowToken.Vault>() {
            path ="flowTokenReceiver"
        } else if vault.getType() == Type<@FUSD.Vault>() {
            path="fusdReceiver"
        }
        if path != "" {
            emit FungibleTokenSent(from: fromAddress, fromName: FIND.reverseLookup(fromAddress), name: "", toAddress: address, message:message, tag:tag, amount:vault.balance, ftType:vault.getType().identifier)
            account.getCapability<&{FungibleToken.Receiver}>(PublicPath(identifier: path)!).borrow()!.deposit(from: <- vault)
            return
        }
        panic("Could not find a valid receiver for this vault type")

    }


    /// Deposit FT to name
    /// @param to: The name to send money too
    /// @param from: The vault to send too
    pub fun deposit(to:String, from: @FungibleToken.Vault) {
        if !FIND.validateFindName(to) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
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
        if !FIND.validateFindName(name) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
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
        access(contract) var addons: {String: Bool}

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
            self.addons={}
        }

        pub fun getName() : String {
            return self.name
        }

        pub fun getAddon() : [String] {
            return self.addons.keys
        }

        pub fun checkAddon(addon: String) : Bool {
            if !self.addons.containsKey(addon) {
                return false
            }
            return self.addons[addon]!
        }

        access(contract) fun addAddon(_ addon:String) {
            self.addons[addon]=true
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
            let network= self.networkCap.borrow() ?? panic("The network is not up")
            network.renew(name: self.name, vault:<-  vault)
        }

        pub fun extendLeaseDapper(merchAccount: Address, vault: @DapperUtilityCoin.Vault) {
            let network= self.networkCap.borrow() ?? panic("The network is not up")
            network.renewDapper(merchAccount: merchAccount, name: self.name, vault:<-  vault)
        }

        access(contract) fun move(profile: Capability<&{Profile.Public}>) {
            let network= self.networkCap.borrow() ?? panic("The network is not up")
            let senderAddress= network.profiles[self.name]!.profile.address
            network.move(name: self.name, profile: profile)


            // set FindNames
            // receiver
            let receiver = profile.borrow() ?? panic("The profile capability is invalid")
            if receiver.getFindName() == "" {
                receiver.setFindName(self.name)
            }

            // sender
            let sender = Profile.find(senderAddress)
            if sender.getFindName() == self.name {
                let network = FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath) ?? panic("Network is not set up")
                let leaseCol = getAccount(senderAddress).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow()!
                let nameLeases = leaseCol.getNames()
                for nameLease in nameLeases {

                    //filter out all leases that are FREE or LOCKED since they are not actice
                    let status = network.readStatus(nameLease)
                    if status.owner != nil && status.owner! == senderAddress {
                        if status.status == FIND.LeaseStatus.TAKEN {
                            sender.setFindName(nameLease)
                            return
                        }
                    }

                }
                sender.setFindName("")
            }
        }

        pub fun getLeaseExpireTime() : UFix64 {
            let network = self.networkCap.borrow() ?? panic("The network is not up")
            return network.getLeaseExpireTime(self.name)
        }

        pub fun getLeaseLockedUntil() : UFix64 {
            let network = self.networkCap.borrow() ?? panic("The network is not up")
            return network.getLeaseLockedUntil(self.name)
        }

        pub fun getProfile():&{Profile.Public}? {
            let network = self.networkCap.borrow() ?? panic("The network is not up")
            return network.profile(self.name)
        }

        pub fun getLeaseStatus() : LeaseStatus {
            return FIND.status(self.name).status
        }

        pub fun validate() : Bool {
            // if network is not there anymore, it is not valid
            if !self.networkCap.check() {
                return false
            }
            let network = self.networkCap.borrow()!
            let lease = network.getLease(self.name)
            // if the network lease is nil, it is definitely not validated
            if lease == nil {
                return false
            }
            // regardless of the status (FREE / LOCKED / TAKEN)
            // (because other functions checks that)
            // if this lease is not the current / latest owner, this lease is not valid anymore
            let registeredOwner = lease!.profile.address
            if registeredOwner == self.owner?.address {
                return true
            }
            return false
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

            if startedAt >= endsAt {
                panic("Cannot start before it will end")
            }
            if extendOnLateBid == 0.0 {
                panic("Extends on late bid must be a non zero value")
            }
            self.endsAt=endsAt
            self.startedAt=startedAt
            self.extendOnLateBid=extendOnLateBid
            self.latestBidCallback=latestBidCallback
            self.name=name
        }

        pub fun getBalance() : UFix64 {
            let cb = self.latestBidCallback.borrow() ?? panic("The bidder has unlinked the capability. bidder address: ".concat(self.latestBidCallback.address.toString()))
            return cb.getBalance(self.name)
        }

        pub fun addBid(callback: Capability<&BidCollection{BidCollectionPublic}>, timestamp: UFix64, lease: &Lease) {
            let offer=callback.borrow()!
            offer.setBidType(name: self.name, type: "auction")

            var previousBuyer: Address?=nil
            if callback.address != self.latestBidCallback.address {
                if offer.getBalance(self.name) <= self.getBalance() {
                    panic("bid must be larger then current bid. Current bid is : ".concat(self.getBalance().toString()).concat(". New bid is at : ").concat(offer.getBalance(self.name).toString()))
                }
                previousBuyer=self.latestBidCallback.address
                //we send the money back
                self.latestBidCallback.borrow()!.cancel(self.name)
            }
            self.latestBidCallback=callback
            let suggestedEndTime=timestamp+self.extendOnLateBid
            if suggestedEndTime > self.endsAt {
                self.endsAt=suggestedEndTime
            }

            let bidder= callback.address
            let profile=getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
            if profile == nil {
                panic("Create a profile before you make a bid")
            }
            let bidderName= profile!.getName()
            let bidderAvatar= profile!.getAvatar()
            let owner=lease.owner!.address
            let ownerName=self.name

            var previousBuyerName:String?=nil
            if let pb = previousBuyer {
                previousBuyerName=FIND.reverseLookup(pb)
            }

            emit EnglishAuction(name: self.name, uuid: lease.uuid, seller: owner, sellerName:ownerName, amount: offer.getBalance(self.name), auctionReservePrice: lease.auctionReservePrice!, status: "active_ongoing", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar:bidderAvatar, endsAt: self.endsAt ,validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)
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
        pub let addons: [String]

        init(name: String, status:LeaseStatus, validUntil: UFix64, lockedUntil:UFix64, latestBid: UFix64?, auctionEnds: UFix64?, salePrice: UFix64?, latestBidBy: Address?, auctionStartPrice: UFix64?, auctionReservePrice: UFix64?, extensionOnLateBid:UFix64?, address:Address, addons: [String]){

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
            self.addons=addons

        }

    }
    /*
    Since a single account can own more then one name there is a collecition of them
    This collection has build in support for direct sale of a FIND leaseToken. The network owner till take 2.5% cut
    */
    pub resource interface LeaseCollectionPublic {
        //fetch all the tokens in the collection
        pub fun getLeases(): [String]
        pub fun getInvalidatedLeases(): [String]
        //fetch all names that are for sale
        pub fun getLeaseInformation() : [LeaseInformation]
        pub fun getLease(_ name: String) :LeaseInformation?

        //add a new lease token to the collection, can only be called in this contract
        access(contract) fun deposit(token: @FIND.Lease)

        access(contract)fun cancelUserBid(_ name: String)
        access(contract) fun increaseBid(_ name: String, balance: UFix64)

        //place a bid on a token
        access(contract) fun registerBid(name: String, callback: Capability<&BidCollection{BidCollectionPublic}>)

        //anybody should be able to fulfill an auction as long as it is done
        pub fun fulfillAuction(_ name: String)
        pub fun buyAddon(name:String, addon: String, vault: @FUSD.Vault)
        pub fun buyAddonDapper(merchAccount: Address, name:String, addon:String, vault: @DapperUtilityCoin.Vault)
        access(account) fun adminAddAddon(name:String, addon: String)
        pub fun getAddon(name:String) : [String]
        pub fun checkAddon(name:String, addon: String) : Bool
        access(account) fun getNames() : [String]
        access(account) fun containsName(_ name: String) : Bool
        access(account) fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&LeaseCollection{LeaseCollectionPublic}>)
        pub fun getLeaseUUID(_ name: String) : UInt64
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

        pub fun buyAddon(name:String, addon:String, vault: @FUSD.Vault)  {
            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            if network.addonPrices[addon] == nil {
                panic("This addon is not available. addon : ".concat(addon))
            }
            let addonPrice = network.addonPrices[addon]!

            let lease = self.borrow(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            if lease.addons.containsKey(addon) {
                panic("You already have this addon : ".concat(addon))
            }

            if vault.balance != addonPrice {
                panic("Expect ".concat(addonPrice.toString()).concat(" FUSD for ").concat(addon).concat(" addon"))
            }

            lease.addAddon(addon)

            //put something in your storage
            emit AddonActivated(name: name, addon: addon)
            let networkWallet = self.networkWallet.borrow() ?? panic("The network is not up")
            networkWallet.deposit(from: <- vault)
        }

        pub fun buyAddonDapper(merchAccount: Address, name:String, addon:String, vault: @DapperUtilityCoin.Vault)  {
            FIND.checkMerchantAddress(merchAccount)

            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            if network.addonPrices[addon] == nil {
                panic("This addon is not available. addon : ".concat(addon))
            }
            let addonPrice = network.addonPrices[addon]!

            let lease = self.borrow(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            if lease.addons.containsKey(addon) {
                panic("You already have this addon : ".concat(addon))
            }

            if vault.balance != addonPrice {
                panic("Expect ".concat(addonPrice.toString()).concat(" Dapper Credit for ").concat(addon).concat(" addon"))
            }

            lease.addAddon(addon)

            //put something in your storage
            emit AddonActivated(name: name, addon: addon)

            // This is here just to check if the network is up
            let networkWallet = self.networkWallet.borrow() ?? panic("The network is not up")

            let wallet = getAccount(merchAccount).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)

            let walletRef = wallet.borrow() ?? panic("Cannot borrow reference to Dapper Merch Account receiver. Address : ".concat(merchAccount.toString()))
            walletRef.deposit(from: <- vault)
        }

        access(account) fun adminAddAddon(name:String, addon:String)  {
            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            if network.addonPrices[addon] == nil {
                panic("This addon is not available. addon : ".concat(addon))
            }
            let addonPrice = network.addonPrices[addon]!

            let lease = self.borrow(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            if lease.addons.containsKey(addon) {
                panic("You already have this addon : ".concat(addon))
            }

            lease.addAddon(addon)

            //put something in your storage
            emit AddonActivated(name: name, addon: addon)
        }

        pub fun getAddon(name: String) : [String] {
            let lease = self.borrow(name)
            if !lease.validate() {
                return []
            }
            return lease.getAddon()
        }

        pub fun checkAddon(name:String, addon: String) : Bool {
            let lease = self.borrow(name)
            if !lease.validate() {
                return false
            }
            return lease.checkAddon(addon: addon)
        }

        pub fun getLeaseUUID(_ name: String) : UInt64 {
            return self.borrow(name).uuid
        }

        pub fun getLease(_ name: String) : LeaseInformation? {
            if !self.leases.containsKey(name) {
                return nil
            }
            let token=self.borrow(name)

            if !token.validate() {
                return nil
            }


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

            return LeaseInformation(name:  name, status: token.getLeaseStatus(), validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLockedUntil(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy, auctionStartPrice: token.auctionStartPrice, auctionReservePrice: token.auctionReservePrice, extensionOnLateBid: token.auctionExtensionOnLateBid, address: token.owner!.address, addons: token.addons.keys)
        }

        access(account) fun getNames() : [String] {
            return self.leases.keys
        }

        access(account) fun containsName(_ name: String) : Bool {
            return self.leases.containsKey(name)
        }

        pub fun getLeaseInformation() : [LeaseInformation]  {
            var info: [LeaseInformation]=[]
            for name in self.leases.keys {
                // if !FIND.validateFindName(name) {
                // 	continue
                // }
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

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            let duration=lease.auctionDuration
            let extensionOnLateBid=lease.auctionExtensionOnLateBid
            if lease.offerCallback == nil {
                panic("cannot start an auction on a name without a bid, set salePrice")
            }

            let callback=lease.offerCallback!
            let offer=callback.borrow()!
            offer.setBidType(name: name, type: "auction")



            let bidder= callback.address
            let bidderProfile= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow() ?? panic("Bidder unlinked the profile capability. bidder address : ".concat(bidder.toString()))
            let bidderName= bidderProfile.getName()
            let bidderAvatar= bidderProfile.getAvatar()
            let owner=lease.owner!.address
            let ownerName=lease.name

            let endsAt=timestamp + duration
            emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:FIND.reverseLookup(owner), amount: offer.getBalance(name), auctionReservePrice: lease.auctionReservePrice!, status: "active_ongoing", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar:bidderAvatar, endsAt: endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)

            let oldAuction <- self.auctions[name] <- create Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: extensionOnLateBid, latestBidCallback: callback, name: name)
            lease.setCallback(nil)

            if lease.offerCallback == nil {
                Debug.log("offer callback is empty")
            }else {
                Debug.log("offer callback is NOT empty")
            }

            destroy oldAuction
        }

        access(contract) fun cancelUserBid(_ name: String) {

            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            if self.auctions.containsKey(name) {
                panic("Cannot cancel a bid that is in an auction=".concat(name))
            }

            let lease= self.borrow(name)

            if let callback = lease.offerCallback {

                let bidder= callback.address
                let bidderProfile= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
                let bidderName=bidderProfile?.getName()
                let bidderAvatar=bidderProfile?.getAvatar()
                let owner=lease.owner!.address
                let ownerName=lease.name
                var amount : UFix64 = 0.0
                if callback.check() {
                    amount = callback.borrow()!.getBalance(name)
                }
                emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: amount, status: "cancel_rejected", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar: bidderAvatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
            }

            lease.setCallback(nil)
        }

        access(contract) fun increaseBid(_ name: String, balance: UFix64) {
            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let lease = self.borrow(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            let timestamp=Clock.time()

            if balance < lease.auctionMinBidIncrement {
                panic("Increment should be greater than ".concat(lease.auctionMinBidIncrement.toString()))
            }
            if self.auctions.containsKey(name) {
                let auction = self.borrowAuction(name)
                if auction.endsAt < timestamp {
                    panic("Auction has ended")
                }
                auction.addBid(callback:auction.latestBidCallback, timestamp:timestamp, lease: lease)
                return
            }


            let bidder= lease.offerCallback!.address
            let bidderProfile= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow() ?? panic("Create a profile before you make a bid")
            let bidderName= bidderProfile.getName()
            let bidderAvatar= bidderProfile.getAvatar()
            let owner=lease.owner!.address
            let ownerName=lease.name

            let balance=lease.offerCallback!.borrow()?.getBalance(name) ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(bidder.toString()))
            Debug.log("Offer is at ".concat(balance.toString()))
            if lease.salePrice == nil  && lease.auctionStartPrice == nil{

                emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "active_offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar: bidderAvatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
                return
            }


            if lease.salePrice != nil && lease.salePrice != nil && balance >= lease.salePrice! {
                self.fulfill(name)
            } else if lease.auctionStartPrice != nil && balance >= lease.auctionStartPrice! {
                self.startAuction(name)
            } else {
                emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "active_offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName,  buyerAvatar: bidderAvatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
            }

        }

        access(contract) fun registerBid(name: String, callback: Capability<&BidCollection{BidCollectionPublic}>) {

            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let timestamp=Clock.time()
            let lease = self.borrow(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            if self.auctions.containsKey(name) {
                let auction = self.borrowAuction(name)

                if auction.latestBidCallback.address == callback.address {
                    panic("You already have the latest bid on this item, use the incraseBid transaction")
                }
                if auction.endsAt < timestamp {
                    panic("Auction has ended")
                }
                auction.addBid(callback:callback, timestamp:timestamp, lease: lease)
                return
            }

            let balance=callback.borrow()?.getBalance(name) ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(callback.address.toString()))
            var previousBuyer:Address?=nil
            if let cb= lease.offerCallback {
                if cb.address == callback.address {
                    panic("You already have the latest bid on this item, use the incraseBid transaction")
                }
                let cbRef = cb.borrow() ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(cb.address.toString()))
                let currentBalance=cbRef.getBalance(name)

                Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
                if currentBalance >= balance {
                    panic("There is already a higher bid on this lease. Current bid is : ".concat(currentBalance.toString()).concat(" New bid is at : ").concat(balance.toString()))
                }
                previousBuyer=cb.address
                cbRef.cancel(name)
            }

            lease.setCallback(callback)



            let bidder= callback.address
            let profile=getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
            if profile == nil {
                panic("Create a profile before you make a bid")
            }
            let bidderName= profile!.getName()
            let bidderAvatar= profile!.getAvatar()
            let owner=lease.owner!.address
            let ownerName=lease.name

            var previousBuyerName:String?=nil
            if let pb=previousBuyer {
                previousBuyerName=FIND.reverseLookup(pb)
            }
            Debug.log("Balance of lease is at ".concat(balance.toString()))
            if lease.salePrice == nil && lease.auctionStartPrice == nil {
                Debug.log("Sale price not set")
                emit DirectOffer(name: name, uuid:lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "active_offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName,  buyerAvatar: bidderAvatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)
                return
            }

            if lease.salePrice != nil && balance >= lease.salePrice! {
                Debug.log("Direct sale!")
                self.fulfill(name)
            }	 else if lease.auctionStartPrice != nil && balance >= lease.auctionStartPrice! {
                self.startAuction(name)
            } else {
                emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "active_offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName,  buyerAvatar: bidderAvatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)
            }
        }

        //cancel will cancel and auction or reject a bid if no auction has started
        pub fun cancel(_ name: String) {

            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let lease = self.borrow(name)
            //if we have a callback there is no auction and it is a blind bid
            if let cb= lease.offerCallback {

                let bidder= cb.address
                let bidderProfile= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
                let bidderName= bidderProfile?.getName()
                let bidderAvatar= bidderProfile?.getAvatar()
                let owner=lease.owner!.address
                let ownerName=lease.name
                Debug.log("we have a blind bid so we cancel that")
                let cbRef = cb.borrow() ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(cb.address.toString()))
                emit DirectOffer(name: name, uuid:lease.uuid, seller: owner, sellerName: ownerName, amount: cbRef.getBalance(name), status: "rejected", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar: bidderAvatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)

                cbRef.cancel(name)
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
                    panic("Cannot cancel finished auction, fulfill it instead")
                }

                let bidder= auction.latestBidCallback.address
                let bidderProfile= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
                let bidderName= bidderProfile?.getName()
                let bidderAvatar= bidderProfile?.getAvatar()
                let owner=lease.owner!.address
                let ownerName=lease.name


                let leaseInfo = self.getLease(name)!

                if auctionEnded {
                    emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:ownerName, amount: balance, auctionReservePrice: lease.auctionReservePrice!, status: "cancel_reserved_not_met", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar: bidderAvatar, endsAt: auction.endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
                } else {
                    emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:ownerName, amount: balance, auctionReservePrice: lease.auctionReservePrice!, status: "cancel_listing", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar: bidderAvatar, endsAt: auction.endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
                }
                let cbRef = auction.latestBidCallback.borrow() ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(bidder.toString()))
                cbRef.cancel(name)
                destroy <- self.auctions.remove(key: name)!
                return
            }
            let owner=lease.owner!.address
            let ownerName=lease.name
            emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:ownerName, amount: 0.0, auctionReservePrice: lease.auctionReservePrice!, status: "cancel_listing", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, buyerAvatar: nil, endsAt: nil, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)

        }

        /// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
        pub fun fulfillAuction(_ name: String) {
            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            if !self.auctions.containsKey(name) {
                panic("Cannot fulfill sale that is not an auction=".concat(name))
            }

            return self.fulfill(name)
        }

        pub fun fulfill(_ name: String) {
            if !self.leases.containsKey(name) {
                panic( "Invalid name=".concat(name))
            }

            let lease = self.borrow(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            if lease.getLeaseStatus() == LeaseStatus.FREE {
                panic("cannot fulfill sale name is now free")
            }

            let oldProfile=lease.getProfile()!

            if let cb= lease.offerCallback {
                let offer= cb.borrow()!
                let newProfile= getAccount(cb.address).getCapability<&{Profile.Public}>(Profile.publicPath)
                let avatar= newProfile.borrow()?.getAvatar() ?? panic("Create a profile before you fulfill a bid")
                let soldFor=offer.getBalance(name)

                //move the token to the new profile
                lease.move(profile: newProfile)
                if lease.salePrice == nil || lease.salePrice != soldFor {
                    emit DirectOffer(name: name, uuid: lease.uuid, seller: lease.owner!.address, sellerName: FIND.reverseLookup(lease.owner!.address), amount: soldFor, status: "sold", vaultType:Type<@FUSD.Vault>().identifier, buyer:newProfile.address, buyerName:FIND.reverseLookup(newProfile.address), buyerAvatar: avatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
                } else {
                    emit Sale(name: name, uuid: lease.uuid, seller: lease.owner!.address, sellerName: FIND.reverseLookup(lease.owner!.address), amount: soldFor, status: "sold", vaultType:Type<@FUSD.Vault>().identifier, buyer:newProfile.address, buyerName:FIND.reverseLookup(newProfile.address), buyerAvatar: avatar, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
                }

                let token <- self.leases.remove(key: name)!
                let vault <- offer.fulfillLease(<- token)
                if self.networkCut != 0.0 {
                    let cutAmount= soldFor * self.networkCut
                    let networkWallet = self.networkWallet.borrow() ?? panic("The network wallet is not set up properly. Wallet address : ".concat(self.networkWallet.address.toString()))
                    networkWallet.deposit(from: <- vault.withdraw(amount: cutAmount))
                    if lease.salePrice == nil || lease.salePrice != soldFor {
                        emit RoyaltyPaid(name: name, uuid: lease.uuid, address: self.networkWallet.address, findName:FIND.reverseLookup(self.networkWallet.address), royaltyName:"Network", amount: cutAmount, vaultType:vault.getType().identifier, saleType: "DirectOffer")
                    } else {
                        emit RoyaltyPaid(name: name, uuid: lease.uuid, address: self.networkWallet.address, findName:FIND.reverseLookup(self.networkWallet.address), royaltyName:"Network", amount: cutAmount, vaultType:vault.getType().identifier, saleType: "Sale")
                    }
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
            let newProfile= getAccount(auctionRef.latestBidCallback.address).getCapability<&{Profile.Public}>(Profile.publicPath)
            let avatar= newProfile.borrow()?.getAvatar() ?? panic("Create a profile before you fulfill a bid")



            //move the token to the new profile
            lease.move(profile: newProfile)
            emit EnglishAuction(name: name, uuid:lease.uuid, seller: lease.owner!.address, sellerName:FIND.reverseLookup(lease.owner!.address), amount: soldFor, auctionReservePrice: lease.auctionReservePrice!, status: "sold", vaultType:Type<@FUSD.Vault>().identifier, buyer:newProfile.address, buyerName:FIND.reverseLookup(newProfile.address), buyerAvatar: avatar, endsAt: self.borrowAuction(name).endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
            let auction <- self.auctions.remove(key: name)!

            let token <- self.leases.remove(key: name)!

            let cbRef = auction.latestBidCallback.borrow() ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(auction.latestBidCallback.address.toString()))

            let vault <- cbRef.fulfillLease(<- token)
            if self.networkCut != 0.0 {
                let cutAmount= soldFor * self.networkCut
                let networkWallet = self.networkWallet.borrow() ?? panic("The network wallet is not set up properly. Wallet address : ".concat(self.networkWallet.address.toString()))
                networkWallet.deposit(from: <- vault.withdraw(amount: cutAmount))
                emit RoyaltyPaid(name: name, uuid: lease.uuid, address: self.networkWallet.address, findName:FIND.reverseLookup(self.networkWallet.address), royaltyName:"Network", amount: cutAmount, vaultType:vault.getType().identifier, saleType: "EnglishAuction")
            }

            //why not use FIND to send money :P
            oldProfile.deposit(from: <- vault)
            destroy auction

        }

        pub fun listForAuction(name :String, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64) {

            if !self.leases.containsKey(name) {
                panic("Cannot list name for sale that is not registered to you name=".concat(name))
            }

            let tokenRef = self.borrow(name)

            if !tokenRef.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            //if we have a callback there is no auction and it is a blind bid
            if let cb= tokenRef.offerCallback {
                let bidder= cb.address
                let bidderProfile= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
                let bidderName= bidderProfile?.getName()
                let bidderAvatar= bidderProfile?.getAvatar()
                let owner=tokenRef.owner!.address
                let ownerName=tokenRef.name
                Debug.log("we have a blind bid so we cancel that")
                let cbRef = cb.borrow() ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(bidder.toString()))
                emit DirectOffer(name: name, uuid:tokenRef.uuid, seller: owner, sellerName: ownerName, amount: cbRef.getBalance(name), status: "rejected", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, buyerAvatar: bidderAvatar, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
                cbRef.cancel(name)
                tokenRef.setCallback(nil)
            }

            tokenRef.setStartAuctionPrice(auctionStartPrice)
            tokenRef.setReservePrice(auctionReservePrice)
            tokenRef.setAuctionDuration(auctionDuration)
            tokenRef.setExtentionOnLateBid(auctionExtensionOnLateBid)
            emit EnglishAuction(name: name, uuid: tokenRef.uuid, seller: self.owner!.address, sellerName:FIND.reverseLookup(self.owner!.address), amount: tokenRef.auctionStartPrice!, auctionReservePrice: tokenRef.auctionReservePrice!, status: "active_listed", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, buyerAvatar: nil, endsAt: nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil(), previousBuyer:nil, previousBuyerName:nil)
        }

        pub fun listForSale(name :String, directSellPrice:UFix64) {

            if !self.leases.containsKey(name) {
                panic("Cannot list name for sale that is not registered to you name=".concat(name))
            }

            let tokenRef = self.borrow(name)

            if !tokenRef.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            tokenRef.setSalePrice(directSellPrice)
            emit Sale(name: name, uuid: tokenRef.uuid, seller: self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: tokenRef.salePrice!, status: "active_listed", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, buyerAvatar: nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
        }


        pub fun delistAuction(_ name: String) {

            if !self.leases.containsKey(name) {
                panic("Cannot delist name for sale that is not registered to you name=".concat(name))
            }

            let tokenRef = self.borrow(name)

            tokenRef.setStartAuctionPrice(nil)
            tokenRef.setReservePrice(nil)
        }


        pub fun delistSale(_ name: String) {
            if !self.leases.containsKey(name) {
                panic("Cannot list name for sale that is not registered to you name=".concat(name))
            }

            let tokenRef = self.borrow(name)
            emit Sale(name: name, uuid:tokenRef.uuid, seller: self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: tokenRef.salePrice!, status: "cancel", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, buyerAvatar: nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
            tokenRef.setSalePrice(nil)
        }

        //note that when moving a name
        pub fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&LeaseCollection{LeaseCollectionPublic}>) {

            let lease = self.borrow(name)
            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            let token <- self.leases.remove(key:  name) ?? panic("missing NFT")
            emit Moved(name: name, previousOwner:self.owner!.address, newOwner: profile.address, validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLockedUntil())
            token.move(profile: profile)
            let walletRef = to.borrow() ?? panic("The receiver capability is not valid. wallet address : ".concat(to.address.toString()))
            walletRef.deposit(token: <- token)

        }

        //depoit a lease token into the lease collection, not available from the outside
        access(contract) fun deposit(token: @FIND.Lease) {
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.leases[token.name] <- token

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getLeases(): [String] {
            var list : [String] = []
            for key in  self.leases.keys {
                let lease = self.borrow(key)
                if !lease.validate() {
                    continue
                }
                list.append(key)
            }
            return list
        }

        pub fun getInvalidatedLeases(): [String] {
            var list : [String] = []
            for key in  self.leases.keys {
                let lease = self.borrow(key)
                if lease.validate() {
                    continue
                }
                list.append(key)
            }
            return list
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrow(_ name: String): &FIND.Lease {
            return (&self.leases[name] as &FIND.Lease?)!
        }

        //borrow the auction
        pub fun borrowAuction(_ name: String): &FIND.Auction {
            return (&self.auctions[name] as &FIND.Auction?)!
        }


        //This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
        pub fun registerUSDC(name: String, vault: @FiatToken.Vault){
            let profileCap = self.owner!.getCapability<&{Profile.Public}>(Profile.publicPath)
            let leases= self.owner!.getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

            let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            network.registerUSDC(name:name, vault: <- vault, profile: profileCap, leases: leases)
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

        //This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
        pub fun registerDapper(merchAccount: Address, name: String, vault: @DapperUtilityCoin.Vault){
            let profileCap = self.owner!.getCapability<&{Profile.Public}>(Profile.publicPath)
            let leases= self.owner!.getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

            let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            network.registerDapper(merchAccount: merchAccount, name:name, vault: <- vault, profile: profileCap, leases: leases)
        }

        pub fun cleanUpInvalidatedLease(_ name: String) {
            let lease = self.borrow(name)
            if lease.validate() {
                panic("This is a valid lease. You cannot clean this up. Lease : ".concat(name))
            }
            destroy <- self.leases.remove(key: name)!
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
        // This address is wrong for some account and can never be refered
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
    pub resource Network {
        access(contract) var wallet: Capability<&{FungibleToken.Receiver}>
        access(contract) let leasePeriod: UFix64
        access(contract) let lockPeriod: UFix64
        access(contract) var defaultPrice: UFix64
        access(contract) let secondaryCut: UFix64
        access(contract) var pricesChangedAt: UFix64
        access(contract) var lengthPrices: {Int: UFix64}
        access(contract) var addonPrices: {String: UFix64}

        access(contract) var publicEnabled: Bool

        //map from name to lease for that name
        access(contract) let profiles: { String: NetworkLease}

        init(leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>, publicEnabled:Bool) {
            self.leasePeriod=leasePeriod
            self.addonPrices = {
                "forge" : 50.0 ,    // will have to run transactions on this when update on mainnet.
                "premiumForge" : 1000.0
            }
            self.lockPeriod=lockPeriod
            self.secondaryCut=secondaryCut
            self.defaultPrice=defaultPrice
            self.lengthPrices=lengthPrices
            self.profiles={}
            self.wallet=wallet
            self.pricesChangedAt= Clock.time()
            self.publicEnabled=publicEnabled
        }

        pub fun getLease(_ name: String) : NetworkLease? {
            return self.profiles[name]
        }

        pub fun setAddonPrice(name:String, price:UFix64) {
            self.addonPrices[name]=price
        }

        pub fun setPrice(default: UFix64, additionalPrices: {Int: UFix64}) {
            self.defaultPrice=default
            self.lengthPrices=additionalPrices
        }


        //this method is only called from a lease, and only the owner has that capability
        access(contract) fun renew(name: String, vault: @FUSD.Vault) {
            if let lease= self.profiles[name] {
                let cost= self.calculateCost(name)
                if vault.balance != cost {
                    panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
                }
                let walletRef = self.wallet.borrow() ?? panic("The receiver capability is invalid. Wallet address : ".concat(self.wallet.address.toString()))
                walletRef.deposit(from: <- vault)
                self.internal_renew(name: name)
                return
            }
            panic("Could not find profile with name=".concat(name))
        }

        access(contract) fun renewDapper(merchAccount: Address, name: String, vault: @DapperUtilityCoin.Vault) {

            FIND.checkMerchantAddress(merchAccount)

            if let lease= self.profiles[name] {
                let cost= self.calculateCost(name)
                if vault.balance != cost {
                    panic("Vault did not contain ".concat(cost.toString()).concat(" amount of Dapper Credit"))
                }
                let wallet = getAccount(merchAccount).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)

                let walletRef = wallet.borrow() ?? panic("Cannot borrow reference to Dapper Merch Account receiver. Address : ".concat(merchAccount.toString()))
                walletRef.deposit(from: <- vault)
                self.internal_renew(name: name)
                return
            }
            panic("Could not find profile with name=".concat(name))
        }

        access(account) fun internal_renew(name: String) {
            if let lease= self.profiles[name] {

                var newTime=0.0
                if lease.status() == LeaseStatus.TAKEN {
                    //the name is taken but not expired so we extend the total period of the lease
                    lease.setValidUntil(lease.validUntil + self.leasePeriod)
                } else {
                    lease.setValidUntil(Clock.time() + self.leasePeriod)
                }
                lease.setLockedUntil(lease.validUntil+ self.lockPeriod)


                emit Register(name: name, owner:lease.profile.address, validUntil: lease.validUntil, lockedUntil: lease.lockedUntil)
                self.profiles[name] =  lease
                return
            }
            panic("Could not find profile with name=".concat(name))
        }

        access(account) fun getLeaseExpireTime(_ name: String) : UFix64{
            if let lease= self.profiles[name] {
                return lease.validUntil
            }
            panic("Could not find profile with name=".concat(name))
        }

        access(account) fun getLeaseLockedUntil(_ name: String) : UFix64{
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
        pub fun registerUSDC(name: String, vault: @FiatToken.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {

            if name.length < 3 {
                panic( "A FIND name has to be minimum 3 letters long")
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

            let address=self.wallet.address
            let account=getAccount(address)
            let usdcCap = account.getCapability<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
            let usdcReceiver = usdcCap.borrow() ?? panic("cound not find usdc vault receiver for address".concat(self.wallet.address.toString()))
            usdcReceiver.deposit(from: <- vault)

            self.internal_register(name: name, profile: profile, leases: leases)
        }
        //everybody can call register, normally done through the convenience method in the contract
        pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {

            if name.length < 3 {
                panic( "A FIND name has to be minimum 3 letters long")
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

            self.internal_register(name: name, profile: profile, leases: leases)
        }

        //everybody can call register, normally done through the convenience method in the contract
        pub fun registerDapper(merchAccount: Address, name: String, vault: @DapperUtilityCoin.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
            FIND.checkMerchantAddress(merchAccount)

            if name.length < 3 {
                panic( "A FIND name has to be minimum 3 letters long")
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
                panic("Vault did not contain ".concat(cost.toString()).concat(" amount of Dapper Credit"))
            }

            let wallet = getAccount(merchAccount).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)

            let walletRef = wallet.borrow() ?? panic("Cannot borrow reference to Dapper Merch Account receiver. Address : ".concat(merchAccount.toString()))
            walletRef.deposit(from: <- vault)
            self.internal_register(name: name, profile: profile, leases: leases)
        }

        access(account) fun internal_register(name: String, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {

            if name.length < 3 {
                panic("A FIND name has to be minimum 3 letters long")
            }
            if !leases.check() {
                panic("The lease collection capability is invalid.")
            }
            if !profile.check() {
                panic("The profile capability is invalid")
            }

            let nameStatus=self.readStatus(name)
            if nameStatus.status == LeaseStatus.TAKEN {
                panic("Name already registered")
            }

            //if we have a locked profile that is not owned by the same identity then panic
            if nameStatus.status == LeaseStatus.LOCKED {
                panic("Name is locked")
            }

            let lease= NetworkLease(
                validUntil:Clock.time() + self.leasePeriod,
                lockedUntil: Clock.time() + self.leasePeriod+ self.lockPeriod,
                profile: profile,
                name: name
            )

            emit Register(name: name, owner:profile.address, validUntil: lease.validUntil, lockedUntil: lease.lockedUntil)
            emit Name(name: name)

            let profileRef = profile.borrow()!

            if profileRef.getFindName() == "" {
                profileRef.setFindName(name)
            }

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

        pub fun getSecondaryCut() : UFix64 {
            return self.secondaryCut
        }

        pub fun getWallet() : Capability<&{FungibleToken.Receiver}> {
            return self.wallet
        }
    }

    pub fun getFindNetworkAddress() : Address {
        return self.account.address
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
        access(contract) fun fulfillLease(_ token: @FIND.Lease) : @FungibleToken.Vault
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
        //if purchase if fulfilled then we deposit money back into vault we get passed along and token into your own leases collection
        access(contract) fun fulfillLease(_ token: @FIND.Lease) : @FungibleToken.Vault{
            if !self.leases.check() {
                panic("The lease collection capability is invalid.")
            }
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

        //called from lease when things are canceled
        //if the bid is canceled from seller then we move the vault tokens back into your vault
        access(contract) fun cancel(_ name: String) {
            if !self.receiver.check() {
                panic("This user does not have receiving vault set up. User: ".concat(self.owner!.address.toString()))
            }
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

            if self.owner!.address == nameStatus.owner {
                panic("cannot bid on your own name")
            }

            let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

            let bid <- create Bid(from: from, name:name, vault: <- vault)
            let leaseCollection= from.borrow() ?? panic("Could not borrow lease bid from owner of name=".concat(name))


            let callbackCapability =self.owner!.getCapability<&BidCollection{BidCollectionPublic}>(FIND.BidPublicPath)
            let oldToken <- self.bids[bid.name] <- bid
            //send info to leaseCollection
            destroy oldToken
            leaseCollection.registerBid(name: name, callback: callbackCapability)
        }


        //increase a bid, will not work if the auction has already started
        pub fun increaseBid(name: String, vault: @FungibleToken.Vault) {
            let nameStatus=FIND.status(name)
            if nameStatus.status ==  LeaseStatus.FREE {
                panic("cannot increaseBid on name that is free")
            }
            let seller=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
            let balance = vault.balance
            let bid =self.borrowBid(name)
            bid.setBidAt(Clock.time())
            bid.vault.deposit(from: <- vault)

            let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
            if !from.check() {
                panic("The seller unlinked the lease collection capability. seller address : ".concat(nameStatus.owner!.toString()))
            }
            from.borrow()!.increaseBid(name, balance: balance)
        }

        //cancel a bid, will panic if called after auction has started
        pub fun cancelBid(_ name: String) {

            let nameStatus=FIND.status(name)
            if nameStatus.status == LeaseStatus.FREE {
                self.cancel(name)
                return
            }
            let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
            if !from.check() {
                panic("The seller unlinked the lease collection capability. seller address : ".concat(nameStatus.owner!.toString()))
            }
            from.borrow()!.cancelUserBid(name)
            self.cancel(name)
        }

        pub fun borrowBid(_ name: String): &Bid {
            return (&self.bids[name] as &Bid?)!
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

    pub fun validateFindName(_ value: String) : Bool {
        if value.length < 3 || value.length > 16 {
            return false
        }
        if !FIND.validateAlphanumericLowerDash(value) {
            return false
        }

        if value.length==16 && FIND.validateHex(value) {
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

    pub fun trimFindSuffix(_ name: String) : String {
        return FindUtils.trimSuffix(name, suffix: ".find")
    }

    access(contract) fun checkMerchantAddress(_ merchAccount: Address) {
        // If only find can sign the trxns and call this function, then we do not have to check the address passed in.
        // Otherwise, would it be wiser if we hard code the address here?

        if FIND.account.address == 0x097bafa4e0b48eef {
            // This is for mainnet
            if merchAccount != 0x55459409d30274ee {
                panic("Merch Account address does not match with expected")
            }
        } else if FIND.account.address == 0x35717efbbce11c74 {
            // This is for testnet
            if merchAccount != 0x4748780c8bf65e19{
                panic("Merch Account address does not match with expected")
            }
        } else {
            // otherwise falls into emulator and user dapper
            if merchAccount != 0x01cf0e2f2f715450{
                panic("Merch Account address does not match with expected ".concat(merchAccount.toString()))
            }
        }
    }

    access(account) fun getMerchantAddress() : Address {
        // If only find can sign the trxns and call this function, then we do not have to check the address passed in.
        // Otherwise, would it be wiser if we hard code the address here?

        if FIND.account.address == 0x097bafa4e0b48eef {
            // This is for mainnet
            return 0x55459409d30274ee
        } else if FIND.account.address == 0x35717efbbce11c74 {
            // This is for testnet
            return 0x4748780c8bf65e19
        } else {
            // otherwise falls into emulator and user dapper
            return 0x01cf0e2f2f715450
        }
    }

    init() {
        self.NetworkPrivatePath= /private/FIND
        self.NetworkStoragePath= /storage/FIND

        self.LeasePublicPath=/public/findLeases
        self.LeaseStoragePath=/storage/findLeases

        self.BidPublicPath=/public/findBids
        self.BidStoragePath=/storage/findBids

        let wallet=self.account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

        // these values are hardcoded here for a reason. Then plan is to throw away the key and not have setters for them so that people can trust the contract to be the same
        let network <-  create Network(
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
