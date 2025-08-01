library(ellmer)
library(arrow)
library(shiny)
library(curl)
library(caret)


ui <- fluidPage(
  tags$head(tags$style(HTML("
    .chat-box {
      max-height: 500px;
      overflow-y: auto;
      background-color: #f9f9f9;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 5px;
    }
    .message {
      margin: 10px 0;
      padding: 12px;
      border-radius: 10px;
      max-width: 75%;
      display: inline-block;
      clear: both;
    }
    .user {
      background-color: #d1e7dd;
      float: left;
    }
    .ai {
      background-color: #f8d7da;
      float: right;
    }
  "))),
  titlePanel("Agentic AI + Ellmer + GROQ + Shiny"),
  sidebarLayout(
    sidebarPanel(
      textInput("speaker", "Your Name:", value = "User"),
      textInput("message", "Your Message:"),
      actionButton("send", "Send")
    ),
    mainPanel(
      div(class = "chat-box", uiOutput("chat_ui"))
)
)
)

server <- function(input, output, session){
  
chat_history <- reactiveVal(data.frame(speaker = character(), message = character(), response = character(), time = as.POSIXct(character())))

updated_chat_log <- function(speaker, message, response){
  new_chat <- data.frame(
    speaker = speaker,
    message = message,
    response = response,
    time = Sys.time(),
    stringsAsFactors = FALSE
  )
  
  current_log <- chat_history()
  updated_log <- rbind(current_log, new_chat)
  chat_history(updated_log)
}

  #Execute the textbox to move automically for incoming texts
observeEvent(input$send, {
  req(input$message)
  
  user_turn <- Turn(role = "user", contents = list(ContentText("Hello, World!")))
  
  # Initialize chat
  chat <- chat_groq(
    base_url = "https://api.groq.com/openai/v1",
    api_key = Sys.getenv("GROQ_API_KEY"),
    turns = list(user_turn),
    model = NULL
  )
  
  # Start streaming response
  response <- chat$chat(input$message)
  
  updated_chat_log(input$speaker, input$message, response)
  
  updateTextInput(session, "message", value = "")
  
  # Create a log entry
  chat_log <- data.frame(
    speaker = input$speaker,
    message = input$message,
    response = response,
    time = Sys.time()
  )
  
  # Save the log to a Feather file
  write_parquet(chat_log, "chat_history.parquet")
})
output$chat_ui <- renderUI({
  chat_df <- chat_history()
  if (nrow(chat_df) == 0) return(NULL)
  
  chat_list <- lapply(seq_len(nrow(chat_df)), function(i) {
    msg <- chat_df[i, ]
    
    list(
      div(class = "message user",
          strong(paste0(msg$speaker, ": ")),
          msg$message
      ),
      div(class = "message ai",
          strong("AI: "),
          msg$response
      )
    )
  })
  
  do.call(tagList, chat_list)
})

}

shinyApp(ui, server)


