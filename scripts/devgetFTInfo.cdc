import "FTRegistry"

access(all) fun main(aliasOrIdentifier: String) : FTRegistry.FTInfo?{

    return FTRegistry.getFTInfo(aliasOrIdentifier)

}
