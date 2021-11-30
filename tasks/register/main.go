package main

//TODO: send mail https://medium.com/vacatronics/how-to-use-gmail-with-go-c980295c23b8

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/meirf/gopart"
	"github.com/onflow/cadence"
)

func readCsvFile2(filePath string) ([]string, []string) {
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

	duplicates := map[string]bool{}
	results := map[string]bool{}
	for i, row := range records {
		if i == 0 {
			continue
		}
		name := row[3]
		_, isDuplicate := duplicates[name]
		if isDuplicate {
			continue
		}
		_, exists := results[name]
		if exists {
			delete(results, name)
			duplicates[name] = true
			continue
		}

		results[name] = true
	}

	resultSlice := make([]string, 0, len(results))
	for k := range results {
		resultSlice = append(resultSlice, k)
	}

	duplicateSlice := make([]string, 0, len(duplicates))
	for k := range duplicates {
		duplicateSlice = append(duplicateSlice, k)
	}

	return resultSlice, duplicateSlice
}

func readCsvFile(filePath string) []string {
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

	results := map[string]bool{}
	for i, row := range records {
		if i == 0 {
			continue
		}
		name := row[3]
		results[name] = true
	}

	resultSlice := make([]string, 0, len(results))
	for k := range results {
		resultSlice = append(resultSlice, k)
	}

	return resultSlice
}

func main() {

	file, ok := os.LookupEnv("file")
	if !ok {
		fmt.Println("file is not present")
		os.Exit(1)
	}

	//g := gwtf.NewGoWithTheFlowMainNet()
	g := gwtf.NewGoWithTheFlowDevNet()

	findLinks := cadence.NewArray([]cadence.Value{
		cadence.NewDictionary([]cadence.KeyValuePair{
			{Key: cadence.NewString("title"), Value: cadence.NewString("twitter")},
			{Key: cadence.NewString("type"), Value: cadence.NewString("twitter")},
			{Key: cadence.NewString("url"), Value: cadence.NewString("https://twitter.com/findonflow")},
		})})

	/*
		g.TransactionFromFile("createProfile").
			SignProposeAndPayAs("find-admin").
			StringArgument("ReservedNames").
			RunPrintEventsFull()
	*/

	g.TransactionFromFile("editProfile").
		SignProposeAndPayAs("find-admin").
		StringArgument("ReservedNames").
		StringArgument(`Reserved names:

1. add a direct offer for the apropriate price
2. ping a mod in find discord to have them approve

Prices:
 - 3 letter name  500 FUSD
 - 4 letter name  100 FUSD
 - 5+ letter name   5 FUSD
`).
		StringArgument("https://find.xyz/find.png").
		StringArrayArgument("find").
		BooleanArgument(false).
		Argument(findLinks).
		RunPrintEventsFull()

	reservations := readCsvFile(file)

	size := 5
	for idxRange := range gopart.Partition(len(reservations), size) {
		//run transaction against flow
		names := reservations[idxRange.Low:idxRange.High]
		g.TransactionFromFile("registerAdmin").
			SignProposeAndPayAs("find-admin").
			StringArrayArgument(names...).
			AccountArgument("find-admin").
			RunPrintEventsFull()
	}
}
