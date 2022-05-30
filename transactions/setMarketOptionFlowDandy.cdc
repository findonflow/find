import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.setMarketOption(name:"FlowDandy", cut: nil, rules:[
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Dandy", types:[ Type<@Dandy.NFT>()],
						ruleType: "nft", allow: true)
            ]
        )
    }
}
