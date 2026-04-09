package helpers

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
)

var ssmClient *ssm.Client

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
	if ssmClient == nil {
		cfg, err := config.LoadDefaultConfig(context.Background())
		if err != nil {
			return "", fmt.Errorf("loading AWS config: %w", err)
		}
		ssmClient = ssm.NewFromConfig(cfg)
	}

	name := fmt.Sprintf("/%s/%s", service, key)
	out, err := ssmClient.GetParameter(context.Background(), &ssm.GetParameterInput{
		Name:           aws.String(name),
		WithDecryption: aws.Bool(true),
	})
	if err != nil {
		return "", err
	}

	return aws.ToString(out.Parameter.Value), nil
}
