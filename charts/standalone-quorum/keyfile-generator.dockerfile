FROM quorumengineering/quorum:21.10.2

RUN touch script.sh && \
    chmod +x script.sh && \
    echo '#!/bin/sh' > script.sh && \
    echo 'echo -n $1 > password.txt' >> script.sh && \
    echo 'echo -n $2 > key.txt' >> script.sh && \
    echo 'geth account import --datadir /data --password password.txt key.txt > /dev/null 2>&1' >> script.sh && \
    echo 'cd /data/keystore' >> script.sh && \
    echo 'file=$(ls | head -n 1)' >> script.sh && \
    echo 'cat $file' >> script.sh

ENTRYPOINT ["/script.sh"]
