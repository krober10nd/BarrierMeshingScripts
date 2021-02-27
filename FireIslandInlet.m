clearvars; close all; clc;
%% DESCRIPTION: Generate the Fire Island water-tight patch for insertion into the GSBv4 msh.
% AUTHOR: KEITH ROBERTS
% LAST UPDATE: Feb. 27, 2021

% triangle res at outer bbox 110m
% reduce NS outer bbox to 0.375 deg
%% DECLARE PARAMETERS FOR MESHING
FI = [40.629540, -73.266107]; % Midpoint of proposed Fire Island barrier

% The barrier representation (these are the endpoints of the crestline).
FI_WEIR_STRUCT.X = [-73.264359 ; -73.265105]; %
FI_WEIR_STRUCT.Y = [ 40.623740 ;  40.636200]; %.624740
FI_WEIR_STRUCT.width = 10;  % 10-m wide
FI_WEIR_STRUCT.min_ele = 40; % 40-m element sizes on front/back faces
FI_WEIR_STRUCT.crest_height=5; % assume a height of 5-m above the free surface.

BSZ = 0.03;
BBOXES{1} = [FI(2)-BSZ FI(2)+BSZ; FI(1)-BSZ FI(1)+BSZ];

% 0.025 x 0.025 degree box around FI with 10-m min. resolution
BSZ = 0.025;
BBOXES{2} = [FI(2)-BSZ FI(2)+BSZ; FI(1)-BSZ FI(1)+BSZ];


COASTLINE = 'NCEI_Sandy_DEMs_1m_NAVD88_contour';
FLOODLINE = 'NCEI_Sandy_DEMs_10m_NAVD88_contour';
DEM       = '/Volumes/KeithJaredR/MESHING_DATASETS/DEMS/NCEI_Sandy_DEMs_13and19asec.KRcleanup20191111.nc';

DT        = 0.5;            % DESIRABLE STABLE TIMESTEP
H0        = [40,10];        % MINIMUM MESH RESOLUTION IN METERS
FSS        = [3,10];             % NUMBER OF POSSIBLE ELEMENTS ACROSS CHANNEL WIDTH
MAX_EL_NS = 100;            % MAXIMUM ELEMENT SIZE NEARSHORE
SLP       = 15;             % NUMBER OF NODES PER GRADIENT OF BATHY
MAX_ELS{1}    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
             1e3 inf 0];    % Overland, maximum mesh resolution in meters.
MAX_ELS{2}    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
             100 inf 0];    % Overland, maximum mesh resolution in meters.
GRADES{1}     = [0.25 0 -inf    % Use a spatially variable gradation rate overland.
    0.35 inf 0] ;
GRADES{2}     = [0.15 0 -inf    % Use a spatially variable gradation rate overland.
    0.05 inf 0] ;
SMOOTHING_WINDOW = 1;       % TURN OFF MOVING AVERAGE COASTLINE WINDOW SMOOTHING
%% BUILD GEOMETRY AND SIZING FUNCTION
for i = 1 : 2
    
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
            'weirs',FI_WEIR_STRUCT);
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
m = interp(m,gdat); 

m4 = lim_bathy_slope(m,0.10);
%% Plots and write to dis
% plot(m4,'b')       % pretty plot
% plot(m4,'bmesh')
% plot(m4,'resolog')
% plot(m4,'bd')
m4 = make_bc(m4,'weirs',gdat{2});    % manually specify: mode 1, 5m above MSL.

save FI m4

save gdat_fi_with weir gdat
%write(m4, 'FI_hires_mesh', '14')

