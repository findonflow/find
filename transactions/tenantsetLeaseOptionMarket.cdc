import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

transaction(nftName: String, nftType: String, cut: UFix64){
    prepare(account: AuthAccount){

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
                receiver: account.getCapability<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath),
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

        let clientRef = account.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setMarketOption(saleItem: saleItem)
    }
}

