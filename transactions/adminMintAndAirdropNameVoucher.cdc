
import Admin from "../contracts/Admin.cdc"
import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(users: [Address], minCharLength: UInt64) {

	prepare(admin:AuthAccount) {

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		let vaultRef = admin.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
		let paymentVault <- vaultRef.withdraw(amount: 0.01 * UFix64(users.length))
		let repayment = admin.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

		let paymentVaultRef = &paymentVault as &FungibleToken.Vault
		for user in users {
			client.mintAndAirdropNameVoucher(
				receiver: user,
				minCharLength: minCharLength,
				storagePayment: paymentVaultRef,
				repayment: repayment)
		}

		vaultRef.deposit(from: <- paymentVault)

	}

}
