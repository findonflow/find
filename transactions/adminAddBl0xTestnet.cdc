import Admin from "../contracts/Admin.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import Bl0x from 0xe8124d8428980aa6
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"


transaction() {

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

				self.adminRef.getFindMarketTenantClient().setMarketOption(
					name:"FlowBl0x", cut: nil, rules:[
            FindMarketTenant.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarketTenant.TenantRule(name:"Neo", types:[ Type<@Bl0x.NFT>()], ruleType: "nft", allow: true)
            ]
        )
    }
}
