import "FungibleToken"
import "FUSD"
import "FlowToken"
import "DapperUtilityCoin"
import "Profile"
import "Debug"
import "Clock"
import "Sender"
import "ProfileCache"
import "FindUtils"
import "PublicPriceOracle"

/*
///FIND

///Flow Integrated Name Directory - A naming service on flow,

/// Lease a name in the network for as little as 5 USD a year, (4 characters cost 100, 3 cost 500)

Taxonomy:

- name: a textual description minimum 3 chars long that can be leased in FIND
- profile: A Versus profile that represents a person, a name registed in FIND points to a profile
- lease: a resource representing registering a name for a period of 1 year
- leaseCollection: Collection of the leases an account holds
- leaseStatus: FREE|TAKEN|LOCKED, a LOCKED lease can be reopend by the owner. A lease will be locked for 90 days before it is freed
*/
access(all) contract FIND {
    //event when FT is sent
    access(all) event FungibleTokenSent(from:Address, fromName:String?, name:String, toAddress:Address, message:String, tag:String, amount: UFix64, ftType:String)

    /// An event to singla that there is a name in the network
    access(all) event Name(name: String)

    access(all) event AddonActivated(name: String, addon:String)

    ///  Emitted when a name is registred in FIND
    access(all) event Register(name: String, owner: Address, validUntil: UFix64, lockedUntil: UFix64)

    /// Emitted when a name is moved to a new owner
    access(all) event Moved(name: String, previousOwner: Address, newOwner: Address, validUntil: UFix64, lockedUntil: UFix64)

    //store the network itself
    access(all) let NetworkStoragePath: StoragePath

    //store the leases you own
    access(all) let LeaseStoragePath: StoragePath
    access(all) let LeasePublicPath: PublicPath

    access(all) fun getLeases() : &[NetworkLease] {
        if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.profiles.values
        }
        panic("Network is not set up")
    }

    //////////////////////////////////////////
    // ORACLE
    //////////////////////////////////////////
    // Get the latest FLOW/USD price
    //This uses the FLOW/USD increment.fi oracle
    access(all) fun getLatestPrice(): UFix64 {
        let lastResult = PublicPriceOracle.getLatestPrice(oracleAddr: self.getFlowUSDOracleAddress())
        let lastBlockNum = PublicPriceOracle.getLatestBlockHeight(oracleAddr: self.getFlowUSDOracleAddress())

        // Make sure the price is not expired
        if getCurrentBlock().height - lastBlockNum > 2000 {
            panic("Price is expired")
        }

        return lastResult
    }


    access(all) fun convertFLOWToUSD(_ amount: UFix64): UFix64 {
        return amount * self.getLatestPrice()
    }

    access(all) fun convertUSDToFLOW(_ amount: UFix64): UFix64 {
        return amount / self.getLatestPrice()
    }

    //////////////////////////////////////////
    // HELPER FUNCTIONS
    //////////////////////////////////////////

    //These methods are basically just here for convenience
    //

    access(all) fun calculateCostInFlow(_ name:String) : UFix64 {
        if !FIND.validateFindName(name) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return self.convertUSDToFLOW(network.calculateCost(name))
        } 
        panic("Network is not set up")
    }

    access(all) fun calculateAddonCostInFlow(_ addon: String) : UFix64 {
        let network=FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath)!

        if !network.publicEnabled {
            panic("Public registration is not enabled yet")
        }

        if network.addonPrices[addon] == nil {
            panic("This addon is not available. addon : ".concat(addon))
        }
        var addonPrice = network.addonPrices[addon]!
        let cost= FIND.convertUSDToFLOW(addonPrice)
        return cost
    }

    /// Calculate the cost of an name
    /// @param _ the name to calculate the cost for
    access(all) fun calculateCost(_ name:String) : UFix64 {
        if !FIND.validateFindName(name) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.calculateCost(name)
        }
        panic("Network is not set up")
    }

    access(all) fun resolve(_ input:String) : Address? {

        let trimmedInput = FIND.trimFindSuffix(input)

        if FIND.validateFindName(trimmedInput) {
            if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
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
    access(all) fun lookupAddress(_ name:String): Address? {

        let trimmedName = FIND.trimFindSuffix(name)

        if !FIND.validateFindName(trimmedName) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.lookup(trimmedName)?.owner?.address
        }
        return nil
    }

    /// Lookup the profile registered for a name
    access(all) fun lookup(_ input:String): &{Profile.Public}? {
        if let address = FIND.resolve(input) {
            let account = getAccount(address)
            return account.capabilities.borrow<&{Profile.Public}>(Profile.publicPath) 
        }
        return nil
    }

    access(all) fun reverseLookupFN() : fun(Address) : String? {
        return fun(address:Address): String? {
            return FIND.reverseLookup(address)
        }
    }

    /// lookup if an address has a .find name, if it does pick either the default one or the first registered
    access(all) fun reverseLookup(_ address:Address): String? {

        let leaseNameCache = ProfileCache.getAddressLeaseName(address)

        if leaseNameCache == nil {
            let leaseOptCol = getAccount(address).capabilities.borrow<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

            if leaseOptCol == nil {
                return nil
            }

            let profileFindName= Profile.find(address).getFindName()

            let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) ?? panic("Network is not set up")

            if profileFindName != "" {
                let status = network.readStatus(profileFindName)
                if status.owner != nil && status.owner! == address {
                    if status.status == FIND.LeaseStatus.TAKEN {
                        ProfileCache.setAddressLeaseNameCache(address: address, leaseName: profileFindName, validUntil: network.getLeaseExpireTime(profileFindName))
                        return profileFindName
                    }
                }
            }

            let leaseCol = leaseOptCol!
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
    access(all) fun depositWithTagAndMessage(to:String, message:String, tag: String, vault: @{FungibleToken.Vault}, from: &Sender.Token){

        let fromAddress= from.owner!.address
        let maybeAddress = FIND.resolve(to)
        if maybeAddress  == nil{
            panic("Not a valid .find name or address")
        }
        let address=maybeAddress!

        let account = getAccount(address)
        if let profile = account.capabilities.borrow<&{Profile.Public}>(Profile.publicPath) {
            emit FungibleTokenSent(from: fromAddress, fromName: FIND.reverseLookup(fromAddress), name: to, toAddress: profile.getAddress(), message:message, tag:tag, amount:vault.balance, ftType:vault.getType().identifier)
            profile.deposit(from: <- vault)
            return
        }

        var path = ""
        if vault.getType() == Type<@FlowToken.Vault>() {
            path ="flowTokenReceiver"
        } else {
            panic("Could not find a valid receiver for this vault type")
        }
        if path != "" {
            emit FungibleTokenSent(from: fromAddress, fromName: FIND.reverseLookup(fromAddress), name: "", toAddress: address, message:message, tag:tag, amount:vault.balance, ftType:vault.getType().identifier)
            account.capabilities.borrow<&{FungibleToken.Receiver}>(PublicPath(identifier: path)!)!.deposit(from: <- vault)
            return
        }
        panic("Could not find a valid receiver for this vault type")

    }


    /// Deposit FT to name
    /// @param to: The name to send money too
    /// @param from: The vault to send too
    access(all) fun deposit(to:String, from: @{FungibleToken.Vault}) {
        if !FIND.validateFindName(to) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            let profile=network.lookup(to) ?? panic("could not find name")
            profile.deposit(from: <- from)
            return
        }
        panic("Network is not set up")
    }

    /// Return the status for a given name
    /// @return The Name status of a name
    access(all) fun status(_ name: String): NameStatus {
        if !FIND.validateFindName(name) {
            panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
        }

        if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return network.readStatus(name)
        }
        panic("Network is not set up")
    }


    /// Struct holding information about a lease. Contains both the internal status the owner of the lease and if the state is persisted or not.
    access(all) struct NameStatus{
        access(all) let status: LeaseStatus
        access(all) let owner: Address?

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

    access(all) entitlement LeaseOwner

    /*

    Lease is a resource you get back when you register a lease.
    You can use methods on it to renew the lease or to move to another profile
    */
    access(all) resource Lease {
        access(contract) let name: String
        access(contract) let networkCap: Capability<&Network>
        access(contract) var addons: {String: Bool}

        //These fields are here, but they are not in use anymore
        access(contract) var salePrice: UFix64?
        access(contract) var auctionStartPrice: UFix64?
        access(contract) var auctionReservePrice: UFix64?
        access(contract) var auctionDuration: UFix64
        access(contract) var auctionMinBidIncrement: UFix64
        access(contract) var auctionExtensionOnLateBid: UFix64
        access(contract) var offerCallback: Capability<&BidCollection>?

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

        access(all) fun getName() : String {
            return self.name
        }

        access(all) fun getAddon() : [String] {
            return self.addons.keys
        }

        access(all) fun checkAddon(addon: String) : Bool {
            if !self.addons.containsKey(addon) {
                return false
            }
            return self.addons[addon]!
        }

        access(contract) fun addAddon(_ addon:String) {
            self.addons[addon]=true
        }

        access(LeaseOwner) fun extendLease(_ vault: @FlowToken.Vault) {
            let network= self.networkCap.borrow() ?? panic("The network is not up")
            network.renew(name: self.name, vault:<-  vault)
        }

        access(LeaseOwner) fun extendLeaseDapper(merchAccount: Address, vault: @DapperUtilityCoin.Vault) {
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
                let network = FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) ?? panic("Network is not set up")
                let leaseCol = getAccount(senderAddress).capabilities.borrow<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath) ?? panic("Could not borrow lease collection")

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

        access(all) fun getLeaseExpireTime() : UFix64 {
            let network = self.networkCap.borrow() ?? panic("The network is not up")
            return network.getLeaseExpireTime(self.name)
        }

        access(all) fun getLeaseLockedUntil() : UFix64 {
            let network = self.networkCap.borrow() ?? panic("The network is not up")
            return network.getLeaseLockedUntil(self.name)
        }

        access(all) fun getProfile():&{Profile.Public}? {
            let network = self.networkCap.borrow() ?? panic("The network is not up")
            return network.profile(self.name)
        }

        access(all) fun getLeaseStatus() : LeaseStatus {
            return FIND.status(self.name).status
        }

        access(all) fun validate() : Bool {
            // if network is not there anymore, it is not valid
            if !self.networkCap.check() {
                return false
            }
            let network = self.networkCap.borrow()!
            let lease = network.getLease(self.name)
            // if the network lease is nil, it is definitely not validated
            if lease == nil {
                Debug.log("no lease")
                return false
            }

            // regardless of the status (FREE / LOCKED / TAKEN)
            //TODO: these comments here are wrong... 
            // (because other functions checks that) 
            // if this lease is not the current / latest owner, this lease is not valid anymore
            let registeredOwner = lease!.profile.address
            if registeredOwner == self.owner?.address {
                if lease!.status() == LeaseStatus.FREE {
                    return false
                }
                return true
            }

            return false
        }
    }



    //struct to expose information about leases
    access(all) struct LeaseInformation {
        access(all) let name: String
        access(all) let address: Address
        access(all) let cost: UFix64
        access(all) let status: String
        access(all) let validUntil: UFix64
        access(all) let lockedUntil: UFix64
        access(all) let latestBid: UFix64?
        access(all) let auctionEnds: UFix64?
        access(all) let salePrice: UFix64?
        access(all) let latestBidBy: Address?
        access(all) let currentTime: UFix64
        access(all) let auctionStartPrice: UFix64?
        access(all) let auctionReservePrice: UFix64?
        access(all) let extensionOnLateBid: UFix64?
        access(all) let addons: [String]

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
        access(all) fun getAddons() : [String] {
            return self.addons
        }

    }
    /*
    Since a single account can own more then one name there is a collecition of them
    This collection has build in support for direct sale of a FIND leaseToken. The network owner till take 2.5% cut
    */
    access(all) resource interface LeaseCollectionPublic {
        //fetch all the tokens in the collection
        access(all) fun getLeases(): [String]
        access(all) fun getInvalidatedLeases(): [String]
        //fetch all names that are for sale
        access(all) fun getLeaseInformation() : [LeaseInformation]
        access(all) fun getLease(_ name: String) :LeaseInformation?

        //add a new lease token to the collection, can only be called in this contract
        access(contract) fun deposit(token: @FIND.Lease)

        access(all) fun buyAddon(name:String, addon: String, vault: @FlowToken.Vault)
        access(all) fun buyAddonDapper(merchAccount: Address, name:String, addon:String, vault: @DapperUtilityCoin.Vault)
        access(account) fun adminAddAddon(name:String, addon: String)
        access(all) fun getAddon(name:String) : [String]
        access(all) fun checkAddon(name:String, addon: String) : Bool
        access(account) fun getNames() : [String]
        access(account) fun containsName(_ name: String) : Bool
        access(LeaseOwner) fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&LeaseCollection>)
        access(all) fun getLeaseUUID(_ name: String) : UInt64
    }

    access(all) resource LeaseCollection: LeaseCollectionPublic {
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

        access(all) fun buyAddon(name:String, addon:String, vault: @FlowToken.Vault)  {
            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }
            let cost=FIND.calculateAddonCostInFlow(addon)

            let lease = self.borrowAuth(name)

            if !lease.validate() {
                panic("This is not a valid lease. Lease already expires and some other user registered it. Lease : ".concat(name))
            }

            if lease.addons.containsKey(addon) {
                panic("You already have this addon : ".concat(addon))
            }

            if vault.balance != cost {
                panic("Expect ".concat(cost.toString()).concat(" FLOW for ").concat(addon).concat(" addon"))
            }

            lease.addAddon(addon)

            //put something in your storage
            emit AddonActivated(name: name, addon: addon)
            let networkWallet = self.networkWallet.borrow() ?? panic("The network is not up")
            networkWallet.deposit(from: <- vault)
        }

        access(all) fun buyAddonDapper(merchAccount: Address, name:String, addon:String, vault: @DapperUtilityCoin.Vault)  {
            FIND.checkMerchantAddress(merchAccount)

            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let network=FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            if network.addonPrices[addon] == nil {
                panic("This addon is not available. addon : ".concat(addon))
            }
            let addonPrice = network.addonPrices[addon]!

            let lease = self.borrowAuth(name)

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

            let wallet = getAccount(merchAccount).capabilities.borrow<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver) ?? panic("Cannot borrow reference to Dapper Merch Account receiver. Address : ".concat(merchAccount.toString()))
            wallet.deposit(from: <- vault)
        }

        access(account) fun adminAddAddon(name:String, addon:String)  {
            if !self.leases.containsKey(name) {
                panic("Invalid name=".concat(name))
            }

            let network=FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            if network.addonPrices[addon] == nil {
                panic("This addon is not available. addon : ".concat(addon))
            }
            let addonPrice = network.addonPrices[addon]!

            let lease = self.borrowAuth(name)

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

        access(all) fun getAddon(name: String) : [String] {
            let lease = self.borrowAuth(name)
            if !lease.validate() {
                return []
            }
            return lease.getAddon()
        }

        access(all) fun checkAddon(name:String, addon: String) : Bool {
            let lease = self.borrowAuth(name)
            if !lease.validate() {
                return false
            }
            return lease.checkAddon(addon: addon)
        }

        access(all) fun getLeaseUUID(_ name: String) : UInt64 {
            return self.borrowAuth(name).uuid
        }

        access(all) fun getLease(_ name: String) : LeaseInformation? {
            if !self.leases.containsKey(name) {
                return nil
            }
            let token=self.borrowAuth(name)

            if !token.validate() {
                return nil
            }


            var latestBid: UFix64? = nil
            var auctionEnds: UFix64?= nil
            var latestBidBy: Address?=nil

            return LeaseInformation(name:  name, status: token.getLeaseStatus(), validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLockedUntil(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy, auctionStartPrice: token.auctionStartPrice, auctionReservePrice: token.auctionReservePrice, extensionOnLateBid: token.auctionExtensionOnLateBid, address: token.owner!.address, addons: token.getAddon())
        }

        access(account) fun getNames() : [String] {
            return self.leases.keys
        }

        access(account) fun containsName(_ name: String) : Bool {
            return self.leases.containsKey(name)
        }

        access(all) fun getLeaseInformation() : [LeaseInformation]  {
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


        access(LeaseOwner) fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&LeaseCollection>) {

            let lease = self.borrowAuth(name)
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
        access(all) fun getLeases(): [String] {
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

        access(all) fun getInvalidatedLeases(): [String] {
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
        access(all) fun borrow(_ name: String): &FIND.Lease {
            return (&self.leases[name])!
        }

        access(LeaseOwner) fun borrowAuth(_ name: String): auth(LeaseOwner) &FIND.Lease {
            return (&self.leases[name])!
        }

        //borrow the auction
        access(all) fun borrowAuction(_ name: String): &FIND.Auction {
            return (&self.auctions[name])!
        }


        //This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
        access(LeaseOwner) fun register(name: String, vault: @FlowToken.Vault){
            let profileCap = self.owner!.capabilities.get<&{Profile.Public}>(Profile.publicPath)
            let leases= self.owner!.capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

            let network=FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            network.register(name:name, vault: <- vault, profile: profileCap, leases: leases)
        }

        //This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
        access(LeaseOwner) fun registerDapper(merchAccount: Address, name: String, vault: @DapperUtilityCoin.Vault){
            let profileCap = self.owner!.capabilities.get<&{Profile.Public}>(Profile.publicPath)
            let leases= self.owner!.capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

            let network=FIND.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath)!

            if !network.publicEnabled {
                panic("Public registration is not enabled yet")
            }

            network.registerDapper(merchAccount: merchAccount, name:name, vault: <- vault, profile: profileCap, leases: leases)
        }

        access(LeaseOwner) fun cleanUpInvalidatedLease(_ name: String) {
            let lease = self.borrowAuth(name)
            if lease.validate() {
                panic("This is a valid lease. You cannot clean this up. Lease : ".concat(name))
            }
            destroy <- self.leases.remove(key: name)!
        }
    }

    //Create an empty lease collection that store your leases to a name
    access(all) fun createEmptyLeaseCollection(): @FIND.LeaseCollection {
        if let network = self.account.storage.borrow<&Network>(from: FIND.NetworkStoragePath) {
            return <- create LeaseCollection(networkCut:network.secondaryCut, networkWallet: network.wallet)
        }
        panic("Network is not set up")
    }



    /*
    Core network things
    //===================================================================================================================
    */
    //a struct that represents a lease of a name in the network.
    access(all) struct NetworkLease {
        access(all) let registeredTime: UFix64
        access(all) var validUntil: UFix64
        access(all) var lockedUntil: UFix64
        access(all) var profile: Capability<&{Profile.Public}>
        // This address is wrong for some account and can never be refered
        access(all) var address: Address
        access(all) var name: String

        init( validUntil:UFix64, lockedUntil:UFix64, profile: Capability<&{Profile.Public}>, name: String) {
            self.validUntil=validUntil
            self.lockedUntil=lockedUntil
            self.registeredTime=Clock.time()
            self.profile=profile
            self.address= profile.address
            self.name=name
        }

        access(all) fun setValidUntil(_ unit: UFix64) {
            self.validUntil=unit
        }

        access(all) fun setLockedUntil(_ unit: UFix64) {
            self.lockedUntil=unit
        }

        access(all) fun status() : LeaseStatus {
            let time=Clock.time()

            if time >= self.lockedUntil {
                return LeaseStatus.FREE
            }

            if time >= self.validUntil {
                return LeaseStatus.LOCKED
            }
            return 	LeaseStatus.TAKEN
        }

        access(all) fun setProfile (_ profile: Capability<&{Profile.Public}>) {
            self.profile=profile
        }
    }


    /*
    FREE, does not exist in profiles dictionary
    TAKEN, registered with a time that is currentTime + leasePeriod
    LOCKED, after TAKEN.time you will get a new  status and the new time will be

    */

    access(all) enum LeaseStatus: UInt8 {
        access(all) case FREE
        access(all) case TAKEN
        access(all) case LOCKED
    }

    /*
    The main network resource that holds the state of the names in the network
    */
    access(all) resource Network {
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

        access(all) fun getLease(_ name: String) : NetworkLease? {
            return self.profiles[name]
        }

        access(account) fun setAddonPrice(name:String, price:UFix64) {
            self.addonPrices[name]=price
        }

        access(account) fun setPrice(defaultPrice: UFix64, additionalPrices: {Int: UFix64}) {
            self.defaultPrice=defaultPrice
            self.lengthPrices=additionalPrices
        }

        access(contract) fun renew(name: String, vault: @FlowToken.Vault) {
            if let lease= self.profiles[name] {
                let cost= FIND.calculateCostInFlow(name) 
                if vault.balance != cost {
                    panic("Vault did not contain ".concat(cost.toString()).concat(" amount of Flow"))
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
                let walletRef = getAccount(merchAccount).capabilities.borrow<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver) ?? panic("Cannot borrow reference to Dapper Merch Account receiver. Address : ".concat(merchAccount.toString()))
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
                lease.setProfile(profile)
                self.profiles[name] = lease
                return
            }
            panic("Could not find profile with name=".concat(name))
        }

        //everybody can call register, normally done through the convenience method in the contract
        access(all) fun register(name: String, vault: @FlowToken.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&{LeaseCollectionPublic}>) {

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

            let cost= FIND.calculateCostInFlow(name)
            if vault.balance != cost {
                panic("Vault did not contain ".concat(cost.toString()).concat(" amount of Flow"))
            }
            self.wallet.borrow()!.deposit(from: <- vault)

            self.internal_register(name: name, profile: profile, leases: leases)
        }

        //everybody can call register, normally done through the convenience method in the contract
        access(all) fun registerDapper(merchAccount: Address, name: String, vault: @DapperUtilityCoin.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&{LeaseCollectionPublic}>) {
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

            let walletRef = getAccount(merchAccount).capabilities.borrow<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver) ?? panic("Cannot borrow reference to Dapper Merch Account receiver. Address : ".concat(merchAccount.toString()))
            walletRef.deposit(from: <- vault)
            self.internal_register(name: name, profile: profile, leases: leases)
        }

        access(account) fun internal_register(name: String, profile: Capability<&{Profile.Public}>,  leases: Capability<&{LeaseCollectionPublic}>) {

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

            leases.borrow()!.deposit(token: <- create Lease(name: name, networkCap: FIND.account.capabilities.storage.issue<&Network>(FIND.NetworkStoragePath)))

        }

        access(all) fun readStatus(_ name: String): NameStatus {
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
        access(all) fun lookup(_ name: String) : &{Profile.Public}? {
            let nameStatus=self.readStatus(name)
            if nameStatus.status != LeaseStatus.TAKEN {
                return nil
            }

            if let lease=self.profiles[name] {
                return lease.profile.borrow()
            }
            return nil
        }

        access(all) fun calculateCost(_ name: String) : UFix64 {
            if self.lengthPrices[name.length] != nil {
                return self.lengthPrices[name.length]!
            } else {
                return self.defaultPrice
            }
        }

        access(account) fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
            self.wallet=wallet
        }

        access(account) fun setPublicEnabled(_ enabled: Bool) {
            self.publicEnabled=enabled
        }

        access(all) fun getSecondaryCut() : UFix64 {
            return self.secondaryCut
        }

        access(all) fun getWallet() : Capability<&{FungibleToken.Receiver}> {
            return self.wallet
        }
    }

    access(all) fun getFindNetworkAddress() : Address {
        return self.account.address
    }



    access(all) fun validateFindName(_ value: String) : Bool {
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

    access(all) fun validateAlphanumericLowerDash(_ value:String) : Bool {
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

    access(all) fun validateHex(_ value:String) : Bool {
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

    access(all) fun trimFindSuffix(_ name: String) : String {
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
            if merchAccount !=  0x179b6b1cb6755e31 {
                panic("Merch Account address does not match with expected ".concat(merchAccount.toString()))
            }
        }
    }


    access(account) fun getFlowUSDOracleAddress() : Address {
        // If only find can sign the trxns and call this function, then we do not have to check the address passed in.
        // Otherwise, would it be wiser if we hard code the address here?
        if FIND.account.address == 0x097bafa4e0b48eef {
            // This is for mainnet
            return 0xe385412159992e11
        } else if FIND.account.address == 0x35717efbbce11c74 {
            // This is for testnet
            return 0xcbdb5a7b89c3c844
        } else {
            //otherwise on emulator we use same account as FIND
            return self.account.address
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
            return 0x179b6b1cb6755e31
        }
    }

    init() {
        self.NetworkStoragePath= /storage/FIND

        self.LeasePublicPath=/public/findLeases
        self.LeaseStoragePath=/storage/findLeases

        self.BidPublicPath=/public/findBids
        self.BidStoragePath=/storage/findBids

        // Check if wallet is already initialized
        if self.account.storage.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {

            // Unpublished the capabilites
            self.account.capabilities.unpublish(/public/fusdBalance)
            self.account.capabilities.unpublish(/public/fusdReceiver)

            // Initialize Wallet
            let vault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())

            // Save the vault to storage
            self.account.storage.save(<-vault, to: /storage/fusdVault)

            // Create a public capability for the vault
            let vaultCap = self.account.capabilities.storage.issue<&FUSD.Vault>(
                /storage/fusdVault
            )

            let capb = self.account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
            self.account.capabilities.publish(capb, at: /public/fusdBalance)


            // Create a public Capability to the Vault's Receiver functionality
            let receiverCap = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(
                /storage/fusdVault
            )
            self.account.capabilities.publish(receiverCap, at: /public/fusdReceiver)
        }

        // Get
        let wallet=self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)

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
        self.account.storage.save(<-network, to: FIND.NetworkStoragePath)
    }


    //////////////////////////////////////////////////////////////////////
    // DEPRECATED
    //////////////////////////////////////////////////////////////////////


    /* This code is dead, it still needs to be here, but it is not in use anymore */
    access(all) event Sold()
    access(all) event SoldAuction()
    access(all) event DirectOfferRejected()
    access(all) event DirectOfferCanceled()
    access(all) event AuctionStarted()
    access(all) event AuctionCanceled()
    access(all) event AuctionBid()
    access(all) event AuctionCanceledReservePrice()
    access(all) event ForSale() 
    access(all) event ForAuction()

    // Deprecated in testnet
    access(all) event TokensRewarded()
    access(all) event TokensCanNotBeRewarded()

    /// Emitted when a name is explicistly put up for sale
    access(all) event Sale(name: String, uuid:UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, buyerAvatar: String?, validUntil: UFix64, lockedUntil: UFix64)

    /// Emitted when an name is put up for on-demand auction
    access(all) event EnglishAuction(name: String, uuid:UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, buyerAvatar: String?, endsAt: UFix64?, validUntil: UFix64, lockedUntil: UFix64, previousBuyer:Address?, previousBuyerName:String?)

    /// Emitted if a bid occurs at a name that is too low or not for sale
    access(all) event DirectOffer(name: String, uuid:UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, buyerAvatar: String?, validUntil: UFix64, lockedUntil: UFix64, previousBuyer:Address?, previousBuyerName:String?)

    access(all) event RoyaltyPaid(name: String, uuid: UInt64, address: Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, saleType: String)

    //store bids made by a bidder to somebody elses leases
    access(all) let BidPublicPath: PublicPath
    access(all) let BidStoragePath: StoragePath

    /* An Auction for a lease */
    access(all) resource Auction {
        access(contract) var endsAt: UFix64
        access(contract) var startedAt: UFix64
        access(contract) let extendOnLateBid: UFix64
        access(contract) var latestBidCallback: Capability<&BidCollection>
        access(contract) let name: String

        init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&BidCollection>, name: String) {

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

    }


    /*
    ==========================================================================
    Bids are a collection/resource for storing the bids bidder made on leases
    ==========================================================================
    */

    //Struct that is used to return information about bids
    access(all) struct BidInfo{
        access(all) let name: String
        access(all) let type: String
        access(all) let amount: UFix64
        access(all) let timestamp: UFix64
        access(all) let lease: LeaseInformation?

        init(name: String, amount: UFix64, timestamp: UFix64, type: String, lease: LeaseInformation?) {
            self.name=name
            self.amount=amount
            self.timestamp=timestamp
            self.type=type
            self.lease=lease
        }
    }

    access(all) resource Bid {
        access(contract) let from: Capability<&LeaseCollection>
        access(contract) let name: String
        access(contract) var type: String
        access(contract) let vault: @FUSD.Vault
        access(contract) var bidAt: UFix64

        init(from: Capability<&LeaseCollection>, name: String, vault: @FUSD.Vault){
            self.vault <- vault
            self.name=name
            self.from=from
            self.type="blind"
            self.bidAt=Clock.time()
        }
    }

    access(all) resource interface BidCollectionPublic {
    }

    //A collection stored for bidders/buyers
    access(all) resource BidCollection: BidCollectionPublic {

        access(contract) var bids : @{String: Bid}
        access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
        access(contract) let leases: Capability<&LeaseCollection>

        init(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&LeaseCollection>) {
            self.bids <- {}
            self.receiver=receiver
            self.leases=leases
        }

    }

}
