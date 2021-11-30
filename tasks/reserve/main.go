package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()

	//	g.ScriptFromFile("find-list").AccountArgument("user2").Run()
	//	os.Exit(0)

	//first step create the adminClient as the fin user
	g.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	g.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("find").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user1").
		StringArgument("User1").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAsService().
		StringArgument("Find").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		StringArgument("Find").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		AccountArgument("user1").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find").
		StringArrayArgument("test").
		AccountArgument("find").
		RunPrintEventsFull()

	g.TransactionFromFile("bid").
		SignProposeAndPayAs("user1").
		StringArgument("test").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	reservedNames := readNameAddresses("find.csv")
	//TODO: extract this into GWTF
	result := g.ScriptFromFile("reserveStatus").AccountArgument("find").RunReturnsJsonString()
	var bids []LeaseBids
	err := json.Unmarshal([]byte(result), &bids)
	if err != nil {
		panic(err)
	}

	for _, bid := range bids {
		reservedAddress, exist := reservedNames[bid.Name]
		if !exist {
			fmt.Sprintf("Name is not reserved %s\n", bid.Name)
			continue
		}

		if bid.LatestBidBy == reservedAddress {
			g.TransactionFromFile("fulfill").SignProposeAndPayAs("find").StringArgument(bid.Name).RunPrintEventsFull()
		} else {
			g.TransactionFromFile("rejectDirectOffer").SignProposeAndPayAs("find").StringArgument(bid.Name).RunPrintEventsFull()
		}
	}

	g.ScriptFromFile("name_status").StringArgument("test").Run()

}

type LeaseBids struct {
	Address     string `json:"address"`
	Cost        string `json:"cost"`
	LatestBid   string `json:"latestBid"`
	LatestBidBy string `json:"latestBidBy"`
	Name        string `json:"name"`
	Status      string `json:"status"`
}

func readNameAddresses(filePath string) map[string]string {
	f, err := os.Open(filePath)
	if err != nil {
		log.Fatal("Unable to read input file "+filePath, err)
	}
	defer f.Close()

	csvReader := csv.NewReader(f)
	records, err := csvReader.ReadAll()

	if err != nil {
		log.Fatal("Unable to parse file as CSV for "+filePath, err)
	}

	results := map[string]string{}
	for i, row := range records {
		if i == 0 {
			continue
		}
		results[row[3]] = row[2]
	}

	return results
}
