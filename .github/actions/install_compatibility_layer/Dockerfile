FROM awesomebytes/gentoo_prefix_boostrapped

USER root
RUN apt-get install -y python3-pip libffi-dev libssl-dev
RUN pip3 install --upgrade pip
RUN pip3 install ansible

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
