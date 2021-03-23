# Interactive Mapping Tool For Mexican Electric Vehicle (EV) Charging Infrastructure
The present R script creates an interactive mapping tool that visualizes EV charging infrastructure across Mexico (as per available in January 2021). Multiple filters are included that help to segment infrastructure availability by state/province, network/operator (e.g.: Tesla, CFE, etc.), connector type (e.g.: CHAdeMO, Combo1, etc.), power band (low, medium or fast charging) and facility type (e.g.:hotel, automotive dealership, shopping center, supermarket, etc.). Another feature is include to plot a buffer of X amount of KMs around each location , to account for density and area coverage.

The libraries utilized for this project include Tidyverse and sf (for spatial data manipulation), leaflet (R application from JavaScript's interactive mapping tool) and Shiny (to create interactive dashboards). The final output has been hosted as in https://msinga.shinyapps.io/Mexico-EV-Chargers/

The dataframe behind the present map visualization tool has been produced by the Frost & Sullivan mobility and automotive research team in January 2021.
