import "FindMarket"
import "FlowToken"
import "FUSD"
import "Dandy"

transaction(){
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.setMarketOption(name:"FUSDDandy", cut: nil, rules:[
            FindMarket.TenantRule(name:"FUSD", types:[Type<@FUSD.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Dandy", types:[ Type<@Dandy.NFT>()], ruleType: "nft", allow: true)
            ]
        )

        tenantRef.setMarketOption(name:"FlowDandy", cut: nil, rules:[
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Dandy", types:[ Type<@Dandy.NFT>()], ruleType: "nft", allow: true)
            ]
        )

    }
}
