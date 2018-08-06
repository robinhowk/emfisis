function showBurstFigure( tspec, fspec, spect, snrMap, snrThreshold, ...
  features, segmentLabels, spineLabels, spines, timestamp, ...
  chorusElements, chorusCount, figname, fLow, fHigh )

  % original spectrogram
  summary = figure('visible', 'off');
  h1 = subplot(4,2,1);
  imagesc(tspec, fspec, spect);
  colormap(h1, jet);
  c = colorbar;
  title(h1, sprintf('(1) Original Spectrogram Starting at\n%s', datestr(timestamp)));
  xlabel(h1, 'Duration of event in seconds');
  ylabel(h1, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h1, 'YDir', 'normal');
  caxis([-160, -30]);
  hold on;
  line([tspec(1), tspec(end)], [fLow, fLow], 'color', 'black', 'linewidth', 1);
  line([tspec(1), tspec(end)], [fHigh, fHigh], 'color', 'black', 'linewidth', 1);
  hold off;

  % snr map
  h2 = subplot(4,2,2);
  pcolor(tspec, fspec, snrMap);
  colormap(h2, jet);
  c = colorbar;
  title(h2, '(2) SNR Map');
  xlabel(h2, 'Duration of event in seconds');
  ylabel(h1, 'Frequency (Hz)');
  title(c, 'SNR');
  set(h2, 'ydir', 'normal');

  % features
  h3 = subplot(4,2,3);
  features(features == min(spect(:))) = NaN;
  pcolor(tspec, fspec, features);
  colormap(h2, jet);
  c = colorbar;
  title(h3, sprintf('(3) Features with SNR > %d', snrThreshold));
  xlabel(h3, 'Duration of event (in seconds)');
  ylabel(h3, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h3, 'YDir', 'normal');

  % spine segments
  h4 = subplot(4,2,4);
  imagesc(tspec, fspec, segmentLabels);
  colormap(h4, colorcube);
  c = colorbar;
  title(h4, '(4) Spine Segments');
  xlabel(h4, 'Duration of event in seconds');
  ylabel(h4, 'Frequency (Hz)');
  set(h4, 'YDir', 'normal');

  % spine labels
  h5 = subplot(4,2,5);
  imagesc(tspec, fspec, spineLabels);
  colormap(h5, colorcube);
  colorbar;
  title(h5, '(5) Identified Spines');
  xlabel(h5, 'Duration of event in seconds');
  ylabel(h5, 'Frequency (Hz)');
  set(h5, 'YDir', 'normal');

  % spines with spectrogram
  h6 = subplot(4,2,6);
  imagesc(tspec, fspec, spect);
  colormap(h6, jet);
  colorbar;
  title(h6, '(6) Spectrogram with Identified Spines');
  xlabel(h6, 'Duration of event in seconds');
  ylabel(h6, 'Frequency (Hz)');
  set(h6, 'YDir', 'normal');
  hold on;
  [f, t] = find(spines == 1);
  plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
  hold off;

  % spectrogram with spnies and 1st degree LOBF, used for determining
  % sweeprate/chorus angle
  h7 = subplot(4,2,7);
  imagesc(tspec, fspec, spect);
  colormap(h7, jet);
  colorbar;
  title(h7, '(7) Spines with 1st Degree Line of Best Fit');
  xlabel(h7, 'Duration of event in seconds');
  ylabel(h7, 'Frequency (Hz)');
  set(h7, 'ydir', 'normal');
  hold on;
  plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
  for i = 1:chorusCount
    tvec = chorusElements(i).startInd:chorusElements(i).stopInd;
    fvec = chorusElements(i).fp1;
    plot(tvec, fvec, 'k', 'linewidth', 1);
  end
  hold off;

  % spectrogram with spines and 3rd degree lobf, used for selecting
  % points save to the cdf
  h8 = subplot(4,2,8);
  imagesc(tspec, fspec, spect);
  colormap(h8, jet);
  colorbar;
  title(h8, '(8) Spines with 3rd Degree Line of Best Fit');
  xlabel(h8, 'Duration of event in seconds');
  ylabel(h8, 'Frequency (Hz)');
  set(h8, 'ydir', 'normal');
  hold on;
  plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
  for i = 1:chorusCount
    tvec = chorusElements(i).startInd:chorusElements(i).stopInd;
    fvec = chorusElements(i).freq;
    plot(tvec, fvec, 'k', 'linewidth', 1);
  end
  hold off;
    
  % render image maximized to screen
  set(gcf, 'Position', get(0, 'Screensize'));

  % save fig
  saveas(summary, figname);
  close all
end

