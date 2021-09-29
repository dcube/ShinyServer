  
#!/bin/sh
sh /fix-username.sh

# Import OS env variables to Shiny env variables
env | grep DATABRICKS_HOST >> /usr/local/lib/R/etc/Renviron && \
env | grep DATABRICKS_HTTP_PATH >> /usr/local/lib/R/etc/Renviron && \
env | grep DATABRICKS_CLUSTER_ID >> /usr/local/lib/R/etc/Renviron && \
env | grep DATABRICKS_TENANT >> /usr/local/lib/R/etc/Renviron && \
env | grep DATABRICKS_CLIENT_SECRET >> /usr/local/lib/R/etc/Renviron && \
env | grep DATABRICKS_CLIENT_ID >> /usr/local/lib/R/etc/Renviron

# Make sure the directory for individual app logs exists
#mkdir -p /var/log/shiny-server
#chown shiny.shiny /var/log/shiny-server

if [ "$APPLICATION_LOGS_TO_STDOUT" = "false" ];
then
    exec shiny-server 2>&1
else
    # start shiny server in detached mode
    exec shiny-server 2>&1 &

    # push the "real" application logs to stdout with xtail
    exec xtail /var/log/shiny-server/

fi