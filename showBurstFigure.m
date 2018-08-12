function showBurstFigure( tspec, fspec, spect, snrMap, snrThreshold, ...
  features, segmentLabels, spineLabels, spines, timestamp, ...
  chorusElements, chorusCount, figname, fLow, fHigh, skeleton, dist, ...
  grad, grad2)

  % original spectrogram
  summary = figure('visible', 'off');
  h1 = subplot(4,3,1);
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
  h2 = subplot(4,3,2);
  pcolor(tspec, fspec, snrMap);
  colormap(h2, jet);
  c = colorbar;
  title(h2, '(2) SNR Map');
  xlabel(h2, 'Duration of event in seconds');
  ylabel(h1, 'Frequency (Hz)');
  title(c, 'SNR');
  set(h2, 'ydir', 'normal');
  shading flat;
  
  % features
  h3 = subplot(4,3,3);
  features(features == min(spect(:))) = NaN;
  pcolor(tspec, fspec, features);
  colormap(h3, jet);
  c = colorbar;
  title(c, '10*log10(psd)');
  title(h3, sprintf('(3) Features with SNR > %d', snrThreshold));
  xlabel(h3, 'Duration of event (in seconds)');
  ylabel(h3, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h3, 'YDir', 'normal');
  caxis([-160, -30]);
  shading flat;
  
  % distance transform
  h9 = subplot(4,3,4);
  pcolor(tspec, fspec, dist);
  shading(h9, 'flat');
  colormap(h9, jet);
  c = colorbar;
  title(h9, '(4), Distance Transform of Detected Features');
  xlabel(h9, 'Duration of event (in seconds)');
  ylabel(h9, 'Frequency (Hz)');
  set(h9, 'ydir', 'normal');
  
  % gradient
  h10 = subplot(4,3,5);
  imagesc(tspec, fspec, grad);
  colormap(h10, gray);
  c = colorbar;
  title(h10, '(5) Gradient of Distance Transform');
  xlabel(h10, 'Duration of event (in seconds)');
  ylabel(h10, 'Frequency (Hz)');
  set(h10, 'ydir', 'normal');
  
  % gradient after threshold 
  h11 = subplot(4,3,6);
  imagesc(tspec, fspec, grad2);
  colormap(h11, gray);
  c = colorbar;
  title(h11, '(6) Gradient Threshold at 0.75');
  xlabel(h11, 'Duration of event (in seconds)');
  ylabel(h11, 'Frequency (Hz)');
  set(h11, 'ydir', 'normal');
  
  % gradient after cleaning
  h12 = subplot(4,3,7);
  imagesc(tspec, fspec, skeleton);
  colormap(h12, gray);
  c = colorbar;
  title(h12, '(7) Gradient after Thinnng and Cleaning');
  xlabel(h12, 'Duration of event (in seconds)');
  ylabel(h12, 'Frequency (Hz)');
  set(h12, 'ydir', 'normal');
  
  % spine segments
  h4 = subplot(4,3,8);
  imagesc(tspec, fspec, segmentLabels);
  colormap(h4, colorcube);
  c = colorbar;
  title(h4, '(8) Spine Segments');
  xlabel(h4, 'Duration of event in seconds');
  ylabel(h4, 'Frequency (Hz)');
  set(h4, 'YDir', 'normal');

  % spine labels
  h5 = subplot(4,3,9);
  imagesc(tspec, fspec, spineLabels);
  colormap(h5, colorcube);
  colorbar;
  title(h5, '(9) Identified Spines');
  xlabel(h5, 'Duration of event in seconds');
  ylabel(h5, 'Frequency (Hz)');
  set(h5, 'YDir', 'normal');

  % spines with spectrogram
  h6 = subplot(4,3,10);
  imagesc(tspec, fspec, spect);
  colormap(h6, jet);
  colorbar;
  caxis([-160, -30]);
  title(c, '10*log10(psd)');
  title(h6, '(10) Spectrogram with Identified Spines');
  xlabel(h6, 'Duration of event in seconds');
  ylabel(h6, 'Frequency (Hz)');
  set(h6, 'YDir', 'normal');
  hold on;
  [f, t] = find(spines == 1);
  plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
  hold off;

  % spectrogram with spnies and 1st degree LOBF, used for determining
  % sweeprate/chorus angle
  h7 = subplot(4,3,11);
  imagesc(tspec, fspec, spect);
  colormap(h7, jet);
  colorbar;
  caxis([-160, -30]);
  title(c, '10*log10(psd)');
  title(h7, '(11) Spectrogram with 1st Degree Line of Best Fit');
  xlabel(h7, 'Duration of event in seconds');
  ylabel(h7, 'Frequency (Hz)');
  set(h7, 'ydir', 'normal');
  hold on;
  for i = 1:chorusCount
    tvec = chorusElements(i).startInd:chorusElements(i).stopInd;
    fvec = chorusElements(i).fp1;
    plot(tspec(tvec), fspec(fvec), 'k*', 'markersize', 2);
  end
  hold off;

  % spectrogram with spines and 3rd degree lobf, used for selecting
  % points save to the cdf
  h8 = subplot(4,3,12);
  imagesc(tspec, fspec, spect);
  colormap(h8, jet);
  colorbar;
  caxis([-160, -30]);
  title(c, '10*log10(psd)');
  title(h8, '(12) Spectrogram with 3rd Degree Line of Best Fit');
  xlabel(h8, 'Duration of event in seconds');
  ylabel(h8, 'Frequency (Hz)');
  set(h8, 'ydir', 'normal');
  hold on;
  for i = 1:chorusCount
    tvec = chorusElements(i).startInd:chorusElements(i).stopInd;
    fvec = chorusElements(i).freq;
    plot(tspec(tvec), fspec(fvec), 'k*', 'markersize', 2);
  end
  hold off;
    
  % render image maximized to screen
  set(gcf, 'Position', get(0, 'Screensize'));

  % save fig
  saveas(summary, figname);
  close all
end

