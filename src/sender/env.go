package main

import (
	"github.com/keighl/postmark"
	"github.com/sjauld/roy-spf/src/helpers"
)

var (
	// If testing, we'll skip all of this
	testMode = false
)

func init() {
	if testMode {
		return
	}

	encryptionSecret = helpers.MustReadSSMSecret("roy-spf-sender", "encryption-secret")
	trackerBaseURL = helpers.MustReadURLEnv("TRACKER_BASE_URL")

	mailerClient = postmark.NewClient(
		helpers.MustReadSSMSecret("roy-spf-sender", "postmark-server-token"),
		"",
	)
}
