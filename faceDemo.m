%% Demo 1: Use surface normals

% Load data
load data/faceSource.mat
load data/faceTarget.mat

% Specify that surface normals are available and can be used.
Options.useNormals = 0;

% Specify that the source deformations should be plotted.
Options.plot = 1;


Options.epsilon = 1e-4;
Options.alphaSet = linspace(100, 10, 9);
Options.GPU = 0;
Options.rigidInit = 0;

% Perform non-rigid ICP
[pointsTransformed, X] = nricp(Source, Target, Options);
