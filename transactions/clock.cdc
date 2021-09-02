import FIND from "../contracts/FIND.cdc"

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!
		adminClient.advanceClock(clock)

	}
}
