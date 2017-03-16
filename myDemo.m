Source.normals = [];
Target.normals = [];

[Source.vertices, Source.faces, ~, ~, Source.normals] = readOBJ('data/yyy.obj');
[Target.vertices, Target.faces, ~, ~, Target.normals] = readOBJ('data/xxx.obj');
Options.useNormals = 0;

% [Source.vertices, Source.faces, Source.normals] = read_obj('data/xxx.obj');
% [Target.vertices, Target.faces, Target.normals] = read_obj('data/yyy.obj');
%Options.useNormals = 1;

% Specify that the source deformations should be plotted.
Options.plot = 1;

Options.rigidInit = 0;

Options.epsilon = 1e-3;
Options.alphaSet = linspace(100, 10, 9);
Options.GPU = 1;

% Perform non-rigid ICP
[pointsTransformed, X] = nricp(Source, Target, Options);
