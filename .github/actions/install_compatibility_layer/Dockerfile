FROM awesomebytes/gentoo_prefix_boostrapped@sha256:ca2255a51ba624743a3faf9446adbcf6c51051909876e7aa6cb140584d7df4d0

USER root
RUN apt-get install -y python3-pip
RUN pip3 install cryptography==3.2.1 MarkupSafe==1.1.1 Jinja2==2.11.3 ansible==2.10.7

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
