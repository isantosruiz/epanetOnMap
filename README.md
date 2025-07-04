# epanetOnMap
Plots pipes of an EPANET network (.INP) with UTM coordinates, converting them to lat/lon and displaying on a geographic map. Supports junction nodes, reservoirs, and pipe geometry.

## Summary
**epanetOnMap** is a flexible MATLAB function for visualizing EPANET network layouts on geographic maps. It reads a standard EPANET .INP file (including [COORDINATES], [PIPES], [RESERVOIRS], and optional [VERTICES] sections), converts UTM coordinates to latitude/longitude, and renders pipes (including curved segments) and nodes (junctions and reservoir markers) on customizable basemaps. Users can specify UTM zone and hemisphere, choose between ‘streets’, ‘satellite’, and other basemap styles, and adjust pipeline line width/color, junction marker size/color, and reservoir marker size/color via Name–Value parameters. This tool simplifies the geospatial inspection of water distribution networks directly within MATLAB.

## Documentation
Install and run the following command:
```matlab
help epanetOnMap

