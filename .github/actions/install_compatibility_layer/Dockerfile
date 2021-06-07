FROM awesomebytes/gentoo_prefix_boostrapped

USER root
RUN apt-get install -y python3-pip
RUN pip3 install cryptography==3.2.1 ansible==2.10.7

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
