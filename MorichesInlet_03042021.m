clearvars; close all; clc;
%% DESCMIPTION: Generate the Moriches Inlet patch for insertion into the GSBv4 msh.
% AUTHOR: KEITH ROBERTS
% LAST UPDATE: March 4, 2021

%% DECLARE PARAMETERS FOR MESHING

% triangle res at outer bbox 100m

% The barMIer representation (these are the endpoints of the crestline).
WEIR_STRUCT.X = [ -72.75836873 ; -72.75238354	]; %
WEIR_STRUCT.Y = [40.76579106; 40.76486749];

% -72.75836873	40.76579106
% -72.75238354	40.76486749

MI = mean([ WEIR_STRUCT.Y, WEIR_STRUCT.X]); 

WEIR_STRUCT.width = 10;  % 10-m wide
WEIR_STRUCT.min_ele = 40; % 40-m element sizes on front/back faces
WEIR_STRUCT.crest_height=5; % assume a height of 5-m above the free surface.

BSZ = 0.08;
BBOXES{1} = [MI(2)-BSZ MI(2)+BSZ; MI(1)-BSZ MI(1)+BSZ];

BSZ = 0.05;
BBOXES{2} = [MI(2)-BSZ MI(2)+BSZ; MI(1)-BSZ MI(1)+BSZ];


COASTLINE = 'NCEI_Sandy_DEMs_1m_NAVD88_contour';
FLOODLINE = 'NCEI_Sandy_DEMs_10m_NAVD88_contour';
DEM       = '/Volumes/KeithJaredR/MESHING_DATASETS/DEMS/NCEI_Sandy_DEMs_13and19asec.KRcleanup20191111.nc';

DT        = 0.5;            % DESIRABLE STABLE TIMESTEP
H0        = [30,10];        % MIMIMUM MESH RESOLUTION IN METERS
FSS        = [3,10];             % NUMBER OF POSSIBLE ELEMENTS ACROSS CHANNEL WIDTH
MAX_EL_NS = 100;            % MAXIMUM ELEMENT SIZE NEARSHORE
SLP       = 15;             % NUMBER OF NODES PER GRADIENT OF BATHY
MAX_ELS{1}    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
    1e3 inf 0];    % Overland, maximum mesh resolution in meters.
MAX_ELS{2}    = [1e3 0 -inf     % Globally, maximum mesh resolution in meters.
    100 inf 0];    % Overland, maximum mesh resolution in meters.
GRADES{1}     = [0.25 0 -inf    % Use a spatially vaMIable gradation rate overland.
    0.35 inf 0] ;
GRADES{2}     = [0.15 0 -inf    % Use a spatially vaMIable gradation rate overland.
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

m4 = lim_bathy_slope(m,0.10);
%% Plots and wMIte to dis
% plot(m2,'b'); % pretty plot
% plot(m2,'bmesh');
% plot(m2,'resolog');
% plot(m2,'bd');
m4 = make_bc(m4,'weirs',gdat{2});

save MI m4

save MI_GDAT gdat

