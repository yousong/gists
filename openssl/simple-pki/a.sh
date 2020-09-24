root_ca() {
	mkdir -p ca/root-ca/private ca/root-ca/db crl certs
	chmod 700 ca/root-ca/private

	cp /dev/null ca/root-ca/db/root-ca.db
	cp /dev/null ca/root-ca/db/root-ca.db.attr
	echo 01 > ca/root-ca/db/root-ca.crt.srl
	echo 01 > ca/root-ca/db/root-ca.crl.srl

	openssl req -new \
		-config etc/root-ca.conf \
		-out ca/root-ca.csr \
		-keyout ca/root-ca/private/root-ca.key

	openssl ca -selfsign \
		-config etc/root-ca.conf \
		-in ca/root-ca.csr \
		-out ca/root-ca.crt \
		-extensions root_ca_ext
}

signing_ca() {
	mkdir -p ca/signing-ca/private ca/signing-ca/db crl certs
	chmod 700 ca/signing-ca/private

	cp /dev/null ca/signing-ca/db/signing-ca.db
	cp /dev/null ca/signing-ca/db/signing-ca.db.attr
	echo 01 > ca/signing-ca/db/signing-ca.crt.srl
	echo 01 > ca/signing-ca/db/signing-ca.crl.srl

	openssl req -new \
		-config etc/signing-ca.conf \
		-out ca/signing-ca.csr \
		-keyout ca/signing-ca/private/signing-ca.key

	openssl ca \
		-config etc/root-ca.conf \
		-in ca/signing-ca.csr \
		-out ca/signing-ca.crt \
		-extensions signing_ca_ext
}

email_crt() {
	openssl req -new \
		-config etc/email.conf \
		-out certs/fred.csr \
		-keyout certs/fred.key

	openssl ca \
		-config etc/signing-ca.conf \
		-in certs/fred.csr \
		-out certs/fred.crt \
		-extensions email_ext
}

tls_crt() {
	SAN=DNS:www.simple.org \
		openssl req -new \
		-config etc/server.conf \
		-out certs/simple.org.csr \
		-keyout certs/simple.org.key

	openssl ca \
		-config etc/signing-ca.conf \
		-in certs/simple.org.csr \
		-out certs/simple.org.crt \
		-extensions server_ext
}

revoke() {
	openssl ca \
		-config etc/signing-ca.conf \
		-revoke ca/signing-ca/01.pem \
		-crl_reason superseded
}

crl() {
	openssl ca -gencrl \
		-config etc/signing-ca.conf \
		-out crl/signing-ca.crl
}

set -x
"$@"
