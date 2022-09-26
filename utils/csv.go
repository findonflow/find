package utils

import (
	"io"
	"os"
	"strconv"
	"strings"

	csvmap "github.com/recursionpharma/go-csv-map"
)

// / Read a filename.csv as a map of id field to propertyBag
func ReadCsvAsMapGroupOnKeyFromFile(fileName string, keyField string) (map[uint64]map[string]string, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}

	res, err := ReadCsvAsMapGroupOnKey(f, keyField)
	if err != nil {
		return res, err
	}
	return res, nil
}

// / Read a io.Reader as a map of id field to propertyBag
func ReadCsvAsMapGroupOnKey(input io.Reader, keyField string) (map[uint64]map[string]string, error) {
	reader := csvmap.NewReader(input)
	var err error
	reader.Columns, err = reader.ReadHeader()
	if err != nil {
		return nil, err
	}
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	dicts := map[uint64]map[string]string{}
	for _, record := range records {

		dictID := record[keyField]
		id, err := strconv.ParseUint(dictID, 10, 64)
		if err != nil {
			return dicts, err
		}
		delete(record, keyField)
		dicts[id] = record
	}
	return dicts, nil
}

func ReadCsv(fileName string) (map[uint64]map[string]map[string]string, error) {

	traits := []string{
		"Background",
		"Clothes",
		"Ear",
		"Eyes",
		"Glasses",
		"Head",
		"Mouth",
		"Neck",
		"Skins",
	}

	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}

	reader := csvmap.NewReader(f)
	reader.Columns, err = reader.ReadHeader()
	if err != nil {
		return nil, err
	}
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	dicts := map[uint64]map[string]map[string]string{}
	for i, record := range records {
		item := map[string]map[string]string{}
		for _, trait := range traits {
			if record["Item/"+trait+" Rarity"] == "" {
				continue
			}

			if item[trait] == nil {
				item[trait] = map[string]string{}
			}

			item[trait]["rarity"] = record["Item/"+trait+" Rarity"]
			item[trait]["value"] = record["Item/"+trait+" Rarity Value"]
			item[trait]["name"] = trait
		}

		if item["name"] == nil {
			item["name"] = map[string]string{}
		}

		item["name"]["name"] = strings.ToLower(record["Item/Name"])

		if item["externalURL"] == nil {
			item["externalURL"] = map[string]string{}
		}

		item["externalURL"]["name"] = strings.ToLower(record["Item/External URL"])

		if record["Item/Series Name"] != "" {

			if item["series"] == nil {
				item["series"] = map[string]string{}
			}

			item["series"]["name"] = "series_" + record["Item/Series Name"]
			item["series"]["value"] = record["Item/Series Value"]
		}

		dicts[uint64(i+1)] = item
	}
	return dicts, nil

}
