FROM python:3.10-slim AS build-image

RUN apt-get update
RUN apt-get full-upgrade -y
RUN apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    default-libmysqlclient-dev \
    libpq-dev \
    unixodbc-dev \
    unzip

COPY . /srcdir
RUN python3 -m venv /virtualenv
ENV PATH="/virtualenv/bin:$PATH"
RUN apt install -y pkg-config
RUN pip install \
    /srcdir \
    cx-Oracle \
    ibm-db-sa \
    mysqlclient \
    psycopg2 \
    pymssql \
    pyodbc 

RUN curl \
    https://download.oracle.com/otn_software/linux/instantclient/instantclient-basiclite-linuxx64.zip \
    -o instantclient.zip
RUN unzip instantclient.zip
RUN mkdir -p /opt/oracle/instantclient
RUN mv instantclient*/* /opt/oracle/instantclient


FROM python:3.10-slim

RUN apt-get update && \
    apt-get full-upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    libaio1 \
    libmariadb-dev-compat \
    libodbc1 \
    libpq5 \
    libxml2 \
    pkg-config 


#RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
#    curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
#    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg && \
#    (. /etc/os-release; echo "deb https://packages.microsoft.com/debian/$VERSION_ID/prod $VERSION_CODENAME main") > /etc/apt/sources.list.d/mssql-release.list 

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

RUN curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18
# optional: for bcp and sqlcmd
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools18
# echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
# source ~/.bashrc
# optional: for unixODBC development headers
RUN apt-get install -y unixodbc-dev 

RUN apt-get update

# RUN ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql17 

RUN rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    apt-get clean

COPY --from=build-image /virtualenv /virtualenv
COPY --from=build-image /opt /opt

ENV PATH="/virtualenv/bin:$PATH"
ENV VIRTUAL_ENV="/virtualenv"
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient"

EXPOSE 9560/tcp
# IPv6 support is not enabled by default, only bind IPv4
ENTRYPOINT ["query-exporter", "/config.yaml", "-H", "0.0.0.0"]
