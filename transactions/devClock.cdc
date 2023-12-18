import "Admin"

transaction(clock: UFix64) {
    prepare(account: auth (BorrowValue) &Account) {

        let adminClient=account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
        adminClient.advanceClock(clock)

    }
}
