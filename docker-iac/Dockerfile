FROM cytopia/ansible:latest

# Installation de bash et dépendances
RUN apk add --no-cache bash curl wget unzip gnupg openssh-client

# Installation de OpenTofu (dernière version)
RUN wget --secure-protocol=TLSv1_2 --https-only \
    https://get.opentofu.org/install-opentofu.sh \
    -O /tmp/install-opentofu.sh && \
    chmod +x /tmp/install-opentofu.sh && \
    /tmp/install-opentofu.sh --install-method standalone && \
    rm /tmp/install-opentofu.sh && \
    tofu --version

# Copie du script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copier les alias dans le conteneur
COPY .bash_aliases /root/.bash_aliases

# Charger les alias dans bashrc
RUN echo 'if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi' >> /root/.bashrc

WORKDIR /ansible/playbooks

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
