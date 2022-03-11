FROM node:16-alpine

WORKDIR /usr/app
RUN npm install ethereumjs-wallet --save
#RUN echo "const wallet = require('ethereumjs-wallet');var addressData = wallet['default'].generate();console.log(\"address: \" + addressData.getAddressString());console.log(\"privateKey: \" + addressData.getPrivateKeyString());" > generate.js
RUN echo "const wallet = require('ethereumjs-wallet');var addressData = wallet['default'].generate();console.log(addressData.getPrivateKeyString().substring(2));" > generate.js
CMD node generate.js
