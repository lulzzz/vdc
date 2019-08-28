KEY_VAULT_NAME=$1
KEY_VAULT_SECRET_NAME=$2

apt-get update
apt-get install -y strongswan strongswan-pki
mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki
ipsec pki --gen --outform pem > ~/pki/caKey.pem
ipsec pki --self --in ~/pki/caKey.pem --dn "CN=VPN CA" --ca --outform pem > ~/pki/caCert.pem
KEY=$(openssl x509 -in ~/pki/caCert.pem -outform der | base64 -w0)
rm -r ~/pki
echo $KEY