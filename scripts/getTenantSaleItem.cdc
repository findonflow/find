import FindMarketTenant from "../contracts/FindMarketTenant.cdc"

pub fun main(tenant: Address) : TenantSaleItems {
    let tenantCap = FindMarketTenant.getTenantCapability(tenant) ?? panic("No tenant capability is set up for this address")
    let tenantRef = tenantCap.borrow() ?? panic("Cannot borrow tenant reference from this address")
    let saleItems = tenantRef.getSaleItems()
    return TenantSaleItems(findSaleItems: saleItems["findSaleItems"]! ,
                           tenantSaleItems: saleItems["tenantSaleItems"]! ,
                           findCuts: saleItems["findCuts"]! )

}

pub struct TenantSaleItems {
    pub let findSaleItems : {String : FindMarketTenant.TenantSaleItem}
    pub let tenantSaleItems : {String : FindMarketTenant.TenantSaleItem}
    pub let findCuts : {String : FindMarketTenant.TenantSaleItem} 

    init(findSaleItems : {String : FindMarketTenant.TenantSaleItem}, 
         tenantSaleItems : {String : FindMarketTenant.TenantSaleItem},
         findCuts : {String : FindMarketTenant.TenantSaleItem}) {
             self.findSaleItems = findSaleItems
             self.tenantSaleItems = tenantSaleItems 
             self.findCuts = findCuts 
         }
}