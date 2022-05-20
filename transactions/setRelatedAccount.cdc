import RelatedAccounts from "../contracts/RelatedAccounts.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String, target: String) {
	prepare(account: AuthAccount) {

		let resolveAddress = FIND.resolve(target)
		if resolveAddress == nil {panic("The input pass in is not a valid name or address. Input : ".concat(target))}
		let address = resolveAddress!
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

