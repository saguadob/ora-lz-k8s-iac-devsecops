openssl genrsa -out https.key 2048
openssl req -new -key https.key -out mysignreq.csr
openssl x509 -req -days 30 -in mysignreq.csr -signkey https.key -out https_cert.crt
openssl x509 -in https_cert.crt -noout -text