import FindMarket from "../contracts/FindMarket.cdc"

access(all) fun main(tenant: Address) : TenantSaleItems {
    let tenantCap = FindMarket.getTenantCapability(tenant) ?? panic("No tenant capability is set up. Tenant Address : ".concat(tenant.toString()))
    let tenantRef = tenantCap.borrow() ?? panic("Cannot borrow tenant reference. Tenant Address : ".concat(tenant.toString()))
    let saleItems = tenantRef.getSaleItems()
    return TenantSaleItems(findSaleItems: saleItems["findSaleItems"]! ,
                           tenantSaleItems: saleItems["tenantSaleItems"]! ,
                           findCuts: saleItems["findCuts"]! )

}

access(all) struct TenantSaleItems {
    access(all) let findSaleItems : {String : FindMarket.TenantSaleItem}
    access(all) let tenantSaleItems : {String : FindMarket.TenantSaleItem}
    access(all) let findCuts : {String : FindMarket.TenantSaleItem} 

    init(findSaleItems : {String : FindMarket.TenantSaleItem}, 
         tenantSaleItems : {String : FindMarket.TenantSaleItem},
         findCuts : {String : FindMarket.TenantSaleItem}) {
             self.findSaleItems = findSaleItems
             self.tenantSaleItems = tenantSaleItems 
             self.findCuts = findCuts 
         }
}