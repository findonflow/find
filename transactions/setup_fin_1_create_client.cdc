
import "../contracts/FIN.cdc"

//set up the adminClient in the contract that will own the network
transaction() {

    prepare(account: AuthAccount) {

        account.save(<- FIN.createAdminProxyClient(), to:FIN.AdminProxyStoragePath)
        account.link<&{FIN.AdminProxyClient}>(FIN.AdminProxyPublicPath, target: FIN.AdminProxyStoragePath)


    }
}
