function [ figname, resultFilename, imagefile, imagefile1, fspec ] = setupBurst( filename, datafilename, paramstring, figFolder, resultsFolder, freqLimit, delta_psd )
%SETUPBURST Creates filenames and trims psd to fce limit. Returns
%imagefile, the trimmed psd, and imagefile1, the trimmed psd thresholded at
%delta_psd

    load(datafilename);
    figname = sprintf('%s/%s_%s.jpg', figFolder, strtok(filename, '.'), paramstring);
    resultFilename = sprintf('%s/%s_result.mat', resultsFolder, strtok(filename, '.'));
    % trim psd to freq limit
    if ~isempty(freqLimit)
       imagefile = psd(1:freqLimit, :);
       fspec = fspec(1:freqLimit);
    else
        imagefile = psd;
    end
    % threshold at delta_psd
    imagefile1 = 10*log10(imagefile);
    imagefile1(imagefile1 < delta_psd) = delta_psd;
end

