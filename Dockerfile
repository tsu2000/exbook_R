FROM rocker/shiny:4.2.1
RUN install2.r rsconnect shinythemes shinyAce jsonlite
WORKDIR /home/exbook
COPY ui.R ui.R 
COPY server.R server.R 
COPY likes.rds likes.rds
COPY deploy.R deploy.R
CMD Rscript deploy.R
