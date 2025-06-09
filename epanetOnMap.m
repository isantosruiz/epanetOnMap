function epanetOnMap(inpFile, varargin)
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

    %% Parse arguments
    p = inputParser;
    addRequired(p, 'inpFile', @(x) ischar(x) || isStringScalar(x));
    addOptional(p, 'zoneUTM', 14, @(x) isnumeric(x) && isscalar(x) && x>=1 && x<=60);
    addOptional(p, 'hemisphere', 'N', @(x) any(strcmpi(x,{'N','S'})));
    isColor = @(x) (ischar(x) || isStringScalar(x)) || ...
               (isnumeric(x) && isvector(x) && numel(x)==3 && all(x>=0) && all(x<=1));
    addParameter(p, 'LineWidth', 1, @(x) isnumeric(x) && isscalar(x) && x>0);
    addParameter(p, 'LineColor', 'r', isColor);
    addParameter(p, 'MarkerSize', 4, @(x) isnumeric(x) && isscalar(x) && x>0);
    addParameter(p, 'MarkerFaceColor', 'b', isColor);
    addParameter(p, 'ReservoirSize', 5, @(x) isnumeric(x) && isscalar(x) && x>0);
    addParameter(p, 'ReservoirColor', [0 0.8 0], isColor);
    addParameter(p, 'Basemap', 'streets', @(x) ischar(x) || isStringScalar(x));
    parse(p, inpFile, varargin{:});

    %% Get parameters
    inpFile         = p.Results.inpFile;
    zoneUTM         = p.Results.zoneUTM;
    hemisphere      = char(p.Results.hemisphere);
    lineWidth       = p.Results.LineWidth;
    lineColor       = p.Results.LineColor;
    markerSize      = p.Results.MarkerSize;
    markerFaceColor = p.Results.MarkerFaceColor;
    reservoirSize   = p.Results.ReservoirSize;
    reservoirColor  = p.Results.ReservoirColor;
    basemapType     = char(p.Results.Basemap);

    %% Read .INP file
    fid = fopen(inpFile, 'r');
    if fid < 0
        error('Could not open INP file: %s', inpFile);
    end
    raw = textscan(fid, '%s', 'Delimiter','\n', 'Whitespace','');
    lines = raw{1};
    fclose(fid);

    %% Initialize data structures
    nodeCoordinates = containers.Map('KeyType','char', 'ValueType','any');
    pipeList        = {};
    reservoirList   = {};
    pipeVertices    = containers.Map('KeyType','char', 'ValueType','any');

    currentSection = '';
    for i = 1:numel(lines)
        ln = strtrim(lines{i});
        if isempty(ln) || startsWith(ln, ';')
            continue;
        end
        if startsWith(ln, '[') && endsWith(ln, ']')
            currentSection = upper(ln);
            continue;
        end
        switch currentSection
            case '[COORDINATES]'
                tk = regexp(ln, '\S+', 'match'); % Improved parsing
                if numel(tk) >= 3
                    nodeId = tk{1};
                    x = str2double(tk{2});
                    y = str2double(tk{3});
                    if ~isnan(x) && ~isnan(y)
                        nodeCoordinates(nodeId) = [x, y];
                    end
                end
            case '[PIPES]'
                tk = regexp(ln, '\S+', 'match');
                if numel(tk) >= 3
                    pipeList(end+1, :) = {tk{1}, tk{2}, tk{3}}; %#ok<AGROW>
                end
            case '[RESERVOIRS]'
                tk = regexp(ln, '\S+', 'match');
                if ~isempty(tk)
                    reservoirList{end+1} = tk{1}; %#ok<AGROW>
                end
            case '[VERTICES]'
                tk = regexp(ln, '\S+', 'match');
                if numel(tk) >= 3
                    pipeId = tk{1};
                    x = str2double(tk{2});
                    y = str2double(tk{3});
                    if ~isnan(x) && ~isnan(y)
                        if ~isKey(pipeVertices, pipeId)
                            pipeVertices(pipeId) = [];
                        end
                        pipeVertices(pipeId) = [pipeVertices(pipeId); x, y];
                    end
                end
        end
    end

    %% Check essential data
    if isempty(nodeCoordinates)
        error('Section [COORDINATES] not found.');
    end
    if isempty(pipeList)
        error('Section [PIPES] not found.');
    end

    %% Define UTM CRS
    if strcmpi(hemisphere, 'N')
        epsgCode = 32600 + zoneUTM;
    else
        epsgCode = 32700 + zoneUTM;
    end
    crsUTM = projcrs(epsgCode);

    %% Create figure and geographic axes
    figure;
    ga = geoaxes;
    hold(ga, 'on');
    try
        geobasemap(ga, basemapType);
    catch
        warning('Could not load basemap ''%s''.', basemapType);
    end

    %% Draw pipes with intermediate vertices
    for k = 1:size(pipeList, 1)
        pipeId    = pipeList{k, 1};
        startNode = pipeList{k, 2};
        endNode   = pipeList{k, 3};

        if ~isKey(nodeCoordinates, startNode) || ~isKey(nodeCoordinates, endNode)
            continue;
        end

        sequence = nodeCoordinates(startNode);
        if isKey(pipeVertices, pipeId)
            sequence = [sequence; pipeVertices(pipeId)];
        end
        sequence = [sequence; nodeCoordinates(endNode)];

        [latSeq, lonSeq] = projinv(crsUTM, sequence(:,1), sequence(:,2));
        geoplot(ga, latSeq, lonSeq, 'Color', lineColor, 'LineWidth', lineWidth);
    end

    %% Mark nodes (junctions and reservoirs)
    nodeIds = keys(nodeCoordinates);
    numNodes = numel(nodeIds);
    latitudes = zeros(numNodes, 1);
    longitudes = zeros(numNodes, 1);
    isReservoir = false(numNodes, 1);

    for j = 1:numNodes
        coords = nodeCoordinates(nodeIds{j});
        [latitudes(j), longitudes(j)] = projinv(crsUTM, coords(1), coords(2));
        if any(strcmp(nodeIds{j}, reservoirList))
            isReservoir(j) = true;
        end
    end

    % Junctions (circles)
    idxJunctions = ~isReservoir;
    if any(idxJunctions)
        geoplot(ga, latitudes(idxJunctions), longitudes(idxJunctions), 'o', ...
            'MarkerSize', markerSize, ...
            'MarkerFaceColor', markerFaceColor, ...
            'MarkerEdgeColor', markerFaceColor);
    end

    % Reservoirs (squares)
    idxReservoirs = isReservoir;
    if any(idxReservoirs)
        geoplot(ga, latitudes(idxReservoirs), longitudes(idxReservoirs), 's', ...
            'MarkerSize', reservoirSize, ...
            'MarkerFaceColor', reservoirColor, ...
            'MarkerEdgeColor', reservoirColor);
    end

    hold(ga, 'off');
end