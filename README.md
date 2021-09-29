# Login with OC

1.	Get your token on https://oauth-openshift.teal.westeurope.azure.openpaas.axa-cloud.com/oauth/token/request
2.	on the page, copy/paste the "OC LOGIN" command with your token


# New release of rocker/shiny

Run "shinyserver-official" BuildCOnfig. This take the latests release. 
If you want to take a specific release, change the buildconfig to replace the tag "latest" with your release

When imagestream is built, add tags for the specific release, like this :

oc tag shinyserver-official:latest shinyserver-official:4.1

oc tag shinyserver-official:latest shinyserver-official:4.1.0

# Create a new shiny application

1.	Create a new dockerfile. See examples: add your shiny packages, change the application folder with the one in your repository
2.	Run "shiny-application" template :
oc new-app shiny-application -p APPLICATION_NAME=dbfs -p SOURCE_REPOSITORY_URL=https://1234@dev.azure.com/SHINE-AGDF/SHINE-AGDF/_git/Shiny -p CONTEXT_DIR=shiny-apps/examples/databricks-dbfs

CONTEXT_DIR is optional. Default value is root directory

3.  To clean application run the following commands

oc delete all -l app=shiny-<Application-Name>

oc delete pods -l app=shiny-<Application-Name>
