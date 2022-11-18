import Admin from "../contracts/Admin.cdc"

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		adminClient.advanceClock(clock)

	}
}
