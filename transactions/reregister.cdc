
//emulator
import NonFungibleToken, Content, FIN from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

transaction(tag: String) {

    prepare(account: AuthAccount) {


        let profileCap = account.getCapability<&{FIN.PublicIdentity}>(/public/finProfile)


        let price=FIN.calculateCost(tag)
        log("The cost for registering this tag is ".concat(price.toString()))

        let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow reference to the owner's Vault!")
        let payVault <- vaultRef.withdraw(amount: price)

        FIN.register(tag: tag, vault: <- payVault, profile: profileCap)

        log("STATUS POST")
        log(FIN.status(tag))

    }

}
 