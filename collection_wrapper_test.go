package test_main

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestNewCollctionsWrapper(t *testing.T) {

	o := overflow.NewOverflowMainnet().Start()

	//	address := "0x886f3aeaf848c535" //bjartek
	address := "0x01d7e57aa5598e47"

	var items Items
	err := o.ScriptFromFile("mainnet_getCollections_old").Args(o.Arguments().String(address)).RunMarshalAs(&items)
	assert.NoError(t, err)

	oldData := map[string]Item{}

	for _, value := range items.Items {
		oldData[fmt.Sprintf("%s-%s", value.ID, value.Name)] = value
	}

	value, err := o.ScriptFromFile("mainnet_getNFTIds").Args(o.Arguments().String(address)).RunReturns()
	if err != nil {
		panic(err)
	}

	var newItems []Item
	newData := map[string]Item{}
	err = o.ScriptFromFile("mainnet_getNFTs").Args(o.Arguments().RawAccount(address).Argument(value)).RunMarshalAs(&newItems)
	assert.NoError(t, err)
	for _, value := range newItems {
		newData[fmt.Sprintf("%s-%s", value.ID, value.Name)] = value
	}

	oldJson, _ := json.MarshalIndent(oldData, "", "   ")
	newJson, _ := json.MarshalIndent(newData, "", "   ")
	assert.JSONEq(t, string(oldJson), string(newJson))
}

type Item struct {
	ContentType string `json:"contentType"`
	ID          string `json:"id"`
	Image       string `json:"image"`
	ListPrice   string `json:"listPrice"`
	ListToken   string `json:"listToken"`
	Name        string `json:"name"`
	Rarity      string `json:"rarity"`
	URL         string `json:"url"`
}
type Items struct {
	Items map[string]Item `json:"items"`
}
