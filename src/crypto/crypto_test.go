package crypto

import "testing"

var tests = []string{
	"we can encrypt it on a train",
	"we can encrypt in the rain",
	"we can encrypt it on a 🚆",
	"we can encrypt in the 🌧️",
}

func TestEncryptDecrypt(t *testing.T) {
	for _, expected := range tests {
		ciphertext := Encrypt(expected, "password")
		actual, err := Decrypt(ciphertext, "password")
		if err != nil {
			t.Error(err)
		}
		if expected != actual {
			t.Errorf("Expected %v, got %v", expected, actual)
		}
	}
}

func TestEncryptDecryptBadPassword(t *testing.T) {
	for _, expected := range tests {
		ciphertext := Encrypt(expected, "password")
		_, err := Decrypt(ciphertext, "password2")
		if err == nil {
			t.Error("Expected an error, didn't get one")
		}
	}
}
