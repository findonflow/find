import FindMarket from "../contracts/FindMarket.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(owner: Address, id: UInt64, amount: UFix64) {
	prepare(account: AuthAccount) {
		let saleItems=FindMarket.getFindSaleItemCapability(owner)!.borrow()!

		let walletReference = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD wallet linked for this account")
		let vault <- walletReference.withdraw(amount: amount)
		saleItems.fulfillNonEscrowedAuction(id, vault: <- vault)
	}
}
