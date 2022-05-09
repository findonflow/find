import RelatedAccounts from "../contracts/RelatedAccounts.cdc"


transaction(name: String, address: Address) {
	prepare(account: AuthAccount) {

		let cap = account.getCapability<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath)
		if !cap.check() {
			let relatedAccounts <- RelatedAccounts.createEmptyAccounts()
			account.save(<- relatedAccounts, to: RelatedAccounts.storagePath)
			account.link<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath, target: RelatedAccounts.storagePath)
		}

		let relatedAccounts =account.borrow<&RelatedAccounts.Accounts>(from:RelatedAccounts.storagePath)!
		relatedAccounts.setFlowAccount(name: name, address: address)
	}
}

