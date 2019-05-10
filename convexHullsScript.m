paramfilename = setparam(tspec, fspec, 15, -100);
load(paramfilename);
% uncomment to use higher resolution spectrogram
% fspec = fspec(1):8:fspec(end);
% [~,fspec,tspec,spect] = spectrogram(BuData, 2048, 2048-256, fspec, 35000);
% spect = 10 * log10(spect);
spect2 = spect;
spect2(spect < -100) = -100;
fspec = fspec(1:size(spect, 1));
[ridges, bwRidges, snrMap, staggeredSnr] = find_ridges(spect2, r);
[refinedSnrMap, refinedFeatures, bwRidges] = refinedSnrFiltering(ridges, bwRidges, 15);
% [filteredRidges, bwRidges] = filterRadonAngles(refinedFeatures);
% [ dist, peaks, featureLabels, numPeaks ] = findDstPeaks( bwRidges, ridges );
[featureLabels, numPeaks] = bwlabel(bwRidges);
convexHulls = getConvexHulls(featureLabels, numPeaks);
[chorusAngles, sweeprates, endpoints, chorusLength, numPeaks, validChorus] = getMaximalLine(convexHulls, numPeaks, mu1);

burstimage = figure('visible', 'off');
h = 1;
subplot(4,3,h);pcolor(tspec, fspec, spect);colormap jet;shading flat;
title(sprintf('(%d) Original Spectrogram Starting at\n%s', h, datestr(timestamp)));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
c=colorbar;caxis([-160, -30]);

h = h+1;
subplot(4,3,h);pcolor(tspec, fspec, spect2);shading flat;colormap jet;c=colorbar;caxis([-100, -30]);
title(sprintf('(%d) Spectrogram Min Psd -100', h));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

h = h+1;
subplot(4,3,h);pcolor(tspec, fspec, snrMap);shading flat;colormap jet;colorbar;
title(sprintf('(%d) SNR Map', h));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

h=h+1;
subplot(4,3,4);pcolor(tspec, fspec, ridges);colormap jet;shading flat;colorbar;
title(sprintf('(%d) Detected Features Using Staggered SNR', h));
xlabel('(%d) Duration of event (in seconds)');ylabel('Frequency (Hz)');

h=h+1;
i13=subplot(4,3,h);
pcolor(tspec, fspec, refinedSnrMap);colormap(i13, jet);shading flat;colorbar;
title(sprintf('(%d) Refined SNR Map of Detected Features\nSNR > 50, Must exceed time threshold', h));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

h=h+1;
i12=subplot(4,3,h);
pcolor(tspec, fspec, refinedFeatures);colormap(i12, jet);shading flat;caxis([-100 -30]);colorbar;
title(sprintf('(%d) Refined Features With Additional SNR Filtering', h));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

% h=h+1;
% i13=subplot(4,3,h);
% pcolor(tspec, fspec, filteredRidges);colormap(i13, jet);shading flat;colorbar;
% title(sprintf('(%d) Detected Features Using Radon Filtering', h));
% xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

% h=h+1;
% subplot(4,3,h);pcolor(tspec, fspec, dist);colormap jet;shading flat;colorbar;
% title(sprintf('(%d) Distance Transform', h));
% xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
% 
% h = h+1;
% tempPeaks = peaks;
% tempPeaks(peaks == 0) = 2;
% tempPeaks = tempPeaks- 1;
% i1=subplot(4,3,h);pcolor(tspec, fspec, tempPeaks);colormap(i1, gray);shading flat;colorbar;
% title(sprintf('(%d) Distance Transform Peaks', h));
% xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

h = h+1;
i10 = subplot(4,3,h);
[labels, ~] = bwlabel(bwRidges);
pcolor(tspec, fspec, labels);colormap(i10, colorcube);shading flat;
title(i10, sprintf('(%d) Connected Features Identification', h));
xlabel('Duration of event (in seconds)');
ylabel('Frequency (Hz)');
colorbar;
hold on;
[f ,t] = find(peaks == 1);
plot(tspec(t), fspec(f), 'k*', 'markersize', 1);
hold off;

h = h+1;
i7 = subplot(4,3,h);hold on;
pcolor(tspec, fspec, spect2);colormap(i7, jet);shading flat;c=colorbar;caxis([-100, -30]);
for i = 1:2:size(convexHulls, 1)
  t = convexHulls(i, :);
  t = t(t>0);
  f = convexHulls(i+1, :);
  f = f(f>0);
  plot(tspec(t), fspec(f), 'black', 'linewidth', 1.5);
end
xlim([tspec(1) tspec(end)]);
ylim([fspec(1) fspec(end)]);
hold off;
title(sprintf('(%d) Convex Hulls of Detected Features', h));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

h = h+1;
i8 = subplot(4,3,h);
pcolor(tspec, fspec, spect2);colormap(i8, jet);shading flat;c=colorbar;caxis([-100, -30]);
hold on;
for i = 1:numPeaks
  plot([tspec(endpoints(i, 1)) tspec(endpoints(i, 3))], [fspec(endpoints(i, 2)) fspec(endpoints(i, 4))], 'k', 'linewidth', 1);
end
hold off;
title(sprintf('(%d) Spectrogram With Maximal Line', h));
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

% distribution of sweeprates
h = h+1;
i9 = subplot(4,3,h:12);
histogram(sweeprates / 1000, 'BinWidth', 0.5);
title(i9, sprintf('(%d) Distribution of Sweeprates', h));
xlabel('Sweeprate (KHz / sec)');
xlim([-15 15]);

% render image maximized to screen
set(gcf, 'Position', get(0, 'Screensize'));

% save fig
% change this to the local folder path on your device
figname = sprintf('/run/media/rhowk/SANDISK/emfisis/images/convexHulls/gold/%s5.0.0.jpg', burstname(1:end-5));
saveas(burstimage, figname);
close all hidden