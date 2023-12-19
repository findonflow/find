import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindRulesCache from "../contracts/FindRulesCache.cdc"
import FindMarketCut from "../contracts/FindMarketCut.cdc"
import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"
import FindUtils from "../contracts/FindUtils.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"

access(all) contract FindMarket {
    access(account) let  pathMap : {String: String}
    access(account) let  listingName : {String: String}
    access(contract) let  saleItemTypes : [Type]
    access(contract) let  saleItemCollectionTypes : [Type]
    access(contract) let  marketBidTypes : [Type]
    access(contract) let  marketBidCollectionTypes : [Type]

    access(all) event RoyaltyPaid(tenant:String, id: UInt64, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, nft:NFTInfo)
    access(all) event RoyaltyCouldNotBePaid(tenant:String, id: UInt64, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, nft:NFTInfo, residualAddress: Address)
    access(all) event FindBlockRules(tenant: String, ruleName: String, ftTypes:[String], nftTypes:[String], listingTypes:[String], status:String)
    access(all) event TenantAllowRules(tenant: String, ruleName: String, ftTypes:[String], nftTypes:[String], listingTypes:[String], status:String)
    access(all) event FindCutRules(tenant: String, ruleName: String, cut:UFix64, ftTypes:[String], nftTypes:[String], listingTypes:[String], status:String)
    access(all) event FindTenantRemoved(tenant: String, address: Address)

    //Residual Royalty
    access(all) var residualAddress : Address

    // Tenant information
    access(all) let TenantClientPublicPath: PublicPath
    access(all) let TenantClientStoragePath: StoragePath

    access(contract) let tenantPathPrefix :String

    access(account) let tenantNameAddress : {String:Address}
    access(account) let tenantAddressName : {Address:String}

    // Deprecated in testnet
    access(all) struct TenantCuts {
        access(all) let findCut:MetadataViews.Royalty?
        access(all) let tenantCut:MetadataViews.Royalty?

        init(findCut:MetadataViews.Royalty?, tenantCut:MetadataViews.Royalty?) {
            self.findCut=findCut
            self.tenantCut=tenantCut
        }
    }

    // Deprecated in testnet
    access(all) struct ActionResult {
        access(all) let allowed:Bool
        access(all) let message:String
        access(all) let name:String

        init(allowed:Bool, message:String, name:String) {
            self.allowed=allowed
            self.message=message
            self.name =name
        }
    }

    // ========================================
    access(all) fun getPublicPath(_ type: Type, name:String) : PublicPath {

        let pathPrefix=self.pathMap[type.identifier]!
        let path=pathPrefix.concat("_").concat(name)

        return PublicPath(identifier: path) ?? panic("Cannot find public path for type ".concat(type.identifier))
    }

    access(all) fun getStoragePath(_ type: Type, name:String) : StoragePath {

        let pathPrefix=self.pathMap[type.identifier]!
        let path=pathPrefix.concat("_").concat(name)

        return StoragePath(identifier: path) ?? panic("Cannot find public path for type ".concat(type.identifier))
    }
    access(all) fun getFindTenantAddress() : Address {
        return FindMarket.account.address
    }

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

    access(all) fun getSaleItemCollectionCapabilities(tenantRef: &{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindMarket.SaleItemCollectionPublic}>] {
        var caps : [Capability<&{FindMarket.SaleItemCollectionPublic}>] = []
        for type in self.getSaleItemCollectionTypes() {
            if type != nil {
                let cap = getAccount(address).capabilities.get<&{FindMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))!
                if cap.check() {
                    caps.append(cap)
                }
            }
        }
        return caps
    }

    access(all) fun getSaleItemCollectionCapability(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindMarket.SaleItemCollectionPublic}> {
        for type in self.getSaleItemCollectionTypes() {
            if self.getMarketOptionFromType(type) == marketOption{
                let cap = getAccount(address).capabilities.get<&{FindMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))!
                return cap
            }
        }
        panic("Cannot find market option : ".concat(marketOption))
    }



    /* Get Sale Reports and Sale Item */
    access(all) fun assertOperationValid(tenant: Address, address: Address, marketOption: String, id:UInt64) : &{SaleItem} {

        let tenantRef=self.getTenant(tenant)

        let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let optRef = collectionCap.borrow()
        if optRef == nil {
            panic("Account not properly set up, cannot borrow sale item collection")
        }
        let ref=optRef!
        let item=ref.borrowSaleItem(id)
        if !item.checkPointer() {
            panic("this is a ghost listing. SaleItem id : ".concat(id.toString()))
        }

        return item
    }

    // Get Royalties Changed Items

    access(all) fun getRoyaltiesChangedIds(tenant:Address, address: Address) : {String : [UInt64]} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : [UInt64]} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)

            let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
            if let optRef = collectionCap.borrow() {
                let ids = optRef.getRoyaltyChangedIds()
                if ids.length > 0 {
                    report[marketOption] = ids
                }
            }
        }
        return report
    }

    access(all) fun getRoyaltiesChangedItems(tenant:Address, address: Address) : {String : FindMarket.SaleItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: nil, getGhost: true, getNFTInfo: true, getRoyaltyChanged: true )
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    /* Get Sale Reports and Sale Item */
    access(all) fun getSaleInformation(tenant: Address, address: Address, marketOption: String, id:UInt64, getNFTInfo: Bool) : FindMarket.SaleItemInformation? {

        let tenantRef=self.getTenant(tenant)
        let info = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: id, getGhost: false, getNFTInfo: getNFTInfo, getRoyaltyChanged: true )
        if info.items.length > 0 {
            return info.items[0]
        }
        return nil
    }

    access(all) fun getSaleItemReport(tenant:Address, address: Address, getNFTInfo: Bool) : {String : FindMarket.SaleItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: nil, getGhost: true, getNFTInfo: getNFTInfo, getRoyaltyChanged: true )
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    access(all) fun getSaleItems(tenant:Address, address: Address, id: UInt64, getNFTInfo: Bool) : {String : FindMarket.SaleItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: id, getGhost: true, getNFTInfo: getNFTInfo, getRoyaltyChanged: true )
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    access(all) fun getNFTListing(tenant:Address, address: Address, id: UInt64, getNFTInfo: Bool) : {String : FindMarket.SaleItemInformation} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.SaleItemInformation} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: id, getGhost: true, getNFTInfo: getNFTInfo, getRoyaltyChanged: true )
            if returnedReport.items.length > 0 {
                report[marketOption] = returnedReport.items[0]
            }
        }
        return report
    }

    access(contract) fun checkSaleInformation(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address, itemId: UInt64?, getGhost: Bool, getNFTInfo: Bool, getRoyaltyChanged: Bool ) : FindMarket.SaleItemCollectionReport {
        let ghost: [FindMarket.GhostListing] =[]
        let info: [FindMarket.SaleItemInformation] =[]
        let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let optRef = collectionCap.borrow()
        if optRef == nil {
            return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
        }
        let ref=optRef!

        var listID : [UInt64]= []
        if let id = itemId{
            if !ref.containsId(id) {
                return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
            }
            listID=[id]
        } else {
            listID = ref.getIds()
        }

        let listingType = ref.getListingType()

        for id in listID {
            //if this id is not present in this Market option then we just skip it
            let item=ref.borrowSaleItem(id)
            if !item.checkPointer() {
                if getGhost {
                    ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
                }
                continue
            }

            // check soulBound Items
            if item.checkSoulBound() {
                ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
                continue
            }

            if getRoyaltyChanged && !item.validateRoyalties() {
                ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
                continue
            }

            let stopped=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:false, name: "delist item for sale"), seller: address, buyer: nil)
            var status="active"

            if !stopped.allowed && stopped.message == "Seller banned by Tenant" {
                status="banned"
                info.append(FindMarket.SaleItemInformation(item:item, status:status, nftInfo:false))
                continue
            }

            if !stopped.allowed {
                status="stopped"
                info.append(FindMarket.SaleItemInformation(item:item, status:status, nftInfo:false))
                continue
            }

            let deprecated=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:true, name: "delist item for sale"), seller: address, buyer: nil)

            if !deprecated.allowed {
                status="deprecated"
                info.append(FindMarket.SaleItemInformation(item:item, status:status, nftInfo:false))
                continue
            }

            if let validTime = item.getValidUntil() {
                if validTime <= Clock.time() {
                    status="ended"
                }
            }
            info.append(FindMarket.SaleItemInformation(item:item, status:status, nftInfo:getNFTInfo))
        }

        return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
    }

    /* Get Bid Collections */
    access(all) fun getMarketBidTypes() : [Type] {
        return self.marketBidTypes
    }

    access(all) fun getMarketBidCollectionTypes() : [Type] {
        return self.marketBidCollectionTypes
    }

    access(all) fun getMarketBidCollectionCapabilities(tenantRef: &{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindMarket.MarketBidCollectionPublic}>] {
        var caps : [Capability<&{FindMarket.MarketBidCollectionPublic}>] = []
        for type in self.getMarketBidCollectionTypes() {
            if let cap = getAccount(address).capabilities.get<&{FindMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type)) {
                caps.append(cap)
            }
        }
        return caps
    }

    access(all) fun getMarketBidCollectionCapability(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindMarket.MarketBidCollectionPublic}> {
        for type in self.getMarketBidCollectionTypes() {
            if self.getMarketOptionFromType(type) == marketOption{
                let cap = getAccount(address).capabilities.get<&{FindMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))!
                return cap
            }
        }
        panic("Cannot find market option : ".concat(marketOption))
    }

    access(all) fun getBid(tenant: Address, address: Address, marketOption: String, id:UInt64, getNFTInfo: Bool) : FindMarket.BidInfo? {
        let tenantRef=self.getTenant(tenant)
        let bidInfo = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, itemId: id, getGhost: false, getNFTInfo: getNFTInfo)
        if bidInfo.items.length > 0 {
            return bidInfo.items[0]
        }
        return nil
    }

    access(all) fun getBidsReport(tenant:Address, address: Address, getNFTInfo: Bool) : {String : FindMarket.BidItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.BidItemCollectionReport} = {}
        for type in self.getMarketBidCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, itemId: nil, getGhost: true, getNFTInfo: getNFTInfo)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    access(contract) fun checkBidInformation(tenantRef: &{FindMarket.TenantPublic}, marketOption: String, address: Address, itemId: UInt64?, getGhost:Bool, getNFTInfo: Bool) : FindMarket.BidItemCollectionReport {
        let ghost: [FindMarket.GhostListing] =[]
        let info: [FindMarket.BidInfo] =[]
        let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)

        let optRef = collectionCap.borrow()
        if optRef==nil {
            return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
        }

        let ref=optRef!

        let listingType = ref.getBidType()
        var listID : [UInt64]= []
        if let id = itemId{
            if !ref.containsId(id) {
                return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
            }
            listID=[id]
        } else {
            listID = ref.getIds()
        }

        for id in listID {

            let bid=ref.borrowBidItem(id)
            let item=self.getSaleInformation(tenant: tenantRef.owner!.address, address: bid.getSellerAddress(), marketOption: marketOption, id: id, getNFTInfo: getNFTInfo)
            if item == nil {
                if getGhost {
                    ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
                }
                continue
            }
            let bidInfo = FindMarket.BidInfo(id: id, bidTypeIdentifier: listingType.identifier,  bidAmount: bid.getBalance(), timestamp: Clock.time(), item:item!)
            info.append(bidInfo)

        }
        return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
    }

    access(all) fun assertBidOperationValid(tenant: Address, address: Address, marketOption: String, id:UInt64) : &{SaleItem} {

        let tenantRef=self.getTenant(tenant)
        let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let optRef = collectionCap.borrow()
        if optRef == nil {
            panic("Account not properly set up, cannot borrow bid item collection. Account address : ".concat(collectionCap.address.toString()))
        }
        let ref=optRef!
        let bidItem=ref.borrowBidItem(id)

        let saleItemCollectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: bidItem.getSellerAddress())
        let saleRef = saleItemCollectionCap.borrow()
        if saleRef == nil {
            panic("Seller account is not properly set up, cannot borrow sale item collection. Seller address : ".concat(saleItemCollectionCap.address.toString()))
        }
        let sale=saleRef!
        let item=sale.borrowSaleItem(id)
        if !item.checkPointer() {
            panic("this is a ghost listing. SaleItem id : ".concat(id.toString()))
        }

        return item
    }

    /* Helper Function */
    access(all) fun getMarketOptionFromType(_ type:Type) : String {
        return self.listingName[type.identifier]!
    }

    access(all) fun typeToListingName(_ type: Type) : String {
        let identifier = type.identifier
        var dots = 0
        var start = 0
        var end = 0
        var counter = 0
        while counter < identifier.length {
            if identifier[counter] == "." {
                dots = dots + 1
            }
            if start == 0 && dots == 2 {
                start = counter
            }
            if end == 0 && dots == 3 {
                end = counter
            }
            counter = counter + 1
        }
        return identifier.slice(from: start + 1, upTo: end)
    }

    /* Admin Function */
    access(account) fun addPathMap(_ type: Type) {
        self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
    }

    access(account) fun addListingName(_ type: Type) {
        self.listingName[type.identifier] =self.typeToListingName(type)
    }

    access(account) fun removePathMap(_ type: Type) {
        self.pathMap.remove(key: type.identifier)
    }

    access(account) fun removeListingName(_ type: Type) {
        self.listingName.remove(key: type.identifier)
    }

    access(account) fun addSaleItemType(_ type: Type) {
        self.saleItemTypes.append(type)
        self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
        self.listingName[type.identifier] =self.typeToListingName(type)
    }

    access(account) fun addMarketBidType(_ type: Type) {
        self.marketBidTypes.append(type)
        self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
        self.listingName[type.identifier] =self.typeToListingName(type)
    }

    access(account) fun addSaleItemCollectionType(_ type: Type) {
        self.saleItemCollectionTypes.append(type)
        self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
        self.listingName[type.identifier] =self.typeToListingName(type)
    }

    access(account) fun addMarketBidCollectionType(_ type: Type) {
        self.marketBidCollectionTypes.append(type)
        self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
        self.listingName[type.identifier] =self.typeToListingName(type)
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

    access(all) fun typeToPathIdentifier(_ type:Type) : String {
        let identifier=type.identifier

        var i=0
        var newIdentifier=""
        while i < identifier.length {

            let item= identifier.slice(from: i, upTo: i+1)
            if item=="." {
                newIdentifier=newIdentifier.concat("_")
            } else {
                newIdentifier=newIdentifier.concat(item)
            }
            i=i+1
        }
        return newIdentifier
    }
    // ========================================

    /// A struct to return what action an NFT can execute
    access(all) struct AllowedListing {
        access(all) let listingType: Type
        access(all) let ftTypes: [Type]
        access(all) let status: String

        init(listingType: Type, ftTypes: [Type], status: String) {
            self.listingType=listingType
            self.ftTypes=ftTypes
            self.status=status
        }
    }

    access(all) struct MarketAction{
        access(all) let listing:Bool
        access(all) let name:String

        init(listing:Bool, name:String){
            self.listing=listing
            self.name=name
        }
    }

    access(all) struct TenantRule{
        access(all) let name:String
        access(all) let types:[Type]
        access(all) let ruleType:String
        access(all) let allow:Bool

        init(name:String, types:[Type], ruleType:String, allow:Bool){

            if !(ruleType == "nft" || ruleType == "ft" || ruleType == "listing") {
                panic("Must be nft/ft/listing")
            }
            self.name=name
            self.types=types
            self.ruleType=ruleType
            self.allow=allow
        }


        access(all) fun accept(_ relevantType: Type): Bool {
            let contains=self.types.contains(relevantType)

            if self.allow && contains{
                return true
            }

            if !self.allow && !contains {
                return true
            }
            return false
        }
    }

    access(all) struct TenantSaleItem {
        access(all) let name:String
        access(all) let cut:MetadataViews.Royalty?
        access(all) let rules:[TenantRule]
        access(all) var status:String

        init(name:String, cut:MetadataViews.Royalty?, rules:[TenantRule], status:String){
            self.name=name
            self.cut=cut
            self.rules=rules
            self.status=status
        }

        access(contract) fun removeRules(_ index: Int) : TenantRule {
            return self.rules.remove(at: index)
        }

        access(contract) fun addRules(_ rule: TenantRule) {
            self.rules.append(rule)
        }

        access(contract) fun alterStatus(_ status : String) {
            self.status = status
        }

        access(contract) fun isValid(nftType: Type, ftType: Type, listingType: Type) : Bool {
            for rule in self.rules {

                var relevantType=nftType
                if rule.ruleType == "listing" {
                    relevantType=listingType
                } else if rule.ruleType=="ft" {
                    relevantType=ftType
                }

                if !rule.accept(relevantType) {
                    return false
                }
            }
            return true
        }
    }

    access(all) resource interface TenantPublic {
        access(all) fun getStoragePath(_ type: Type) : StoragePath
        access(all) fun getPublicPath(_ type: Type) : PublicPath
        access(all) fun allowedAction(listingType: Type, nftType:Type, ftType:Type, action: MarketAction, seller: Address? , buyer: Address?) : FindRulesCache.ActionResult
        access(all) fun getCuts(name:String, listingType: Type, nftType:Type, ftType:Type) : {String : FindMarketCutStruct.Cuts}
        access(all) fun getAllowedListings(nftType: Type, marketType: Type) : AllowedListing?
        access(all) fun getBlockedNFT(marketType: Type) : [Type]
        access(all) let name:String
    }

    //this needs to be a resource so that nobody else can make it.
    access(all) resource Tenant : TenantPublic{

        access(self) let findSaleItems : {String : TenantSaleItem}
        access(self) let tenantSaleItems : {String : TenantSaleItem}
        access(self) let findCuts : {String : TenantSaleItem}

        access(all) let name: String

        init(_ name:String) {
            self.name=name
            self.tenantSaleItems={}
            self.findSaleItems={}
            self.findCuts= {}
        }

        // This is an one-off temporary function to switch all receiver of rules / cuts to Switchboard cut
        // This requires all tenant and find to have the switchboard set up, but this is very powerful and can enable all sorts of FT listings

        access(account) fun setupSwitchboardCut() {
            for key in self.findSaleItems.keys {
                let val = self.findSaleItems[key]!
                if val.cut != nil {
                    let newReceiver = getAccount(val.cut!.receiver.address).capabilities.get<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath)!
                    let newCut = MetadataViews.Royalty(
                        receiver: newReceiver,
                        cut: val.cut!.cut,
                        description: val.cut!.description
                    )
                    let newVal = FindMarket.TenantSaleItem(
                        name : val.name,
                        cut : newCut,
                        rules : val.rules,
                        status : val.status
                    )
                    self.findSaleItems[key] = newVal
                }
            }

            for key in self.tenantSaleItems.keys {
                let val = self.tenantSaleItems[key]!
                if val.cut != nil {
                    let newReceiver = getAccount(val.cut!.receiver.address).capabilities.get<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath)!
                    let newCut = MetadataViews.Royalty(
                        receiver: newReceiver,
                        cut: val.cut!.cut,
                        description: val.cut!.description
                    )
                    let newVal = FindMarket.TenantSaleItem(
                        name : val.name,
                        cut : newCut,
                        rules : val.rules,
                        status : val.status
                    )
                    self.tenantSaleItems[key] = newVal
                }
            }

            for key in self.findCuts.keys {
                let val = self.findCuts[key]!
                if val.cut != nil {
                    let newReceiver = getAccount(val.cut!.receiver.address).capabilities.get<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath)!
                    let newCut = MetadataViews.Royalty(
                        receiver: newReceiver,
                        cut: val.cut!.cut,
                        description: val.cut!.description
                    )
                    let newVal = FindMarket.TenantSaleItem(
                        name : val.name,
                        cut : newCut,
                        rules : val.rules,
                        status : val.status
                    )
                    self.findCuts[key] = newVal
                }
            }
            FindRulesCache.resetTenantCutCache(self.name)
            FindRulesCache.resetTenantFindRulesCache(self.name)
            FindRulesCache.resetTenantTenantRulesCache(self.name)
        }

        access(account) fun checkFindCuts(_ cutName: String) : Bool {
            return self.findCuts.containsKey(cutName)
        }

        access(account) fun alterMarketOption(name: String, status: String) {
            pre{
                self.tenantSaleItems[name] != nil : "This saleItem does not exist. Item : ".concat(name)
            }
            self.tenantSaleItems[name]!.alterStatus(status)
            FindRulesCache.resetTenantTenantRulesCache(self.name)
            FindRulesCache.resetTenantCutCache(self.name)
            self.emitRulesEvent(item: self.tenantSaleItems[name]!, type: "tenant", status: status)
        }

        access(account) fun setExtraCut(types: [Type], category: String, cuts: FindMarketCutStruct.Cuts) {
            FindMarketCut.setTenantCuts(tenant: self.name, types: types, category: category, cuts: cuts)
        }

        access(all) fun getCuts(name:String, listingType: Type, nftType:Type, ftType:Type) : {String : FindMarketCutStruct.Cuts} {

            let cuts = FindMarketCut.getCuts(tenant: self.name, listingType: listingType, nftType: nftType, ftType: ftType)

            cuts["find"] = self.getFindCut(name: name, listingType: listingType, nftType: nftType, ftType: ftType)

            cuts["tenant"] = self.getTenantCut(name: name, listingType: listingType, nftType: nftType, ftType: ftType)

            return cuts
        }

        access(all) fun getFindCut(name:String, listingType: Type, nftType:Type, ftType:Type) : FindMarketCutStruct.Cuts? {
            let ruleId = FindMarketCut.getRuleId(listingType: listingType, nftType: nftType, ftType: ftType)
            let findRuleId = ruleId.concat("-find")
            if let cache = FindRulesCache.getTenantCut(tenant: self.name, ruleId: findRuleId) {
                var returningCut : FindMarketCutStruct.Cuts? = nil
                if let findCut = cache.findCut {
                    returningCut = FindMarketCutStruct.Cuts(cuts:[
                    FindMarketCutStruct.GeneralCut(
                        name : findCut.description,
                        cap: findCut.receiver,
                        cut: findCut.cut,
                        description: findCut.description
                    )
                    ]
                )
            }
            return returningCut
        }

        var cacheFindCut : MetadataViews.Royalty? = nil
        var returningCut : FindMarketCutStruct.Cuts? = nil
        for findCut in self.findCuts.values {
            let valid = findCut.isValid(nftType: nftType, ftType: ftType, listingType: listingType)
            if valid && findCut.cut != nil {
                cacheFindCut = findCut.cut
                returningCut = FindMarketCutStruct.Cuts(cuts:[
                FindMarketCutStruct.GeneralCut(
                    name : findCut.cut!.description,
                    cap: findCut.cut!.receiver,
                    cut: findCut.cut!.cut,
                    description: findCut.cut!.description
                )
                ]
            )
            break
        }
    }

    // store that to cache
    let cacheCut = FindRulesCache.TenantCuts(
        findCut: cacheFindCut,
        tenantCut: nil,
    )
    FindRulesCache.setTenantCutCache(tenant: self.name, ruleId: findRuleId, cut: cacheCut)

    return returningCut
}

access(all) fun getTenantCut(name:String, listingType: Type, nftType:Type, ftType:Type) : FindMarketCutStruct.Cuts? {
    let ruleId = FindMarketCut.getRuleId(listingType: listingType, nftType: nftType, ftType: ftType)
    let tenantRuleId = ruleId.concat("-tenant")
    if let cache = FindRulesCache.getTenantCut(tenant: self.name, ruleId: tenantRuleId) {
        var returningCut : FindMarketCutStruct.Cuts? = nil
        if let tenantCut = cache.tenantCut {
            returningCut = FindMarketCutStruct.Cuts(cuts: [
            FindMarketCutStruct.GeneralCut(
                name : tenantCut.description,
                cap: tenantCut.receiver,
                cut: tenantCut.cut,
                description: tenantCut.description
            )
            ]
        )
    }
    return returningCut
}

var cacheTenantCut : MetadataViews.Royalty? = nil
var returningCut : FindMarketCutStruct.Cuts? = nil
for item in self.tenantSaleItems.values {
    let valid = item.isValid(nftType: nftType, ftType: ftType, listingType: listingType)

    if valid && item.cut != nil{
        cacheTenantCut = item.cut
        returningCut = FindMarketCutStruct.Cuts(cuts: [
        FindMarketCutStruct.GeneralCut(
            name : item.cut!.description,
            cap: item.cut!.receiver,
            cut: item.cut!.cut,
            description: item.cut!.description
        )
        ]
    )
    break
}
}

// store that to cache
let cacheCut = FindRulesCache.TenantCuts(
    findCut: nil,
    tenantCut: cacheTenantCut,
)
FindRulesCache.setTenantCutCache(tenant: self.name, ruleId: tenantRuleId, cut: cacheCut)

return returningCut
}

access(account) fun addSaleItem(_ item: TenantSaleItem, type:String) {
    if type=="find" {
        var status : String? = nil
        if self.findSaleItems[item.name] != nil {
            status = "update"
        }
        self.findSaleItems[item.name]=item
        FindRulesCache.resetTenantFindRulesCache(self.name)
        self.emitRulesEvent(item: item, type: "find", status: status)
    } else if type=="tenant" {
        var status : String? = nil
        if self.findSaleItems[item.name] != nil {
            status = "update"
        }
        self.tenantSaleItems[item.name]=item
        FindRulesCache.resetTenantTenantRulesCache(self.name)
        FindRulesCache.resetTenantCutCache(self.name)
        self.emitRulesEvent(item: item, type: "tenant", status: status)
    } else if type=="cut" {
        var status : String? = nil
        if self.findSaleItems[item.name] != nil {
            status = "update"
        }
        self.findCuts[item.name]=item
        FindRulesCache.resetTenantCutCache(self.name)
        self.emitRulesEvent(item: item, type: "cut", status: status)
    } else{
        panic("Not valid type to add sale item for")
    }
}

access(account) fun removeSaleItem(_ name:String, type:String) : TenantSaleItem {
    if type=="find" {
        let item = self.findSaleItems.remove(key: name) ?? panic("This Find Sale Item does not exist. SaleItem : ".concat(name))
        FindRulesCache.resetTenantFindRulesCache(self.name)
        self.emitRulesEvent(item: item, type: "find", status: "remove")
        return item
    } else if type=="tenant" {
        let item = self.tenantSaleItems.remove(key: name)?? panic("This Tenant Sale Item does not exist. SaleItem : ".concat(name))
        FindRulesCache.resetTenantTenantRulesCache(self.name)
        FindRulesCache.resetTenantCutCache(self.name)
        self.emitRulesEvent(item: item, type: "tenant", status: "remove")
        return item
    } else if type=="cut" {
        let item = self.findCuts.remove(key: name)?? panic("This Find Cut does not exist. Cut : ".concat(name))
        FindRulesCache.resetTenantCutCache(self.name)
        self.emitRulesEvent(item: item, type: "cut", status: "remove")
        return item
    }
    panic("Not valid type to add sale item for")

}

// if status is nil, will fetch the original rule status (use for removal of rules)
access(contract) fun emitRulesEvent(item: TenantSaleItem, type: String, status: String?) {
    let tenant = self.name
    let ruleName = item.name
    var ftTypes : [String] = []
    var nftTypes : [String] = []
    var listingTypes : [String] = []
    var ruleStatus = status
    for rule in item.rules {
        var array : [String] = []
        for t in rule.types {
            array.append(t.identifier)
        }
        if rule.ruleType == "ft" {
            ftTypes = array
        } else if rule.ruleType == "nft" {
            nftTypes = array
        } else if rule.ruleType == "listing" {
            listingTypes = array
        }
    }
    if ruleStatus == nil {
        ruleStatus = item.status
    }

    if type == "find" {
        emit FindBlockRules(tenant: tenant, ruleName: ruleName, ftTypes:ftTypes, nftTypes:nftTypes, listingTypes:listingTypes, status:ruleStatus!)
        return
    } else if type == "tenant" {
        emit TenantAllowRules(tenant: tenant, ruleName: ruleName, ftTypes:ftTypes, nftTypes:nftTypes, listingTypes:listingTypes, status:ruleStatus!)
        return
    } else if type == "cut" {
        emit FindCutRules(tenant: tenant, ruleName: ruleName, cut:item.cut?.cut ?? 0.0, ftTypes:ftTypes, nftTypes:nftTypes, listingTypes:listingTypes, status:ruleStatus!)
        return
    }
    panic("Panic executing emitRulesEvent, Must be nft/ft/listing")
}

access(all) fun allowedAction(listingType: Type, nftType:Type, ftType:Type, action: MarketAction, seller: Address?, buyer: Address?) : FindRulesCache.ActionResult{
    /* Check for Honour Banning */
    let profile = getAccount(FindMarket.tenantNameAddress[self.name]!).capabilities.borrow<&{Profile.Public}>(Profile.publicPath) ?? panic("Cannot get reference to Profile to check honour banning. Tenant Name : ".concat(self.name))
    if seller != nil && profile.isBanned(seller!) {
        return FindRulesCache.ActionResult(allowed:false, message: "Seller banned by Tenant", name: "Profile Ban")
    }
    if buyer != nil && profile.isBanned(buyer!) {
        return FindRulesCache.ActionResult(allowed:false, message: "Buyer banned by Tenant", name: "Profile Ban")
    }

    let ruleId = listingType.identifier.concat(nftType.identifier).concat(ftType.identifier)
    let findRulesCache = FindRulesCache.getTenantFindRules(tenant: self.name, ruleId: ruleId)

    if findRulesCache == nil {
        // if the cache returns nil, go thru the logic once to save the result to the cache
        for item in self.findSaleItems.values {
            for rule in item.rules {
                var relevantType=nftType
                if rule.ruleType == "listing" {
                    relevantType=listingType
                } else if rule.ruleType=="ft" {
                    relevantType=ftType
                }

                if rule.accept(relevantType) {
                    continue
                }
                let result = FindRulesCache.ActionResult(allowed:false, message: rule.name, name: item.name)
                FindRulesCache.setTenantFindRulesCache(tenant: self.name, ruleId: ruleId, result: result)
                return result
            }
            if item.status=="stopped" {
                let result = FindRulesCache.ActionResult(allowed:false, message: "Find has stopped this item", name:item.name)
                FindRulesCache.setTenantFindRulesCache(tenant: self.name, ruleId: ruleId, result: result)
                return result
            }

            if item.status=="deprecated" && action.listing{
                let result = FindRulesCache.ActionResult(allowed:false, message: "Find has deprected mutation options on this item", name:item.name)
                FindRulesCache.setTenantFindRulesCache(tenant: self.name, ruleId: ruleId, result: result)
                return result
            }
        }
        FindRulesCache.setTenantFindRulesCache(tenant: self.name, ruleId: ruleId, result: FindRulesCache.ActionResult(allowed:true, message: "No Find deny rules hit", name:""))

    } else if !findRulesCache!.allowed {
        return findRulesCache!
    }


    let tenantRulesCache = FindRulesCache.getTenantTenantRules(tenant: self.name, ruleId: ruleId)

    if tenantRulesCache == nil {
        // if the cache returns nil, go thru the logic once to save the result to the cache
        for item in self.tenantSaleItems.values {
            let valid = item.isValid(nftType: nftType, ftType: ftType, listingType: listingType)

            if !valid {
                continue
            }

            if item.status=="stopped" {
                let result = FindRulesCache.ActionResult(allowed:false, message: "Tenant has stopped this item", name:item.name)
                FindRulesCache.setTenantTenantRulesCache(tenant: self.name, ruleId: ruleId, result: result)
                return result
            }

            if item.status=="deprecated" && action.listing{
                let result = FindRulesCache.ActionResult(allowed:false, message: "Tenant has deprected mutation options on this item", name:item.name)
                FindRulesCache.setTenantTenantRulesCache(tenant: self.name, ruleId: ruleId, result: result)
                return result
            }
            let result = FindRulesCache.ActionResult(allowed:true, message:"OK!", name:item.name)
            FindRulesCache.setTenantTenantRulesCache(tenant: self.name, ruleId: ruleId, result: result)
            return result
        }

        let result = FindRulesCache.ActionResult(allowed:false, message:"Nothing matches", name:"")
        FindRulesCache.setTenantTenantRulesCache(tenant: self.name, ruleId: ruleId, result: result)
        return result

    }
    return tenantRulesCache!

}

access(all) fun getPublicPath(_ type: Type) : PublicPath {
    return FindMarket.getPublicPath(type, name: self.name)
}

access(all) fun getStoragePath(_ type: Type) : StoragePath {
    return FindMarket.getStoragePath(type, name: self.name)
}

access(all) fun getAllowedListings(nftType: Type, marketType: Type) : AllowedListing? {

    // Find Rules have to be deny rules
    var containsNFTType = false
    var containsListingType = true
    for item in self.findSaleItems.values {
        for rule in item.rules {
            if rule.types.contains(nftType){
                containsNFTType = true
            }
            if rule.ruleType == "listing" && !rule.types.contains(marketType) {
                containsListingType = false
            }
        }
        if containsListingType && containsNFTType {
            return nil
        }
        containsNFTType = false
        containsListingType = true
    }

    // Tenant Rules have to be allow rules
    var returningFTTypes : [Type] = []
    for item in self.tenantSaleItems.values {
        var allowedFTTypes : [Type] = []
        if item.status != "active" {
            continue
        }
        for rule in item.rules {
            if rule.ruleType == "ft"{
                allowedFTTypes = rule.types
            }
            if rule.types.contains(nftType) && rule.allow {
                containsNFTType = true
            }
            if rule.ruleType == "listing" && !rule.types.contains(marketType) && rule.allow {
                containsListingType = false
            }
        }
        if containsListingType && containsNFTType {
            returningFTTypes.appendAll(allowedFTTypes)
        }

        containsNFTType = false
        containsListingType = true
    }

    if returningFTTypes.length == 0 {
        return nil
    }
    returningFTTypes = FindUtils.deDupTypeArray(returningFTTypes)
    return AllowedListing(listingType: marketType, ftTypes: returningFTTypes, status: "active")
}

access(all) fun getBlockedNFT(marketType: Type) : [Type] {
    // Find Rules have to be deny rules
    let list : [Type] = []
    var containsListingType = true
    var l : [Type] = []
    for item in self.findSaleItems.values {
        for rule in item.rules {
            if rule.ruleType == "listing" && !rule.types.contains(marketType){
                containsListingType = false
            }
            if rule.ruleType == "nft" {
                l.appendAll(rule.types)
            }
        }
        if containsListingType {
            for type in l {
                if list.contains(type) {
                    continue
                }
                list.append(type)
            }
        }
        l = []
        containsListingType = true
    }

    containsListingType = false
    // Tenant Rules have to be allow rules
    for item in self.tenantSaleItems.values {
        for rule in item.rules {
            if item.status != "stopped" {
                continue
            }
            if rule.ruleType == "nft"{
                l.appendAll(rule.types)
            }
            if rule.types.contains(marketType) && rule.allow {
                containsListingType = true
            }

        }
        if containsListingType {
            for type in l {
                if list.contains(type) {
                    continue
                }
                list.append(type)
            }
        }
        l = []
        containsListingType = false
    }
    return list
}
}

// Tenant admin stuff
//Admin client to use for capability receiver pattern
access(all) fun funcreateTenantClient() : @TenantClient {
    return <- create TenantClient()
}


//interface to use for capability receiver pattern
access(all) resource interface TenantClientPublic  {
    access(all) fun addCapability(_ cap: Capability<&Tenant>)
}

/*

A tenantClient should be able to:
- deprecte a certain market type: No new listings can be made

*/
//admin proxy with capability receiver
access(all) resource TenantClient: TenantClientPublic {

    access(self) var capability: Capability<&Tenant>?

    access(all) fun  addCapability(_ cap: Capability<&Tenant>) {

        if !cap.check() {
            panic("Invalid tenant")
        }
        if self.capability != nil {
            panic("Server already set")
        }
        self.capability = cap
    }

    init() {
        self.capability = nil
    }

    access(all) fun setMarketOption(saleItem: TenantSaleItem) {
        let tenant = self.getTenantRef()
        tenant.addSaleItem(saleItem, type: "tenant")
    }

    access(all) fun removeMarketOption(name: String) {
        let tenant = self.getTenantRef()
        tenant.removeSaleItem(name, type: "tenant")
    }

    access(all) fun enableMarketOption(_ name: String) {
        let tenant = self.getTenantRef()
        tenant.alterMarketOption(name: name, status: "active")
    }

    access(all) fun deprecateMarketOption(_ name: String) {
        let tenant = self.getTenantRef()
        tenant.alterMarketOption(name: name, status: "deprecated")
    }

    access(all) fun stopMarketOption(_ name: String) {
        let tenant = self.getTenantRef()
        tenant.alterMarketOption(name: name, status: "stopped")
    }

    access(all) fun getTenantRef() : &Tenant {
        if self.capability == nil {
            panic("TenantClient is not present")
        }
        if !self.capability!.check() {
            panic("Tenant client is not linked anymore")
        }

        return self.capability!.borrow()!
    }

    access(all) fun setExtraCut(types: [Type], category: String, cuts: FindMarketCutStruct.Cuts) {
        let tenant = self.getTenantRef()
        tenant.setExtraCut(types: types, category: category, cuts: cuts)
    }
}

access(account) fun removeFindMarketTenant(tenant: Address) {

    if let name = self.tenantAddressName[tenant]  {
        FindRulesCache.resetTenantFindRulesCache(name)
        FindRulesCache.resetTenantTenantRulesCache(name)
        FindRulesCache.resetTenantCutCache(name)

        let account=FindMarket.account
        let tenantPath=self.getTenantPathForName(name)
        let sp=StoragePath(identifier: tenantPath)!
        let pubp=PublicPath(identifier:tenantPath)!
        destroy account.storage.load<@Tenant>(from: sp)
        account.capabilities.unpublish(pubp)
        self.tenantAddressName.remove(key: tenant)
        self.tenantNameAddress.remove(key: name)
        emit FindTenantRemoved(tenant: name, address: tenant)
    }

}

access(account) fun createFindMarket(name: String, address:Address, findCutSaleItem: TenantSaleItem?) : Capability<&Tenant> {
    let account=FindMarket.account

    let tenant <- create Tenant(name)
    //fetch the TenentRegistry from our storage path and add the new tenant with the given name and address

    //add to registry
    self.tenantAddressName[address]=name
    self.tenantNameAddress[name]=address

    if findCutSaleItem != nil {
        tenant.addSaleItem(findCutSaleItem!, type: "cut")
    }

    //end do on outside

    let tenantPath=self.getTenantPathForName(name)
    let sp=StoragePath(identifier: tenantPath)!
    let pubp=PublicPath(identifier:tenantPath)!
    account.storage.save(<- tenant, to: sp)
    let cap = account.capabilities.storage.issue<&{TenantPublic}>(sp)
    account.capabilities.publish(cap, at: pubp)
    let tenantCap = account.capabilities.storage.issue<&Tenant>(sp)
    return tenantCap
}

access(all) fun getTenantPathForName(_ name:String) : String {
    if !self.tenantNameAddress.containsKey(name) {
        panic("tenant is not registered in registry")
    }

    return self.tenantPathPrefix.concat("_").concat(name)
}

access(all) fun getTenantPathForAddress(_ address:Address) : String {
    if !self.tenantAddressName.containsKey(address) {
        panic("tenant is not registered in registry")
    }

    return self.getTenantPathForName(self.tenantAddressName[address]!)
}

access(all) fun getTenantCapability(_ marketplace:Address) : Capability<&{TenantPublic}>? {

    if !self.tenantAddressName.containsKey(marketplace)  {
        "tenant is not registered in registry"
    }

    return FindMarket.account.capabilities.get<&{TenantPublic}>(PublicPath(identifier:self.getTenantPathForAddress(marketplace))!)!
}


access(account) fun pay(tenant: String, id: UInt64, saleItem: &{SaleItem}, vault: @{FungibleToken.Vault}, royalty: MetadataViews.Royalties, nftInfo:NFTInfo, cuts:{String : FindMarketCutStruct.Cuts}, resolver: (fun (Address) : String?), resolvedAddress: {Address: String}) {
    let resolved : {Address : String} = resolvedAddress

    fun resolveName(_ addr: Address ) : String? {
        if !resolved.containsKey(addr) {
            let name = resolver(addr)
            if name != nil {
                resolved[addr] = name
                return name
            } else {
                resolved[addr] = ""
                return nil
            }
        }

        let name = resolved[addr]!
        if name == "" {
            return nil
        }
        return name
    }

    let buyer=saleItem.getBuyer()
    let seller=saleItem.getSeller()
    let soldFor=vault.getBalance()
    let ftType=vault.getType()

    /* Residual Royalty */
    var payInFUT = false
    var payInDUC = false
    let ftInfo = FTRegistry.getFTInfoByTypeIdentifier(ftType.identifier)! // If this panic, there is sth wrong in FT set up
    let oldProfileCap= getAccount(seller).capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
    let oldProfile = self.getPaymentWallet(oldProfileCap, ftInfo, panicOnFailCheck: true)

    /* Check the total royalty to prevent changing of royalties */
    let royalties = royalty.getRoyalties()

    if royalties.length != 0 {
        var totalRoyalties : UFix64 = 0.0

        for royaltyItem in royalties {
            totalRoyalties = totalRoyalties + royaltyItem.cut
            let description=royaltyItem.description

            var cutAmount= soldFor * royaltyItem.cut
            if tenant == "onefootball" {
                //{"onefootball largest of 6% or 0.65": 0.65)}
                let minAmount = 0.65

                if minAmount > cutAmount {
                    cutAmount = minAmount
                }
            }

            var receiver = royaltyItem.receiver.address
            let name = resolveName(royaltyItem.receiver.address)
            let wallet = self.getPaymentWallet(royaltyItem.receiver, ftInfo, panicOnFailCheck: false)

            /* If the royalty receiver check failed */
            if wallet.owner!.address == FindMarket.residualAddress {
                emit RoyaltyCouldNotBePaid(tenant:tenant, id: id, saleID: saleItem.uuid, address:receiver, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo, residualAddress: wallet.owner!.address)
                wallet.deposit(from: <- vault.withdraw(amount: cutAmount))
                continue
            }
            emit RoyaltyPaid(tenant:tenant, id: id, saleID: saleItem.uuid, address:receiver, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
            wallet.deposit(from: <- vault.withdraw(amount: cutAmount))
        }
        if totalRoyalties != saleItem.getTotalRoyalties() {
            panic("The total Royalties to be paid is changed after listing.")
        }
    }

    for key in cuts.keys {
        let allCuts = cuts[key]!
        for cut in allCuts.cuts {
            if var cutAmount= cut.getAmountPayable(soldFor) {
                let findName = resolveName(cut.getAddress())
                emit RoyaltyPaid(tenant: tenant, id: id, saleID: saleItem.uuid, address:cut.getAddress(), findName: findName , royaltyName: cut.getName(), amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
                let vaultRef = cut.getReceiverCap().borrow() ?? panic("Royalty receiving account is not set up properly. Royalty account address : ".concat(cut.getAddress().toString()).concat(" Royalty Name : ").concat(cut.getName()))
                vaultRef.deposit(from: <- vault.withdraw(amount: cutAmount))
            }
        }
    }

    oldProfile.deposit(from: <- vault)
}

access(account) fun getPaymentWallet(_ cap: Capability<&{FungibleToken.Receiver}>, _ ftInfo: FTRegistry.FTInfo, panicOnFailCheck: Bool) : &{FungibleToken.Receiver} {
    var tempCap = cap

    // If capability is valid, we do not trust it but will do the below checks
    if tempCap.check() {
        let ref = cap.borrow()!
        let underlyingType = ref.getType()
        switch underlyingType {
            // If the underlying matches with the token type, we return the ref
        case ftInfo.type :
            return ref
            // If the underlying is a profile, we check if the wallet type is registered in profile wallet and then return
            // If it is not registered, it falls through and be handled by residual
        case Type<@Profile.User>():
            if let ProfileRef = getAccount(cap.address).capabilities.borrow<&{Profile.Public}>(Profile.publicPath) {
                if ProfileRef.hasWallet(ftInfo.type.identifier) {
                    return ref
                }
            }
            // If the underlying is a switchboard, we check if the wallet type is registered in switchboard wallet and then return
            // If it is not registered, it falls through and be handled by residual
        case Type<@FungibleTokenSwitchboard.Switchboard>() :
            if let sbRef = getAccount(cap.address).capabilities.borrow<&{FungibleTokenSwitchboard.SwitchboardPublic}>(FungibleTokenSwitchboard.PublicPath) {
                if sbRef.getVaultTypes().contains(ftInfo.type) {
                    return ref
                }
            }
            // If the underlying is a tokenforwarder, we cannot verify if it is pointing to the right vault type.
            // The best we can do is to try borrow from the standard path and TRY deposit
        case Type<@TokenForwarding.Forwarder>() :
            // This might break FindMarket with NFT with "Any" kind of forwarder.
            // We might have to restrict this to only DUC FUT at the moment and fix it after.
            if !ftInfo.tag.contains("dapper"){
                return ref
            }
        }
    }

    // if capability is not valid, or if the above cases are fell through, we will try to get one with "standard" path
    if let tempCap = getAccount(cap.address).capabilities.borrow<&{FungibleToken.Receiver}>(ftInfo.receiverPath) {
        return tempCap
    }

    if !panicOnFailCheck {
        // If it all falls throught, these edge cases will be handled by a residual account that has switchboard set up
        return getAccount(FindMarket.residualAddress).capabilities.borrow<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath) ?? panic("Cannot borrow residual vault in address : ".concat(FindMarket.residualAddress.toString()).concat(" type : ").concat(ftInfo.typeIdentifier))
    }

    let msg = "User ".concat(cap.address.toString()).concat(" does not have any usable links set up for vault type ").concat(ftInfo.typeIdentifier)
    panic(msg)
}

access(all) struct NFTInfo {
    access(all) let id: UInt64
    access(all) let name:String
    access(all) let thumbnail:String
    access(all) let type: String
    access(all) var rarity:String?
    access(all) var editionNumber: UInt64?
    access(all) var totalInEdition: UInt64?
    access(all) var scalars: {String:UFix64}
    access(all) var tags : {String:String}
    access(all) var collectionName: String?
    access(all) var collectionDescription: String?

    init(_ item: &{ViewResolver.Resolver}, id: UInt64, detail: Bool){

        self.tags = {}

        self.collectionName=nil
        self.collectionDescription=nil
        self.scalars = {
            "uuid" : UFix64(item.uuid)
        }
        self.rarity= nil
        self.editionNumber=nil
        self.totalInEdition=nil
        let display = MetadataViews.getDisplay(item) ?? panic("cannot get MetadataViews.Display View")
        self.name=display.name
        self.thumbnail=display.thumbnail.uri()
        self.type=item.getType().identifier
        self.id=id

        if detail {
            if let ncd = MetadataViews.getNFTCollectionDisplay(item) {
                self.collectionName=ncd.name
                self.collectionDescription=ncd.description
            }

            if let rarity = MetadataViews.getRarity(item) {
                if rarity.description != nil {
                    self.rarity=rarity.description!
                }

                if rarity.score != nil {
                    self.scalars["rarity_score"] = rarity.score!
                }
                if rarity.max != nil {
                    self.scalars["rarity_max"] = rarity.max!
                }
            }

            let numericValues  = {"Date" : true, "Numeric":true, "Number":true, "date":true, "numeric":true, "number":true}

            var singleTrait : MetadataViews.Trait? = nil
            let traits : [MetadataViews.Trait] = []
            if let view = item.resolveView(Type<MetadataViews.Trait>()) {
                if let t = view as? MetadataViews.Trait {
                    singleTrait = t
                    traits.append(t)
                }
            }

            if let t =  MetadataViews.getTraits(item) {
                traits.appendAll(t.traits)
            }

            for trait in traits {

                let name = trait.name
                let display = trait.displayType ?? "String"

                var traitName = name

                if numericValues[display] != nil {

                    if display == "Date" || display == "date" {
                        traitName = "date.".concat(traitName)
                    }

                    if let value = trait.value as? Number {
                        self.scalars[traitName]  = UFix64(value)
                    }
                } else {
                    if let value = trait.value as? String {
                        self.tags[traitName]  = value
                    }
                    if let value = trait.value as? Bool {
                        if value {
                            self.tags[traitName]  = "true"
                        }else {
                            self.tags[traitName]  = "false"
                        }
                    }

                }
                if let rarity = trait.rarity {
                    if rarity.description != nil {
                        self.tags[traitName.concat("_rarity")] = rarity.description!
                    }

                    if rarity.score != nil {
                        self.scalars[traitName.concat("_rarity_score")] = rarity.score!
                    }
                    if rarity.max != nil {
                        self.scalars[traitName.concat("_rarity_max")] = rarity.max!
                    }
                }
            }

            var singleEdition : MetadataViews.Edition? = nil
            let editions : [MetadataViews.Edition] = []
            if let view = item.resolveView(Type<MetadataViews.Edition>()) {
                if let e = view as? MetadataViews.Edition {
                    singleEdition = e
                    editions.append(e)
                }
            }

            if let e = MetadataViews.getEditions(item) {
                editions.appendAll(e.infoList)
            }

            for edition in editions {

                if edition.name == nil {
                    self.editionNumber=edition.number
                    self.totalInEdition=edition.max
                } else {
                    self.scalars["edition_".concat(edition.name!).concat("_number")] = UFix64(edition.number)
                    if edition.max != nil {
                        self.scalars["edition_".concat(edition.name!).concat("_max")] = UFix64(edition.max!)
                    }
                }
            }

            if let serial = MetadataViews.getSerial(item) {
                self.scalars["serial_number"] = UFix64(serial.number)
            }

            if let url = MetadataViews.getExternalURL(item) {
                self.tags["external_url"] = url.url
            }
        }
    }
}

access(all) struct GhostListing{
    //		access(all) let listingType: Type
    access(all) let listingTypeIdentifier: String
    access(all) let id: UInt64


    init(listingType:Type, id:UInt64) {
        //			self.listingType=listingType
        self.listingTypeIdentifier=listingType.identifier
        self.id=id
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
    access(all) fun getIds(): [UInt64]
    access(all) fun getRoyaltyChangedIds(): [UInt64]
    access(all) fun containsId(_ id: UInt64): Bool
    access(account) fun borrowSaleItem(_ id: UInt64) : &{SaleItem}
    access(all) fun getListingType() : Type
}

access(all) struct SaleItemCollectionReport {
    access(all) let items : [FindMarket.SaleItemInformation]
    access(all) let ghosts: [FindMarket.GhostListing]

    init(items: [SaleItemInformation], ghosts: [GhostListing]) {
        self.items=items
        self.ghosts=ghosts
    }
}

access(all) resource interface MarketBidCollectionPublic {
    access(all) fun getIds() : [UInt64]
    access(all) fun containsId(_ id: UInt64): Bool
    access(all) fun getBidType() : Type
    access(account) fun borrowBidItem(_ id: UInt64) : &{Bid}
}

access(all) struct BidItemCollectionReport {
    access(all) let items : [FindMarket.BidInfo]
    access(all) let ghosts: [FindMarket.GhostListing]

    init(items: [BidInfo], ghosts: [GhostListing]) {
        self.items=items
        self.ghosts=ghosts
    }
}

access(all) resource interface Bid {
    access(all) fun getBalance() : UFix64
    access(all) fun getSellerAddress() : Address
    access(all) fun getBidExtraField() : {String : AnyStruct}
}

access(all) resource interface SaleItem {

    //this is the type of sale this is, auction, direct offer etc
    access(all) fun getSaleType(): String
    access(all) fun getListingTypeIdentifier(): String

    access(all) fun getSeller(): Address
    access(all) fun getBuyer(): Address?

    access(all) fun getSellerName() : String?
    access(all) fun getBuyerName() : String?

    access(all) fun toNFTInfo(_ detail: Bool) : FindMarket.NFTInfo
    access(all) fun checkPointer() : Bool
    access(all) fun checkSoulBound() : Bool
    access(all) fun getListingType() : Type

    // access(all) getFtAlias(): String
    //the Type of the item for sale
    access(all) fun getItemType(): Type
    //The id of fun the nft for sale
    access(all) fun getItemID() : UInt64
    //The id of fun this sale item, ie the UUID of the item listed for sale
    access(all) fun getId() : UInt64

    access(all) fun getBalance(): UFix64
    access(all) fun getAuction(): AuctionItem?
    access(all) fun getFtType() : Type //The type of FT used for this sale item
    access(all) fun getValidUntil() : UFix64? //A timestamp that says when this item is valid until

    access(all) fun getSaleItemExtraField() : {String : AnyStruct}

    access(all) fun getTotalRoyalties() : UFix64
    access(all) fun validateRoyalties() : Bool
    access(all) fun getDisplay() : MetadataViews.Display
    access(all) fun getNFTCollectionData() : MetadataViews.NFTCollectionData
}

access(all) struct SaleItemInformation {
    access(all) let nftIdentifier: String
    access(all) let nftId: UInt64
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

    access(all) var nft: NFTInfo?
    access(all) let auction: AuctionItem?
    access(all) let listingStatus:String
    access(all) let saleItemExtraField: {String : AnyStruct}

    init(item: &{SaleItem}, status:String, nftInfo: Bool) {
        self.nftIdentifier= item.getItemType().identifier
        self.nftId=item.getItemID()
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
        self.nft=nil
        if nftInfo {
            if status != "stopped" {
                self.nft=item.toNFTInfo(true)
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
    access(all) let id: UInt64
    access(all) let bidAmount: UFix64
    access(all) let bidTypeIdentifier: String
    access(all) let timestamp: UFix64
    access(all) let item: SaleItemInformation

    init(id: UInt64, bidTypeIdentifier: String, bidAmount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
        self.id=id
        self.bidAmount=bidAmount
        self.bidTypeIdentifier=bidTypeIdentifier
        self.timestamp=timestamp
        self.item=item
    }
}

access(all) fun getTenantAddress(_ name: String) : Address? {
    return FindMarket.tenantNameAddress[name]
}

access(account) fun setResidualAddress(_ address: Address) {
    FindMarket.residualAddress = address
}

init() {
    self.tenantAddressName={}
    self.tenantNameAddress={}

    self.TenantClientPublicPath=/public/findMarketClient
    self.TenantClientStoragePath=/storage/findMarketClient

    self.tenantPathPrefix=  FindMarket.typeToPathIdentifier(Type<@Tenant>())

    self.saleItemTypes = []
    self.saleItemCollectionTypes = []
    self.pathMap = {}
    self.listingName={}
    self.marketBidTypes = []
    self.marketBidCollectionTypes = []

    self.residualAddress = self.account.address // This has to be changed

}

}
