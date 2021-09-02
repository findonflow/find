import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

//Check the status of a fin user
pub fun main(tag: String) :  &{Profile.Public}? {
    return FIND.lookup(tag)
}
