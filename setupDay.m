function [ summaryFigFilename, cdfFilename ] = setupDay( date, paramstring )
%SETUPDAY setup directores and filename strings for day
  summaryFigFilename = sprintf('%s/%04d%02d%02d_a_%s_summary.jpg', figFolder, date.Year, date.Month, date.Day, paramstring);
   
    
    cdfFilename = sprintf('%s/rbsp-a_chorus-elements_%04d%02d%02d_v1.0.0', cdfFolder, date.Year, date.Month, date.Day);
end

