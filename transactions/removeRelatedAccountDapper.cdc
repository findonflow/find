import RelatedAccounts from "../contracts/RelatedAccounts.cdc"

transaction(name: String){

	var relatedAccounts : &RelatedAccounts.Accounts?

	prepare(account: AuthAccount) {

		self.relatedAccounts= account.borrow<&RelatedAccounts.Accounts>(from:RelatedAccounts.storagePath)
		if self.relatedAccounts == nil {
			let relatedAccounts <- RelatedAccounts.createEmptyAccounts()
			account.save(<- relatedAccounts, to: RelatedAccounts.storagePath)
			account.link<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath, target: RelatedAccounts.storagePath)
			self.relatedAccounts= account.borrow<&RelatedAccounts.Accounts>(from:RelatedAccounts.storagePath)
		}

		let cap = account.getCapability<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath)
		if !cap.check() {
			account.unlink(RelatedAccounts.publicPath)
			account.link<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath, target: RelatedAccounts.storagePath)
		}

	}

	execute{
		self.relatedAccounts!.deleteAccount(name: name)
	}
}

