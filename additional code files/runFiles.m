% change this to the local folder path on your device
filelist = dir(fullfile('D:\emfisis\source files\gold', '*.mat'))

for iFile = 1:size(filelist, 1)
  filename = filelist(iFile).name
  burstname = sprintf('%s', filename(1:end-4));
%   filenamenew = sprintf('C:\\Users\\robin\\Desktop\\emfisis\\source files\\green\\%s', filename);
  filenamenew = sprintf('D:\\emfisis\\source files\\gold\\%s', filename)
  load(filenamenew);
  runFile;
%   numChorus
  clearvars -except filelist
end
