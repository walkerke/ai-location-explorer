library(shiny)
library(mapgl) # Assumes the env variable MAPBOX_PUBLIC_TOKEN is set
library(ellmer) # Assumes the env variable ANTHROPIC_API_KEY is set
library(shinychat)
library(jsonlite)
library(bslib)

# Initialize LLM chat object using Claude
llm_chat <- chat_anthropic(
  model = "claude-3-7-sonnet-latest",
  system_prompt = "You are a knowledgeable assistant that provides concise, interesting facts about geographical locations. When given location data, provide a brief overview of the location, including historical significance, cultural importance, or interesting facts if applicable. Keep your response conversational and engaging."
)

# UI with simple bslib page_sidebar
ui <- page_sidebar(
  padding = 0,
  sidebar = sidebar(
    width = 350,
    title = "AI-powered Location Explorer",
    p(
      "Search for a location with the map's geocoder, and I'll tell you interesting facts about it!"
    ),
    hr(),
    output_markdown_stream("location_info")
  ),

  # Main content area with the map
  mapboxglOutput("map", height = "100%"),
)

# Server
server <- function(input, output, session) {
  # Initialize map with Mapbox geocoder
  output$map <- renderMapboxgl({
    mapboxgl(
      center = c(0, 0),
      zoom = 1
    ) |>
      add_geocoder_control(
        position = "top-right",
        placeholder = "Search for a location...",
        collapsed = FALSE
      )
  })

  # React to geocoding results
  observeEvent(input$map_geocoder, {
    geocode_result <- input$map_geocoder$result

    if (!is.null(geocode_result)) {
      # Create prompt for the LLM
      prompt <- paste(
        "Please tell me about this location:",
        toJSON(geocode_result),
        "\nProvide a brief overview focusing on why this place is significant or interesting."
      )

      # Use ellmer's built-in streaming async functionality
      stream <- llm_chat$stream_async(prompt)

      # Stream the response to the markdown output
      markdown_stream(
        id = "location_info",
        content_stream = stream,
        operation = "replace"
      )
    }
  })
}

# Run the app
shinyApp(ui, server)
