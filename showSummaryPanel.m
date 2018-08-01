function showSummaryPanel( counts, edges, figname )
    
    summary = figure('position', [80 80 1600 900]);
    % plot hourly totals
    h1 = subplot(3, 1, 1);
    bar(0:1:23, counts.hourlyTotals, 'histc');
    axis(h1, 'tight');
    title(h1, 'Total Chorus, By Hour');
    xlabel('Hour');
    ylabel('Total Chorus');
    
    % distribution of sweeprates
    h2 = subplot(3,1,2);
    bins = (edges.sweeprates(1:end-1) + edges.sweeprates(2:end)) / 2;
    bar(bins, counts.sweeprates / sum(counts.sweeprates), 'histc');
    axis(h2, 'tight');
    title(h2, 'Distribution of Sweeprates');
    xlabel('Sweeprate (KHz / sec)');
    ylabel('Estimated\newlineprobability');
    
    h3 = subplot(3,1,3);
    bins = (edges.chorusAngles(1:end-1) + edges.chorusAngles(2:end)) / 2;
    bar(bins, counts.chorusAngles / sum(counts.chorusAngles), 'histc');
    axis(h3, 'tight');
    title(h3, 'Distribution of Chorus Angles');
    ylabel('Estimated\newlineprobability');
    
    % save figure
    saveas(summary, figname);
    close all
end

