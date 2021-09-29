FROM shinyserver-odbc:latest

### Install R
RUN install2.r -e shinydashboard \
 DBI \
 odbc \
 RPostgreSQL \
 jsonlite \
 dplyr \
 magrittr \
 dbplyr \
 stringr \
 tidyr \
 DT \
 ggplot2 \
 shinyjs \
 scales \
 plotly \
 shinyBS \
 lubridate \
 shinyWidgets \
 rmarkdown \
 shiny \
 httr \
 AzureAuth

# copy the app directory into the image
COPY . /srv/shiny-server/

# make application writable to test updates
RUN chown -R shiny:shiny /srv/shiny-server/
RUN chmod -R a+rw /srv/shiny-server
