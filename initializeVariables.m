function [ counts ] = initializeVariables( paramfilename )
    load(paramfilename, 'histEdges');
    chorusAngles = zeros(1, length(histEdges.chorusAngles) - 1);
    sweeprates = zeros(1, length(histEdges.sweeprates) - 1);
    hourTotals = zeros(1, 24);
    psdSums = [];
    sweepratesList = [];
    
    counts = struct('chorusAngles', chorusAngles, ...
        'sweeprates', sweeprates, ...
        'hourlyTotals', hourTotals, ...
        'psdSums', psdSums, ...
        'sweepratesList', sweepratesList);
end