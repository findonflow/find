import Admin from "../contracts/Admin.cdc"
import Bl0x from 0xe8124d8428980aa6
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(tenant: Address) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        self.adminRef.setNFTInfo(
            alias: "Bl0x", 
            type: Type<@Bl0x.NFT>(), 
            icon: "https://global-uploads.webflow.com/60f008ba9757da0940af288e/626e4af22f80f09e2783df44_blox.jpg", 
            providerPath: Bl0x.CollectionPrivatePath, 
            publicPath: Bl0x.CollectionPublicPath, 
            storagePath: Bl0x.CollectionStoragePath, 
            allowedFTTypes: nil, 
            address:0xe8124d8428980aa6, externalFixedUrl: "bl0x-5ccsb92pb-findonflow.vercel.app")

        let rules = [
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Bl0x", types:[Type<@Bl0x.NFT>()], ruleType: "nft", allow: true)
        ]

        let tenantSaleItem = FindMarket.TenantSaleItem(
            name: "FlowBl0x", 
            cut: nil, 
            rules: rules, 
            status:"active"
        )

        self.adminRef.setMarketOption(tenant: tenant, saleItem: tenantSaleItem)
        
    }
}
