import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import NeoVoucher from 0xd6b39e5b5b367aad


transaction(tenant: Address){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<&Admin.FindMarketAdmin>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let saleItem = FindMarket.TenantSaleItem(name:"FlowNeo", cut: nil, rules:[
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Neo", types:[ Type<@NeoVoucher.NFT>()], ruleType: "nft", allow: true)
            ],
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: saleItem)
    }
}
