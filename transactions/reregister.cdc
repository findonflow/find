
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(tag: String) {

    prepare(account: AuthAccount) {


        let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)

        let price=FIND.calculateCost(tag)
        log("The cost for registering this tag is ".concat(price.toString()))

        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
        let payVault <- vaultRef.withdraw(amount: price)

        FIND.register(tag: tag, vault: <- payVault, profile: profileCap)

        log("STATUS POST")
        log(FIND.status(tag))

    }

}
 
