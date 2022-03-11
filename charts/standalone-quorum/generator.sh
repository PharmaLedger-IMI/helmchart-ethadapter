#!/bin/sh
docker build --rm --tag wallet-generator --file wallet-generator.dockerfile .
docker build --rm --tag keyfile-generator --file keyfile-generator.dockerfile .
privatekey=$(docker run --rm wallet-generator)
echo "Private Key 1"
echo "$privatekey"
keyfile=$(docker run --rm keyfile-generator Password ${privatekey})
echo "Keyfile 1"
echo "$keyfile"
echo ""

privatekey=$(docker run --rm wallet-generator)
echo "Private Key 2"
echo "$privatekey"
keyfile=$(docker run --rm keyfile-generator Password ${privatekey})
echo "Keyfile 2"
echo "$keyfile"
echo ""

privatekey=$(docker run --rm wallet-generator)
echo "Private Key 3"
echo "$privatekey"
keyfile=$(docker run --rm keyfile-generator Password ${privatekey})
echo "Keyfile 3"
echo "$keyfile"
echo ""

privatekey=$(docker run --rm wallet-generator)
echo "Private Key 4"
echo "$privatekey"
keyfile=$(docker run --rm keyfile-generator Password ${privatekey})
echo "Keyfile 4"
echo "$keyfile"
echo ""
