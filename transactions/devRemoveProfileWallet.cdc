import Profile from "../contracts/Profile.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		let wallet = account.storage.borrow<&Profile.User>(from: Profile.storagePath)! 
		wallet.removeWallet("Flow")
		wallet.removeWallet("FUSD")
		wallet.removeWallet("USDC")
	}
}
