package helpers

import (
	"fmt"

	"github.com/aws/aws-lambda-go/events"
)

var ResponseHeaders = map[string]string{
	"Access-Control-Allow-Origin": "*",
	"Content-Type":                "application/json",
}

func ResponseBadRequest() (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode:      400,
		Headers:         ResponseHeaders,
		Body:            `{"status":"error", "error": "malformed request"}`,
		IsBase64Encoded: false,
	}, nil
}

func ResponseNotImplemented() (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode:      501,
		Headers:         ResponseHeaders,
		Body:            `{"status":"error","error":"not implemented"}`,
		IsBase64Encoded: false,
	}, nil
}

func ResponseOK() (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode:      200,
		Headers:         ResponseHeaders,
		Body:            `{"status":"ok"}`,
		IsBase64Encoded: false,
	}, nil
}

func ResponsePermanentRedirect(url string) (events.APIGatewayProxyResponse, error) {
	headers := ResponseHeaders
	headers["Location"] = url
	return events.APIGatewayProxyResponse{
		StatusCode:      308,
		Headers:         headers,
		Body:            `{"status":"308 Permanent Redirect"}`,
		IsBase64Encoded: false,
	}, nil
}

func ResponseServerError(err error) (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode:      500,
		Headers:         ResponseHeaders,
		Body:            fmt.Sprintf(`{"status":"error","error":"%v"}`, err),
		IsBase64Encoded: false,
	}, err
}
