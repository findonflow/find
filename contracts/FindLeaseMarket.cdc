import FungibleToken from "./standard/FungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "./FIND.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindRulesCache from "../contracts/FindRulesCache.cdc"
import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

access(all) contract FindLeaseMarket {

    access(contract) let  saleItemTypes : [Type]
    access(contract) let  saleItemCollectionTypes : [Type]
    access(contract) let  marketBidTypes : [Type]
    access(contract) let  marketBidCollectionTypes : [Type]

    access(all) event RoyaltyPaid(tenant:String, leaseName: String, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, leaseInfo:LeaseInfo)
    access(all) event RoyaltyCouldNotBePaid(tenant:String, leaseName: String, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, leaseInfo:LeaseInfo, residualAddress: Address)
    access(all) event FindBlockRules(tenant: String, ruleName: String, ftTypes:[String], listingTypes:[String], status:String)
    access(all) event TenantAllowRules(tenant: String, ruleName: String, ftTypes:[String], listingTypes:[String], status:String)
    access(all) event FindCutRules(tenant: String, ruleName: String, cut:UFix64, ftTypes:[String], listingTypes:[String], status:String)

    // ========================================

    /* Get Tenant */
    access(all) fun getTenant(_ tenant: Address) : &{FindMarket.TenantPublic} {
        return FindMarket.getTenantCapability(tenant)!.borrow()!
    }



    access(all) fun getSaleItemTypes() : [Type] {
        return self.saleItemTypes
    }

    /* Get SaleItemCollections */
    access(all) fun getSaleItemCollectionTypes() : [Type] {
        return self.saleItemCollectionTypes
    }

    access(all) fun getSaleItemCollectionCapabilities(tenantRef: &{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindLeaseMarket.SaleItemCollectionPublic}>] {
        var caps : [Capability<&{FindLeaseMarket.SaleItemCollectionPublic}>] = []
        for type in self.getSaleItemCollectionTypes() {
            if type != nil {
                let cap = getAccount(address).capabilities.get<&{FindLeaseMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))!
                if cap.check() {
                    caps.append(cap)
                }
            }
        }
        return caps
    }

    access(all) fun getSaleItemCollectionCapability(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindLeaseMarket.SaleItemCollectionPublic}> {
        for type in self.getSaleItemCollectionTypes() {
            if FindMarket.getMarketOptionFromType(type) == marketOption{
                let cap = getAccount(address).capabilities.get<&{FindLeaseMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))!
                return cap
            }
        }
        panic("Cannot find market option : ".concat(marketOption))
    }



    /* Get Sale Reports and Sale Item */
    access(all) fun assertOperationValid(tenant: Address, name: String, marketOption: String) : &{SaleItem} {

        let tenantRef=self.getTenant(tenant)
        let address=FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
        let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let optRef = collectionCap.borrow()
        if optRef == nil {
            panic("Account not properly set up, cannot borrow sale item collection")
        }
        let ref=optRef!
        let item=ref.borrowSaleItem(name)
        if !item.checkPointer() {
            panic("this is a ghost listing")
        }

        return item
    }

    /* Get Sale Reports and Sale Item */
    access(all) fun getSaleInformation(tenant: Address, name: String, marketOption: String, getLeaseInfo: Bool) : FindLeaseMarket.SaleItemInformation? {
        let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
        let tenantRef=self.getTenant(tenant)
        let info = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: name, getGhost: false, getLeaseInfo: getLeaseInfo)
        if info.items.length > 0 {
            return info.items[0]
        }
        return nil
    }

    access(all) fun getSaleItemReport(tenant:Address, address: Address, getLeaseInfo: Bool) : {String : FindLeaseMarket.SaleItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindLeaseMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = FindMarket.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: nil, getGhost: true, getLeaseInfo: getLeaseInfo)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    access(all) fun getSaleItems(tenant:Address, name: String, getLeaseInfo: Bool) : {String : FindLeaseMarket.SaleItemCollectionReport} {
        let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindLeaseMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = FindMarket.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: name, getGhost: true, getLeaseInfo: getLeaseInfo)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    access(all) fun getLeaseListing(tenant:Address, name: String, getLeaseInfo: Bool) : {String : FindLeaseMarket.SaleItemInformation} {
        let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindLeaseMarket.SaleItemInformation} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = FindMarket.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: name, getGhost: true, getLeaseInfo: getLeaseInfo)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport.items[0]
            }
        }
        return report
    }

    access(contract) fun checkSaleInformation(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address, name: String?, getGhost: Bool, getLeaseInfo: Bool) : FindLeaseMarket.SaleItemCollectionReport {
        let ghost: [FindLeaseMarket.GhostListing] =[]
        let info: [FindLeaseMarket.SaleItemInformation] =[]
        let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let optRef = collectionCap.borrow()
        if optRef == nil {
            return FindLeaseMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
        }
        let ref=optRef!

        var listName : [String]= []
        if let leaseName = name{
            if !ref.containsNameSale(leaseName) {
                return FindLeaseMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
            }
            listName=[leaseName]
        } else {
            listName = ref.getNameSales()
        }

        let listingType = ref.getListingType()

        for leaseName in listName {
            //if this id is not present in this Market option then we just skip it
            let item=ref.borrowSaleItem(leaseName)
            if !item.checkPointer() {
                if getGhost {
                    ghost.append(FindLeaseMarket.GhostListing(listingType: listingType, name:leaseName))
                }
                continue
            }
            let stopped=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:false, name:"delist item for sale"), seller: address, buyer: nil)
            var status="active"

            if !stopped.allowed && stopped.message == "Seller banned by Tenant" {
                status="banned"
                info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: false))
                continue
            }

            if !stopped.allowed {
                status="stopped"
                info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: false))
                continue
            }

            let deprecated=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:true, name:"delist item for sale"), seller: address, buyer: nil)

            if !deprecated.allowed {
                status="deprecated"
                info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: getLeaseInfo))
                continue
            }

            if let validTime = item.getValidUntil() {
                if validTime <= Clock.time() {
                    status="ended"
                }
            }
            info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: getLeaseInfo))
        }

        return FindLeaseMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
    }

    /* Get Bid Collections */
    access(all) fun getMarketBidTypes() : [Type] {
        return self.marketBidTypes
    }

    access(all) fun getMarketBidCollectionTypes() : [Type] {
        return self.marketBidCollectionTypes
    }

    access(all) fun getMarketBidCollectionCapabilities(tenantRef: &{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindLeaseMarket.MarketBidCollectionPublic}>] {
        var caps : [Capability<&{FindLeaseMarket.MarketBidCollectionPublic}>] = []
        for type in self.getMarketBidCollectionTypes() {
            let cap = getAccount(address).capabilities.get<&{FindLeaseMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))!
            if cap.check() {
                caps.append(cap)
            }
        }
        return caps
    }

    access(all) fun getMarketBidCollectionCapability(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindLeaseMarket.MarketBidCollectionPublic}> {
        for type in self.getMarketBidCollectionTypes() {
            if FindMarket.getMarketOptionFromType(type) == marketOption{
                let cap = getAccount(address).capabilities.get<&{FindLeaseMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))!
                return cap
            }
        }
        panic("Cannot find market option : ".concat(marketOption))
    }

    access(all) fun getBid(tenant: Address, address: Address, marketOption: String, name:String, getLeaseInfo: Bool) : FindLeaseMarket.BidInfo? {
        let tenantRef=self.getTenant(tenant)
        let bidInfo = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, name: name, getGhost: false, getLeaseInfo: getLeaseInfo)
        if bidInfo.items.length > 0 {
            return bidInfo.items[0]
        }
        return nil
    }

    access(all) fun getBidsReport(tenant:Address, address: Address, getLeaseInfo: Bool) : {String : FindLeaseMarket.BidItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindLeaseMarket.BidItemCollectionReport} = {}
        for type in self.getMarketBidCollectionTypes() {
            let marketOption = FindMarket.getMarketOptionFromType(type)
            let returnedReport = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, name: nil, getGhost: true, getLeaseInfo: getLeaseInfo)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    access(contract) fun checkBidInformation(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address, name: String?, getGhost:Bool, getLeaseInfo: Bool) : FindLeaseMarket.BidItemCollectionReport {
        let ghost: [FindLeaseMarket.GhostListing] =[]
        let info: [FindLeaseMarket.BidInfo] =[]
        let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)

        let optRef = collectionCap.borrow()
        if optRef==nil {
            return FindLeaseMarket.BidItemCollectionReport(items: info, ghosts: ghost)
        }

        let ref=optRef!

        let listingType = ref.getBidType()
        var listName : [String]= []
        if let leaseName = name{
            if !ref.containsNameBid(leaseName) {
                return FindLeaseMarket.BidItemCollectionReport(items: info, ghosts: ghost)
            }
            listName=[leaseName]
        } else {
            listName = ref.getNameBids()
        }

        for leaseName in listName {

            let bid=ref.borrowBidItem(leaseName)
            let item=self.getSaleInformation(tenant: tenantRef.owner!.address, name: leaseName, marketOption: marketOption, getLeaseInfo: getLeaseInfo)
            if item == nil {
                if getGhost {
                    ghost.append(FindLeaseMarket.GhostListing(listingType: listingType, name:leaseName))
                }
                continue
            }
            let bidInfo = FindLeaseMarket.BidInfo(name: leaseName, bidTypeIdentifier: listingType.identifier,  bidAmount: bid.getBalance(), timestamp: Clock.time(), item:item!)
            info.append(bidInfo)

        }
        return FindLeaseMarket.BidItemCollectionReport(items: info, ghosts: ghost)
    }

    access(all) fun assertBidOperationValid(tenant: Address, address: Address, marketOption: String, name:String) : &{SaleItem} {

        let tenantRef=self.getTenant(tenant)
        let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let optRef = collectionCap.borrow()
        if optRef == nil {
            panic("Account not properly set up, cannot borrow bid item collection. Account address : ".concat(collectionCap.address.toString()))
        }
        let ref=optRef!
        let bidItem=ref.borrowBidItem(name)

        let saleItemCollectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: bidItem.getSellerAddress())
        let saleRef = saleItemCollectionCap.borrow()
        if saleRef == nil {
            panic("Seller account is not properly set up, cannot borrow sale item collection. Seller address : ".concat(saleItemCollectionCap.address.toString()))
        }
        let sale=saleRef!
        let item=sale.borrowSaleItem(name)
        if !item.checkPointer() {
            panic("this is a ghost listing")
        }

        return item
    }

    /////// Pointer Section

    access(all) struct interface LeasePointer {
        access(all) let name: String
        access(all) let uuid: UInt64

        access(all) fun valid() : Bool
        access(all) fun getUUID() :UInt64
        access(all) fun getLease() : FIND.LeaseInformation
        access(all) fun owner() : Address
        access(contract) fun borrow() : &{FIND.LeaseCollectionPublic}
    }

    access(all) struct ReadLeasePointer : LeasePointer {
        access(self) let cap: Capability<&{FIND.LeaseCollectionPublic}>
        access(all) let name: String
        access(all) let uuid: UInt64

        // Passing in the reference here to ensure that is the owner
        init(name: String) {

            let address = FIND.lookupAddress(name) ?? panic("This lease name is not owned")
            self.cap=getAccount(address).capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!
            self.name=name

            if !self.cap.check() {
                panic("The capability is not valid.")
            }

            self.uuid = self.cap.borrow()!.getLeaseUUID(name)

        }

        access(contract) fun borrow() : &{FIND.LeaseCollectionPublic} {
            return self.cap.borrow() ?? panic("The capability of pointer is not linked.")
        }

        access(all) fun getLease() : FIND.LeaseInformation {
            return self.borrow().getLease(self.name) ?? panic("The owner doesn't hold the lease anymore".concat(self.name))
        }

        access(all) fun getUUID() :UInt64{
            return self.uuid
        }

        access(all) fun owner() : Address {
            return self.cap.address
        }

        access(all) fun valid() : Bool {
            if !self.cap.check() || !self.cap.borrow()!.getNames().contains(self.name) {
                return false
            }

            if Clock.time() > FindLeaseMarket.getNetwork().getLeaseExpireTime(self.name) {
                return false
            }
            return true
        }
    }

    access(all) struct AuthLeasePointer : LeasePointer {
        access(self) let cap: Capability<auth(FIND.Leasee) &FIND.LeaseCollection>
        access(all) let name: String
        access(all) let uuid: UInt64

        // Passing in the reference here to ensure that is the owner
        init(cap:Capability<auth(FIND.Leasee) &FIND.LeaseCollection>, name: String) {
            self.cap=cap
            self.name=name

            if !self.cap.borrow()!.getNames().contains(name) {
                panic("Please pass in the corresponding lease collection reference.")
            }

            if !self.cap.check() {
                panic("The capability is not valid.")
            }

            self.uuid = self.cap.borrow()!.getLeaseUUID(name)
        }

        access(contract) fun borrow() : &{FIND.LeaseCollectionPublic} {
            return self.cap.borrow() ?? panic("The capability of pointer is not linked.")
        }

        access(all) fun getLease() : FIND.LeaseInformation {
            return self.borrow().getLease(self.name) ?? panic("The owner doesn't hold the lease anymore".concat(self.name))
        }

        access(all) fun getUUID() :UInt64{
            return self.uuid
        }

        access(all) fun valid() : Bool {
            if !self.cap.check() || !self.cap.borrow()!.getNames().contains(self.name) {
                return false
            }

            if Clock.time() > FindLeaseMarket.getNetwork().getLeaseExpireTime(self.name) {
                return false
            }
            return true
        }

        access(account) fun move(to: Address) {
            if !self.valid() {
                panic("The lease capability is not valid")
            }
            let receiver = getAccount(to)
            let profile = receiver.capabilities.get<&{Profile.Public}>(Profile.publicPath)!
            let leases = receiver.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)!
            self.borrow().move(name: self.name, profile: profile, to: leases)
        }

        access(all) fun owner() : Address {
            return self.cap.address
        }

    }

    access(account) fun pay(tenant: String, leaseName: String, saleItem: &{SaleItem}, vault: @{FungibleToken.Vault}, leaseInfo: LeaseInfo, cuts:{String : FindMarketCutStruct.Cuts}) {
        let buyer=saleItem.getBuyer()
        let seller=saleItem.getSeller()
        let soldFor=vault.getBalance()
        let ftType=vault.getType()
        let ftInfo = FTRegistry.getFTInfoByTypeIdentifier(ftType.identifier)! // If this panic, there is sth wrong in FT set up
        let oldProfileCap= getAccount(seller).capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        let oldProfile = FindMarket.getPaymentWallet(oldProfileCap, ftInfo, panicOnFailCheck: true)

        for key in cuts.keys {
            let allCuts = cuts[key]!
            for cut in allCuts.cuts {
                if var cutAmount= cut.getAmountPayable(soldFor) {
                    let findName = FIND.reverseLookup(cut.getAddress())
                    emit RoyaltyPaid(tenant: tenant, leaseName: leaseName, saleID: saleItem.uuid, address:cut.getAddress(), findName: findName , royaltyName: cut.getName(), amount: cutAmount,  vaultType: ftType.identifier, leaseInfo:leaseInfo)
                    let vaultRef = cut.getReceiverCap().borrow() ?? panic("Royalty receiving account is not set up properly. Royalty account address : ".concat(cut.getAddress().toString()).concat(" Royalty Name : ").concat(cut.getName()))
                    vaultRef.deposit(from: <- vault.withdraw(amount: cutAmount))
                }
            }
        }


        oldProfile.deposit(from: <- vault)
    }

    //struct to expose information about leases
    access(all) struct LeaseInfo {
        access(all) let name: String
        access(all) let address: Address
        access(all) let cost: UFix64
        access(all) let status: String
        access(all) let validUntil: UFix64
        access(all) let lockedUntil: UFix64
        access(all) let addons: [String]

        init(_ pointer: {FindLeaseMarket.LeasePointer}){
            let network = FindLeaseMarket.getNetwork()
            let name = pointer.name
            let status= network.readStatus(name)
            self.name=name
            var s="TAKEN"
            if status.status == FIND.LeaseStatus.FREE {
                s="FREE"
            } else if status.status == FIND.LeaseStatus.LOCKED {
                s="LOCKED"
            }
            self.status=s
            self.validUntil=network.getLeaseExpireTime(name)
            self.lockedUntil=network.getLeaseLockedUntil(name)
            self.address=status.owner!
            self.cost=network.calculateCost(name)
            if pointer.valid() {
                let lease = pointer.borrow()
                self.addons=lease.getAddon(name: name)
            } else {
                self.addons=[]
            }
        }

    }

    access(all) resource interface SaleItem {
        //this is the type of sale this is, active, cancelled etc
        access(all) fun getSaleType(): String
        access(all) fun getSeller(): Address
        access(all) fun getBuyer(): Address?

        access(all) fun getSellerName() : String?
        access(all) fun getBuyerName() : String?

        access(all) fun toLeaseInfo() : FindLeaseMarket.LeaseInfo
        access(all) fun checkPointer() : Bool
        access(all) fun getListingType() : Type
        access(all) fun getListingTypeIdentifier(): String

        //the Type of the item for sale
        access(all) fun getItemType(): Type
        //The id of the nft for sale
        access(all) fun getLeaseName() : String

        access(all) fun getBalance(): UFix64
        access(all) fun getAuction(): AuctionItem?
        access(all) fun getFtType() : Type //The type of FT used for this sale item
        access(all) fun getValidUntil() : UFix64? //A timestamp that says when this item is valid until

        access(all) fun getSaleItemExtraField() : {String : AnyStruct}
        access(all) fun getId() : UInt64
    }

    access(all) resource interface Bid {
        access(all) fun getBalance() : UFix64
        access(all) fun getSellerAddress() : Address
        access(all) fun getBidExtraField() : {String : AnyStruct}
    }

    access(all) struct SaleItemInformation {
        access(all) let leaseIdentifier: String
        access(all) let leaseName: String
        access(all) let seller: Address
        access(all) let sellerName: String?
        access(all) let amount: UFix64?
        access(all) let bidder: Address?
        access(all) var bidderName: String?
        access(all) let listingId: UInt64

        access(all) let saleType: String
        access(all) let listingTypeIdentifier: String
        access(all) let ftAlias: String
        access(all) let ftTypeIdentifier: String
        access(all) let listingValidUntil: UFix64?

        access(all) var lease: LeaseInfo?
        access(all) let auction: AuctionItem?
        access(all) let listingStatus:String
        access(all) let saleItemExtraField: {String : AnyStruct}

        init(item: &{SaleItem}, status:String, leaseInfo: Bool) {
            self.leaseIdentifier= item.getItemType().identifier
            self.leaseName=item.getLeaseName()
            self.listingStatus=status
            self.saleType=item.getSaleType()
            self.listingTypeIdentifier=item.getListingTypeIdentifier()
            self.listingId=item.getId()
            self.amount=item.getBalance()
            self.bidder=item.getBuyer()
            self.bidderName=item.getBuyerName()
            self.seller=item.getSeller()
            self.sellerName=item.getSellerName()
            self.listingValidUntil=item.getValidUntil()
            self.lease=nil
            if leaseInfo {
                if status != "stopped" {
                    self.lease=item.toLeaseInfo()
                }
            }
            let ftIdentifier=item.getFtType().identifier
            self.ftTypeIdentifier=ftIdentifier
            let ftInfo=FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)
            self.ftAlias=ftInfo?.alias ?? ""

            self.auction=item.getAuction()
            self.saleItemExtraField=item.getSaleItemExtraField()
        }
    }

    access(all) struct BidInfo{
        access(all) let name: String
        access(all) let bidAmount: UFix64
        access(all) let bidTypeIdentifier: String
        access(all) let timestamp: UFix64
        access(all) let item: SaleItemInformation

        init(name: String, bidTypeIdentifier: String, bidAmount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
            self.name=name
            self.bidAmount=bidAmount
            self.bidTypeIdentifier=bidTypeIdentifier
            self.timestamp=timestamp
            self.item=item
        }
    }

    access(all) struct AuctionItem {
        //end time
        //current time
        access(all) let startPrice: UFix64
        access(all) let currentPrice: UFix64
        access(all) let minimumBidIncrement: UFix64
        access(all) let reservePrice: UFix64
        access(all) let extentionOnLateBid: UFix64
        access(all) let auctionEndsAt: UFix64?
        access(all) let timestamp: UFix64

        init(startPrice: UFix64, currentPrice: UFix64, minimumBidIncrement: UFix64, reservePrice: UFix64, extentionOnLateBid: UFix64, auctionEndsAt: UFix64? , timestamp: UFix64){
            self.startPrice = startPrice
            self.currentPrice = currentPrice
            self.minimumBidIncrement = minimumBidIncrement
            self.reservePrice = reservePrice
            self.extentionOnLateBid = extentionOnLateBid
            self.auctionEndsAt = auctionEndsAt
            self.timestamp = timestamp
        }
    }

    access(all) resource interface SaleItemCollectionPublic {
        access(all) fun getNameSales(): [String]
        access(all) fun containsNameSale(_ name: String): Bool
        access(account) fun borrowSaleItem(_ name: String) : &{SaleItem}
        access(all) fun getListingType() : Type
    }

    access(all) resource interface MarketBidCollectionPublic {
        access(all) fun getNameBids() : [String]
        access(all) fun containsNameBid(_ name: String): Bool
        access(all) fun getBidType() : Type
        access(account) fun borrowBidItem(_ name: String) : &{Bid}
    }

    access(all) struct GhostListing{
        //		access(all) let listingType: Type
        access(all) let listingTypeIdentifier: String
        access(all) let name: String


        init(listingType:Type, name:String) {
            //			self.listingType=listingType
            self.listingTypeIdentifier=listingType.identifier
            self.name=name
        }
    }

    access(all) struct SaleItemCollectionReport {
        access(all) let items : [FindLeaseMarket.SaleItemInformation]
        access(all) let ghosts: [FindLeaseMarket.GhostListing]

        init(items: [SaleItemInformation], ghosts: [GhostListing]) {
            self.items=items
            self.ghosts=ghosts
        }
    }

    access(all) struct BidItemCollectionReport {
        access(all) let items : [FindLeaseMarket.BidInfo]
        access(all) let ghosts: [FindLeaseMarket.GhostListing]

        init(items: [BidInfo], ghosts: [GhostListing]) {
            self.items=items
            self.ghosts=ghosts
        }
    }

    access(contract) fun getNetwork() : &FIND.Network {
        return FindLeaseMarket.account.storage.borrow<&FIND.Network>(from : FIND.NetworkStoragePath) ?? panic("Network is not up")
    }

    /* Admin Function */
    access(account) fun addSaleItemType(_ type: Type) {
        self.saleItemTypes.append(type)
        FindMarket.addPathMap(type)
        FindMarket.addListingName(type)
    }

    access(account) fun addMarketBidType(_ type: Type) {
        self.marketBidTypes.append(type)
        FindMarket.addPathMap(type)
        FindMarket.addListingName(type)
    }

    access(account) fun addSaleItemCollectionType(_ type: Type) {
        self.saleItemCollectionTypes.append(type)
        FindMarket.addPathMap(type)
        FindMarket.addListingName(type)
    }

    access(account) fun addMarketBidCollectionType(_ type: Type) {
        self.marketBidCollectionTypes.append(type)
        FindMarket.addPathMap(type)
        FindMarket.addListingName(type)
    }

    access(account) fun removeSaleItemType(_ type: Type) {
        var counter = 0
        while counter < self.saleItemTypes.length {
            if type == self.saleItemTypes[counter] {
                self.saleItemTypes.remove(at: counter)
            }
            counter = counter + 1
        }
    }

    access(account) fun removeMarketBidType(_ type: Type) {
        var counter = 0
        while counter < self.marketBidTypes.length {
            if type == self.marketBidTypes[counter] {
                self.marketBidTypes.remove(at: counter)
            }
            counter = counter + 1
        }
    }

    access(account) fun removeSaleItemCollectionType(_ type: Type) {
        var counter = 0
        while counter < self.saleItemCollectionTypes.length {
            if type == self.saleItemCollectionTypes[counter] {
                self.saleItemCollectionTypes.remove(at: counter)
            }
            counter = counter + 1
        }
    }

    access(account) fun removeMarketBidCollectionType(_ type: Type) {
        var counter = 0
        while counter < self.marketBidCollectionTypes.length {
            if type == self.marketBidCollectionTypes[counter] {
                self.marketBidCollectionTypes.remove(at: counter)
            }
            counter = counter + 1
        }
    }

    init() {

        self.saleItemTypes = []
        self.saleItemCollectionTypes = []
        self.marketBidTypes = []
        self.marketBidCollectionTypes = []

    }

}
