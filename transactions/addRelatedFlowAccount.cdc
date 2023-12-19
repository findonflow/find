import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

transaction(name: String, address: Address) {

	var relatedAccounts : &FindRelatedAccounts.Accounts?

	prepare(account: auth(BorrowValue) &Account) {

		self.relatedAccounts= account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
		if self.relatedAccounts == nil {
			let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
			account.storage.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
			account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
			self.relatedAccounts = account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
		}

		let cap = account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
		if !cap.check() {
			account.unlink(FindRelatedAccounts.publicPath)
			account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
		}
	}

	execute {
		self.relatedAccounts!.addFlowAccount(name:name, address: address)
	}

}
