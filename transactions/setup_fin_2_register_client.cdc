
import NonFungibleToken, Content, FIN from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79


//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{FIN.AdminClient}>(FIN.AdminClientPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let admin=account.getCapability<&FIN.Administrator>(FIN.AdministratorPrivatePath)
        client.addCapability(admin)

    }
}
 