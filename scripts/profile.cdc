import Profile from "../contracts/Profile.cdc"
pub fun main(address:Address) : Profile.UserProfile? {
  return getAccount(address)
        .getCapability<&{Profile.Public}>(Profile.publicPath)
        .borrow()?.asProfile()
}
