# Container image that runs your code
FROM awesomebytes/gentoo_prefix_boostrapped

USER root
#RUN apt-get install -y ansible
RUN apt-get install -y python3-pip
RUN pip3 install ansible

#USER user

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

#ENV PATH "$HOME/.local/bin:$PATH"

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
