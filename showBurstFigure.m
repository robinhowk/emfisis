function showBurstFigure( tspec, fspec, spect, ridges, timestamp, spines, spinesSnr, ...
    spinesFinal, chorusElements, chorusCount, edges, figname, fLow, fHigh )

    % original spectrogram
    summary = figure('position', [80 80 1600 900], 'visible', 'off');
    h1 = subplot(3,2,1);
    imagesc(tspec, fspec, spect);
    colormap(h1, jet);
    c = colorbar;
    title(h1, sprintf('(1) Original Spectrogram Starting at\n%s', datestr(timestamp)));
    xlabel(h1, 'Duration of event in seconds');
    ylabel(h1, 'Frequency (Hz)');
    title(c, '10*log10(psd)');
    set(h1, 'YDir', 'normal');
    hold on;
    line([tspec(1), tspec(end)], [fLow, fLow], 'color', 'black', 'linewidth', 1);
    line([tspec(1), tspec(end)], [fHigh, fHigh], 'color', 'black', 'linewidth', 1);
    hold off;
    
    % ridges
    h2 = subplot(3,2,2);
    imagesc(tspec, fspec, ridges);
    colormap(h2, jet);
    c = colorbar;
    title(h2, '(2) Ridges, Local SNR = 10');
    xlabel(h2, 'Duration of event (in seconds)');
    ylabel(h2, 'Frequency (Hz)');
    title(c, '10*log10(psd)');
    set(h2, 'YDir', 'normal');
    
    % spines from gradient
    h3 = subplot(3,2,3);
    imagesc(tspec, fspec, spect);
    colormap(h3, jet);
    c = colorbar;
    title(h3, '(3) Spines Found From Gradient');
    xlabel(h3, 'Duration of event in seconds');
    ylabel(h3, 'Frequency (Hz)');
    title(c, '10*log10(psd)');
    set(h3, 'YDir', 'normal');
    hold on;
    [f, t] = find(spines == 1);
    plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
    hold off;
    
    % spines with snr = 15
    h4 = subplot(3,2,4);
    imagesc(tspec, fspec, spect);
    colormap(h4, jet);
    colorbar;
    title(h4, '(4) Spines with SNR Threshold = 5');
    xlabel(h4, 'Duration of event in seconds');
    ylabel(h4, 'Frequency (Hz)');
    set(h4, 'YDir', 'normal');
    [f, t] = find(spinesSnr == 1);
    hold on;
    plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
    hold off;
    
    % final spines
    h5 = subplot(3,2,5);
    imagesc(tspec, fspec, spect);
    colormap(h5, jet);
    colorbar;
    title(h5, '(5) Chorus Spines');
    xlabel(h5, 'Duration of event in seconds');
    ylabel(h5, 'Frequency (Hz)');
    set(h5, 'YDir', 'normal');
    hold on;
    [f, t] = find(spinesFinal == 1);
    plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
    hold off;
    
    h6 = subplot(3,2,6);
    if chorusCount > 0
        sweeprates = [chorusElements.sweeprate];
    else
        sweeprates = [];
    end
    histogram(sweeprates / 1000, edges);
    axis tight;
    title(h6, '(6) Distribution of Sweeprates');
    xlabel('Sweeprate (KHz / second)');
    ylabel('Total');
    
    % save fig
    saveas(summary, figname);
    close all
end

