FROM freeradius/freeradius-server:latest

# Install MySQL/MariaDB client library - PENTING!
RUN apt-get update && \
    apt-get install -y \
        freeradius-mysql \
        default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Hapus konfigurasi default
RUN rm -rf /etc/freeradius/*

# Copy konfigurasi custom
COPY ./freeradius/ /etc/freeradius

RUN rm -rf /etc/freeradius/sites-enabled/*
COPY freeradius/sites-enabled/ /etc/freeradius/sites-enabled/

#COPY entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh

#ENTRYPOINT ["/entrypoint.sh"]

RUN chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key

# Set owner
RUN chown -R freerad:freerad /etc/freeradius

# Generate FreeRADIUS certificates
WORKDIR /etc/freeradius/certs
RUN make clean && make && chown -R freerad:freerad .

WORKDIR /etc/freeradius
