import "Dandy"


transaction() {
    prepare(account: auth(LoadValue) &Account) {
        destroy account.storage.load<@Dandy.Collection>(from: Dandy.CollectionStoragePath)
    }
}
