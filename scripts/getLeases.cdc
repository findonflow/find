import "FIND"

access(all)
fun main() : [FIND.NetworkLease] {
    return FIND.getLeases()
}
