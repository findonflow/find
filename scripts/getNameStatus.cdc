import "FIND"
import "Profile"

access(all)
fun main(name: String) :  &{Profile.Public}? {
    return FIND.lookup(name)
}
