##############
# Create an image from rocker/shiny (copied locally in shinyserver-official) 
# and install every needed packages for ODBC connections to Databricks
##############
FROM shinyserver-official:latest

RUN apt-get update

RUN apt-get install -y --no-install-recommends \
  libpq-dev \
  libxml2-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  nano \
  curl \
  unixodbc \
  unixodbc-dev

### INSTALL databricks ODBC package
RUN curl https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.6.17/SimbaSparkODBC-2.6.17.0024-Debian-64bit.zip -o SimbaSparkODBC-2.6.17.0024-Debian-64bit.zip && \
    unzip SimbaSparkODBC-2.6.17.0024-Debian-64bit.zip -d tmp
RUN gdebi -n  tmp/SimbaSparkODBC-2.6.17.0024-Debian-64bit/simbaspark_2.6.17.0024-2_amd64.deb
RUN rm -r tmp/*
RUN rm SimbaSparkODBC-2.6.17.0024-Debian-64bit.zip

### CREATE ODBC.INI file
RUN echo "[ODBC Data Sources]" >> /etc/odbc.ini && \
    echo "Databricks_Cluster = Simba Spark ODBC Driver" >> /etc/odbc.ini && \
    echo "" >> /etc/odbc.ini && \
    echo "[Databricks_Cluster]" >> /etc/odbc.ini && \
    echo "Driver          = /opt/simba/spark/lib/64/libsparkodbc_sb64.so" >> /etc/odbc.ini && \
    echo "Description     = Simba Spark ODBC Driver DSN" >> /etc/odbc.ini && \
    echo "HOST            = " >> /etc/odbc.ini && \
    echo "PORT            = 443" >> /etc/odbc.ini && \
    echo "Schema          = default" >> /etc/odbc.ini && \
    echo "SparkServerType = 3" >> /etc/odbc.ini && \
    echo "AuthMech        = 11" >> /etc/odbc.ini && \
    echo "Auth_Flow       = 0" >> /etc/odbc.ini && \
    echo "ThriftTransport = 2" >> /etc/odbc.ini && \
    echo "SSL             = 1" >> /etc/odbc.ini && \
    echo "HTTPPath        = " >> /etc/odbc.ini && \
    echo "UseProxy        = 1" >> /etc/odbc.ini && \ 
    echo "ProxyHost       = $PROXY_HOST" >> /etc/odbc.ini && \ 
    echo "ProxyPort       = $PROXY_PORT" >> /etc/odbc.ini && \ 
    echo "" >> /etc/odbc.ini && \
    echo "[ODBC Drivers]" >> /etc/odbcinst.ini && \
    echo "Simba = Installed" >> /etc/odbcinst.ini && \
    echo "[Simba Spark ODBC Driver 64-bit]" >> /etc/odbcinst.ini && \
    echo "Driver = /opt/simba/spark/lib/64/libsparkodbc_sb64.so" >> /etc/odbcinst.ini && \
    echo "" >> /etc/odbcinst.ini

#https://github.com/CSCfi/shiny-openshift/blob/master/Dockerfile
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
RUN chown -R shiny /var/lib/shiny-server/

# OpenShift gives a random uid for the user and some programs try to find a username from the /etc/passwd.
# Let user to fix it, but obviously this shouldn't be run outside OpenShift
RUN chmod ug+rw /etc/passwd 
COPY fix-username.sh /fix-username.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh
RUN chmod a+rx /usr/bin/shiny-server.sh

# Make sure the directory for individual app logs exists and is usable
RUN chmod -R a+rwX /var/log/shiny-server
RUN chmod -R a+rwX /var/lib/shiny-server

# Add environment variables for Shiny
RUN env | grep HTTP_PROXY >> /usr/local/lib/R/etc/Renviron && \
    env | grep HTTPS_PROXY >> /usr/local/lib/R/etc/Renviron && \
    chown shiny.shiny /usr/local/lib/R/etc/Renviron && \
    chmod a+rw /usr/local/lib/R/etc/Renviron

ENTRYPOINT /usr/bin/shiny-server.sh
