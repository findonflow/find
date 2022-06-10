import Admin from "../contracts/Admin.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        self.adminRef.addForgeCapabilities(type: Type<@Dandy.ForgeMinter>().identifier, cap: Dandy.getForgeCapability())
    }
}
 