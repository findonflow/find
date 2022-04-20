import FindMarket from "../contracts/FindMarket.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(owner: Address, id: UInt64, amount: UFix64) {
	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let bids= account.borrow<&FindMarket.MarketBidCollection>(from: tenant.information.bidStoragePath)!

		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the flowTokenVault!")
		let vault <- vaultRef.withdraw(amount: amount) 

		bids.fulfillAuction(id:id, vault: <- vault)
	}
}
