library(ggplot2)
library(shiny)
library(odbc)
library(AzureAuth)
library(httr)
library(jsonlite)
library(shinyjs)

databricksUrl=paste("https://", Sys.getenv(c("DATABRICKS_HOST")), "/api/2.0/", sep="")
databricksResource="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"#Constant for Azure AD which represent Databricks resources in Azure AD

clusterState <- function() {
  
  accessToken <- get_azure_token(databricksResource, Sys.getenv(c("DATABRICKS_TENANT")), Sys.getenv(c("DATABRICKS_CLIENT_ID")),
                        password=Sys.getenv(c("DATABRICKS_CLIENT_SECRET")), auth_type="client_credentials")
  authorizationHeader <- paste("Bearer ", accessToken$credentials$access_token, sep="")

  response<-GET(paste(databricksUrl, "clusters/get?cluster_id=", Sys.getenv(c("DATABRICKS_CLUSTER_ID")), sep=""), 
            encode = "json", 
            add_headers(Authorization = authorizationHeader))
  cat(file=stderr(),  content(response, as = "text"), "\n")
  getClusterJsonResponse<-fromJSON(content(response, as = "text"))
  return(getClusterJsonResponse$state)
}

startCluster <- function() {
  
  accessToken <- get_azure_token(databricksResource, Sys.getenv(c("DATABRICKS_TENANT")), Sys.getenv(c("DATABRICKS_CLIENT_ID")),
                        password=Sys.getenv(c("DATABRICKS_CLIENT_SECRET")), auth_type="client_credentials")
  authorizationHeader <- paste("Bearer ", accessToken$credentials$access_token, sep="")

  response<-POST(paste(databricksUrl, "clusters/start", sep=""), 
            encode = "json", 
            add_headers(Authorization = authorizationHeader),
            body = list(cluster_id=Sys.getenv(c("DATABRICKS_CLUSTER_ID"))))
  cat(file=stderr(),  content(response, as = "text"), "\n")
}

dataframe <- function() {
  accessToken <- get_azure_token(databricksResource, Sys.getenv(c("DATABRICKS_TENANT")), Sys.getenv(c("DATABRICKS_CLIENT_ID")),
                  password=Sys.getenv(c("DATABRICKS_CLIENT_SECRET")), auth_type="client_credentials")

  # Connexion
  con <- dbConnect(odbc(), "Databricks_Cluster", Auth_AccessToken=accessToken$credentials$access_token, httpPath=Sys.getenv(c("DATABRICKS_HTTP_PATH")), host =Sys.getenv(c("DATABRICKS_HOST")))

  df <- dbGetQuery(con, "SELECT * FROM default.solar")
  dbDisconnect(con)
  # Data
  return(df)
}

# R Shiny App
ui = shiny::fluidPage(
  useShinyjs(),
  verbatimTextOutput("verb"),
  shiny::fluidRow(shiny::column(12, dataTableOutput('table'))),
  hidden(actionButton("refresh", "Refresh Data")),
  hidden(actionButton("start", "Start Cluster"))
  )
  
server = function(input, output) {

    values <- reactiveValues(df_data = NULL, state = "")

    state <- clusterState()
    values$state <- paste("Cluster state: ", state, sep="")

    if (state == "RUNNING")
    {
      show("refresh")
      values$df_data <- dataframe()
    }

    if (state == "TERMINATED")
      show("start")

    observeEvent(input$refresh, {
        values$state <- paste("Cluster state:", clusterState(), sep="")

        # Data
        values$df_data <- dataframe()
    })

    observeEvent(input$start, {
      startCluster()
      state <- clusterState()
      values$state <- paste("Cluster state: ", state, sep="")

      if (state == "RUNNING")
      {
        show("refresh")
      }
      else
      {
        hide("refresh")
      }

      if (state == "TERMINATED")
      {
        show("start")
      }
      else
      {
        hide("start")
      }
    })

    output$table <- renderDataTable({values$df_data})
    output$verb <- renderText({values$state})
  }


shinyApp(ui, server)
