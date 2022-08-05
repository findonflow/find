import Admin from "../contracts/Admin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(tenant: Address, ftName: String, ftTypes: [String] , nftName: String, nftTypes: [String], listingName: String, listingTypes: [String]) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{

        let ft : [Type] = []
        for type in ftTypes {
            ft.append(CompositeType(type)!)
        }

        let nft : [Type] = []
        for type in nftTypes {
            nft.append(CompositeType(type)!)
        }

        let listing : [Type] = []
        for type in listingTypes {
            listing.append(CompositeType(type)!)
        }

        let rules = [
            FindMarket.TenantRule(name:listingName, types:listing, ruleType: "listing", allow: true), 
            FindMarket.TenantRule(name:ftName, types:ft, ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:nftName, types:nft, ruleType: "nft", allow: true)
        ]

        let tenantSaleItem = FindMarket.TenantSaleItem(
            name: listingName.concat(ftName).concat(nftName), 
            cut: nil, 
            rules: rules, 
            status:"active"
        )

        self.adminRef.setMarketOption(tenant: tenant, saleItem: tenantSaleItem)
        
    }
}
