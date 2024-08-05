import "FindMarket"
import "FlowToken"
import "FindLeaseMarketSale"
import "FindLeaseMarketAuctionSoft"
import "FindLeaseMarketDirectOfferSoft"
import "MetadataViews"
import "FungibleToken"
import "FungibleTokenSwitchboard"

transaction(nftName: String, nftType: String, cut: UFix64){
    prepare(account: auth(BorrowValue) &Account){

        let defaultRules : [FindMarket.TenantRule] = [
        FindMarket.TenantRule(
            name: "Flow",
            types:[Type<@FlowToken.Vault>()],
            ruleType: "ft",
            allow:true
        ),
        FindMarket.TenantRule(
            name: "Soft",
            types:[Type<@FindLeaseMarketSale.SaleItem>(),
            Type<@FindLeaseMarketAuctionSoft.SaleItem>(),
            Type<@FindLeaseMarketDirectOfferSoft.SaleItem>()
            ],
            ruleType: "listing",
            allow:true
        )
        ]

        defaultRules.append(
            FindMarket.TenantRule(
                name: nftName,
                types:[CompositeType(nftType)!],
                ruleType: "nft",
                allow:true
            )
        )

        var royalty : MetadataViews.Royalty? = nil
        if cut != 0.0 {
            royalty = MetadataViews.Royalty(
                receiver: account.capabilities.get<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath),
                cut: cut,
                description: "tenant"
            )
        }

        let saleItem = FindMarket.TenantSaleItem(
            name: "Flow".concat(nftName).concat("Soft"),
            cut: royalty,
            rules: defaultRules,
            status: "active"
        )

        let clientRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setMarketOption(saleItem: saleItem)
    }
}
