import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

transaction() {

	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
		if relatedAccounts == nil {
			let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
			account.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
			account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
		}

		let cap = account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
		if !cap.check() {
			account.unlink(FindRelatedAccounts.publicPath)
			account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
		}
	}

}
