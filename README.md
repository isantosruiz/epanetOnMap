# epanetOnMap
Reads EPANET .INP files and plots pipes plus junction/reservoir markers on MATLAB geographic basemaps.

## Summary
**epanetOnMap** is a flexible MATLAB function for visualizing EPANET network layouts on geographic maps. It reads a standard EPANET .INP file (including [COORDINATES], [PIPES], [RESERVOIRS], and optional [VERTICES] sections), converts UTM coordinates to latitude/longitude, and renders pipes (including curved segments) and nodes (junctions and reservoir markers) on customizable basemaps. Users can specify UTM zone and hemisphere, choose between ‘streets’, ‘satellite’, and other basemap styles, and adjust pipeline line width/color, junction marker size/color, and reservoir marker size/color via Name–Value parameters. This tool simplifies the geospatial inspection of water distribution networks directly within MATLAB.

## Documentation
```matlab
% epanetOnMap  Plots pipes of an EPANET network (.INP) with UTM coordinates,
%              converting them to lat/lon and displaying on a geographic map.
%              Supports junction nodes, reservoirs, and pipe geometry.
%
%   epanetOnMap(inpFile, zoneUTM, hemisphere, Name,Value, ...) accepts:
%     inpFile          : path/filename of the EPANET .INP file (char/string)
%     zoneUTM          : integer (1-60), UTM zone (default: 14)
%     hemisphere       : 'N' or 'S' for north or south (default: 'N')
%     Name,Value pairs to customize:
%       'LineWidth'       : line width for pipes (numeric, default: 1)
%       'LineColor'       : line color for pipes (char/string or RGB 1x3, default: 'r')
%       'MarkerSize'      : marker size for nodes (numeric, default: 4)
%       'MarkerFaceColor' : fill color for junction markers (char/string or RGB 1x3, default: 'b')
%       'ReservoirSize'   : marker size for reservoirs (numeric, default: 5)
%       'ReservoirColor'  : color for square reservoir markers (char/string or RGB 1x3, default: [0 0.8 0])
%       'Basemap'         : type of basemap (char/string: 'streets','satellite',...; default: 'streets')
%
%   EXAMPLE 1:
%     epanetOnMap('Guanajuato.inp')
%   EXAMPLE 2:
%     epanetOnMap('Madrid1.inp', 30, 'N', ...
%         'LineWidth',1.5, 'LineColor',[1 1 0], ...
%         'MarkerSize',4, 'MarkerFaceColor','c', ...
%         'ReservoirSize',5, 'ReservoirColor',[0 0.8 0], ...
%         'Basemap','satellite');
%
% AUTHOR: Ildeberto de los Santos Ruiz
% DATE: June 9, 2025
% REQUIRES: MATLAB R2020b+ & Mapping Toolbox

