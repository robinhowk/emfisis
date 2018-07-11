function [ sourceFiles ] = getSourceFiles ( ppFilename, fceFilename, timestamp)
    date = datestr(timestamp, 'yyyy MM DD');
    year = date(1:4);
    month = date(6:7);
    day = date(9:10);
    
    filelist = dir(sprintf('/var/EMFISIS-SOC/OUT/RBSP-A/L2/%s/%s/%s', year, month, day));
    sourceNum = 0;
    for i = 1:numel(filelist)
        if size(regexp(filelist(i).name, 'rbsp-[a,b]_WFR-waveform-continuous-burst_emfisis?'), 1) == 1
            filename = filelist(i).name;
            sourceNum = sourceNum + 1;
            sourceFiles{sourceNum, 1} = filename;
        end
    end
    sourceFiles{sourceNum + 1, 1} = ppFilename;
    sourceFiles{sourceNum + 2, 1} = fceFilename;
end