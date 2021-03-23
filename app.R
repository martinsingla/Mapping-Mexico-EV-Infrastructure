# Mexico Shiny Map
rm(list= ls())

library(tidyverse)
library(sf)
library(leaflet)
library(shiny)

# Data
dat <- st_read("data/cargadores_mexico_clean.geojson")
mex <- st_read("data/estados_mexico/estados_mexico.shp")
mex$ESTADO <- c("BAJA CALIFORNIA", "BAJA CALIFORNIA SUR", "NAYARIT", "JALISCO", "AGUASCALIENTES", "GUANAJUATO",
                "QUERETARO DE ARTEAGA", "HIDALGO", "MICHOACAN DE OCAMPO", "MEXICO", "DISTRITO FEDERAL", "COLIMA", "MORELOS", "YUCATAN", "CAMPECHE", 
                "PUEBLA", "QUINTANA ROO", "TLAXCALA", "GUERRERO", "OAXACA", "TABASCO", "CHIAPAS", "SONORA", "CHIHUAHUA", 
                "COAHUILA DE ZARAGOZA", "SINALOA", "DURANGO", "ZACATECAS", "SAN LUIS POTOSI", "NUEVO LEON", "TAMAULIPAS", 
                "VERACRUZ DE IGNACIO DE LA LLAVE")

estados <- c("All", unique(mex$ESTADO))
networks <- c("All", unique(dat$network))
connectors <- c("All", "CHAdeMO", "SAEJ1772", "Combo1", "Tesla")
facilities <- c("All", unique(dat$t_loc))

crs <- "+proj=utm +zone=19 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"

#UI
ui <- fluidPage(
  h1("MEXICO - EV Infrastructure Interactive Map (Frost & Sullivan v1.0 - 22.3.2021)", 
     style= "font-size:19px;"),
  sidebarLayout(
    sidebarPanel(
      img(src= "fs-logo2.png", align = "center" , height= 50, width= 230 ),
      width = 3,
      selectInput(
        inputId = "state", 
        label = "Filter State/Province", 
        choices = estados, 
        selected = "All"
      ),
      selectInput(
        inputId = "network",
        label = "Filter Operator/Network",
        choices = networks,
        selected = "All", 
        multiple = TRUE
      ),
      selectInput(
        inputId = "connector",
        label = "Filter Connector Type",
        choices = connectors,
        selected = "All",
        multiple = TRUE
      ),
      radioButtons(
        inputId = "speed",
        label = "Filter Charging Speed",
        choiceNames = c("All", "Slow/Medium", "Fast Charging"), 
        choiceValues = c("All", "Media", "Rápida"),
        inline = TRUE, 
        selected = "All"
      ),
      selectInput(inputId = "facilities", 
                  label= "Filter Facility Type",
                  choices = facilities,
                  selected = "All", 
                  multiple = TRUE
      ),
      radioButtons(inputId = "buffer", 
                   label = "Additional: Plot area buffer",
                   choiceNames = c("None" ,"500m", "2km","5km","10km"),
                   choiceValues = c("no_buf", 500, 2000, 5000, 10000), 
                   inline = TRUE,
                   selected = "no_buf"
      ),
      actionButton("execute", label = "Find Chargers!", icon("charging-station"), 
                   style="color: #fff; background-color: #337ab7; border-color: #2e6da4")
    ),
    mainPanel(
      width = 9,
      leafletOutput("my_map", height = 650)
    )
  )
)

# Server
server <- function(input, output){
  
  #Data selection reactive
  
  filterData <- eventReactive(input$execute, {
    #filter state
    if("All" %in% input$state){
      a <- dat
    } else if (is.null(input$state)){
      a <- dat
    } else {
      a <- dat[dat$ENTIDAD == input$state,]
    }
    #filter network
    if("All" %in% input$network | is.null(input$network)){
      a <- a
    } else {
      a <- a[a$network %in% input$network,]
    }
    #filter connector
    if("All" %in% input$connector | is.null(input$connector)){
      a <- a
    } else {
      if("CHAdeMO" %in% input$connector){
        a <- a[a$con_CHAdeMO == 1,]
      }
      if("SAEJ1772" %in% input$connector){
        a <- a[a$con_SAEJ1772 ==1,]
      }
      if("Combo1" %in% input$connector){
        a <- a[a$con_Combo1 ==1,]
      }
      if("Tesla" %in% input$connector){
        a <- a[a$con_tesla ==1,]
      }
    }
    #filter speed
    if(input$speed == "All"){
      a <- a
    } else {
      if(input$speed == "Media"){
        a <- a[a$nvl_carga == "Media",]
      } else {
        if(input$speed == "Rápida"){
          a <- a[a$nvl_carga == "Rápida",]
        }
      }
    }
    #filter facilities
    if("All" %in% input$facilities | is.null(input$facilities)){
      a <- a
    } else {
      a <- a[a$t_loc %in% input$facilities,]
    }
    a
  })
  
  #Coordinates/Zoom  Reactive
  lngCoord <- eventReactive(input$execute, {
    if(input$state == "All"){
      -101.447174
    } else {
      st_coordinates(st_centroid(mex[mex$ESTADO == input$state,]))[1]
    }
  })
  latCoord <- eventReactive(input$execute, {
    if(input$state == "All"){
      21.984955
    } else {
      st_coordinates(st_centroid(mex[mex$ESTADO == input$state,]))[2] 
    }
  })
  zoom <- eventReactive(input$execute, {
    if(input$state == "All"){
      5
    } else {
      8
    }
  })
  
  #Buffer selection reactive
  buffer <- eventReactive(input$execute, {
    if(input$buffer == "no_buf"){
      dat %>%
        filter(ID == 64) %>%
        st_transform(crs) %>%
        st_buffer(dist= 0.001) %>%
        st_transform(4326)
    } else {
      filterData() %>%
        st_transform(crs = crs) %>%
        st_buffer(dist = as.numeric(input$buffer)) %>%
        st_transform(4326)
    }
  })
  
  #Colors
  pal_net <- colorFactor(palette = "Set1", domain = networks)
  
  #Map rendering
  output$my_map <- renderLeaflet({
    
    leaflet() %>%
      
      #Base tiles
      addProviderTiles("CartoDB.Positron", group = "Basemap: CartoDB (default)") %>% 
      addTiles(group = "Basemap: OpenStreetMap") %>%
      addProviderTiles("Esri.WorldImagery", group="Basemap: ESRI Satelite") %>% 
      
      #country map
      addPolygons(data= mex, color = "blue", weight = 1, fill = NA) %>%
      
      #controls
      addLayersControl(baseGroups = c("Basemap: CartoDB (default)", 
                                      "Basemap: OpenStreetMap",
                                      "Basemap: ESRI Satelite"),
                       position= "bottomright", 
                       options = layersControlOptions(collapsed = FALSE))
  })
  
  observe({
    proxy <- leafletProxy("my_map")
    proxy %>%
      #set zoom and coords
      setView(lng = lngCoord(), lat = latCoord(), zoom = zoom()) %>%
      
      clearShapes()%>%
      clearMarkers() %>%
      #country map
      addPolygons(data= mex, color = "blue", weight = 1, fill = NA) %>%
      
      #buffers
      addPolygons(data= buffer(), stroke = FALSE, fillOpacity = 0.1) %>%
      
      #chargers
      addCircleMarkers(data= filterData(),
                 color = ~pal_net(filterData() %>% pull(network)), 
                 radius = 3, opacity = 2, 
                 label = ~network,
                 popup = ~paste(paste("Nombre: ", Nombre, sep = ""),
                                paste("Address: ", Dir, sep= ""),
                                paste("Estado: ", ENTIDAD, sep=""),
                                paste("Operated by: ", network, sep = ""), 
                                paste("Conectors: ", t_conector, " (", n_conectores, ") ",  sep= ""),
                                paste("Charge Lvl: ", nvl_carga, sep = ""),
                                sep = "<br/>"),
                 group = "networks") %>%
      
      #legends & contorls
      clearControls() %>%
      addLegend(position = "topleft", pal = pal_net, values = filterData() %>% pull(network), group = "networks") 
  })
  
}


#Execute Shiny
shinyApp(ui = ui, server= server)



