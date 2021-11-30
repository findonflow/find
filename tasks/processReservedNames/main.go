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

	file, ok := os.LookupEnv("file")
	if !ok {
		fmt.Println("file is not present")
		os.Exit(1)
	}

	g := gwtf.NewGoWithTheFlowEmulator()

	reservedNames := readNameAddresses(file)
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
