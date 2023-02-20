import FIND from "../contracts/FIND.cdc"

 pub fun main(address: String, index: Int): [StoragePath] {
    let account = getAuthAccount(FIND.resolve(address)!)
    return account.storagePaths
  }
