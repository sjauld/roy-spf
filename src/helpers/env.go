package helpers

import (
	"log"
	"net/url"
	"os"
)

func MustReadStringEnv(env string) string {
	v, ok := os.LookupEnv(env)

	if !ok {
		log.Fatalf("You must set %v in your environment", env)
	}
	return v
}

func MustReadURLEnv(env string) *url.URL {
	s := MustReadStringEnv(env)

	u, err := url.Parse(s)
	if err != nil {
		log.Fatalf("Your %v URL is invalid: %v", env, err)
	}
	return u
}
