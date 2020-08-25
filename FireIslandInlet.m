clearvars; close all; clc;
%% DESCRIPTION: Generate the Fire Island water-tight patch for insertion into the GSBv4 msh.
% AUTHOR: KEITH ROBERTS
% DATE: August 25, 2020

%% DECLARE PARAMETERS FOR MESHING
FI = [40.629540, -73.266107]; % Midpoint of proposed Fire Island barrier

% The barrier representation (these are the endpoints of the crestline).
FI_WEIR_STRUCT.X = [-73.264359 ; -73.265105];
FI_WEIR_STRUCT.Y = [ 40.623740 ;  40.636200]; %.624740
FI_WEIR_STRUCT.width = 10;  % 10-m wide
FI_WEIR_STRUCT.min_ele = 30; % 30-m element sizes on front/back faces
FI_WEIR_STRUCT.crest_height=5; % assume a height of 5-m above the free surface.

% 0.05 x 0.05 degree box around FI with 25-m min. resolution
BSZ = 0.05;
BBOXES{1} = [FI(2)-BSZ FI(2)+BSZ; FI(1)-BSZ FI(1)+BSZ];

% 0.025 x 0.025 degree box around FI with 10-m min. resolution
BSZ = 0.025;
BBOXES{2} = [FI(2)-BSZ FI(2)+BSZ; FI(1)-BSZ FI(1)+BSZ];


COASTLINE = 'NCEI_Sandy_DEMs_1m_NAVD88_contour';
FLOODLINE = 'NCEI_Sandy_DEMs_10m_NAVD88_contour';
DEM       = 'NCEI_Sandy_DEMs_13and19asec.HBcleanup20191111.nc';

DT        = 0.5;            % DESIRABLE STABLE TIMESTEP
H0        = [25,10];        % MINIMUM MESH RESOLUTION IN METERS
FS        = 10;             % NUMBER OF POSSIBLE ELEMENTS ACROSS CHANNEL WIDTH
MAX_EL_NS = 100;            % MAXIMUM ELEMENT SIZE NEARSHORE
SLP       = 15;             % NUMBER OF NODES PER GRADIENT OF BATHY
MAX_EL    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
    100 inf 0];    % Overland, maximum mesh resolution in meters.
GRADE     = [0.15 0 -inf    % Use a spatially variable gradation rate overland.
    0.05 inf 0] ;
SMOOTHING_WINDOW = 1;       % TURN OFF MOVING AVERAGE COASTLINE WINDOW SMOOTHING
%% BUILD GEOMETRY AND SIZING FUNCTION
for i = 1 : 2
    BBOX = BBOXES{i};
    MIN_EL = H0(i);

    gdat{i} = geodata('shp',COASTLINE,...
        'dem',DEM,...
        'bbox',BBOX,...
        'h0',MIN_EL,...
        'window',SMOOTHING_WINDOW);
    
    fh{i} = edgefx('geodata',gdat{i},...
        'fs',FS,...
        'max_el_ns',MAX_EL_NS,...
        'max_el',MAX_EL,...
        'slp',SLP,...
        'g',GRADE,...
        'dt',DT);
end
%% BUID MESH WATER-TIGHT MESH ONLY
mshopts = meshgen('ef',fh,'bou',gdat);

muw = mshopts.build.grd;

%% EXTRACT "SHORELINE" CONSTRAINTS

m1 = make_bc(muw,'auto',gdat{1}) ;           % Apply boundary conditions automatically

[pfix,egfix] = extractFixedConstraints(m1) ; % extract shoreline constraints

%% Remove egfix and egfix nearby weir by creating a wider weir.
FI_WEIR_STRUCT.width=200; % of width 200-m
dmy = geodata('shp',COASTLINE,...
    'bbox',BBOX,...
    'h0',MIN_EL,...
    'weirs',FI_WEIR_STRUCT);
FI_WEIR_STRUCT.width = 10; % % set width back to original 10-m wide

% Remove edges if midpoint of edge is inside dummy weir
egfix_mid = (pfix(egfix(:,1),:) + pfix(egfix(:,2),:))/2;
inbar = inpoly(egfix_mid,dmy.weirPfix, dmy.weirEgfix);
inbar = sum(inbar,2) ;
egfix(inbar==1,:) = [];
tmppfix = pfix(unique(egfix(:)),:);
pfix = tmppfix;
egfix = renumberEdges(egfix);


%% CONSTRUCT GEOMETRY WITH FLOODPLAIN
for i = 1 : 2
    MIN_EL = H0(i);
    BBOX = BBOXES{i};
    if i == 1
        gdat2{i} = geodata('shp',FLOODLINE,...
            'dem',DEM,...
            'bbox',BBOX,...
            'h0',MIN_EL,...
            'window',SMOOTHING_WINDOW);
    else
        gdat2{i} = geodata('shp',FLOODLINE,...
            'dem',DEM,...
            'bbox',BBOX,...
            'h0',MIN_EL,...
            'window',SMOOTHING_WINDOW,...
            'weirs',FI_WEIR_STRUCT);
    end
    
end

%% BUILD MESH RESPECTING POINT AND EDGE CONSTRAINTS

mshopts = meshgen('ef',fh,'bou',gdat2,'plot_on',1,...
    'pfix',pfix,'egfix',egfix,'fixboxes',[1,1]);

m2 = mshopts.build.grd;

%% INTERPOLATE TOPOBATHY AND MAKE SURE ITS SMOOTH
m3 = interpFP(m2,gdat2{1},muw,gdat{1});

m4 = lim_bathy_slope(m3,0.10);
%% Plots and write to dis
% plot(m2,'b'); % pretty plot
% plot(m2,'bmesh');
% plot(m2,'resolog');
% plot(m2,'bd');
m4 = make_bc(m4,'weirs',gdat2{2}); 

save FI m4

