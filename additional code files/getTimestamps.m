filelist = dir(fullfile('C:\Users\robin\Desktop\emfisis\source files\20121117', '*.mat'));
% filelist = dir(fullfile('C:\emfisis\source files\20121101', '*.mat'))
fileInfo = cell(size(filelist, 1), 2);

for iFile = 1:size(filelist, 1)
  filename = filelist(iFile).name;
  filenamenew = sprintf('C:\\Users\\robin\\Desktop\\emfisis\\source files\\20121117\\%s', filename);
%   filenamenew = sprintf('D:\\emfisis\\files\\%s', filename)
  load(filenamenew);
  fileInfo{iFile, 1} = filename;
  fileInfo{iFile, 2} = char(timestamp);
  clearvars -except filelist iFile fileInfo
end
T = cell2table(fileInfo);
writetable(T,'C:\\Users\\robin\\Desktop\\emfisis\\source files\\20121117\\20121117.csv')
