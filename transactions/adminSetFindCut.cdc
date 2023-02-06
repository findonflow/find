import Admin from "../contracts/Admin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(tenant: Address, cut: UFix64){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let defaultRules : [FindMarket.TenantRule] = [
			FindMarket.TenantRule(
				name: "standardFT",
				types:[Type<@FlowToken.Vault>(), Type<@FUSD.Vault>(), Type<@FiatToken.Vault>(), Type<@DapperUtilityCoin.Vault>(), Type<@FlowUtilityToken.Vault>()],
				ruleType: "ft",
				allow:true
			)
		]

		let royalty = MetadataViews.Royalty(
			receiver: adminRef.getSwitchboardReceiverPublic(),
			cut: cut,
			description: "find"
		)

		let saleItem = FindMarket.TenantSaleItem(
			name: "findRoyalty",
			cut: royalty,
			rules: defaultRules,
			status: "active"
		)

        adminRef.setFindCut(tenant: tenant, saleItem:saleItem)
    }
}

