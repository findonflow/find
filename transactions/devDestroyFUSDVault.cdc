import "FUSD"

transaction() {
    prepare(account: auth(UnpublishCapability, LoadValue) &Account) {
        account.capabilities.unpublish(/public/fusdBalance)
        account.capabilities.unpublish(/public/fusdReceiver)
        destroy account.storage.load<@FUSD.Vault>(from: /storage/fusdVault) ?? panic("Cannot load flow token vault")
    }
}
