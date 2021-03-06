clearvars; close all; clc;
%% DESCSIPTION: Generate the Shinnecock Inlet patch for insertion into the GSBv4 msh.
% AUTHOR: KEITH ROBERTS
% LAST UPDATE: March 4, 2021

%% DECLARE PARAMETERS FOR MESHING

% triangle res at outer bbox 87m

% The barSIer representation (these are the endpoints of the crestline).
WEIR_STRUCT.X = [  -72.47834598 ; -72.47359815	]; %
WEIR_STRUCT.Y = [  40.84214568  ;  40.84226792  ];

% -72.47834598	40.84214568
% -72.47359815	40.84226792


SI = mean([ WEIR_STRUCT.Y, WEIR_STRUCT.X]); 

WEIR_STRUCT.width = 10;  % 10-m wide
WEIR_STRUCT.min_ele = 40; % 40-m element sizes on front/back faces
WEIR_STRUCT.crest_height=5; % assume a height of 5-m above the free surface.

BSZ = 0.03;
BBOXES{1} = [SI(2)-BSZ SI(2)+BSZ; SI(1)-BSZ SI(1)+BSZ];

% 0.020 x 0.020 degree box around SI with 10-m SIn. resolution
BSZ = 0.020;
BBOXES{2} = [SI(2)-BSZ SI(2)+BSZ; SI(1)-BSZ SI(1)+BSZ];


COASTLINE = 'NCEI_Sandy_DEMs_1m_NAVD88_contour';
FLOODLINE = 'NCEI_Sandy_DEMs_10m_NAVD88_contour';
DEM       = '/Volumes/KeithJaredR/MESHING_DATASETS/DEMS/NCEI_Sandy_DEMs_13and19asec.KRcleanup20191111.nc';


DT        = 0.5;            % DESIRABLE STABLE TIMESTEP
H0        = [30,15];        % MINIMUM MESH RESOLUTION IN METERS
FSS        = [3,10];             % NUMBER OF POSSIBLE ELEMENTS ACROSS CHANNEL WIDTH
MAX_EL_NS = 100;            % MAXIMUM ELEMENT SIZE NEARSHORE
SLP       = 15;             % NUMBER OF NODES PER GRADIENT OF BATHY
MAX_ELS{1}    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
    150 inf 0];    % Overland, maximum mesh resolution in meters.
MAX_ELS{2}    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
    100 inf 0];    % Overland, maximum mesh resolution in meters.
GRADES{1}     = [0.25 0 -inf    % Use a spatially vaSIable gradation rate overland.
    0.35 inf 0] ;
GRADES{2}     = [0.15 0 -inf    % Use a spatially vaSIable gradation rate overland.
    0.05 inf 0] ;
SMOOTHING_WINDOW = 1;       % TURN OFF MOVING AVERAGE COASTLINE WINDOW SMOOTHING

%% BUILD GEOMETRY AND SIZING FUNCTION
for i = 1 : length(BBOXES)
    
    BBOX = BBOXES{i};
    MIN_EL = H0(i);
    MAX_EL = MAX_ELS{i};
    GRADE = GRADES{i};
    FS = FSS(i);
    
    if i == 2
        gdat{i} = geodata('shp',FLOODLINE,...
            'dem',DEM,...
            'bbox',BBOX,...
            'h0',MIN_EL,...
            'window',SMOOTHING_WINDOW,...
            'weirs',WEIR_STRUCT);
    else
        gdat{i} = geodata('shp',FLOODLINE,...
            'dem',DEM,...
            'bbox',BBOX,...
            'h0',MIN_EL,...
            'window',SMOOTHING_WINDOW);
    end
    
    fh{i} = edgefx('geodata',gdat{i},...
        'fs',FS,...
        'max_el_ns',MAX_EL_NS,...
        'max_el',MAX_EL,...
        'slp',SLP,...
        'g',GRADE,...
        'dt',DT);
end


%% BUID MESH
mshopts = meshgen('ef',fh,'bou',gdat,'plot_on',1);

m = mshopts.build.grd;

%% INTERPOLATE TOPOBATHY AND MAKE SURE ITS SMOOTH
m = interp(m,DEM);
sum(isnan(m.b))   % QA  should be ==0

m4 = lim_bathy_slope(m,0.10);

%%% run pit filling script here %%%

%% Plots and wSIte to dis
% plot(m2,'b'); % pretty plot
% plot(m2,'bmesh');
% plot(m2,'resolog');
% plot(m2,'bd');

m4 = make_bc(m4,'weirs',gdat{2});

save SI m4

save SI_GDAT gdat

%�write(m4, 'SI_hires_mesh_NoWeir', '14')
