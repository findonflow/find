
import "../contracts/FiNS.cdc"

//set up the adminClient in the contract that will own the network
transaction() {

    prepare(account: AuthAccount) {

        account.save(<- FiNS.createAdminProxyClient(), to:FiNS.AdminProxyStoragePath)
        account.link<&{FiNS.AdminProxyClient}>(FiNS.AdminProxyPublicPath, target: FiNS.AdminProxyStoragePath)


    }
}
