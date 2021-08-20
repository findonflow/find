import FiNS from "../contracts/FiNS.cdc"
import Profile from "../contracts/Profile.cdc"

//Check the status of a fin user
pub fun main(tag: String) :  &{Profile.Public}? {
    return FiNS.lookup(tag)
}
