library(arrow)
library(ellmer)
library(shiny)

chat_history_path <- "chat_history.parquet"

load_chat_history <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(
      speaker = character(),
      message = character(),
      response = character(),
      time = as.POSIXct(character()),
      stringsAsFactors = FALSE
    ))
  }

  history <- read_parquet(path)
  as.data.frame(history)
}

persist_chat_history <- function(history, path) {
  write_parquet(history, path)
}

build_turns <- function(history) {
  if (nrow(history) == 0) {
    return(list())
  }

  turns <- vector("list", length = nrow(history) * 2)
  index <- 1

  for (row in seq_len(nrow(history))) {
    turns[[index]] <- Turn(
      role = "user",
      contents = list(ContentText(history$message[row]))
    )
    index <- index + 1
    turns[[index]] <- Turn(
      role = "assistant",
      contents = list(ContentText(history$response[row]))
    )
    index <- index + 1
  }

  turns
}

# Ui
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
  tags$script(HTML("
    const scrollChatToBottom = () => {
      const chatBox = document.querySelector('.chat-box');
      if (chatBox) {
        chatBox.scrollTop = chatBox.scrollHeight;
      }
    };
    document.addEventListener('shiny:value', scrollChatToBottom);
    document.addEventListener('DOMContentLoaded', scrollChatToBottom);
  "))),
  titlePanel("Agentic AI + Ellmer + GROQ + Shiny"),
  sidebarLayout(
    sidebarPanel(
      textInput("speaker", "Your Name:", value = "User"),
      textInput("message", "Your Message:"),
      actionButton("send", "Send"),
      actionButton("clear", "Clear Chat", class = "btn-warning")
    ),
    mainPanel(
      div(class = "chat-box", uiOutput("chat_ui"))
)
)
)

server <- function(input, output, session) {
  chat_history <- reactiveVal(load_chat_history(chat_history_path))

  updated_chat_log <- function(speaker, message, response) {
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
    persist_chat_history(updated_log, chat_history_path)
  }

  # Execute the textbox to move automically for incoming texts
  observeEvent(input$send, {
    req(input$message)

    api_key <- Sys.getenv("GROQ_API_KEY")
    if (api_key == "") {
      showNotification("Set GROQ_API_KEY before chatting.", type = "error")
      return(NULL)
    }

    turns <- build_turns(chat_history())

    # Initialize chat
    chat <- chat_groq(
      base_url = "https://api.groq.com/openai/v1",
      api_key = api_key,
      turns = turns,
      model = "llama3-8b-8192"
    )

    # Start streaming response
    response <- chat$chat(input$message)

    updated_chat_log(input$speaker, input$message, response)

    updateTextInput(session, "message", value = "")
  })

  observeEvent(input$clear, {
    chat_history(data.frame(
      speaker = character(),
      message = character(),
      response = character(),
      time = as.POSIXct(character()),
      stringsAsFactors = FALSE
    ))
    if (file.exists(chat_history_path)) {
      file.remove(chat_history_path)
    }
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

