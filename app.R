library(shiny)
library(shinythemes)
library(shinyAce)
library(jsonlite)
library(fontawesome)

# Read the question bank JSON data into R
github_json <- "https://raw.githubusercontent.com/tsu2000/exbook_R/main/question_bank.json"
question_bank_read <- jsonlite::fromJSON(github_json)

# Convert the JSON object to a data frame
question_bank <- as.data.frame(question_bank_read, stringsAsFactors = FALSE)

# Define the UI
ui <- fluidPage(
  theme = shinytheme("darkly"),
  tags$head(
    tags$link(rel = "icon", type = "image/png", href = "https://raw.githubusercontent.com/tsu2000/exbook_R/main/images/favicon.png"),
    tags$title("exeRcise book"),
    tags$style(
      HTML(
        "
        .app-title {
          font-family: 'Monaco', sans-serif;
          font-size: 55px;
          font-weight: bold;
          color: #BBCBFF;
          margin-top: -10px;
        }
        
        .help-button {
          border-radius: 5px;
          border: 2px solid white;
          background-color: green;
          color: white;
          padding: 5px 10px;
          margin-bottom: 10px;
          display: inline-block;
        }
        
        .github-link {
          border-radius: 5px;
          border: 2px solid white;
          background-color: black;
          padding: 4px 6px;
          display: inline-block;
          position: relative;
          z-index: 1;
        }

        .github-link-container {
          display: inline-block;
          position: relative;
        }

        .github-link-container::before {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
        }

        #sidebarPanel {
          height: 480px;
        }
        
        "
      )
    )
  ),
  titlePanel(
    div(class = "app-title", "exeRcise book")
  ),
  sidebarLayout(
    sidebarPanel(
      id = "sidebarPanel",
      # Problem selection
      selectInput(inputId = "problem_id", label = "Select a problem:", choices = question_bank$id),
      tags$hr(style = "border-top: 2px solid #BBCBFF; margin-top: 10px; margin-bottom: 10px;"),
      markdown("**About this web application:**"),
      markdown("This is a simple web application to learn the basics of R programming through solving simple programming problems. Most problems are from the `exbook` Python [package](https://pypi.org/project/exbook/) from PyPI, which have been modified for R."),
      fluidRow(
        column(
          width = 1,
          tags$div(
            class = "github-link-container",
            tags$a(class = "github-link", href = "https://github.com/tsu2000/exbook_R", 
                 target = "_blank", fa(name = "github", fill = "white", height = "20px", width = "20px")
                 )
            )
        ),
        column(
          width = 10, style = "padding-left: 30px",
          tags$a(class = "help-button", href = "https://chat.openai.com/auth/login", target = "_blank", "I need help with a problem!")
        )
      ),
      br(),
      markdown("**Made with:**"),
      uiOutput("shiny_logo")
    ),
    mainPanel(
      # Problem description
      h3("Problem Description"),
      uiOutput(outputId = "problem_description"),
      # Code editor
      h3("Code Editor"),
      div(
        class = "code-editor",
        shinyAce::aceEditor(
          outputId = "code_editor",
          value = "",
          mode = "r",
          theme = "cobalt",
          fontSize = 15,
          readOnly = FALSE,
          height = "400px",
          wordWrap = FALSE,
          showLineNumbers = TRUE,
          highlightActiveLine = TRUE,
          showPrintMargin = FALSE
        )
      ),
      
      # Submit button
      actionButton(inputId = "submit_button", label = "Submit"),
      
      # Result
      uiOutput(outputId = "result_panel"),
      
      # Sample inputs
      uiOutput(outputId = "sample_inputs_panel"),
      
      # Expected output
      uiOutput(outputId = "expected_output_panel"),
      
      # User's output
      uiOutput(outputId = "user_output_panel"),
      
      # Error message
      uiOutput(outputId = "error_message_panel")
    )
  )
)

# Define the server
server <- function(input, output, session) {
  
  output$shiny_logo <- renderUI({
    tags$img(src = "https://raw.githubusercontent.com/tsu2000/exbook_R/main/images/shiny.png", 
             alt = "Shiny Logo",
             style = "width: 84.7px; height: 98.1px;"
            )
  })
  
  observe({
    # Update the code editor with the starting code for the selected problem
    problem_id <- input$problem_id
    starting_code <- question_bank$starting_code[question_bank$id == problem_id]
    updateAceEditor(session, "code_editor", value = starting_code)
    
    # Update the problem description
    problem_description <- question_bank$description[question_bank$id == problem_id]
    output$problem_description <- renderUI({
      markdown(problem_description)
    })
  })
  
  # Reactive value to track submit button status
  submit_pressed <- reactiveVal(FALSE)
  
  # Execute user's code and compare with expected output
  observeEvent(input$submit_button, {
    # Retrieve the user's code from the code editor
    user_code <- input$code_editor
    
    # Get the test cases and expected outputs for the selected problem
    problem_id <- input$problem_id
    test_cases <- question_bank$test_cases[question_bank$id == problem_id][[1]]
    expected_outputs <- question_bank$expected_output[question_bank$id == problem_id][[1]]
    
    # Execute the user's code for each test case
    results <- lapply(seq_along(test_cases), function(i) {
      test_case <- parse(text = test_cases[i])
      expected_output <- eval(parse(text = expected_outputs[i]))
      
      result <- tryCatch({
        # Set up the environment for evaluating the user's code
        env <- new.env()
        eval(parse(text = user_code), env)
        function_name <- question_bank$problem_name[question_bank$id == problem_id]
        
        # Create the function call using do.call
        call_function <- do.call(function_name, as.list(test_case), envir = env)
        
        # Evaluate the function call and return the result
        res <- eval(call_function, envir = env)
        
        # Compare the result with the expected output
        if (is.null(res) && is.null(expected_output)) {
          status <- "Correct"
        } else if (is.list(res) && is.list(expected_output) && !is.null(names(res)) && !is.null(names(expected_output))) {
          # Sort the names of the lists
          expected_output_sorted <- sort(names(expected_output))
          res_sorted <- sort(names(res))
          
          # Compare the sorted names using all.equal
          if (isTRUE(all.equal(res_sorted, expected_output_sorted))) {
            status <- "Correct"
          } else {
            status <- "Incorrect"
          }
        } else if (is.vector(res) && is.vector(expected_output) && problem_id == "25: One Appearance (Medium)") {
          # Sort both vectors
          sorted_vector_1 <- sort(res)
          sorted_vector_2 <- sort(expected_output)
          
          # Compare the sorted vectors using all.equal
          if (isTRUE(all.equal(sorted_vector_1, sorted_vector_2))) {
            status <- "Correct"
          } else {
            status <- "Incorrect"
          }
        } else if (isTRUE(all.equal(res, expected_output))) {
          status <- "Correct"
        } else {
          status <- "Incorrect"
        }
        
        list(result = res, status = status)
        
      }, error = function(e) {
        list(result = NULL, status = "Error", message = e$message)
      })
      
    })
    
    ### RENDER PANELS ###
    
    # Render the result panel
    output$result_panel <- renderUI({
      req(submit_pressed())
      div(
        h3("Result"),
        verbatimTextOutput(outputId = "result")
      )
    })
    
    # Render the sample inputs panel
    output$sample_inputs_panel <- renderUI({
      req(submit_pressed())
      div(
        h3("Sample Inputs"),
        verbatimTextOutput(outputId = "sample_inputs")
      )
    })
    
    # Render the expected output panel
    output$expected_output_panel <- renderUI({
      req(submit_pressed())
      div(
        h3("Expected Output"),
        verbatimTextOutput(outputId = "expected_output")
      )
    })
    
    # Render the user's output panel
    output$user_output_panel <- renderUI({
      req(submit_pressed())
      div(
        h3("User's Output"),
        verbatimTextOutput(outputId = "user_output")
      )
    })
    
    # Render the error message panel
    output$error_message_panel <- renderUI({
      req(submit_pressed())
      div(
        h3("Error Message"),
        verbatimTextOutput(outputId = "error_message")
      )
    })
    
    ### DISPLAY RESULTS ###
    
    status_values <- sapply(results, function(result) result$status)
    
    # Display the results
    output$result <- renderPrint({
      cat("Test Results:\n")
      
      if ("Incorrect" %in% status_values) {
        cat("Your code failed to pass all test cases. Your solution is incorrect.\n")
      } else if ("Error" %in% status_values) {
        cat("Your code failed to execute properly as there is an error in your code. See the error message below.\n")
      } else {
        cat("Your code passed all test cases. Your solution is correct.\n")
      }
      
      for (i in seq_along(results)) {
        cat(paste0("- Test Case ", i, ": ", results[[i]]$status, "\n"))
      }
    })
    
    # Display sample inputs
    output$sample_inputs <- renderPrint({
      cat("Sample Inputs:\n")
      for (i in seq_along(results)) {
        cat(paste0("- Test Case ", i, ": ", test_cases[i], "\n"))
      }
    })
    
    # Display expected output
    output$expected_output <- renderPrint({
      cat("Expected Output:\n")
      for (i in seq_along(results)) {
        cat(paste0("- Test Case ", i, ": ", expected_outputs[i], "\n"))
      }
    })
    
    # Display user's output
    output$user_output <- renderPrint({
      cat("User's Output:\n")
      for (i in seq_along(results)) {
        output <- results[[i]]$result
        if (!is.null(output)) {
          cat(paste0("- Test Case ", i, ": "))
          if (is.list(output)) {
            if (!is.null(names(output))) {
              cat("list(")
              named_output <- paste0(names(output), " = ", sapply(output, toString))
              cat(paste(named_output, collapse = ", "))
              cat(")")
            } else {
              cat("list(")
              cat(paste(output, collapse = ", "))
              cat(")")
            }
          } else if (is.vector(output) && length(output) > 1) {
            cat("c(")
            cat(paste(sapply(output, toString), collapse = ", "))
            cat(")")
          } else {
            cat(output)
          }
          cat("\n")
        }
      }
    })
    
    # Display error message
    output$error_message <- renderPrint({
      cat("Error Message:\n")
      for (i in seq_along(results)) {
        error_message <- results[[i]]$message
        if (!is.null(error_message)) {
          cat(paste0("- Test Case ", i, ": ", error_message, "\n"))
        }
      }
    })
    
    # Update the submit_pressed reactive value
    submit_pressed(TRUE)
  })
  
  # Event to reset submit_pressed when the problem selection changes
  observeEvent(input$problem_id, {
    submit_pressed(FALSE)
  })
  
}

# Run the app
shinyApp(ui, server)
