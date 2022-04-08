package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"

	"github.com/bjartek/overflow/overflow"
	"github.com/meirf/gopart"
)

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
		name := row[0]
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

	o := overflow.NewOverflowMainnet().Start()

	names := readCsvFile("names.txt")
	fmt.Printf("Names is %d long", len(names))

	reservations := readCsvFile(file)
	fmt.Printf("Reservation is %d long", len(reservations))

	var filtered []string
	for _, value := range reservations {
		skip := false
		for _, name := range names {
			if value == name {
				skip = true
			}
		}

		if len(value) > 16 {
			skip = true
		}
		if skip {
			continue
		}
		filtered = append(filtered, value)
	}

	size := 50
	for idxRange := range gopart.Partition(len(filtered), size) {
		//run transaction against flow
		names := filtered[idxRange.Low:idxRange.High]
		o.TransactionFromFile("registerAdmin").
			SignProposeAndPayAs("find-admin").
			Args(o.Arguments().StringArray(names...).Account("find-admin")).
			RunPrintEventsFull()
	}
}
