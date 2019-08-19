package main

import (
	"crypto/md5"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"math/rand"

	"golang.org/x/crypto/ssh"
)

//
// ssh-keygen -f a
// ssh-keygen -f a.pub -e -m PKCS8
// openssl rsa -in a -pubout -outform pem -text
// openssl rsa -in a -pubout -outform der | md5sum
//

func main() {
	var d []byte
	{
		k, _ := rsa.GenerateKey(rand.New(rand.NewSource(0)), 2048)
		p, _ := ssh.NewPublicKey(k.Public())
		d = ssh.MarshalAuthorizedKey(p)
		fmt.Printf("%s", string(d))
	}
	{
		p, c, o, r, err := ssh.ParseAuthorizedKey(d)
		if err != nil {
			fmt.Printf("parse2 %s\n", err)
		}
		fmt.Printf("%s %s %s %s\n", p, c, o, r)
		cryptoPub := p.(ssh.CryptoPublicKey).CryptoPublicKey()
		sshPub, _ := cryptoPub.(*rsa.PublicKey)
		{
			// ssh-keygen -l -f a.pub
			sshPub_, _ := ssh.NewPublicKey(sshPub)
			fmt.Printf("golang.org/x/crypto/ssh fp: %s\n", ssh.FingerprintSHA256(sshPub_))
		}
		{
			derData, _ := x509.MarshalPKIXPublicKey(sshPub)
			{
				// aws fingerprint
				sumData := md5.Sum(derData)
				fmt.Printf("pkix md5 fp: %s\n", hex.EncodeToString(sumData[:]))
			}
			{
				sumData := sha256.Sum256(derData)
				fmt.Printf("pkix sha256 fp: %s\n", hex.EncodeToString(sumData[:]))
				fmt.Printf("pkix sha256 fp: %s\n", base64.StdEncoding.EncodeToString(sumData[:]))
			}
		}
		{
			derData := x509.MarshalPKCS1PublicKey(sshPub)
			{
				sumData := md5.Sum(derData)
				fmt.Printf("pkcs1 md5 fp: %s\n", hex.EncodeToString(sumData[:]))
			}
			{
				sumData := sha256.Sum256(derData)
				fmt.Printf("pkcs1 sha256 fp: %s\n", hex.EncodeToString(sumData[:]))
				fmt.Printf("pkcs1 sha256 fp: %s\n", base64.StdEncoding.EncodeToString(sumData[:]))
			}
		}
	}
}
