import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import Clock from "../contracts/Clock.cdc"

// Contract to store all helper functions. 
pub contract FindMarketOptions {

    access(contract) var saleItemCollectionTypes : [Type]
    access(contract) var marketBidCollectionTypes : [Type]

		pub fun getFindTenantAddress() : Address {
			return FindMarketOptions.account.address
		}

    /* Get Tenant */
    pub fun getTenant(_ tenant: Address) : &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic} {
        pre{
            FindMarketTenant.getTenantCapability(tenant) != nil : "This tenant does not exist." 
            FindMarketTenant.getTenantCapability(tenant)!.check() : "The capability to tenant is not valid." 
        }
        return FindMarketTenant.getTenantCapability(tenant)!.borrow()!
    }

    /* Get SaleItemCollections */
    pub fun getSaleItemCollectionTypes() : [Type] {
        return self.saleItemCollectionTypes
    }

    pub fun getSaleItemCollectionCapabilities(tenantRef: &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}, address: Address) : [Capability<&{FindMarket.SaleItemCollectionPublic}>] {
        var caps : [Capability<&{FindMarket.SaleItemCollectionPublic}>] = []
        for type in self.getSaleItemCollectionTypes() {
            if type != nil {
                let cap = getAccount(address).getCapability<&{FindMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type!))
                if cap.check() {
                    caps.append(cap)
                }
            }
        }
        return caps
    }

     pub fun getSaleItemCollectionCapability(tenantRef: &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindMarket.SaleItemCollectionPublic}> {
        for type in self.getSaleItemCollectionTypes() {
            if self.getMarketOptionFromType(type) == marketOption{
                let cap = getAccount(address).getCapability<&{FindMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type!))
                return cap
            }
        }
        panic("Cannot find market option : ".concat(marketOption))
    }

     /* Get Sale Reports and Sale Item */
    pub fun getSaleInformation(tenant: Address, address: Address, marketOption: String, id:UInt64) : FindMarket.SaleItemInformation? {
        let tenantRef=self.getTenant(tenant)
        let info = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, ids: [id], getGhost: false)
        if info.items.length > 0 {
            return info.items[0]
        }
        return nil
    }

    pub fun getSaleItemReport(tenant:Address, address: Address) : {String : FindMarket.SaleItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, ids: [], getGhost: true)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }

    pub fun getSaleItems(tenant:Address, address: Address, id: UInt64) : {String : FindMarket.SaleItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.SaleItemCollectionReport} = {}
        for type in self.getSaleItemCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type)
            let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, ids: [id], getGhost: true)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }
    
    access(contract) fun checkSaleInformation(tenantRef: &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}, marketOption: String, address: Address, ids: [UInt64], getGhost:Bool) : FindMarket.SaleItemCollectionReport {
        let ghost: [FindMarket.GhostListing] =[]
        let info: [FindMarket.SaleItemInformation] =[]
        let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let ref = collectionCap.borrow() ?? panic("Cannot borrow reference to the paased in capability.")
        let listingType = ref.getListingType()
        var listID = ids 
        if ids.length == 0 {
            listID = ref.getIds()
        }
        for id in listID {
            if ref.getIds().contains(id) {
                let item=ref.borrowSaleItem(id)
                if !item.checkPointer() {
                    if getGhost {
                        ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
                    }
                    continue
                } 
                //TODO: do we need to be smarter about this?
                let stopped=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "delist item for sale"))
                var status="active"
                if !stopped.allowed {
                    status="stopped"
                }
                let deprecated=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarketTenant.MarketAction(listing:true, "delist item for sale"))

                if !deprecated.allowed {
                    status="deprecated"
                }

                if let validTime = item.getValidUntil() {
                    if validTime >= Clock.time() {
                        status="ended"
                    }
                }
                info.append(FindMarket.SaleItemInformation(item, status))
            }
        }

        return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
    }

    /* Get Bid Collections */
    pub fun getMarketBidCollectionTypes() : [Type] {
        return self.marketBidCollectionTypes
    }

    pub fun getMarketBidCollectionCapabilities(tenantRef: &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}, address: Address) : [Capability<&{FindMarket.MarketBidCollectionPublic}>] {
        var caps : [Capability<&{FindMarket.MarketBidCollectionPublic}>] = []
        for type in self.getMarketBidCollectionTypes() {
            let cap = getAccount(address).getCapability<&{FindMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type!))
            if cap.check() {
                caps.append(cap)
            }
        }
        return caps
    }

    pub fun getMarketBidCollectionCapability(tenantRef: &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindMarket.MarketBidCollectionPublic}> {
        for type in self.getMarketBidCollectionTypes() {
            if self.getMarketOptionFromType(type!) == marketOption{
                let cap = getAccount(address).getCapability<&{FindMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type!))
                return cap
            }
        }
        panic("Cannot find market option : ".concat(marketOption))
    }
    pub fun getBid(tenant: Address, address: Address, marketOption: String, id:UInt64) : FindMarket.BidInfo? {
        let tenantRef=self.getTenant(tenant)
        let bidInfo = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, ids: [id], getGhost: false)
        if bidInfo.items.length > 0 {
            return bidInfo.items[0]
        }
        return nil
    }

    pub fun getBidsReport(tenant:Address, address: Address) : {String : FindMarket.BidItemCollectionReport} {
        let tenantRef = self.getTenant(tenant)
        var report : {String : FindMarket.BidItemCollectionReport} = {}
        for type in self.getMarketBidCollectionTypes() {
            let marketOption = self.getMarketOptionFromType(type!)
            let returnedReport = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, ids: [], getGhost: true)
            if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
                report[marketOption] = returnedReport
            }
        }
        return report
    }


    access(contract) fun checkBidInformation(tenantRef: &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}, marketOption: String, address: Address, ids: [UInt64], getGhost:Bool) : FindMarket.BidItemCollectionReport {
        let ghost: [FindMarket.GhostListing] =[]
        let info: [FindMarket.BidInfo] =[]
        let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
        let ref = collectionCap.borrow() ?? panic("Cannot borrow reference to the paased in capability.")
        let listingType = ref.getBidType()
        var listID = ids 
        if ids.length == 0 {
            listID = ref.getIds()
        }
        for id in listID {
            if ref.getIds().contains(id) {
                let bid=ref.borrowBidItem(id)
                let item=self.getSaleInformation(tenant: tenantRef.owner!.address, address: bid.getSellerAddress(), marketOption: marketOption, id: id)
                if item == nil {
                    if getGhost {
                        ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
                    }
                    continue
                } 
                let bidInfo = FindMarket.BidInfo(id: id, bidTypeIdentifier: listingType.identifier,  bidAmount: bid.getBalance(), timestamp: Clock.time(), item:item!)
                info.append(bidInfo)
            }
        }
        return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
    }

    /* Helper Function */
    pub fun getMarketOptionFromType(_ type: Type) : String {
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
    access(account) fun addSaleItemCollectionType(_ type: Type) {
        self.saleItemCollectionTypes.append(type)
    }

    access(account) fun addMarketBidCollectionType(_ type: Type) {
        self.marketBidCollectionTypes.append(type)
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

    init(){
        self.saleItemCollectionTypes = []
        self.marketBidCollectionTypes = []
    }

}
