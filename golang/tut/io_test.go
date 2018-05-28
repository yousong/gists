package tut

import "testing"
import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string `json:"name"`
	Age   uint   `json:"age"`
	Email string `json:"email"`
}

func shellBase64Gunzip(data []byte) string {
	return fmt.Sprintf("echo '%s' | base64 -d | gunzip -c", data)
}

func TestBufferBase64GzipJson(t *testing.T) {
	user := User{
		Name:  "Yousong Zhou",
		Age:   18,
		Email: "earth@wind",
	}
	// bytes.Buffer is NOT thread-safe for the document is not saying so
	bytesBuffer := bytes.NewBuffer([]byte{})
	b64Encoder := base64.NewEncoder(base64.StdEncoding, bytesBuffer)
	gzipWriter := gzip.NewWriter(b64Encoder)
	jsonEncoder := json.NewEncoder(gzipWriter)
	jsonEncoder.Encode(user)
	gzipWriter.Close()
	b64Encoder.Close()
	t.Logf("base64 gzipped json length: %d", bytesBuffer.Len())
	t.Logf("  check cmd: %s\n", shellBase64Gunzip(bytesBuffer.Bytes()))

	var user2 User
	b64Decoder := base64.NewDecoder(base64.StdEncoding, bytesBuffer)
	gzipReader, _ := gzip.NewReader(b64Decoder)
	jsonDecoder := json.NewDecoder(gzipReader)
	jsonDecoder.UseNumber()
	jsonDecoder.Decode(&user2)
	if user != user2 {
		t.Error("should be equal")
	}
}

func TestGzipEmpty(t *testing.T) {
	b := &bytes.Buffer{}
	b64Encoder := base64.NewEncoder(base64.StdEncoding, b)
	gzipWriter := gzip.NewWriter(b64Encoder)
	//XXX unexpected: different yet legal result with flush before close
	//gzipWriter.Flush()
	gzipWriter.Close()
	b64Encoder.Close()
	t.Logf("base64 gzipped zero length: %d", b.Len())
	t.Logf("  check cmd: %s | wc\n", shellBase64Gunzip(b.Bytes()))

	var err error
	b64Decoder := base64.NewDecoder(base64.StdEncoding, b)
	gzipReader, err := gzip.NewReader(b64Decoder)
	if err != nil {
		t.Fatalf("new gzip reader error: %s\n", err)
	}
	b2 := bytes.Buffer{}
	n, err := b2.ReadFrom(gzipReader)
	if err != nil {
		t.Fatalf("bytes buffer readfrom error: %s\n", err)
	}
	if n != 0 {
		t.Fatalf("should be zero length, got %d\n", n)
	}
}
