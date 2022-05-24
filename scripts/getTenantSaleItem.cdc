import FindMarket from "../contracts/FindMarket.cdc"

pub fun main(tenant: Address) : TenantSaleItems {
    let tenantCap = FindMarket.getTenantCapability(tenant) ?? panic("No tenant capability is set up for this address")
    let tenantRef = tenantCap.borrow() ?? panic("Cannot borrow tenant reference from this address")
    let saleItems = tenantRef.getSaleItems()
    return TenantSaleItems(findSaleItems: saleItems["findSaleItems"]! ,
                           tenantSaleItems: saleItems["tenantSaleItems"]! ,
                           findCuts: saleItems["findCuts"]! )

}

pub struct TenantSaleItems {
    pub let findSaleItems : {String : FindMarket.TenantSaleItem}
    pub let tenantSaleItems : {String : FindMarket.TenantSaleItem}
    pub let findCuts : {String : FindMarket.TenantSaleItem} 

    init(findSaleItems : {String : FindMarket.TenantSaleItem}, 
         tenantSaleItems : {String : FindMarket.TenantSaleItem},
         findCuts : {String : FindMarket.TenantSaleItem}) {
             self.findSaleItems = findSaleItems
             self.tenantSaleItems = tenantSaleItems 
             self.findCuts = findCuts 
         }
}