
import "../contracts/FIND.cdc"

//set up the adminClient in the contract that will own the network
transaction() {

    prepare(account: AuthAccount) {

        account.save(<- FIND.createAdminProxyClient(), to:FIND.AdminProxyStoragePath)
        account.link<&{FIND.AdminProxyClient}>(FIND.AdminProxyPublicPath, target: FIND.AdminProxyStoragePath)


    }
}
