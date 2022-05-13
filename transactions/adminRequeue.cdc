import Admin from "../contracts/Admin.cdc"

/// @param packId: The id of the pack to requeue
transaction(packId:UInt64) {

	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		adminClient.requeue(packId: packId)
	}

}
