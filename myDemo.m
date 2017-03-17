Source.normals = [];
Target.normals = [];

[Source.vertices, Source.faces, ~, ~, Source.normals] = readOBJ('data/yyy.obj');
[Target.vertices, Target.faces, ~, ~, Target.normals] = readOBJ('data/xxx.obj');
Options.useNormals = 0;

% [Source.vertices, Source.faces, Source.normals] = read_obj('data/xxx.obj');
% [Target.vertices, Target.faces, Target.normals] = read_obj('data/yyy.obj');
%Options.useNormals = 1;

Options.useMarker = 0;
Options.snapTarget = 0;
Options.rigidInit = 0;
Options.beta = 1;
Options.epsilon = 1e-4;
Options.alphaSet = linspace(100, 10, 10);
Options.GPU = 0;

Options.plot = 1;
Options.verbose = 1;

% Perform non-rigid ICP
[pointsTransformed, X] = onricp(Source, Target, Options);
