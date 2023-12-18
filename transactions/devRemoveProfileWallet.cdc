import Profile from "../contracts/Profile.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		let wallet = account.borrow<&Profile.User>(from: Profile.storagePath)! 
		wallet.removeWallet("Flow")
		wallet.removeWallet("FUSD")
		wallet.removeWallet("USDC")
	}
}
