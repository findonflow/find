
//emulator
import NonFungibleToken, Content, FIN from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

transaction(tag: String) {

    prepare(account: AuthAccount) {


        log("STATUS PRE")
        log(FIN.status(tag))

        //this could probably just be a transaction of their own
        let vault=account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let profile <- Content.createContent("Test") as! @NonFungibleToken.NFT
        let identity  <- FIN.createIdentity(profile: <- profile, vault: vault)

        account.save(<-identity, to: /storage/finProfile)
        account.link<&{FIN.PublicIdentity}>( /public/finProfile, target: /storage/finProfile)

        let profileCap = account.getCapability<&{FIN.PublicIdentity}>(/public/finProfile)


        let price=FIN.calculateCost(tag)
        log("The cost for registering this tag is ".concat(price.toString()))

        let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow reference to the owner's Vault!")
        let payVault <- vaultRef.withdraw(amount: price)

        FIN.register(tag: tag, vault: <- payVault, profile: profileCap)

        log("STATUS POST")
        log(FIN.status(tag))

        let nft=FIN.lookup(tag)?.borrowNFT()!  
        log("CONTENT IS ".concat(nft.content))
    }

}
 