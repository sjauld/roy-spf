package helpers

import (
	"fmt"
	"os"

	"github.com/segmentio/chamber/store"
)

const (
	chamberExpectedRegionEnv = "CHAMBER_AWS_REGION"
	chamberFallbackRegion    = "ap-southeast-2"

	ssmRetries = 3
)

var secretStore store.Store

// MustReadSSMSecret gets your secret out of SSM, or dies trying.
func MustReadSSMSecret(service, key string) string {
	s, err := ReadSSMSecret(service, key)
	if err != nil {
		panic(fmt.Sprintf("Could not read %v/%v: %v", service, key, err))
	}

	return s
}

// ReadSSMSecret attempts to get your secret out of SSM
func ReadSSMSecret(service, key string) (string, error) {
	setSecretStore()

	secretID := store.SecretId{
		Service: service,
		Key:     key,
	}
	// -1 gives the latest version of a secret
	val, err := secretStore.Read(secretID, -1)
	if err != nil {
		return "", err
	}
	return *val.Value, nil
}

func setSecretStore() {
	if secretStore != nil {
		return
	}

	trySetChamberAWSRegion()

	secretStore = store.NewSSMStore(ssmRetries)
}

func trySetChamberAWSRegion() {
	if _, ok := os.LookupEnv(chamberExpectedRegionEnv); ok {
		return
	}

	// Try copying from the environment
	if r, ok := os.LookupEnv("AWS_DEFAULT_REGION"); ok {
		os.Setenv(chamberExpectedRegionEnv, r)
		return
	}
	if r, ok := os.LookupEnv("AWS_REGION"); ok {
		os.Setenv(chamberExpectedRegionEnv, r)
		return
	}
	if r, ok := os.LookupEnv("CHAMBER_REGION"); ok {
		os.Setenv(chamberExpectedRegionEnv, r)
		return
	}
	os.Setenv(chamberExpectedRegionEnv, chamberFallbackRegion)
}
