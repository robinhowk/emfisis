function showBurstFigure( tspec, fspec, spect, snrMap, snrThreshold, ridges, ...
  features, segmentLabels, spineLabels, spines, timestamp, ...
  chorusElements, chorusCount, figname, fLow, fHigh, skeleton, dist, ...
  dist2, imagefile)

  % original spectrogram
  summary = figure('visible', 'off');
  h1 = subplot(4,4,1);
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
  h2 = subplot(4,4,2);
  imagesc(tspec, fspec, snrMap);
  colormap(h2, jet);
  c = colorbar;
  title(h2, '(2) SNR Map');
  xlabel(h2, 'Duration of event in seconds');
  ylabel(h2, 'Frequency (Hz)');
  title(c, 'SNR');
  set(h2, 'ydir', 'normal');
  
  % snr histogram
  h15 = subplot(4,4,3);
  hist(snrMap(:), 50);
  title(h15, '(3) Histogram of SNR Values');
  xlabel(h15, 'SNR');
  
  % features
  h3 = subplot(4,4,4);
  features(features == min(spect(:))) = NaN;
  pcolor(tspec, fspec, features);
  colormap(h3, jet);
  c = colorbar;
  title(c, '10*log10(psd)');
  title(h3, sprintf('(4) Features wiht SNR > \n%.01d', snrThreshold));
  xlabel(h3, 'Duration of event (in seconds)');
  ylabel(h3, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h3, 'YDir', 'normal');
  caxis([-160, -30]);
  shading flat;
  
  % ridges
  h13 = subplot(4,4,5);
  ridges(ridges == min(ridges(:))) = NaN;
  pcolor(tspec, fspec, ridges);
  colormap(h13, jet);
  c = colorbar;
  title(c, '10*log10(psd)');
  title(h13, '(5) Ridge Features');
  xlabel(h13, 'Duration of event (in seconds)');
  ylabel(h13, 'Frequency (Hz)');
  set(h13, 'ydir','normal');
  caxis([-160, -30]);
  shading flat;
  
  % distance transform
  h9 = subplot(4,4,6);
  pcolor(tspec, fspec, dist);
  shading(h9, 'flat');
  colormap(h9, jet);
  c = colorbar;
  title(h9, '(6), Distance Transform of Ridge Features');
  xlabel(h9, 'Duration of event (in seconds)');
  ylabel(h9, 'Frequency (Hz)');
  set(h9, 'ydir', 'normal');
  
  % thresholded distance transform
  h10 = subplot(4,4,7);
  pcolor(tspec, fspec, dist2);
  colormap(h10, jet);
  shading(h10, 'flat');
  c = colorbar;
  title(h10, '(7) Distance Transform Threshold at 1.25');
  xlabel(h10, 'Duration of event (in seconds)');
  ylabel(h10, 'Frequency (Hz)');
  set(h10, 'ydir', 'normal');
  
%   % gradient after threshold 
%   h11 = subplot(4,4,7);
%   imagesc(tspec, fspec, grad2);
%   colormap(h11, gray);
%   c = colorbar;
%   title(h11, '(7) Gradient Threshold at 0.75');
%   xlabel(h11, 'Duration of event (in seconds)');
%   ylabel(h11, 'Frequency (Hz)');
%   set(h11, 'ydir', 'normal');
  
  % gradient after cleaning
  h12 = subplot(4,4,8);
  imagesc(tspec, fspec, skeleton);
  colormap(h12, gray);
  shading(h12, 'flat');
  c = colorbar;
  title(h12, '(8) Skeleton After Thinnng and Cleaning');
  xlabel(h12, 'Duration of event (in seconds)');
  ylabel(h12, 'Frequency (Hz)');
  set(h12, 'ydir', 'normal');
  
  % spine segments
  h4 = subplot(4,4,9);
  imagesc(tspec, fspec, segmentLabels);
  colormap(h4, colorcube);
  c = colorbar;
  title(h4, '(9) Spine Segments');
  xlabel(h4, 'Duration of event in seconds');
  ylabel(h4, 'Frequency (Hz)');
  set(h4, 'YDir', 'normal');

  % spine labels
  h5 = subplot(4,4,10);
  imagesc(tspec, fspec, spineLabels);
  colormap(h5, colorcube);
  colorbar;
  title(h5, '(10) Identified Spines');
  xlabel(h5, 'Duration of event in seconds');
  ylabel(h5, 'Frequency (Hz)');
  set(h5, 'YDir', 'normal');

  % spines with spectrogram
  h6 = subplot(4,4,11);
  imagesc(tspec, fspec, spect);
  colormap(h6, jet);
  colorbar;
  caxis([-160, -30]);
  title(c, '10*log10(psd)');
  title(h6, '(11) Spectrogram with Identified Spines');
  xlabel(h6, 'Duration of event in seconds');
  ylabel(h6, 'Frequency (Hz)');
  set(h6, 'YDir', 'normal');
  hold on;
  [f, t] = find(spines == 1);
  plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
  hold off;

  % spectrogram with spnies and 1st degree LOBF, used for determining
  % sweeprate/chorus angle
  h7 = subplot(4,4,12);
  imagesc(tspec, fspec, spect);
  colormap(h7, jet);
  colorbar;
  caxis([-160, -30]);
  title(c, '10*log10(psd)');
  title(h7, '(12) Spectrogram with 1st Degree Line of Best Fit');
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
  h8 = subplot(4,4,13);
  imagesc(tspec, fspec, spect);
  colormap(h8, jet);
  colorbar;
  caxis([-160, -30]);
  title(c, '10*log10(psd)');
  title(h8, '(13) Spectrogram with 3rd Degree Line of Best Fit');
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
  
  h14 = subplot(4,4,14);
  imagesc(10*log10(imagefile));
  colormap(h14, jet);
  colorbar;
  title(h14, '(14) Full Spectrogram For Reference');
  xlabel(h14, 'Time Index');
  ylabel(h14, 'Frequency Index');
  set(h14, 'ydir', 'normal');
      
  % render image maximized to screen
  set(gcf, 'Position', get(0, 'Screensize'));

  % save fig
  saveas(summary, figname);
  close all
end

