import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import NeoVoucher from 0xd6b39e5b5b367aad
import NeoAvatar from 0xd6b39e5b5b367aad
import NeoMember from 0xd6b39e5b5b367aad
import NeoSticker from 0xd6b39e5b5b367aad
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"


transaction(){
    prepare(account: AuthAccount){
        let path = FindMarketTenant.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarketTenant.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.setMarketOption(name:"FlowNeo", cut: nil, rules:[
            FindMarketTenant.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarketTenant.TenantRule(name:"Neo", types:[
								Type<@NeoVoucher.NFT>(), 
								Type<@NeoSticker.NFT>(),
								Type<@NeoMember.NFT>(),
								Type<@NeoAvatar.NFT>(),
								Type<@NeoSticker.NFT>()], 
						ruleType: "nft", allow: true)
            ]
        )
    }
}
