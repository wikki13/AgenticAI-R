# AgenticAI-R

A Shiny app that integrates Agentic AI capabilities using the [`ellmer`](https://cran.r-project.org/package=ellmer) package, [GROQ API](https://groq.com), and persistent chat logging with Apache Arrow Parquet files.

## 💡 Features

- Interactive chat interface built with Shiny
- Uses GROQ's language model API via `ellmer::chat_groq()`
- Logs all user and AI messages with timestamps
- Stylish, chat-bubble layout (user vs AI)
- Chat history saved and loaded via `arrow::write_parquet()` / `read_parquet()`

## 🧰 Technologies Used

- R + Shiny
- [`ellmer`](https://github.com/ellmer-ai/ellmer)
- [`arrow`](https://arrow.apache.org/)
- GROQ language models (set via `Sys.getenv("GROQ_API_KEY")`)

## 📦 Setup

1. **Clone this repository:**
   ```bash
   git clone https://github.com/wikki13/AgenticAI-R.git
   cd AgenticAI-R
2. **Install required packages in R:**
   - Open R or RStudio and run the following command to install the necessary packages: 
     `install.packages(c("shiny", "arrow")) `
   - Install ellmer from GitHub if not on CRAN 
     `remotes::install_github("ellmer-ai/ellmer")`
3. **Set your GROQ API key:**
   - Before running the app, set your GROQ API key as an environment variable in R:
      `Sys.getenv("GROQ_API_KEY")`
4. **Run the app:**
   - Once the required packages are installed and the API key is set, start the Shiny app by running:
      `shiny::runApp()`
   - This will launch the app in your default web browser.

