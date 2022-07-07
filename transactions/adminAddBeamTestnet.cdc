import Admin from "../contracts/Admin.cdc"
// import Beam from 0x6085ae87e78e1433
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(tenant:Address) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        let nftType = CompositeType("A.6085ae87e78e1433.Beam.NFT")!
        self.adminRef.setNFTInfo(alias: "Beam", type: nftType, icon: "https://frightclub.niftory.com/fc_black_logo_round.svg", providerPath: /private/BeamCollection001, publicPath: /public/BeamCollection001, storagePath: /storage/BeamCollection001, allowedFTTypes: nil, address: 0x6085ae87e78e1433, externalFixedUrl: "frightclub.niftory.com")

        let rules = [
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Beam", types:[nftType], ruleType: "nft", allow: true)
        ]

        let tenantSaleItem = FindMarket.TenantSaleItem(
            name: "FlowBeam", 
            cut: nil, 
            rules: rules, 
            status:"active"
        )

        self.adminRef.setMarketOption(tenant: tenant, saleItem: tenantSaleItem)
 
    }
}
