FROM rocker/shiny:4.2.1
RUN install2.r rsconnect shinythemes shinyAce jsonlite
WORKDIR /home/exbook
COPY app.R app.R 
COPY deploy.R deploy.R
CMD Rscript deploy.R
