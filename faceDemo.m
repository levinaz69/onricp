%% Demo 1: Use surface normals

% Load data
load data/faceSource.mat
load data/faceTarget.mat

Options.snapTarget = 0;
Options.useNormals = 0;
Options.plot = 1;
Options.useMarker = 0;
Options.beta = 1;
Options.verbose = 1;
Options.epsilon = 1e-4;
Options.alphaSet = linspace(100, 10, 10);
Options.GPU = 0;
Options.rigidInit = 0;

% Perform non-rigid ICP
[pointsTransformed, X] = onricp(Source, Target, Options);
