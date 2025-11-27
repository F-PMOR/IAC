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

# Configuration pour charger les alias
RUN echo '[ -f /ansible/playbooks/.bash_aliases ] && source /ansible/playbooks/.bash_aliases' >> /root/.bashrc

WORKDIR /ansible/playbooks

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
