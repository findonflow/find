import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

access(all)
fun main(name: String) :  &{Profile.Public}? {
    return FIND.lookup(name)
}
