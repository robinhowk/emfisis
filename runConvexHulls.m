% change this to the local folder path on your device
filelist = dir(fullfile('/run/media/rhowk/SANDISK/emfisis/source files/gold', '*.mat'))

for iFile = 1:size(filelist, 1)
  filename = filelist(iFile).name
  burstname = sprintf('%s', filename(1:end-4));
  % change this to the local folder path on your device
  filenamenew = sprintf('/run/media/rhowk/SANDISK/emfisis/source files/gold/%s', filename);
  load(filenamenew);
  convexHullsScript;
%   numChorus
  clearvars -except filelist
end
