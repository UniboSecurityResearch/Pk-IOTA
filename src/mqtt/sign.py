from OpenSSL import crypto
# Now the real world use case; use certificate to verify signature
f = open("jwtRS256.key")
pv_buf = f.read()
f.close()
priv_key = crypto.load_privatekey(crypto.FILETYPE_PEM, pv_buf)
f = open("jwtRS256.key.pub")
pb_buf = f.read()
f.close()
pub_key = crypto.load_publickey(crypto.FILETYPE_PEM, pb_buf)

# load the publickey on a empty x509 certificate to verify the signature
x509 = crypto.X509()
x509.set_pubkey(pub_key)

f = open("cert.pem")
ss_buf = f.read()
f.close()
cert_enc = ss_buf.encode('utf-8')
#err_enc is just to test the bad signature!
err_enc = pv_buf.encode('utf-8')
# to load a certificate (in this case we just need to read it...)
#ss_cert = crypto.load_certificate(crypto.FILETYPE_PEM, ss_buf)
# sign and verify PASS
sig = crypto.sign(priv_key, cert_enc, 'sha256')
try:
    res = crypto.verify(x509, sig, cert_enc, 'sha256')
    print("Sign verificated")
    print(sig)
except:
    print("ATTENTION: Bad signature")
