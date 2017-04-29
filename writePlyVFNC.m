function writePlyVFNC(filename,V,F,N,C,mode)
  % WRITEPLY wrapper for write_ply
  %
  % Inputs:
  %   filename  path to output .ply file
  %   V  #V by 3 list of mesh vertex positions
  %   F  #F by 3 list of mesh triangle indices
  %   N  #N by 3 list of mesh normal vectors
  %   mode  followed by
  %      'ascii'                ASCII text data
  %      {'binary_little_endian'}   binary data, little endian
  %      'binary_big_endian'      binary data, big endian
  %
  %
  
  if nargin < 5
    mode = 'binary_little_endian';
  end

  fid = fopen(filename,'wt');
  fprintf(fid,'ply\nformat %s 1.0\n',mode);
  fprintf(fid,'element vertex %d\n',size(V,1));
  fprintf(fid,'property float x\n');
  fprintf(fid,'property float y\n');
  fprintf(fid,'property float z\n');
  fprintf(fid,'property float nx\n');
  fprintf(fid,'property float ny\n');
  fprintf(fid,'property float nz\n');
  fprintf(fid,'property uchar red\n');
  fprintf(fid,'property uchar green\n');
  fprintf(fid,'property uchar blue\n');
  fprintf(fid,'element face %d\n',size(F,1));
  fprintf(fid,'property list int int vertex_indices\n');
  fprintf(fid,'end_header\n');
  FF = [size(F,2)*ones(size(F,1),1) F-1];
  switch mode
  case 'ascii'
    % do nothing
    fprintf(fid,'%f %f %f %f %f %f %u %u %u\n',[V N C]');
    format = [repmat('%d ',1,size(FF,2)) '\n'];
    fprintf(fid,format,FF');
  case {'binary_little_endian','binary_big_endian'}
    fclose(fid);
    switch mode
    case 'binary_little_endian'
      fid = fopen(filename,'a','ieee-le');
    case 'binary_big_endian'
      fid = fopen(filename,'a','ieee-be');
    end
    for i = 1:size(V,1)
        fwrite(fid,V(i,:)','float');
        fwrite(fid,N(i,:)','float');
        fwrite(fid,C(i,:)','uchar');
    end
    fwrite(fid,FF','int');
  otherwise
    error('Unsupported format: %s',mode);
  end
  fclose(fid);

  %% OLD 200x slower way (possible to produce slightly smaller files and control
  %% over precision)
  %write_ply(V,F,filename,mode);
end
