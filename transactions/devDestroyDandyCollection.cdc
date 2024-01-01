import Dandy from "../contracts/Dandy.cdc"


transaction() {
    prepare(account: auth(LoadValue) &Account) {
        destroy account.storage.load<@Dandy.Collection>(from: Dandy.CollectionStoragePath)
    }
}
