
import NonFungibleToken, Content, FIN from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

//set up the adminClient in the contract that will own the network
transaction() {

    prepare(account: AuthAccount) {

        account.save(<- FIN.createAdminClient(), to:FIN.AdminClientStoragePath)
        account.link<&{FIN.AdminClient}>(FIN.AdminClientPublicPath, target: FIN.AdminClientStoragePath)


    }
}
