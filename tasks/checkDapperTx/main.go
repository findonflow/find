package main

import (
	"bytes"
	"fmt"
	"os"
	"strings"

	"github.com/onflow/flow-go/utils/io"
)

func main() {

	network := os.Getenv("FLOW_NETWORK")
	path := os.Getenv("FOLDER_PATH")
	folder := fmt.Sprintf("./dapper-tx/%s", network)
	inUseFolder := path

	fmt.Printf("========================Running on network : %s=======================\n", network)
	fmt.Println()
	files, err := ReadFiles(folder)
	if err != nil {
		panic(err)
	}

	filesInUse, err := ReadFiles(inUseFolder)
	if err != nil {
		panic(err)
	}
	fmt.Println("========================Transactions to be Uploaded========================")
	var count int = 0
	for name, file := range files {
		if !Compare(file, filesInUse) {
			fmt.Printf("%s\n", name)
			count++
		}
	}
	if count == 0 {
		fmt.Println("Nil")

	}
	fmt.Println()
	fmt.Println()
	fmt.Println("========================Transactions to be Updated=========================")
	count = 0
	for name, file := range filesInUse {

		if !Compare(file, files) {
			fmt.Printf("%s\n", name)
		}
	}
	if count == 0 {
		fmt.Println("Nil")

	}
	fmt.Println()
	fmt.Println()
}

func Compare(file []byte, list map[string][]byte) bool {

	for _, target := range list {
		if bytes.Equal(file, target) {
			return true
		}
	}
	return false

}

func ReadFiles(path string) (map[string][]byte, error) {

	entries, err := os.ReadDir(path)
	if err != nil {
		fmt.Printf("error reading folder in path %s \n", path)
		fmt.Println(err)
		return nil, err
	}

	files := map[string][]byte{}
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), "getMetadata") {
			continue
		}
		cadenceFile, err := io.ReadFile(fmt.Sprintf("%s/%s", path, e.Name()))
		if err != nil {
			fmt.Printf("error reading %s/%s file \n", path, e.Name())
			fmt.Println(err)
			continue
		}
		files[e.Name()] = cadenceFile
	}
	return files, nil
}
