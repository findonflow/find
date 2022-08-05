import Admin from "../contracts/Admin.cdc"
import Art from 0x99ca04281098b33d
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(tenant: Address) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        self.adminRef.setNFTInfo(
            alias: "Versus", 
            type: Type<@Art.NFT>(), 
            icon: "https://global-uploads.webflow.com/60f008ba9757da0940af288e/60f02cad72175a774926125f_flow%20versus%20twitter%20lgoo.jpg",
            providerPath: /private/versusArtCollection,
            publicPath: Art.CollectionPublicPath, 
            storagePath: Art.CollectionStoragePath, 
            allowedFTTypes: nil, 
						address:0x99ca04281098b33d, externalFixedUrl: "https://versus.auction")

        let rules = [
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Versus", types:[Type<@Art.NFT>()], ruleType: "nft", allow: true)
        ]

        let tenantSaleItem = FindMarket.TenantSaleItem(
            name: "FlowVersus", 
            cut: nil, 
            rules: rules, 
            status:"active"
        )

        self.adminRef.setMarketOption(tenant: tenant, saleItem: tenantSaleItem)
    }
}
