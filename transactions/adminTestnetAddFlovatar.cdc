import Admin from "../contracts/Admin.cdc"
import Flovatar from 0x9392a4a7c3f49a0b
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(tenant:Address) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{

        self.adminRef.setNFTInfo(alias: "Flovatar", type: Type<@Flovatar.NFT>(), icon: "https://styles.redditmedia.com/t5_5ikf79/styles/communityIcon_fraplt3tgk681.jpg", providerPath: /private/FlovatarCollection, publicPath: Flovatar.CollectionPublicPath, storagePath: Flovatar.CollectionStoragePath, allowedFTTypes: nil, address: 0x9392a4a7c3f49a0b, externalFixedUrl: "flovatar.com")

        let rules = [
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Flovatar", types:[Type<@Flovatar.NFT>()], ruleType: "nft", allow: true)
        ]

        let tenantSaleItem = FindMarket.TenantSaleItem(
            name: "FlowFLovatar", 
            cut: nil, 
            rules: rules, 
            status:"active"
        )

        self.adminRef.setMarketOption(tenant: tenant, saleItem: tenantSaleItem)
 
    }
}
