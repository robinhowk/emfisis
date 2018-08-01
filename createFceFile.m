function createFceFile( filename )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
 
    addpath 'matlab_cdf364_patch-64';   
    fileList = dir('data/fceSource/*.cdf');
    
    fid = fopen(filename, 'a');
    fprintf(fid, '# Epoch(UTC), 0.5*f_ce(Hz)');

    for fileIndex = 1:size(fileList)
        filename = sprintf('data/fceSource/%s', fileList(fileIndex).name);
        epochs = spdfcdfread(filename, 'Variable', 'Epoch', 'CDFEpochtoString', true);
        fce = spdfcdfread(filename, 'Variable', 'Buvw');
        
        epochs = cell2mat(epochs);
        epochs = epochs(:,1:23);
        
        for i = 1:size(fce,1)
            fprintf(fid, '\n%sZ, %G', epochs(i,:), sqrt(sum(fce(i,:).^2)) * 14);
        end
    end

    fclose('all');
end

