import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

pub fun main(name: String) :  &{Profile.Public}? {
    return FIND.lookup(name)
}
