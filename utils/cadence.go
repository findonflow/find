package utils

import (
	"encoding/json"
	"io/ioutil"
	"strconv"

	"github.com/onflow/cadence"
)

type TraitList struct {
	Background uint64 `json:"Background"`
	Clothes    uint64 `json:"Clothes"`
	Eyes       uint64 `json:"Eyes"`
	Head       uint64 `json:"Head"`
	Mouth      uint64 `json:"Mouth"`
	Skins      uint64 `json:"Skins"`
	Series     uint64 `json:"series"`
}

type Trait struct {
	DisplayType       string `json:"display_type"`
	Name              string `json:"name"`
	RarityDescription string `json:"rarity_description"`
	RarityMax         string `json:"rarity_max"`
	RarityScore       string `json:"rarity_score"`
	Value             string `json:"value"`
}

func GetTraitFromCsvInCadenceDictionary() (*cadence.Dictionary, *cadence.Dictionary, *cadence.Dictionary, *cadence.Dictionary, *cadence.Dictionary) {

	file, _ := ioutil.ReadFile("flomies_traits.json")

	data := map[string]Trait{}

	_ = json.Unmarshal([]byte(file), &data)

	nameMap := map[string]string{}
	valueMap := map[string]string{}
	scoreMap := map[string]string{}
	maxMap := map[string]string{}
	descriptionMap := map[string]string{}
	for i, d := range data {
		nameMap[i] = d.Name
		valueMap[i] = d.Value
		scoreMap[i] = d.Name
		maxMap[i] = d.RarityScore
		descriptionMap[i] = d.RarityDescription
	}

	name, err := CreateTraitCadenceDictionary(nameMap)
	if err != nil {
		panic(err)
	}
	value, err := CreateTraitCadenceDictionary(valueMap)
	if err != nil {
		panic(err)
	}
	score, err := CreateTraitCadenceDictionary(scoreMap)
	if err != nil {
		panic(err)
	}
	max, err := CreateTraitCadenceDictionary(maxMap)
	if err != nil {
		panic(err)
	}
	description, err := CreateTraitCadenceDictionary(descriptionMap)
	if err != nil {
		panic(err)
	}

	return name, value, score, max, description
}

func GetNFTTraitListFromCsvInCadenceDictionary(numberOfSlices, slice int) cadence.Dictionary {

	file, _ := ioutil.ReadFile("flomies_trait_list.json") // <- 3333

	data := map[string]TraitList{}

	_ = json.Unmarshal([]byte(file), &data)

	mod := len(data) % numberOfSlices
	numberPerInterval := (len(data) - mod) / numberOfSlices
	endsAt := numberPerInterval * slice
	if numberOfSlices == slice {
		endsAt = endsAt + mod
	}
	startFrom := endsAt - numberPerInterval + 1

	traitListMap := map[uint64][]uint64{}
	for i, d := range data {

		integer, _ := strconv.ParseUint(i, 10, 64)
		if integer < uint64(startFrom) || integer > uint64(endsAt) {
			continue
		}

		list := []uint64{}
		if d.Background != 0 {
			list = append(list, d.Background)
		}
		if d.Clothes != 0 {
			list = append(list, d.Clothes)
		}
		if d.Eyes != 0 {
			list = append(list, d.Eyes)
		}
		if d.Head != 0 {
			list = append(list, d.Head)
		}
		if d.Mouth != 0 {
			list = append(list, d.Mouth)
		}
		if d.Series != 0 {
			list = append(list, d.Series)
		}
		if d.Skins != 0 {
			list = append(list, d.Skins)
		}
		traitListMap[integer] = list
	}

	res, _ := CreateTraitListCadenceDictionary(traitListMap)
	return res
}

func CreateTraitCadenceDictionary(input map[string]string) (*cadence.Dictionary, error) {
	array := []cadence.KeyValuePair{}
	for key, val := range input {
		integer, _ := strconv.ParseInt(key, 10, 64)
		integerKey := cadence.NewInt(int(integer))
		stringVal, err := cadence.NewString(val)
		if err != nil {
			return nil, err
		}
		array = append(array, cadence.KeyValuePair{Key: integerKey, Value: stringVal})
	}
	dict := cadence.NewDictionary(array)
	return &dict, nil
}

func CreateTraitListCadenceDictionary(input map[uint64][]uint64) (cadence.Dictionary, error) {
	array := []cadence.KeyValuePair{}
	for key, vals := range input {
		integerKey := cadence.NewUInt64(key)
		arr := []cadence.Value{}
		for _, value := range vals {
			uint64Val := cadence.NewUInt64(value)
			arr = append(arr, uint64Val)
		}
		arrVal := cadence.NewArray(arr)

		array = append(array, cadence.KeyValuePair{Key: integerKey, Value: arrVal})
	}
	dict := cadence.NewDictionary(array)
	return dict, nil
}

// TODO: move to overflow?
func CreateCadenceDictionary(input map[string]string) (*cadence.Dictionary, error) {
	array := []cadence.KeyValuePair{}
	for key, val := range input {
		stringVal, err := cadence.NewString(val)
		if err != nil {
			return nil, err
		}
		stringKey, err := cadence.NewString(key)
		if err != nil {
			return nil, err
		}
		array = append(array, cadence.KeyValuePair{Key: stringKey, Value: stringVal})
	}
	dict := cadence.NewDictionary(array)
	return &dict, nil
}

// A Metadata csv field is a excel/csv file that has one field that should be key and the others should be values, this method will return a map of rowKey -> { columHeader : rowValue}
func ReadMetadataCsvFileAsCadenceDict(filename, keyField string) (*cadence.Dictionary, error) {
	data, err := ReadCsvAsMapGroupOnKeyFromFile(filename, keyField)
	if err != nil {
		return nil, err
	}

	var dataValues []cadence.KeyValuePair
	for key, value := range data {

		dict, err := CreateCadenceDictionary(value)
		if err != nil {
			return nil, err
		}

		dataValues = append(dataValues, cadence.KeyValuePair{
			Key:   cadence.NewUInt64(key),
			Value: *dict,
		})
	}
	dataDict := cadence.NewDictionary(dataValues)
	return &dataDict, nil
}
