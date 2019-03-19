% filelist = dir(fullfile('C:\Users\robin\Desktop\emfisis\files', '*.mat'))
filelist = dir(fullfile('D:\emfisis\files', '*.mat'))

for iFile = 1:size(filelist, 1)
  filename = filelist(iFile).name
  burstname = sprintf('%s', filename(1:end-4));
%   filenamenew = sprintf('C:\\Users\\robin\\Desktop\\emfisis\\files\\%s', filename)
  filenamenew = sprintf('D:\\emfisis\\files\\%s', filename)
  load(filenamenew);
  runFile;
  numChorus
  clearvars -except filelist
end
